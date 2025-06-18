package com.example.location_tracking

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import android.content.SharedPreferences

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON") {
            
            Log.d("BootReceiver", "Device boot completed")
            
            // Check if tracking was active before reboot
            val sharedPreferences: SharedPreferences = 
                context.getSharedPreferences("location_tracking_prefs", Context.MODE_PRIVATE)
            
            if (sharedPreferences.getBoolean("is_tracking", false)) {
                Log.d("BootReceiver", "Restarting location service after boot")
                LocationServiceHelper.startService(context)
            }
        }
    }
} 