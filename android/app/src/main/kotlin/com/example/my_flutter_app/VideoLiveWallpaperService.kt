package com.example.my_flutter_app

import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.SurfaceTexture
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.media.MediaPlayer
import android.opengl.EGL14
import android.opengl.EGLConfig
import android.opengl.EGLContext
import android.opengl.EGLDisplay
import android.opengl.EGLSurface
import android.opengl.GLES11Ext
import android.opengl.GLES20
import android.opengl.GLUtils
import android.opengl.Matrix
import android.os.Handler
import android.os.HandlerThread
import android.service.wallpaper.WallpaperService
import android.util.Log
import android.view.Surface
import android.view.SurfaceHolder
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.sin
import kotlin.random.Random

/**
 * Video live wallpaper that plays a looping video file via OpenGL ES 2.0,
 * with gyroscope parallax and the same effect overlays (particles, water,
 * color overlay) as [GyroLiveWallpaperService].
 */
class VideoLiveWallpaperService : WallpaperService() {

    override fun onCreateEngine(): Engine = VideoEngine()

    // ── Water ripple simulation ──────────────────────────────────────────
    private class WaterSim(val cols: Int, val rows: Int) {
        private var cur  = Array(cols) { FloatArray(rows) }
        private var prev = Array(cols) { FloatArray(rows) }

        fun applyGravity(gxN: Float, gyN: Float) {
            val strength = 3.0f
            if (abs(gxN) > 0.05f) {
                val edgeX = if (gxN > 0f) cols - 2 else 1
                val step = (rows / 10).coerceAtLeast(1)
                for (y in step until rows - step step (step / 2).coerceAtLeast(1)) {
                    cur[edgeX][y] += strength
                }
            }
            if (abs(gyN) > 0.05f) {
                val edgeY = if (gyN > 0f) rows - 2 else 1
                val step = (cols / 10).coerceAtLeast(1)
                for (x in step until cols - step step (step / 2).coerceAtLeast(1)) {
                    cur[x][edgeY] += strength
                }
            }
        }

        fun step() {
            for (x in 1 until cols - 1) {
                for (y in 1 until rows - 1) {
                    val newH = (cur[x - 1][y] + cur[x + 1][y] +
                                cur[x][y - 1] + cur[x][y + 1]) * 0.5f - prev[x][y]
                    prev[x][y] = (newH * 0.985f).coerceIn(-20f, 20f)
                }
            }
            val tmp = cur; cur = prev; prev = tmp
        }

        fun renderBitmap(waterR: Int, waterG: Int, waterB: Int, baseAlpha: Int): Bitmap {
            val pixels = IntArray(cols * rows)
            for (y in 0 until rows) {
                for (x in 0 until cols) {
                    val h = cur[x][y]
                    val norm = (h / 8f).coerceIn(-1f, 1f)
                    val nx = if (x in 1 until cols - 1) cur[x + 1][y] - cur[x - 1][y] else 0f
                    val ny = if (y in 1 until rows - 1) cur[x][y + 1] - cur[x][y - 1] else 0f
                    val spec = ((nx + ny + 2f) / 4f).coerceIn(0f, 1f)
                    val a = (baseAlpha + norm * 70 + spec * 80).toInt().coerceIn(0, 220)
                    val r = (waterR + spec * (255 - waterR)).toInt().coerceIn(0, 255)
                    val g = (waterG + spec * (255 - waterG)).toInt().coerceIn(0, 255)
                    val b = (waterB + spec * (255 - waterB)).toInt().coerceIn(0, 255)
                    pixels[y * cols + x] = (a shl 24) or (r shl 16) or (g shl 8) or b
                }
            }
            val bmp = Bitmap.createBitmap(cols, rows, Bitmap.Config.ARGB_8888)
            bmp.setPixels(pixels, 0, cols, 0, 0, cols, rows)
            return bmp
        }
    }

