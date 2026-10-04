import Flutter
import UIKit
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Weather background refresh: iOS only accepts BGTaskScheduler handlers
    // registered before launch finishes (registering later, when the farmer first
    // turns weather on, raises an exception). The id must match kWeatherTask in
    // weather_sync.dart and BGTaskSchedulerPermittedIdentifiers in Info.plist.
    // With weather off the task finds no saved farm and does nothing. The
    // background engine also needs the plugins (path_provider) registered.
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: "org.hacknation.fieldassistant.weather",
      earliestBeginInSeconds: NSNumber(value: 3 * 60 * 60))
    WorkmanagerPlugin.registerLaunchHandlers()
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
