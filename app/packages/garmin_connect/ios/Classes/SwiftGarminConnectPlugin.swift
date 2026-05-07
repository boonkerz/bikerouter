import Flutter
import UIKit
import ConnectIQ

private let kUrlScheme = "wegwiesel-ciq"
private let kIQAppUuid = "07496366-1daf-4b06-8a76-cce54de65c91"
private let kStoreUuid = "00000000-0000-0000-0000-000000000000"
private let kDevicesKey = "wegwiesel.garmin.devices"

public class SwiftGarminConnectPlugin: NSObject, FlutterPlugin {

    private let connectIQ = ConnectIQ.sharedInstance()
    private var devices: [IQDevice] = []
    private var pendingSelection: FlutterResult? = nil
    private var initialized = false
    private weak var registrar: FlutterPluginRegistrar?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "wegwiesel/garmin",
                                           binaryMessenger: registrar.messenger())
        let instance = SwiftGarminConnectPlugin()
        instance.registrar = registrar
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
    }

    private func ensureInitialized() {
        if initialized { return }
        connectIQ?.initialize(withUrlScheme: kUrlScheme, uiOverrideDelegate: nil)
        loadDevices()
        for d in devices {
            connectIQ?.register(forDeviceEvents: d, delegate: self)
        }
        initialized = true
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        ensureInitialized()
        switch call.method {
        case "isAvailable":
            result(true)

        case "listDevices":
            result(devices.map(deviceToMap))

        case "pickDevices":
            // Hands off to Garmin Connect Mobile so the user can authorise devices.
            // The result is sent back asynchronously via openURL.
            if pendingSelection != nil {
                pendingSelection?(FlutterError(code: "BUSY", message: "device picker already open", details: nil))
            }
            pendingSelection = result
            connectIQ?.showDeviceSelection()

        case "sendCode":
            handleSendCode(call: call, result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleSendCode(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let deviceId = args["deviceId"] as? String,
              let code = args["code"] as? String else {
            result(FlutterError(code: "ARGS", message: "deviceId and code required", details: nil))
            return
        }
        guard let uuid = UUID(uuidString: deviceId),
              let device = devices.first(where: { $0.uuid == uuid }) else {
            result(FlutterError(code: "UNKNOWN_DEVICE", message: "device not in cache", details: nil))
            return
        }
        guard let appUuid = UUID(uuidString: kIQAppUuid),
              let storeUuid = UUID(uuidString: kStoreUuid),
              let app = IQApp(uuid: appUuid, store: storeUuid, device: device) else {
            result(FlutterError(code: "APP_INIT", message: "could not build IQApp", details: nil))
            return
        }
        let payload: [String: Any] = ["code": code]
        connectIQ?.sendMessage(payload, to: app, progress: nil) { sendResult in
            switch sendResult {
            case .success:
                result(nil)
            case .failure_AppNotFound:
                result(FlutterError(code: "APP_NOT_FOUND",
                                    message: "Wegwiesel Sync not installed on this device",
                                    details: nil))
            case .failure_DeviceNotAvailable:
                result(FlutterError(code: "DEVICE_NOT_AVAILABLE",
                                    message: "device offline",
                                    details: nil))
            default:
                let label = NSStringFromSendMessageResult(sendResult) ?? "unknown"
                result(FlutterError(code: "SEND_FAILED",
                                    message: "\(label)",
                                    details: nil))
            }
        }
    }

    // MARK: - URL handling (round-trip from Garmin Connect Mobile)

    public func application(_ application: UIApplication,
                            open url: URL,
                            options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        guard url.scheme == kUrlScheme else { return false }
        ensureInitialized()
        if let arr = connectIQ?.parseDeviceSelectionResponse(from: url) as? [IQDevice] {
            devices = arr
            saveDevices()
            for d in devices {
                connectIQ?.register(forDeviceEvents: d, delegate: self)
            }
            pendingSelection?(devices.map(deviceToMap))
            pendingSelection = nil
            return true
        }
        pendingSelection?(FlutterError(code: "PARSE_FAILED",
                                       message: "could not read device list from GCM",
                                       details: url.absoluteString))
        pendingSelection = nil
        return true
    }

    // MARK: - Device persistence (plain JSON — keeps iOS 13 compat)

    private func saveDevices() {
        let payload: [[String: String]] = devices.map { d in
            [
                "uuid": d.uuid.uuidString,
                "modelName": d.modelName ?? "",
                "friendlyName": d.friendlyName ?? "",
                "partNumber": d.partNumber ?? "",
            ]
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: payload, options: [])
            UserDefaults.standard.set(data, forKey: kDevicesKey)
        } catch {
            NSLog("garmin_connect: failed to save devices: \(error)")
        }
    }

    private func loadDevices() {
        guard let data = UserDefaults.standard.data(forKey: kDevicesKey),
              let arr = (try? JSONSerialization.jsonObject(with: data)) as? [[String: String]] else {
            return
        }
        devices = arr.compactMap { dict in
            guard let uuidStr = dict["uuid"], let uuid = UUID(uuidString: uuidStr) else { return nil }
            let model = dict["modelName"] ?? ""
            let name = dict["friendlyName"] ?? ""
            let part = dict["partNumber"] ?? ""
            if part.isEmpty {
                return IQDevice(id: uuid, modelName: model, friendlyName: name)
            }
            return IQDevice(id: uuid, modelName: model, friendlyName: name, partNumber: part)
        }
    }

    private func deviceToMap(_ d: IQDevice) -> [String: Any] {
        let status = connectIQ?.getDeviceStatus(d) ?? .invalidDevice
        return [
            "id": d.uuid.uuidString,
            "name": d.friendlyName ?? "",
            "modelName": d.modelName ?? "",
            "status": statusString(status),
        ]
    }

    private func statusString(_ s: IQDeviceStatus) -> String {
        switch s {
        case .connected: return "connected"
        case .notConnected: return "notConnected"
        case .notFound: return "notPaired"
        case .bluetoothNotReady: return "bluetoothNotReady"
        case .invalidDevice: return "unknown"
        @unknown default: return "unknown"
        }
    }
}

extension SwiftGarminConnectPlugin: IQDeviceEventDelegate {
    public func deviceStatusChanged(_ device: IQDevice, status: IQDeviceStatus) {
        // Status changes don't need to bubble up unless the UI is showing a
        // live list; the current sheet flow only checks status at picker time.
    }
}
