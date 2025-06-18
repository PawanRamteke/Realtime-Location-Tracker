package com.example.location_tracking

import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import io.flutter.plugin.common.MethodChannel

object LocationServiceHelper {
    private const val TAG = "LocationServiceHelper"

    fun startService(context: Context) {
        Log.d(TAG, "Starting location service")
        val serviceIntent = Intent(context, LocationService::class.java).apply {
            action = "START_TRACKING"
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
    }

    fun stopService(context: Context) {
        Log.d(TAG, "Stopping location service")
        val serviceIntent = Intent(context, LocationService::class.java).apply {
            action = "STOP_TRACKING"
        }
        context.stopService(serviceIntent)
    }

    fun setMethodChannel(channel: MethodChannel) {
        LocationService.setMethodChannel(channel)
    }
} 