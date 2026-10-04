import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:workmanager/workmanager.dart';

import '../core/config.dart';
import 'weather.dart';
import 'weather_risk.dart';

/// Background task id. On iOS it must match BGTaskSchedulerPermittedIdentifiers
/// in ios/Runner/Info.plist.
const kWeatherTask = 'org.hacknation.fieldassistant.weather';

/// Runs in a background isolate when the OS allows it — Android: every few
/// hours, only while the phone has a connection; iOS: when iOS decides
/// (often once a day). Uses the saved farm location, never GPS.
@pragma('vm:entry-point')
void weatherTaskDispatcher() {
  Workmanager().executeTask((task, input) async {
    final r = await Weather.refreshSaved();
    return r != RefreshResult.failed; // false: the OS retries later
  });
}

/// Why the forecast could not be updated, or the farm could not be located.
enum WeatherProblem { none, notUpdated, locationOff, permissionDenied, noFix }

/// Keeps the farm's forecast fresh while the app runs (start, resume, back
/// online) and owns the background task. Grow → Weather listens to it.
///
/// The forecast is for the FARM, saved once with "I'm at my farm now": farmers
/// often only have signal in town or on a hill, and the forecast there would be
/// for the wrong place.
class WeatherSync extends ChangeNotifier {
  FarmLocation? farm;
  Forecast? forecast;
  bool updating = false;
  bool locating = false;
  WeatherProblem problem = WeatherProblem.none;

  StreamSubscription<List<ConnectivityResult>>? _net;
  AppLifecycleListener? _life;
  bool _disposed = false;

  bool get enabled => farm != null;
  List<DayForecast> get upcoming => forecast?.upcoming(DateTime.now()) ?? const [];
  List<WeatherAlert> get alerts => findAlerts(upcoming);
  bool get stale => forecast != null && forecast!.age(DateTime.now()) > kWeatherStaleAfter;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Call once from main(), before any task is scheduled.
  static Future<void> initBackground() async {
    try {
      await Workmanager().initialize(weatherTaskDispatcher);
    } catch (_) {/* no background refresh on this platform; the app still refreshes while open */}
  }

  /// Loads the saved forecast, then refreshes now, on resume and whenever the
  /// phone comes back online.
  Future<void> start() async {
    await _reload();
    _net = Connectivity().onConnectivityChanged.listen((r) {
      if (r.any((c) => c != ConnectivityResult.none)) refresh();
    });
    _life = AppLifecycleListener(onResume: refresh);
    if (enabled) {
      await _schedule();
      await refresh();
    }
  }

  Future<void> _reload() async {
    final d = await Weather.load();
    farm = d.farm;
    forecast = d.forecast;
    _notify();
  }

  /// Downloads a new forecast when one is due ([force]: now). Offline it
  /// fails quietly and keeps the last forecast.
  Future<void> refresh({bool force = false}) async {
    if (updating || locating) return;
    await _reload(); // the background task may have saved a newer one
    final f = forecast;
    if (!enabled || (!force && f != null && f.age(DateTime.now()) < kWeatherRefreshEvery)) return;
    updating = true;
    _notify();
    final r = await Weather.refreshSaved(force: true);
    if (r == RefreshResult.failed) problem = WeatherProblem.notUpdated;
    if (r == RefreshResult.updated) problem = WeatherProblem.none;
    updating = false;
    await _reload();
  }

  /// Turns weather on, or moves the farm: asks for location permission, then
  /// saves the position rounded to [kLocationStepDeg].
  Future<void> setFarmHere() async {
    if (locating) return;
    locating = true;
    problem = WeatherProblem.none;
    _notify();
    try {
      final pos = await _locate();
      if (pos == null) return;
      final here = FarmLocation.rounded(pos.latitude, pos.longitude, DateTime.now());
      final old = await Weather.load();
      final sameFarm = old.farm != null && old.farm!.sameSpot(here);
      await Weather.save(WeatherData(farm: here, forecast: sameFarm ? old.forecast : null));
      await _reload();
      await _schedule();
    } finally {
      locating = false;
      _notify();
    }
    if (enabled) await refresh(force: true);
  }

  Future<Position?> _locate() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        problem = WeatherProblem.locationOff;
        return null;
      }
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p != LocationPermission.whileInUse && p != LocationPermission.always) {
        problem = WeatherProblem.permissionDenied;
        return null;
      }
      try {
        // Low accuracy is plenty for weather and works from cell towers.
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 30)),
        );
      } catch (_) {
        // No fix in time: accept a recent last-known position, not an old one from elsewhere.
        final last = await Geolocator.getLastKnownPosition();
        if (last != null && DateTime.now().difference(last.timestamp) < const Duration(hours: 1)) return last;
        problem = WeatherProblem.noFix;
        return null;
      }
    } catch (_) {
      problem = WeatherProblem.noFix;
      return null;
    }
  }

  /// Opens the screen that fixes the current [problem].
  Future<void> openSettings() async {
    try {
      problem == WeatherProblem.locationOff ? await Geolocator.openLocationSettings() : await Geolocator.openAppSettings();
    } catch (_) {}
  }

  /// Turns weather off: deletes the saved location and forecast and stops the
  /// background task.
  Future<void> turnOff() async {
    try {
      await Workmanager().cancelByUniqueName(kWeatherTask);
    } catch (_) {}
    await Weather.clear();
    problem = WeatherProblem.none;
    await _reload();
  }

  Future<void> _schedule() async {
    try {
      await Workmanager().registerPeriodicTask(
        kWeatherTask,
        kWeatherTask,
        frequency: kWeatherRefreshEvery,
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
    } catch (_) {/* background refresh is a bonus; the app still refreshes while open */}
  }

  @override
  void dispose() {
    _disposed = true;
    _net?.cancel();
    _life?.dispose();
    super.dispose();
  }
}
