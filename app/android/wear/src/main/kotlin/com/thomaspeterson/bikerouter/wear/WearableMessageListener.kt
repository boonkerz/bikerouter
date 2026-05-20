package com.thomaspeterson.bikerouter.wear

import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService

/**
 * Receives navigation pushes from the paired phone. The phone-side bridge
 * sends each update twice — durable via DataClient and (when reachable)
 * live via MessageClient. We route both into [NavigationStateHolder], and
 * the Compose UI re-renders.
 *
 * Paths and field names match the phone-side WatchBridge.kt constants
 * (/wegwiesel/nav, /wegwiesel/stop).
 */
class WearableMessageListener : WearableListenerService() {

    override fun onDataChanged(dataEvents: DataEventBuffer) {
        dataEvents.forEach { event ->
            val item = event.dataItem
            val path = item.uri.path ?: return@forEach
            if (!path.startsWith("/wegwiesel/")) return@forEach
            val map = DataMapItem.fromDataItem(item).dataMap
            val payload = mutableMapOf<String, Any?>().apply {
                if (map.containsKey("direction")) {
                    put("direction", map.getString("direction"))
                }
                if (map.containsKey("distanceMeters")) {
                    put("distanceMeters", map.getInt("distanceMeters"))
                }
                if (map.containsKey("remainingKm")) {
                    put("remainingKm", map.getDouble("remainingKm"))
                }
                if (map.containsKey("remainingMinutes")) {
                    put("remainingMinutes", map.getInt("remainingMinutes"))
                }
                if (map.containsKey("streetName")) {
                    put("streetName", map.getString("streetName"))
                }
            }
            NavigationStateHolder.apply(payload)
        }
    }

    override fun onMessageReceived(messageEvent: MessageEvent) {
        if (!messageEvent.path.startsWith("/wegwiesel/")) return
        val text = String(messageEvent.data, Charsets.UTF_8)
        NavigationStateHolder.apply(parsePipeSeparated(text))
    }

    /**
     * Inverse of WatchBridge.serialize: turns
     * "direction=left|distanceMeters=120|…" into a typed map. We make
     * the numeric fields ints/doubles so [NavigationStateHolder.apply]
     * doesn't need to re-cast.
     */
    private fun parsePipeSeparated(text: String): Map<String, Any?> {
        if (text.isEmpty()) return emptyMap()
        val out = mutableMapOf<String, Any?>()
        for (pair in text.split('|')) {
            val eq = pair.indexOf('=')
            if (eq < 0) continue
            val key = pair.substring(0, eq)
            val value = pair.substring(eq + 1)
            out[key] = when (key) {
                "distanceMeters", "remainingMinutes" -> value.toIntOrNull() ?: value
                "remainingKm" -> value.toDoubleOrNull() ?: value
                else -> value
            }
        }
        return out
    }
}
