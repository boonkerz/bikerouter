import Flutter
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var engine: FlutterEngine?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let flutterEngine = FlutterEngine(name: "main_engine")
        flutterEngine.run()
        GeneratedPluginRegistrant.register(with: flutterEngine)
        self.engine = flutterEngine

        let controller = FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = controller
        window?.makeKeyAndVisible()
    }
}
