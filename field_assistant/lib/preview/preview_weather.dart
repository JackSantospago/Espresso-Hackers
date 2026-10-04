import '../services/weather.dart';
import '../services/weather_sync.dart';
import 'fake_data.dart';

/// [WeatherSync] with no GPS, network or background task: starts with weather
/// on and [fakeForecast]; "Turn off" and "I'm at my farm" work in memory, so
/// both the off and the on layout can be tried. Pass `on: false` to start off.
class PreviewWeather extends WeatherSync {
  PreviewWeather({bool on = true}) {
    if (on) _turnOn();
  }

  void _turnOn() {
    farm = FarmLocation(-0.40, 36.95, DateTime.now());
    forecast = fakeForecast();
  }

  @override
  Future<void> start() async {}

  @override
  Future<void> refresh({bool force = false}) async {
    if (!enabled || updating) return;
    updating = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    forecast = fakeForecast();
    updating = false;
    notifyListeners();
  }

  @override
  Future<void> setFarmHere() async {
    locating = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    _turnOn();
    locating = false;
    problem = WeatherProblem.none;
    notifyListeners();
  }

  @override
  Future<void> turnOff() async {
    farm = null;
    forecast = null;
    notifyListeners();
  }

  @override
  Future<void> openSettings() async {}
}
