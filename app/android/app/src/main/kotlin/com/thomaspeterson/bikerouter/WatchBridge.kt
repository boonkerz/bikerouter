package com.thomaspeterson.bikerouter

import android.content.Context
import com.google.android.gms.tasks.Tasks
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.MessageClient
import com.google.android.gms.wearable.Node
import com.google.android.gms.wearable.NodeClient
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await

/**
 * Phone-side bridge for the Wear OS companion. Mirrors the iOS
 * [WatchBridge.swift]: the Flutter `wegwiesel/watch` method channel calls
 * here, and we push the payload to the paired watch via the Wearable Data
 * Layer.
 *
 * We use both APIs the SDK provides:
 *  - [DataClient.putDataItem] writes a *durable* item that the watch
 *    sees the next time it wakes up, even if the connection drops.
 *    Equivalent to iOS's `transferUserInfo`.
 *  - [MessageClient.sendMessage] is *live* — only delivers when the
 *    watch is currently reachable. Equivalent to iOS's `sendMessage`.
 *
 * `/wegwiesel/nav` is the well-known DataItem path used by both phone
 * (writer) and watch (listener) — change in tandem on both sides.
 */
class WatchBridge(context: Context, private val channel: MethodChannel) :
    MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL_NAME = "wegwiesel/watch"
        const val PATH_NAV = "/wegwiesel/nav"
        const val PATH_STOP = "/wegwiesel/stop"

        fun install(flutterEngine: FlutterEngine, context: Context) {
            val ch = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            ch.setMethodCallHandler(WatchBridge(context, ch))
        }
    }

    private val data: DataClient = Wearable.getDataClient(context)
    private val messages: MessageClient = Wearable.getMessageClient(context)
    private val nodes: NodeClient = Wearable.getNodeClient(context)
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    override fun onMethodCall(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isReachable" -> scope.launch {
                val reachable = try {
                    nodes.connectedNodes.await().any { it.isNearby }
                } catch (_: Exception) {
                    false
                }
                channel.invokeMethod("__noop__", null) // keep imports lively
                runOnPlatformThread { result.success(reachable) }
            }

            "updateNavigation" -> {
                val args = call.arguments as? Map<*, *>
                if (args == null) {
                    result.error("bad_args", "expected map", null)
                    return
                }
                publish(args, path = PATH_NAV)
                result.success(null)
            }

            "stopNavigation" -> {
                publish(mapOf("direction" to "idle"), path = PATH_STOP)
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    /** Fire-and-forget publish on both the durable + live channels. */
    private fun publish(payload: Map<*, *>, path: String) {
        scope.launch {
            // Durable: shows up on the watch when it next wakes.
            try {
                val request = PutDataMapRequest.create(path).apply {
                    dataMap.putString("direction",
                        payload["direction"]?.toString() ?: "idle")
                    payload["distanceMeters"]?.let {
                        dataMap.putInt("distanceMeters",
                            (it as Number).toInt())
                    }
                    payload["remainingKm"]?.let {
                        dataMap.putDouble("remainingKm",
                            (it as Number).toDouble())
                    }
                    payload["remainingMinutes"]?.let {
                        dataMap.putInt("remainingMinutes",
                            (it as Number).toInt())
                    }
                    payload["streetName"]?.let {
                        dataMap.putString("streetName", it.toString())
                    }
                    // Wearable de-dupes identical PutData calls; the timestamp
                    // forces every navigation tick to actually propagate.
                    dataMap.putLong("ts", System.currentTimeMillis())
                }.asPutDataRequest().setUrgent()
                Tasks.await(data.putDataItem(request))
            } catch (_: Exception) { /* best-effort */ }

            // Live: snappy update while the watch is foregrounded.
            try {
                val connected = nodes.connectedNodes.await()
                val bytes = serialize(payload)
                connected.filter(Node::isNearby).forEach { node ->
                    try {
                        Tasks.await(messages.sendMessage(node.id, path, bytes))
                    } catch (_: Exception) { /* best-effort per node */ }
                }
            } catch (_: Exception) { /* best-effort */ }
        }
    }

    /**
     * Serializes the payload into a compact pipe-separated string —
     * MessageClient takes a ByteArray, and a JSON dep just for this
     * single call would be overkill. The watch's onMessageReceived
     * parses with the same convention.
     *
     * Format: `direction=…|distanceMeters=…|remainingKm=…|…`
     */
    private fun serialize(payload: Map<*, *>): ByteArray {
        val sb = StringBuilder()
        var first = true
        for ((k, v) in payload) {
            if (!first) sb.append('|')
            sb.append(k.toString()).append('=').append(v?.toString() ?: "")
            first = false
        }
        return sb.toString().toByteArray(Charsets.UTF_8)
    }

    private fun runOnPlatformThread(block: () -> Unit) {
        // MethodChannel.Result callbacks must run on the platform thread.
        // The Flutter engine dispatches via the channel's BinaryMessenger.
        android.os.Handler(android.os.Looper.getMainLooper()).post(block)
    }
}
