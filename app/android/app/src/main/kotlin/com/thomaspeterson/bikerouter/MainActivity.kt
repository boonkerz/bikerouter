package com.thomaspeterson.bikerouter

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Wear OS companion bridge. Idempotent: no-ops if no watch is
        // paired, so it's safe to install unconditionally.
        WatchBridge.install(flutterEngine, applicationContext)
    }
}
