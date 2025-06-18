package com.example.location_tracking

import android.app.*
import android.content.Context
import android.content.Intent
import android.location.Location
import android.os.*
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.*
import android.util.Log
import android.app.PendingIntent
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat
import android.Manifest
import android.app.NotificationManager
import android.app.NotificationChannel
import android.graphics.Color
import io.flutter.plugin.common.MethodChannel
import android.content.SharedPreferences
import com.google.android.gms.location.Priority

class LocationService : Service() {
    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var locationCallback: LocationCallback
    private lateinit var sharedPreferences: SharedPreferences
    private var isTracking = false

    companion object {
        private const val NOTIFICATION_CHANNEL_ID = "location_tracking_channel"
        private const val NOTIFICATION_ID = 12345
        private const val SHARED_PREFS_NAME = "location_tracking_prefs"
        private const val TRACKING_STATE_KEY = "is_tracking"
        private const val TAG = "LocationService"

        private var methodChannel: MethodChannel? = null

        fun setMethodChannel(channel: MethodChannel) {
            methodChannel = channel
        }
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "LocationService onCreate")
        
        sharedPreferences = getSharedPreferences(SHARED_PREFS_NAME, Context.MODE_PRIVATE)
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        
        createNotificationChannel()
        setupLocationCallback()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Location Tracking",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Used for tracking location in background"
                enableLights(true)
                lightColor = Color.BLUE
                enableVibration(true)
                setShowBadge(false)
            }

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun setupLocationCallback() {
        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                locationResult.lastLocation?.let { location ->
                    Log.d(TAG, "Location update: ${location.latitude}, ${location.longitude}")
                    Log.d(TAG, "Location accuracy: ${location.accuracy}, speed: ${location.speed}")
                    sendLocationToFlutter(location)
                }
            }
        }
    }

    private fun sendLocationToFlutter(location: Location) {
        val locationData = HashMap<String, Any>()
        locationData["latitude"] = location.latitude
        locationData["longitude"] = location.longitude
        locationData["accuracy"] = location.accuracy
        locationData["altitude"] = location.altitude
        locationData["speed"] = location.speed
        locationData["timestamp"] = System.currentTimeMillis()

        Log.d(TAG, "Sending location to Flutter: $locationData")
        methodChannel?.invokeMethod("onLocationUpdate", locationData)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "LocationService onStartCommand with action: ${intent?.action}")
        
        when (intent?.action) {
            "START_TRACKING" -> startTracking()
            "STOP_TRACKING" -> stopTracking()
        }

        return START_STICKY
    }

    private fun startTracking() {
        if (isTracking) {
            Log.d(TAG, "Location tracking already active, skipping start")
            return
        }
        Log.d(TAG, "Starting location tracking")

        isTracking = true
        sharedPreferences.edit().putBoolean(TRACKING_STATE_KEY, true).apply()

        startForeground(NOTIFICATION_ID, createNotification())
        requestLocationUpdates()
    }

    private fun stopTracking() {
        if (!isTracking) return
        Log.d(TAG, "Stopping location tracking")

        isTracking = false
        sharedPreferences.edit().putBoolean(TRACKING_STATE_KEY, false).apply()

        fusedLocationClient.removeLocationUpdates(locationCallback)
        stopForeground(true)
        stopSelf()
    }

    private fun createNotification(): Notification {
        val notificationIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            notificationIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("Location Tracking Active")
            .setContentText("Tracking your location in background")
            .setSmallIcon(R.drawable.launch_background)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()
    }

    private fun requestLocationUpdates() {
        if (ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED) {
            Log.e(TAG, "Location permission not granted")
            return
        }

        val locationRequest = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 10000)
            .setWaitForAccurateLocation(false)
            .setMinUpdateIntervalMillis(5000)
            .setMaxUpdateDelayMillis(15000)
            .build()

        try {
            Log.d(TAG, "Requesting location updates with settings: interval=10s, minUpdateInterval=5s")
            fusedLocationClient.requestLocationUpdates(
                locationRequest,
                locationCallback,
                Looper.getMainLooper()
            )
            Log.d(TAG, "Location updates requested successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error requesting location updates: ${e.message}")
            e.printStackTrace()
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        if (isTracking) {
            stopTracking()
        }
    }
} 