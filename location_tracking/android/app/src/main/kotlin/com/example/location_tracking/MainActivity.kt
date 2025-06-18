package com.example.location_tracking

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.content.SharedPreferences
import android.content.Context

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.location_tracking/location"
    private lateinit var methodChannel: MethodChannel
    private lateinit var sharedPreferences: SharedPreferences

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        sharedPreferences = getSharedPreferences("location_tracking_prefs", Context.MODE_PRIVATE)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        LocationServiceHelper.setMethodChannel(methodChannel)

        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startLocationService" -> {
                    try {
                        LocationServiceHelper.startService(this)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SERVICE_START_ERROR", e.message, null)
                    }
                }
                "stopLocationService" -> {
                    try {
                        LocationServiceHelper.stopService(this)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SERVICE_STOP_ERROR", e.message, null)
                    }
                }
                "isServiceRunning" -> {
                    result.success(sharedPreferences.getBoolean("is_tracking", false))
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Check if service was running before app was killed
        if (sharedPreferences.getBoolean("is_tracking", false)) {
            LocationServiceHelper.startService(this)
        }
    }
}
