package com.silifton.varsitykotha

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // The home-screen widget's data (lib/features/widget/home_widget.dart).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "varsitykotha/widget")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "save" -> {
                        NextClassWidget.save(applicationContext, call.arguments as String)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
