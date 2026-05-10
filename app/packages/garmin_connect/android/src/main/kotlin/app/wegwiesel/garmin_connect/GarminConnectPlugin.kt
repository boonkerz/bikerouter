package app.wegwiesel.garmin_connect

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.garmin.android.connectiq.ConnectIQ
import com.garmin.android.connectiq.IQApp
import com.garmin.android.connectiq.IQDevice
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

private const val IQ_APP_UUID = "07496366-1daf-4b06-8a76-cce54de65c91"

class GarminConnectPlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var connectIQ: ConnectIQ? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    // 0 = init in flight, 1 = ready, 2 = error (e.g. GCM not installed)
    @Volatile private var initState: Int = 0
    private val pendingCalls = mutableListOf<() -> Unit>()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "wegwiesel/garmin")
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
        startInit()
    }

    private fun startInit() {
        val ctx = context ?: return
        connectIQ = ConnectIQ.getInstance(ctx, ConnectIQ.IQConnectType.WIRELESS)
        connectIQ?.initialize(ctx, true, object : ConnectIQ.ConnectIQListener {
            override fun onSdkReady() {
                initState = 1
                drainPending()
            }

            override fun onInitializeError(status: ConnectIQ.IQSdkErrorStatus?) {
                initState = 2
                drainPending()
            }

            override fun onSdkShutDown() {
                initState = 0
            }
        })
    }

    private fun drainPending() {
        synchronized(pendingCalls) {
            val copy = pendingCalls.toList()
            pendingCalls.clear()
            copy.forEach { mainHandler.post(it) }
        }
    }

    private fun runWhenReady(block: () -> Unit) {
        if (initState != 0) {
            block()
            return
        }
        synchronized(pendingCalls) {
            if (initState != 0) {
                block()
            } else {
                pendingCalls.add(block)
            }
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAvailable" -> runWhenReady { result.success(initState == 1) }
            "listDevices" -> runWhenReady { handleList(result) }
            "pickDevices" -> runWhenReady { handleList(result) }
            "sendCode" -> runWhenReady { handleSend(call, result) }
            else -> result.notImplemented()
        }
    }

    private fun handleList(result: MethodChannel.Result) {
        val ciq = connectIQ
        if (initState != 1 || ciq == null) {
            result.success(emptyList<Map<String, Any?>>())
            return
        }
        try {
            val devices = ciq.knownDevices ?: emptyList()
            result.success(devices.map(::deviceToMap))
        } catch (t: Throwable) {
            result.error("LIST_FAILED", t.message, null)
        }
    }

    private fun handleSend(call: MethodCall, result: MethodChannel.Result) {
        val ciq = connectIQ
        if (initState != 1 || ciq == null) {
            result.error("NOT_READY", "Garmin SDK not ready", null)
            return
        }
        val deviceId = call.argument<String>("deviceId")
        val code = call.argument<String>("code")
        if (deviceId.isNullOrEmpty() || code.isNullOrEmpty()) {
            result.error("ARGS", "deviceId and code required", null)
            return
        }
        val target = try {
            ciq.knownDevices?.firstOrNull { it.deviceIdentifier.toString() == deviceId }
        } catch (t: Throwable) {
            result.error("LIST_FAILED", t.message, null)
            return
        }
        if (target == null) {
            result.error("UNKNOWN_DEVICE", "device $deviceId not in known list", null)
            return
        }
        val app = IQApp(IQ_APP_UUID)
        try {
            ciq.sendMessage(target, app, hashMapOf("code" to code)) { _, _, status ->
                when (status) {
                    ConnectIQ.IQMessageStatus.SUCCESS ->
                        mainHandler.post { result.success(null) }
                    ConnectIQ.IQMessageStatus.FAILURE_DEVICE_NOT_CONNECTED ->
                        mainHandler.post { result.error("DEVICE_NOT_AVAILABLE", "device offline", null) }
                    ConnectIQ.IQMessageStatus.FAILURE_INVALID_DEVICE ->
                        mainHandler.post { result.error("APP_NOT_FOUND", "Wegwiesel Sync not installed", null) }
                    else ->
                        mainHandler.post { result.error("SEND_FAILED", status.toString(), null) }
                }
            }
        } catch (t: Throwable) {
            result.error("SEND_FAILED", t.message, null)
        }
    }

    private fun deviceToMap(d: IQDevice): Map<String, Any?> = mapOf(
        "id" to d.deviceIdentifier.toString(),
        "name" to (d.friendlyName ?: ""),
        "modelName" to (d.friendlyName ?: ""),
        "status" to when (d.status) {
            IQDevice.IQDeviceStatus.CONNECTED -> "connected"
            IQDevice.IQDeviceStatus.NOT_CONNECTED -> "notConnected"
            IQDevice.IQDeviceStatus.NOT_PAIRED -> "notPaired"
            else -> "unknown"
        },
    )

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        try {
            context?.let { connectIQ?.shutdown(it) }
        } catch (_: Throwable) {
            // ignore — shutdown isn't strictly required and can throw if init never finished
        }
        channel.setMethodCallHandler(null)
    }
}
