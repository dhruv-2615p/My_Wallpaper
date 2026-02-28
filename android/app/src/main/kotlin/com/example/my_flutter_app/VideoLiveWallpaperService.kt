package com.example.my_flutter_app

import android.content.Context
import android.media.MediaPlayer
import android.service.wallpaper.WallpaperService
import android.util.Log
import android.view.SurfaceHolder

/**
 * Live wallpaper that plays a looping video file directly to the surface.
 * The video path is stored in SharedPreferences under key "video_path".
 *
 * Note: MediaPlayer renders directly to the SurfaceHolder surface, which gives
 * the smoothest playback but does not allow Canvas overlays on the same surface.
 */
class VideoLiveWallpaperService : WallpaperService() {

    override fun onCreateEngine(): Engine = VideoEngine()

    inner class VideoEngine : Engine() {

        private var mediaPlayer: MediaPlayer? = null
        private var surfaceReady = false

        override fun onSurfaceCreated(holder: SurfaceHolder) {
            super.onSurfaceCreated(holder)
            surfaceReady = true
            startPlayback()
        }

        override fun onSurfaceDestroyed(holder: SurfaceHolder) {
            super.onSurfaceDestroyed(holder)
            surfaceReady = false
            stopPlayback()
        }

        override fun onVisibilityChanged(visible: Boolean) {
            if (visible) {
                if (mediaPlayer == null && surfaceReady) startPlayback()
                else mediaPlayer?.start()
            } else {
                mediaPlayer?.pause()
            }
        }

        override fun onDestroy() {
            super.onDestroy()
            stopPlayback()
        }

        private fun startPlayback() {
            val path = getSharedPreferences("gyro_live_wp", Context.MODE_PRIVATE)
                .getString("video_path", null) ?: return

            stopPlayback()

            try {
                mediaPlayer = MediaPlayer().apply {
                    setDataSource(path)
                    setSurface(surfaceHolder.surface)
                    isLooping = true
                    setVolume(0f, 0f)          // live wallpaper = no audio
                    setVideoScalingMode(MediaPlayer.VIDEO_SCALING_MODE_SCALE_TO_FIT_WITH_CROPPING)
                    prepare()
                    start()
                }
            } catch (e: Exception) {
                Log.e("VideoLiveWallpaper", "Failed to start video playback: ${e.message}")
            }
        }

        private fun stopPlayback() {
            try {
                mediaPlayer?.stop()
                mediaPlayer?.release()
            } catch (_: Exception) {}
            mediaPlayer = null
        }
    }
}
