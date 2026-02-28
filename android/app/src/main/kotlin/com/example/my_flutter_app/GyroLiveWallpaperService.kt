package com.example.my_flutter_app

import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.PorterDuff
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Handler
import android.os.HandlerThread
import android.service.wallpaper.WallpaperService
import android.view.SurfaceHolder
import kotlin.math.absoluteValue
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.sqrt
import kotlin.random.Random

// ─────────────────────────────────────────────────────────────────────────────
// Shallow-water physics simulation (Hugo Elias ripple algorithm + body force)
// ─────────────────────────────────────────────────────────────────────────────
private class WaterSim(val cols: Int, val rows: Int) {

    private var cur  = Array(cols) { FloatArray(rows) }
    private var prev = Array(cols) { FloatArray(rows) }

    fun addDrop(cx: Int, cy: Int, radius: Int = 3, amount: Float = 6f) {
        for (dx in -radius..radius) {
            for (dy in -radius..radius) {
                val x = (cx + dx).coerceIn(1, cols - 2)
                val y = (cy + dy).coerceIn(1, rows - 2)
                cur[x][y] += amount
            }
        }
    }

    fun applyGravity(gxN: Float, gyN: Float) {
        val mag = sqrt(gxN * gxN + gyN * gyN).coerceIn(0.05f, 1f)
        val strength = mag * 0.55f
        if (gxN.absoluteValue > 0.05f) {
            val edgeX = if (gxN > 0f) 1 else cols - 2
            val step = (rows / 10).coerceAtLeast(1)
            for (y in step until rows - step step (step / 2).coerceAtLeast(1)) {
                cur[edgeX][y] += strength
            }
        }
        if (gyN.absoluteValue > 0.05f) {
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

// ─────────────────────────────────────────────────────────────────────────────
// Particle system – snow / rain / fireflies / stars / bubbles / leaves
// ─────────────────────────────────────────────────────────────────────────────
private class ParticleSys(
    val count: Int,
    val type: Int,
    val screenW: Float,
    val screenH: Float
) {
    private val rng = Random.Default
    private val px  = FloatArray(count)
    private val py  = FloatArray(count)
    private val pvx = FloatArray(count)
    private val pvy = FloatArray(count)
    private val palpha = FloatArray(count)
    private val psize  = FloatArray(count)
    private val phase  = FloatArray(count)

    init { for (i in 0 until count) spawn(i, initial = true) }

    private fun spawn(i: Int, initial: Boolean = false) {
        px[i] = rng.nextFloat() * screenW
        py[i] = if (initial) rng.nextFloat() * screenH else when (type) {
            4 -> screenH + psize[i]; else -> -20f
        }
        pvx[i] = (rng.nextFloat() - 0.5f) * when (type) {
            1 -> 2f; 3 -> 3f; else -> 1.5f
        }
        pvy[i] = when (type) {
            0 -> rng.nextFloat() * 1.5f + 0.5f
            1 -> rng.nextFloat() * 8f + 8f
            2 -> (rng.nextFloat() - 0.5f) * 1f
            3 -> rng.nextFloat() * 2f + 1f
            4 -> -(rng.nextFloat() * 1.5f + 0.5f)
            5 -> 0f
            else -> 1f
        }
        palpha[i] = when (type) {
            2, 5 -> rng.nextFloat(); else -> 0.7f + rng.nextFloat() * 0.3f
        }
        psize[i] = when (type) {
            0 -> 3f + rng.nextFloat() * 5f
            1 -> 1.5f + rng.nextFloat() * 1f
            2 -> 4f + rng.nextFloat() * 6f
            3 -> 5f + rng.nextFloat() * 8f
            4 -> 4f + rng.nextFloat() * 8f
            5 -> 1.5f + rng.nextFloat() * 3f
            else -> 4f
        }
        phase[i] = rng.nextFloat() * (2f * Math.PI.toFloat())
    }

    var time = 0f

    fun step(gravX: Float, gravY: Float) {
        time += 0.016f
        for (i in 0 until count) {
            when (type) {
                2 -> {
                    px[i] += pvx[i] + sin((time + phase[i]).toDouble()).toFloat() * 0.5f
                    py[i] += pvy[i] + cos((time * 0.7f + phase[i]).toDouble()).toFloat() * 0.5f
                    palpha[i] = (0.4f + sin((time * 1.5f + phase[i]).toDouble()).toFloat() * 0.4f).coerceIn(0.1f, 0.9f)
                }
                5 -> {
                    palpha[i] = (0.5f + sin((time * 2f + phase[i]).toDouble()).toFloat() * 0.5f).coerceIn(0.2f, 1f)
                    continue
                }
                4 -> {
                    pvx[i] += gravX * 0.005f
                    pvy[i] -= gravY.absoluteValue * 0.01f
                    px[i] += pvx[i] + sin((time + phase[i]).toDouble()).toFloat() * 0.3f
                    py[i] += pvy[i]
                }
                else -> {
                    pvx[i] += gravX * 0.05f
                    pvy[i] += gravY * 0.05f
                    pvx[i] = pvx[i].coerceIn(-15f, 15f)
                    pvy[i] = pvy[i].coerceIn(-15f, 20f)
                    px[i] += pvx[i]
                    py[i] += pvy[i]
                }
            }
            if (py[i] > screenH + 40f || py[i] < -40f || px[i] < -40f || px[i] > screenW + 40f) {
                spawn(i)
            }
        }
    }

    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)

    fun draw(canvas: Canvas) {
        for (i in 0 until count) {
            paint.alpha = (palpha[i] * 255).toInt().coerceIn(0, 255)
            val s = psize[i]
            when (type) {
                0 -> {
                    paint.color = Color.WHITE
                    paint.alpha = (palpha[i] * 200).toInt()
                    canvas.drawCircle(px[i], py[i], s, paint)
                }
                1 -> {
                    paint.color = Color.argb((palpha[i] * 180).toInt(), 180, 200, 255)
                    paint.strokeWidth = 1.5f
                    paint.style = Paint.Style.STROKE
                    canvas.drawLine(px[i], py[i], px[i] - pvx[i] * 2, py[i] - pvy[i] * 2, paint)
                    paint.style = Paint.Style.FILL
                }
                2 -> {
                    paint.color = Color.argb((palpha[i] * 255).toInt(), 200, 255, 80)
                    canvas.drawCircle(px[i], py[i], s, paint)
                    paint.color = Color.argb((palpha[i] * 80).toInt(), 200, 255, 80)
                    canvas.drawCircle(px[i], py[i], s * 2.5f, paint)
                }
                3 -> {
                    paint.color = Color.argb(
                        (palpha[i] * 200).toInt(),
                        180 + (phase[i] * 20).toInt() % 60,
                        80 + (phase[i] * 10).toInt() % 40,
                        10
                    )
                    canvas.drawOval(px[i] - s, py[i] - s * 0.6f, px[i] + s, py[i] + s * 0.6f, paint)
                }
                4 -> {
                    paint.color = Color.argb((palpha[i] * 60).toInt(), 180, 210, 255)
                    canvas.drawCircle(px[i], py[i], s, paint)
                    paint.color = Color.argb((palpha[i] * 150).toInt(), 255, 255, 255)
                    paint.style = Paint.Style.STROKE
                    paint.strokeWidth = 1.5f
                    canvas.drawCircle(px[i], py[i], s, paint)
                    paint.style = Paint.Style.FILL
                }
                5 -> {
                    paint.color = Color.argb((palpha[i] * 255).toInt(), 255, 255, 255)
                    canvas.drawCircle(px[i], py[i], s, paint)
                }
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Live Wallpaper Service
// ─────────────────────────────────────────────────────────────────────────────
class GyroLiveWallpaperService : WallpaperService() {

    override fun onCreateEngine(): Engine = GyroEngine()

    inner class GyroEngine : Engine(), SensorEventListener {

        private val prefs: SharedPreferences by lazy {
            getSharedPreferences("gyro_live_wp", Context.MODE_PRIVATE)
        }

        // ── Background thread ──
        private val drawThread = HandlerThread("gyro-wall-draw").also { it.start() }
        private val drawHandler = Handler(drawThread.looper)

        // ── Surface info ──
        private var surfaceW = 0
        private var surfaceH = 0

        // ── Base image ──
        private var baseBitmap: Bitmap? = null

        // ── Effect settings ──
        private var sensitivity       = 1f
        private var isGyroEnabled     = true
        private var isWaterEnabled    = false
        private var waterLevel        = 0.2f
        private var waterR            = 0; private var waterG = 191; private var waterB = 255
        private var isColorOverlay    = false
        private var colorOverlayColor = 0x33191970
        private var isBlur            = false
        private var blurAmount        = 0f
        private var isParticles       = false
        private var particleTypeIdx   = 0
        private var particleCount     = 50

        // ── Gyroscope parallax ──
        @Volatile private var offsetX = 0f
        @Volatile private var offsetY = 0f
        private var smoothX = 0f; private var smoothY = 0f
        private val lpAlpha = 0.12f
        private val baseMaxOffset = 60f

        // ── Accelerometer for water/particles gravity ──
        @Volatile private var gravX = 0f
        @Volatile private var gravY = 9.8f

        // ── Simulations ──
        private var waterSim: WaterSim? = null
        private var particles: ParticleSys? = null

        // ── Draw ticker ──
        private val frameIntervalMs = 16L
        private val frameRunnable: Runnable = object : Runnable {
            override fun run() {
                tickAndDraw()
                if (isVisible) drawHandler.postDelayed(this, frameIntervalMs)
            }
        }

        private val drawPaint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)
        private val overlayPaint = Paint()

        // ───────────────────────────────────────── lifecycle

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

        override fun onSurfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
            super.onSurfaceChanged(holder, format, width, height)
            drawHandler.post {
                surfaceW = width; surfaceH = height
                reloadAll()
            }
        }

        override fun onVisibilityChanged(visible: Boolean) {
            drawHandler.removeCallbacks(frameRunnable)
            if (visible) {
                drawHandler.post {
                    reloadAll()
                    frameRunnable.run()
                }
            }
        }

        override fun onSurfaceDestroyed(holder: SurfaceHolder) {
            drawHandler.removeCallbacksAndMessages(null)
            (getSystemService(Context.SENSOR_SERVICE) as SensorManager).unregisterListener(this)
        }

        override fun onDestroy() {
            drawHandler.removeCallbacksAndMessages(null)
            drawThread.quitSafely()
            (getSystemService(Context.SENSOR_SERVICE) as SensorManager).unregisterListener(this)
            baseBitmap?.recycle(); baseBitmap = null
        }

        // ───────────────────────────────────────── sensors

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

        // ───────────────────────────────────────── load

        private fun reloadAll() {
            readPrefs()
            loadBitmap()
            buildSimulations()
        }

        private fun readPrefs() {
            sensitivity       = prefs.getFloat("sensitivity", 1f)
            isGyroEnabled     = prefs.getBoolean("is_gyro_enabled", true)
            isWaterEnabled    = prefs.getBoolean("is_water_enabled", false)
            waterLevel        = prefs.getFloat("water_level", 0.2f)
            val waterArgb     = prefs.getInt("water_color_argb", Color.argb(68, 0, 191, 255))
            waterR            = Color.red(waterArgb)
            waterG            = Color.green(waterArgb)
            waterB            = Color.blue(waterArgb)
            isColorOverlay    = prefs.getBoolean("is_color_overlay", false)
            colorOverlayColor = prefs.getInt("color_overlay_argb", Color.argb(50, 25, 25, 112))
            isBlur            = prefs.getBoolean("is_blur", false)
            blurAmount        = prefs.getFloat("blur_amount", 0f)
            isParticles       = prefs.getBoolean("is_particles", false)
            particleTypeIdx   = prefs.getInt("particle_type", 0)
            particleCount     = prefs.getInt("particle_count", 50)
        }

        private fun loadBitmap() {
            val path = prefs.getString("image_path", null) ?: return
            if (surfaceW <= 0 || surfaceH <= 0) return
            val raw = BitmapFactory.decodeFile(path, BitmapFactory.Options().apply {
                inPreferredConfig = Bitmap.Config.ARGB_8888
            }) ?: return
            val margin = (baseMaxOffset * sensitivity * 2).toInt()
            val targetW = surfaceW + margin * 2
            val targetH = surfaceH + margin * 2
            val scale = maxOf(targetW.toFloat() / raw.width, targetH.toFloat() / raw.height)
            val sw = (raw.width  * scale).toInt().coerceAtLeast(1)
            val sh = (raw.height * scale).toInt().coerceAtLeast(1)

            baseBitmap?.recycle()
            val scaled = Bitmap.createScaledBitmap(raw, sw, sh, true)
            if (raw != scaled) raw.recycle()
            baseBitmap = scaled
        }

        private fun buildSimulations() {
            waterSim  = null
            particles = null
            if (surfaceW <= 0 || surfaceH <= 0) return
            if (isWaterEnabled) {
                val simCols = 80
                val simRows = (simCols.toFloat() * surfaceH / surfaceW).toInt().coerceAtLeast(40)
                waterSim = WaterSim(simCols, simRows)
            }
            if (isParticles) {
                particles = ParticleSys(particleCount, particleTypeIdx, surfaceW.toFloat(), surfaceH.toFloat())
            }
        }

        // ───────────────────────────────────────── draw loop

        private fun tickAndDraw() {
            val gxN = (-gravX / 10f).coerceIn(-1f, 1f)
            val gyN = (-gravY / 10f).coerceIn(-1f, 1f)
            waterSim?.let { ws ->
                ws.applyGravity(gxN, gyN)
                repeat(2) { ws.step() }
            }
            particles?.step(gxN, gyN)
            drawFrame(gxN, gyN)
        }

        private fun drawFrame(gxN: Float, gyN: Float) {
            val holder = surfaceHolder
            var canvas: Canvas? = null
            try {
                canvas = holder.lockCanvas() ?: return
                val bmp = baseBitmap
                if (bmp == null || bmp.isRecycled) {
                    canvas.drawARGB(255, 0, 0, 0); return
                }
                val imgLeft = (canvas.width  - bmp.width)  / 2f + if (isGyroEnabled) offsetX else 0f
                val imgTop  = (canvas.height - bmp.height) / 2f + if (isGyroEnabled) offsetY else 0f
                canvas.drawARGB(255, 0, 0, 0)
                canvas.drawBitmap(bmp, imgLeft, imgTop, drawPaint)

                if (isColorOverlay) {
                    overlayPaint.color = colorOverlayColor
                    canvas.drawRect(0f, 0f, canvas.width.toFloat(), canvas.height.toFloat(), overlayPaint)
                }

                particles?.draw(canvas)

                waterSim?.let { ws ->
                    val baseAlpha = (waterLevel * 400f).toInt().coerceIn(20, 200)
                    val waterBmp = ws.renderBitmap(waterR, waterG, waterB, baseAlpha)
                    val scaledWater = Bitmap.createScaledBitmap(waterBmp, canvas.width, canvas.height, true)
                    waterBmp.recycle()
                    canvas.drawBitmap(scaledWater, 0f, 0f, drawPaint)
                    scaledWater.recycle()
                }
            } finally {
                canvas?.let { holder.unlockCanvasAndPost(it) }
            }
        }
    }
}
