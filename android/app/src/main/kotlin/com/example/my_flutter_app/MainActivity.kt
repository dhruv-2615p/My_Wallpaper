package com.example.my_flutter_app

import android.app.WallpaperManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL    = "com.example.my_flutter_app/live_wallpaper"
        private const val PREFS_NAME = "gyro_live_wp"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    // ── Image live wallpaper with gyro + effects ──────────────
                    "setLiveWallpaper" -> {
                        val imagePath = call.argument<String>("imagePath")
                        if (imagePath == null) {
                            result.error("INVALID_ARG", "imagePath is required", null); return@setMethodCallHandler
                        }

                        saveEffectPrefs(call.arguments as Map<*, *>, imagePath)

                        launchLiveWallpaperPicker(
                            GyroLiveWallpaperService::class.java.name, result
                        )
                    }

                    // ── Video live wallpaper ──────────────────────────────────
                    "setVideoLiveWallpaper" -> {
                        val videoPath = call.argument<String>("videoPath")
                        if (videoPath == null) {
                            result.error("INVALID_ARG", "videoPath is required", null); return@setMethodCallHandler
                        }

                        getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                            .edit()
                            .putString("video_path", videoPath)
                            .apply()

                        launchLiveWallpaperPicker(
                            VideoLiveWallpaperService::class.java.name, result
                        )
                    }

                    else -> result.notImplemented()
                }
            }
    }

    // ── Save all effect settings to SharedPreferences ─────────────────────────
    private fun saveEffectPrefs(args: Map<*, *>, imagePath: String) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit()

        prefs.putString("image_path", imagePath)
        prefs.putFloat("sensitivity",      (args["sensitivity"] as? Double)?.toFloat() ?: 1f)
        prefs.putBoolean("is_gyro_enabled", args["isGyroEnabled"] as? Boolean ?: true)

        // Water
        prefs.putBoolean("is_water_enabled", args["isWaterEnabled"] as? Boolean ?: false)
        prefs.putFloat("water_level",        (args["waterLevel"] as? Double)?.toFloat() ?: 0.2f)
        val waterHex = args["waterColorHex"] as? String ?: "#4400BFFF"
        prefs.putInt("water_color_argb", parseHexColor(waterHex))

        // Colour overlay
        prefs.putBoolean("is_color_overlay",  args["isColorOverlayEnabled"] as? Boolean ?: false)
        val overlayHex = args["colorOverlayHex"] as? String ?: "#33191970"
        val overlayOpacity = (args["colorOverlayOpacity"] as? Double)?.toFloat() ?: 0.15f
        val baseColor = parseHexColor(overlayHex)
        val overlayAlpha = (overlayOpacity * 255).toInt().coerceIn(0, 255)
        prefs.putInt("color_overlay_argb",
            Color.argb(overlayAlpha, Color.red(baseColor), Color.green(baseColor), Color.blue(baseColor))
        )

        // Blur
        prefs.putBoolean("is_blur",    args["isBlurEnabled"] as? Boolean ?: false)
        prefs.putFloat("blur_amount", (args["blurAmount"] as? Double)?.toFloat() ?: 0f)

        // Particles
        prefs.putBoolean("is_particles",   args["isParticlesEnabled"] as? Boolean ?: false)
        prefs.putInt("particle_type",      args["particleTypeIndex"] as? Int ?: 0)
        prefs.putInt("particle_count",     args["particleCount"] as? Int ?: 50)

        prefs.apply()
    }

    private fun parseHexColor(hex: String): Int {
        return try {
            val clean = hex.trimStart('#')
            when (clean.length) {
                6 -> Color.parseColor("#$clean")
                8 -> Color.parseColor("#$clean")
                else -> Color.argb(68, 0, 191, 255)
            }
        } catch (_: Exception) {
            Color.argb(68, 0, 191, 255)
        }
    }

    private fun launchLiveWallpaperPicker(serviceClass: String, result: MethodChannel.Result) {
        try {
            val intent = Intent(WallpaperManager.ACTION_CHANGE_LIVE_WALLPAPER).apply {
                putExtra(
                    WallpaperManager.EXTRA_LIVE_WALLPAPER_COMPONENT,
                    ComponentName(packageName, serviceClass)
                )
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("INTENT_ERROR", e.message, null)
        }
    }
}


