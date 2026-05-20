import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Workaround for flutter/flutter#183900:
    // Swizzle createTouchRateCorrectionVSyncClientIfNeeded to prevent
    // SIGSEGV crash on ProMotion devices (iOS 26) where engine is not
    // yet initialized when viewDidLoad fires.
    FlutterViewController.swizzleVSyncClientCreation()

    GeneratedPluginRegistrant.register(with: self)
    // Bridge for the paired Apple Watch (v2.2). The bridge no-ops when
    // there's no watch paired, so it's safe to register unconditionally.
    if let registrar = self.registrar(forPlugin: "WatchBridge") {
      WatchBridge.register(with: registrar)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

extension FlutterViewController {
  static func swizzleVSyncClientCreation() {
    let selector = NSSelectorFromString("createTouchRateCorrectionVSyncClientIfNeeded")
    guard let original = class_getInstanceMethod(FlutterViewController.self, selector) else {
      return
    }
    let replacement = class_getInstanceMethod(
      FlutterViewController.self,
      #selector(FlutterViewController.noopVSyncClient)
    )!
    method_exchangeImplementations(original, replacement)
  }

  @objc func noopVSyncClient() {
    // Intentionally empty - prevents crash on ProMotion + iOS 26
  }
}