    // ── Particle system ──────────────────────────────────────────────────
    private class ParticleSys(
        val count: Int, val type: Int,
        val screenW: Float, val screenH: Float
    ) {
        private val rng = Random.Default
        private val px = FloatArray(count); private val py = FloatArray(count)
        private val pvx = FloatArray(count); private val pvy = FloatArray(count)
        private val palpha = FloatArray(count); private val psize = FloatArray(count)
        private val phase = FloatArray(count)

        init { for (i in 0 until count) spawn(i, initial = true) }

        private fun spawn(i: Int, initial: Boolean = false) {
            px[i] = rng.nextFloat() * screenW
            py[i] = if (initial) rng.nextFloat() * screenH else when (type) {
                4 -> screenH + psize[i]; else -> -20f
            }
            pvx[i] = (rng.nextFloat() - 0.5f) * when (type) { 1 -> 2f; 3 -> 3f; else -> 1.5f }
            pvy[i] = when (type) {
                0 -> rng.nextFloat() * 1.5f + 0.5f; 1 -> rng.nextFloat() * 8f + 8f
                2 -> (rng.nextFloat() - 0.5f) * 1f; 3 -> rng.nextFloat() * 2f + 1f
                4 -> -(rng.nextFloat() * 1.5f + 0.5f); 5 -> 0f; else -> 1f
            }
            palpha[i] = when (type) { 2, 5 -> rng.nextFloat(); else -> 0.7f + rng.nextFloat() * 0.3f }
            psize[i] = when (type) {
                0 -> 3f + rng.nextFloat() * 5f; 1 -> 1.5f + rng.nextFloat() * 1f
                2 -> 4f + rng.nextFloat() * 6f; 3 -> 5f + rng.nextFloat() * 8f
                4 -> 4f + rng.nextFloat() * 8f; 5 -> 1.5f + rng.nextFloat() * 3f; else -> 4f
            }
            phase[i] = rng.nextFloat() * (2f * Math.PI.toFloat())
        }

        var time = 0f
        fun step(gravX: Float, gravY: Float) {
            time += 0.016f
            for (i in 0 until count) {
                when (type) {
                    2 -> { px[i] += pvx[i] + sin((time + phase[i]).toDouble()).toFloat() * 0.5f; py[i] += pvy[i] + cos((time * 0.7f + phase[i]).toDouble()).toFloat() * 0.5f; palpha[i] = (0.4f + sin((time * 1.5f + phase[i]).toDouble()).toFloat() * 0.4f).coerceIn(0.1f, 0.9f) }
                    5 -> { palpha[i] = (0.5f + sin((time * 2f + phase[i]).toDouble()).toFloat() * 0.5f).coerceIn(0.2f, 1f); continue }
                    4 -> { pvx[i] += gravX * 0.005f; pvy[i] -= abs(gravY) * 0.01f; px[i] += pvx[i] + sin((time + phase[i]).toDouble()).toFloat() * 0.3f; py[i] += pvy[i] }
                    else -> { pvx[i] += gravX * 0.05f; pvy[i] += gravY * 0.05f; pvx[i] = pvx[i].coerceIn(-15f, 15f); pvy[i] = pvy[i].coerceIn(-15f, 20f); px[i] += pvx[i]; py[i] += pvy[i] }
                }
                if (py[i] > screenH + 40f || py[i] < -40f || px[i] < -40f || px[i] > screenW + 40f) spawn(i)
            }
        }

        private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        fun draw(canvas: Canvas) {
            for (i in 0 until count) {
                val s = psize[i]
                when (type) {
                    0 -> { paint.color = Color.WHITE; paint.alpha = (palpha[i] * 200).toInt(); canvas.drawCircle(px[i], py[i], s, paint) }
                    1 -> { paint.color = Color.argb((palpha[i] * 180).toInt(), 180, 200, 255); paint.strokeWidth = 1.5f; paint.style = Paint.Style.STROKE; canvas.drawLine(px[i], py[i], px[i] - pvx[i] * 2, py[i] - pvy[i] * 2, paint); paint.style = Paint.Style.FILL }
                    2 -> { paint.color = Color.argb((palpha[i] * 255).toInt(), 200, 255, 80); canvas.drawCircle(px[i], py[i], s, paint); paint.color = Color.argb((palpha[i] * 80).toInt(), 200, 255, 80); canvas.drawCircle(px[i], py[i], s * 2.5f, paint) }
                    3 -> { paint.color = Color.argb((palpha[i] * 200).toInt(), 180 + (phase[i] * 20).toInt() % 60, 80 + (phase[i] * 10).toInt() % 40, 10); canvas.drawOval(px[i] - s, py[i] - s * 0.6f, px[i] + s, py[i] + s * 0.6f, paint) }
                    4 -> { paint.color = Color.argb((palpha[i] * 60).toInt(), 180, 210, 255); canvas.drawCircle(px[i], py[i], s, paint); paint.color = Color.argb((palpha[i] * 150).toInt(), 255, 255, 255); paint.style = Paint.Style.STROKE; paint.strokeWidth = 1.5f; canvas.drawCircle(px[i], py[i], s, paint); paint.style = Paint.Style.FILL }
                    5 -> { paint.color = Color.argb((palpha[i] * 255).toInt(), 255, 255, 255); canvas.drawCircle(px[i], py[i], s, paint) }
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    // Video Engine — EGL / GLES 2.0
    // ─────────────────────────────────────────────────────────────────────
    inner class VideoEngine : Engine(), SensorEventListener,
        SurfaceTexture.OnFrameAvailableListener {

        private val TAG = "VideoLiveWP"
        private val prefs: SharedPreferences by lazy {
            getSharedPreferences("gyro_live_wp", Context.MODE_PRIVATE)
        }

        // Background thread
        private val drawThread = HandlerThread("video-wall-draw").also { it.start() }
        private val drawHandler = Handler(drawThread.looper)

        // Surface
        private var surfaceW = 0; private var surfaceH = 0

        // EGL
        private var eglDisplay: EGLDisplay = EGL14.EGL_NO_DISPLAY
        private var eglContext: EGLContext = EGL14.EGL_NO_CONTEXT
        private var eglSurface: EGLSurface = EGL14.EGL_NO_SURFACE

        // Video texture
        private var videoTexId = 0
        private var surfaceTexture: SurfaceTexture? = null
        private var mediaPlayer: MediaPlayer? = null
        private val stMatrix = FloatArray(16)
        @Volatile private var frameAvailable = false

        // Effects overlay texture
        private var overlayTexId = 0
        private var overlayBitmap: Bitmap? = null
        private var overlayCanvas: Canvas? = null

        // GL programs
        private var videoProg = 0; private var overlayProg = 0

        // Vertex buffers
        private var posBuffer: FloatBuffer? = null
        private var texBuffer: FloatBuffer? = null

        // Effect settings
        private var sensitivity = 1f; private var isGyroEnabled = true
        private var isWaterEnabled = false; private var waterLevel = 0.2f
        private var waterR = 0; private var waterG = 191; private var waterB = 255
        private var isColorOverlay = false; private var colorOverlayColor = 0x33191970
        private var isParticles = false; private var particleTypeIdx = 0; private var particleCount = 50

        // Gyro + accel
        @Volatile private var offsetX = 0f; @Volatile private var offsetY = 0f
        private var smoothX = 0f; private var smoothY = 0f
        private val lpAlpha = 0.12f; private val baseMaxOffset = 60f
        @Volatile private var gravX = 0f; @Volatile private var gravY = 9.8f

        // Simulations
        private var waterSim: WaterSim? = null; private var particles: ParticleSys? = null

        // Draw helpers
        private val drawPaint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)
        private val overlayPaint = Paint()

        // Render loop
        private val frameMs = 16L
        private val frameRunnable = object : Runnable {
            override fun run() {
                renderFrame()
                if (isVisible) drawHandler.postDelayed(this, frameMs)
            }
        }

        // ── SurfaceTexture callback ──
        override fun onFrameAvailable(st: SurfaceTexture) { frameAvailable = true }

        // ── Lifecycle ──
        override fun onCreate(surfaceHolder: SurfaceHolder) {
            super.onCreate(surfaceHolder)
            val sm = getSystemService(Context.SENSOR_SERVICE) as SensorManager
            sm.getDefaultSensor(Sensor.TYPE_GYROSCOPE)?.let {
                sm.registerListener(this, it, SensorManager.SENSOR_DELAY_GAME)
            }
            sm.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)?.let {
                sm.registerListener(this, it, SensorManager.SENSOR_DELAY_GAME)
            }
        }

        override fun onSurfaceChanged(holder: SurfaceHolder, fmt: Int, w: Int, h: Int) {
            super.onSurfaceChanged(holder, fmt, w, h)
            drawHandler.post {
                surfaceW = w; surfaceH = h
                initGL(holder)
                readPrefs()
                buildSimulations()
                startVideo()
            }
        }

        override fun onVisibilityChanged(visible: Boolean) {
            drawHandler.removeCallbacks(frameRunnable)
            if (visible) {
                drawHandler.post {
                    readPrefs()
                    buildSimulations()
                    if (mediaPlayer == null) startVideo() else mediaPlayer?.start()
                    frameRunnable.run()
                }
            } else {
                mediaPlayer?.pause()
            }
        }

        override fun onSurfaceDestroyed(holder: SurfaceHolder) {
            drawHandler.removeCallbacksAndMessages(null)
            drawHandler.post { releaseAll() }
            (getSystemService(Context.SENSOR_SERVICE) as SensorManager).unregisterListener(this)
        }

        override fun onDestroy() {
            drawHandler.removeCallbacksAndMessages(null)
            drawThread.quitSafely()
            (getSystemService(Context.SENSOR_SERVICE) as SensorManager).unregisterListener(this)
        }

        // ── Sensors ──
        override fun onSensorChanged(event: SensorEvent) {
            when (event.sensor.type) {
                Sensor.TYPE_GYROSCOPE -> {
                    smoothX = smoothX * (1 - lpAlpha) + event.values[1] * lpAlpha
                    smoothY = smoothY * (1 - lpAlpha) + event.values[0] * lpAlpha
                    val maxOff = baseMaxOffset * sensitivity
                    offsetX = (smoothX * 20 * sensitivity).coerceIn(-maxOff, maxOff)
                    offsetY = (smoothY * 20 * sensitivity).coerceIn(-maxOff, maxOff)
                }
                Sensor.TYPE_ACCELEROMETER -> {
                    gravX = gravX * 0.8f + event.values[0] * 0.2f
                    gravY = gravY * 0.8f + event.values[1] * 0.2f
                }
            }
        }
        override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {}

        // ── Prefs ──
        private fun readPrefs() {
            sensitivity    = prefs.getFloat("sensitivity", 1f)
            isGyroEnabled  = prefs.getBoolean("is_gyro_enabled", true)
            isWaterEnabled = prefs.getBoolean("is_water_enabled", false)
            waterLevel     = prefs.getFloat("water_level", 0.2f)
            val wArgb      = prefs.getInt("water_color_argb", Color.argb(68, 0, 191, 255))
            waterR = Color.red(wArgb); waterG = Color.green(wArgb); waterB = Color.blue(wArgb)
            isColorOverlay    = prefs.getBoolean("is_color_overlay", false)
            colorOverlayColor = prefs.getInt("color_overlay_argb", Color.argb(50, 25, 25, 112))
            isParticles       = prefs.getBoolean("is_particles", false)
            particleTypeIdx   = prefs.getInt("particle_type", 0)
            particleCount     = prefs.getInt("particle_count", 50)
        }

        private fun buildSimulations() {
            waterSim = null; particles = null
            if (surfaceW <= 0 || surfaceH <= 0) return
            if (isWaterEnabled) {
                val c = 80; val r = (c.toFloat() * surfaceH / surfaceW).toInt().coerceAtLeast(40)
                waterSim = WaterSim(c, r)
            }
            if (isParticles) particles = ParticleSys(particleCount, particleTypeIdx, surfaceW.toFloat(), surfaceH.toFloat())
        }

        // ── EGL / GL setup ──
        private fun initGL(holder: SurfaceHolder) {
            releaseGL()

            eglDisplay = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY)
            val ver = IntArray(2)
            EGL14.eglInitialize(eglDisplay, ver, 0, ver, 1)

            val attribs = intArrayOf(
                EGL14.EGL_RENDERABLE_TYPE, EGL14.EGL_OPENGL_ES2_BIT,
                EGL14.EGL_RED_SIZE, 8, EGL14.EGL_GREEN_SIZE, 8,
                EGL14.EGL_BLUE_SIZE, 8, EGL14.EGL_ALPHA_SIZE, 8,
                EGL14.EGL_NONE
            )
            val cfgs = arrayOfNulls<EGLConfig>(1); val numCfg = IntArray(1)
            EGL14.eglChooseConfig(eglDisplay, attribs, 0, cfgs, 0, 1, numCfg, 0)
            val eglConfig = cfgs[0]!!

            eglContext = EGL14.eglCreateContext(
                eglDisplay, eglConfig, EGL14.EGL_NO_CONTEXT,
                intArrayOf(EGL14.EGL_CONTEXT_CLIENT_VERSION, 2, EGL14.EGL_NONE), 0
            )
            eglSurface = EGL14.eglCreateWindowSurface(
                eglDisplay, eglConfig, holder.surface, intArrayOf(EGL14.EGL_NONE), 0
            )
            EGL14.eglMakeCurrent(eglDisplay, eglSurface, eglSurface, eglContext)

            // Textures
            val texIds = IntArray(2)
            GLES20.glGenTextures(2, texIds, 0)
            videoTexId = texIds[0]; overlayTexId = texIds[1]

            GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, videoTexId)
            GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
            GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
            GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE)
            GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE)

            GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, overlayTexId)
            GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
            GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
            GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE)
            GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE)

            // SurfaceTexture for video
            surfaceTexture = SurfaceTexture(videoTexId).also {
                it.setOnFrameAvailableListener(this)
            }

            // Overlay bitmap
            overlayBitmap = Bitmap.createBitmap(surfaceW, surfaceH, Bitmap.Config.ARGB_8888)
            overlayCanvas = Canvas(overlayBitmap!!)

            // Shader programs
            videoProg = buildProgram(VIDEO_VERT, VIDEO_FRAG)
            overlayProg = buildProgram(OVERLAY_VERT, OVERLAY_FRAG)

            // Vertex buffers
            val pos = floatArrayOf(-1f, -1f, 1f, -1f, -1f, 1f, 1f, 1f)
            posBuffer = ByteBuffer.allocateDirect(pos.size * 4)
                .order(ByteOrder.nativeOrder()).asFloatBuffer().apply { put(pos); position(0) }
            val tex = floatArrayOf(0f, 0f, 1f, 0f, 0f, 1f, 1f, 1f)
            texBuffer = ByteBuffer.allocateDirect(tex.size * 4)
                .order(ByteOrder.nativeOrder()).asFloatBuffer().apply { put(tex); position(0) }
        }

        // ── Video playback ──
        private fun startVideo() {
            val path = prefs.getString("video_path", null) ?: return
            val st = surfaceTexture ?: return
            stopVideo()
            try {
                mediaPlayer = MediaPlayer().apply {
                    setDataSource(path)
                    setSurface(Surface(st))
                    isLooping = true
                    setVolume(0f, 0f)
                    setVideoScalingMode(MediaPlayer.VIDEO_SCALING_MODE_SCALE_TO_FIT_WITH_CROPPING)
                    prepare()
                    start()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to start video: ${e.message}")
            }
        }

        private fun stopVideo() {
            try { mediaPlayer?.stop(); mediaPlayer?.release() } catch (_: Exception) {}
            mediaPlayer = null
        }

        // ── Render ──
        private fun renderFrame() {
            if (eglDisplay == EGL14.EGL_NO_DISPLAY) return
            if (!EGL14.eglMakeCurrent(eglDisplay, eglSurface, eglSurface, eglContext)) return

            if (frameAvailable) {
                surfaceTexture?.updateTexImage()
                surfaceTexture?.getTransformMatrix(stMatrix)
                frameAvailable = false
            }

            // Step simulations
            val gxN = (-gravX / 10f).coerceIn(-1f, 1f)
            val gyN = (-gravY / 10f).coerceIn(-1f, 1f)
            waterSim?.let { ws -> ws.applyGravity(gxN, gyN); repeat(2) { ws.step() } }
            particles?.step(gxN, gyN)

            GLES20.glViewport(0, 0, surfaceW, surfaceH)
            GLES20.glClearColor(0f, 0f, 0f, 1f)
            GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)

            drawVideoQuad()
            drawEffectsOverlay()

            EGL14.eglSwapBuffers(eglDisplay, eglSurface)
        }

        private fun drawVideoQuad() {
            GLES20.glUseProgram(videoProg)

            // MVP with overscale + gyro translation
            val mvp = FloatArray(16)
            Matrix.setIdentityM(mvp, 0)
            Matrix.scaleM(mvp, 0, 1.15f, 1.15f, 1f)
            if (isGyroEnabled) {
                val tx = offsetX / surfaceW * 2f
                val ty = -offsetY / surfaceH * 2f
                Matrix.translateM(mvp, 0, tx, ty, 0f)
            }

            val posLoc = GLES20.glGetAttribLocation(videoProg, "aPosition")
            val texLoc = GLES20.glGetAttribLocation(videoProg, "aTexCoord")

            GLES20.glUniformMatrix4fv(GLES20.glGetUniformLocation(videoProg, "uSTMatrix"), 1, false, stMatrix, 0)
            GLES20.glUniformMatrix4fv(GLES20.glGetUniformLocation(videoProg, "uMVPMatrix"), 1, false, mvp, 0)

            posBuffer?.position(0)
            GLES20.glEnableVertexAttribArray(posLoc)
            GLES20.glVertexAttribPointer(posLoc, 2, GLES20.GL_FLOAT, false, 0, posBuffer)

            texBuffer?.position(0)
            GLES20.glEnableVertexAttribArray(texLoc)
            GLES20.glVertexAttribPointer(texLoc, 2, GLES20.GL_FLOAT, false, 0, texBuffer)

            GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
            GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, videoTexId)
            GLES20.glUniform1i(GLES20.glGetUniformLocation(videoProg, "sTexture"), 0)

            GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)
            GLES20.glDisableVertexAttribArray(posLoc)
            GLES20.glDisableVertexAttribArray(texLoc)
        }

        private fun drawEffectsOverlay() {
            val bmp = overlayBitmap ?: return
            val cvs = overlayCanvas ?: return

            bmp.eraseColor(Color.TRANSPARENT)
            var hasEffects = false

            if (isColorOverlay) {
                overlayPaint.color = colorOverlayColor
                cvs.drawRect(0f, 0f, surfaceW.toFloat(), surfaceH.toFloat(), overlayPaint)
                hasEffects = true
            }
            particles?.let { it.draw(cvs); hasEffects = true }
            waterSim?.let { ws ->
                val ba = (waterLevel * 400f).toInt().coerceIn(20, 200)
                val waterBmp = ws.renderBitmap(waterR, waterG, waterB, ba)
                val scaled = Bitmap.createScaledBitmap(waterBmp, surfaceW, surfaceH, true)
                waterBmp.recycle()
                cvs.drawBitmap(scaled, 0f, 0f, drawPaint)
                scaled.recycle()
                hasEffects = true
            }

            if (!hasEffects) return

            GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, overlayTexId)
            GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, bmp, 0)

            GLES20.glEnable(GLES20.GL_BLEND)
            GLES20.glBlendFunc(GLES20.GL_SRC_ALPHA, GLES20.GL_ONE_MINUS_SRC_ALPHA)

            GLES20.glUseProgram(overlayProg)
            val posLoc = GLES20.glGetAttribLocation(overlayProg, "aPosition")
            val texLoc = GLES20.glGetAttribLocation(overlayProg, "aTexCoord")

            posBuffer?.position(0)
            GLES20.glEnableVertexAttribArray(posLoc)
            GLES20.glVertexAttribPointer(posLoc, 2, GLES20.GL_FLOAT, false, 0, posBuffer)

            texBuffer?.position(0)
            GLES20.glEnableVertexAttribArray(texLoc)
            GLES20.glVertexAttribPointer(texLoc, 2, GLES20.GL_FLOAT, false, 0, texBuffer)

            GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
            GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, overlayTexId)
            GLES20.glUniform1i(GLES20.glGetUniformLocation(overlayProg, "sTexture"), 0)

            GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)
            GLES20.glDisableVertexAttribArray(posLoc)
            GLES20.glDisableVertexAttribArray(texLoc)
            GLES20.glDisable(GLES20.GL_BLEND)
        }

        // ── Cleanup ──
        private fun releaseAll() { stopVideo(); releaseGL() }

        private fun releaseGL() {
            if (eglDisplay != EGL14.EGL_NO_DISPLAY) {
                EGL14.eglMakeCurrent(eglDisplay, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_CONTEXT)
                if (eglSurface != EGL14.EGL_NO_SURFACE) EGL14.eglDestroySurface(eglDisplay, eglSurface)
                if (eglContext != EGL14.EGL_NO_CONTEXT) EGL14.eglDestroyContext(eglDisplay, eglContext)
                EGL14.eglTerminate(eglDisplay)
            }
            eglDisplay = EGL14.EGL_NO_DISPLAY
            eglContext = EGL14.EGL_NO_CONTEXT
            eglSurface = EGL14.EGL_NO_SURFACE
            surfaceTexture?.release(); surfaceTexture = null
            overlayBitmap?.recycle(); overlayBitmap = null; overlayCanvas = null
        }

        // ── GL helpers ──
        private fun buildProgram(vertSrc: String, fragSrc: String): Int {
            val vs = compileShader(GLES20.GL_VERTEX_SHADER, vertSrc)
            val fs = compileShader(GLES20.GL_FRAGMENT_SHADER, fragSrc)
            return GLES20.glCreateProgram().also {
                GLES20.glAttachShader(it, vs); GLES20.glAttachShader(it, fs); GLES20.glLinkProgram(it)
            }
        }
        private fun compileShader(type: Int, src: String) = GLES20.glCreateShader(type).also {
            GLES20.glShaderSource(it, src); GLES20.glCompileShader(it)
        }
    }

    companion object {
        private const val VIDEO_VERT = """
            attribute vec4 aPosition;
            attribute vec2 aTexCoord;
            uniform mat4 uSTMatrix;
            uniform mat4 uMVPMatrix;
            varying vec2 vTexCoord;
            void main() {
                gl_Position = uMVPMatrix * aPosition;
                vTexCoord = (uSTMatrix * vec4(aTexCoord, 0.0, 1.0)).xy;
            }"""
        private const val VIDEO_FRAG = """
            #extension GL_OES_EGL_image_external : require
            precision mediump float;
            varying vec2 vTexCoord;
            uniform samplerExternalOES sTexture;
            void main() { gl_FragColor = texture2D(sTexture, vTexCoord); }"""
        private const val OVERLAY_VERT = """
            attribute vec4 aPosition;
            attribute vec2 aTexCoord;
            varying vec2 vTexCoord;
            void main() {
                gl_Position = aPosition;
                vTexCoord = vec2(aTexCoord.x, 1.0 - aTexCoord.y);
            }"""
        private const val OVERLAY_FRAG = """
            precision mediump float;
            varying vec2 vTexCoord;
            uniform sampler2D sTexture;
            void main() { gl_FragColor = texture2D(sTexture, vTexCoord); }"""
    }
}
