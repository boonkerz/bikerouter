package app.wegwiesel.garmin_connect

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

class GarminConnectPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "wegwiesel/garmin")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        // Real Android implementation lands in a follow-up sprint. For now,
        // mirror iOS stub semantics so Dart can detect "not available".
        when (call.method) {
            "isAvailable" -> result.success(false)
            "listDevices" -> result.success(emptyList<Map<String, Any?>>())
            "pickDevices" -> result.success(emptyList<Map<String, Any?>>())
            "sendCode" -> result.error("NOT_IMPLEMENTED", "Garmin send not yet wired on Android", null)
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
