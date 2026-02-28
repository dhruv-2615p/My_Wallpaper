package com.example.my_flutter_app

import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Shader
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Handler
import android.os.HandlerThread
import android.service.wallpaper.WallpaperService
import android.view.SurfaceHolder
import kotlin.math.abs
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin
import kotlin.random.Random

// ---------------------------------------------------------------------------
// Particle system
// ---------------------------------------------------------------------------
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
                    pvy[i] -= abs(gravY) * 0.01f
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
                    paint.style = Paint.Style.FILL
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
                    paint.style = Paint.Style.FILL
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
                    paint.style = Paint.Style.FILL
                    canvas.drawOval(px[i] - s, py[i] - s * 0.6f, px[i] + s, py[i] + s * 0.6f, paint)
                }
                4 -> {
                    paint.color = Color.argb((palpha[i] * 60).toInt(), 180, 210, 255)
                    paint.style = Paint.Style.FILL
                    canvas.drawCircle(px[i], py[i], s, paint)
                    paint.color = Color.argb((palpha[i] * 150).toInt(), 255, 255, 255)
                    paint.style = Paint.Style.STROKE
                    paint.strokeWidth = 1.5f
                    canvas.drawCircle(px[i], py[i], s, paint)
                    paint.style = Paint.Style.FILL
                }
                5 -> {
                    paint.color = Color.argb((palpha[i] * 255).toInt(), 255, 255, 255)
                    paint.style = Paint.Style.FILL
                    canvas.drawCircle(px[i], py[i], s, paint)
                }
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Ice-cube data
// ---------------------------------------------------------------------------
private class IceCubeNative(
    var xFrac: Float,
    val w: Float,
    val h: Float,
    val bobPhase: Float,
    val bobSpeed: Float,
    val bobAmp: Float,
    val crackSeed: Int
) {
    var vx = 0f
}

// ---------------------------------------------------------------------------
// Live Wallpaper Service
// ---------------------------------------------------------------------------
class GyroLiveWallpaperService : WallpaperService() {

    override fun onCreateEngine(): Engine = GyroEngine()

    inner class GyroEngine : Engine(), SensorEventListener {

        private val prefs: SharedPreferences by lazy {
            getSharedPreferences("gyro_live_wp", Context.MODE_PRIVATE)
        }

        private val drawThread = HandlerThread("gyro-wall-draw").also { it.start() }
        private val drawHandler = Handler(drawThread.looper)

        private var surfaceW = 0
        private var surfaceH = 0
        private var baseBitmap: Bitmap? = null

        // --- effect settings ---
        private var sensitivity       = 1f
        private var isGyroEnabled     = true
        private var isWaterEnabled    = false
        private var waterLevel        = 0.2f
        private var waterColorArgb    = Color.argb(153, 0, 191, 255)
        private var waterR = 0; private var waterG = 191; private var waterB = 255; private var waterA = 153
        private var iceCount          = 3
        private var isColorOverlay    = false
        private var colorOverlayColor = 0x33191970
        private var isBlur            = false
        private var blurAmount        = 0f
        private var isParticles       = false
        private var particleTypeIdx   = 0
        private var particleCount     = 50

        // --- gyroscope parallax ---
        @Volatile private var offsetX = 0f
        @Volatile private var offsetY = 0f
        private var smoothX = 0f; private var smoothY = 0f
        private val lpAlpha = 0.12f
        private val baseMaxOffset = 60f

        // --- accelerometer ---
        @Volatile private var gravX = 0f
        @Volatile private var gravY = 9.8f

        // --- water tilt (smoothed faster: 0.12 not 0.06) ---
        private var smoothTilt = 0f

        private var animTime = 0f
        private var iceList: List<IceCubeNative> = emptyList()
        private var particles: ParticleSys? = null

        private val frameIntervalMs = 16L
        private val frameRunnable: Runnable = object : Runnable {
            override fun run() {
                tickAndDraw()
                if (isVisible) drawHandler.postDelayed(this, frameIntervalMs)
            }
        }

        private val drawPaint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)
        private val overlayPaint = Paint()
        private val waterPaint = Paint(Paint.ANTI_ALIAS_FLAG)
        private val icePaint = Paint(Paint.ANTI_ALIAS_FLAG)
        private val hlPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.STROKE }

        // ---- lifecycle ----

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
            drawHandler.post { surfaceW = w; surfaceH = h; reloadAll() }
        }

        override fun onVisibilityChanged(visible: Boolean) {
            drawHandler.removeCallbacks(frameRunnable)
            if (visible) drawHandler.post { reloadAll(); frameRunnable.run() }
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

        // ---- sensors ----

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
                    gravX = gravX * 0.85f + event.values[0] * 0.15f
                    gravY = gravY * 0.85f + event.values[1] * 0.15f
                }
            }
        }

        override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {}

        // ---- load ----

        private fun reloadAll() { readPrefs(); loadBitmap(); buildSimulations() }

        private fun readPrefs() {
            sensitivity       = prefs.getFloat("sensitivity", 1f)
            isGyroEnabled     = prefs.getBoolean("is_gyro_enabled", true)
            isWaterEnabled    = prefs.getBoolean("is_water_enabled", false)
            waterLevel        = prefs.getFloat("water_level", 0.2f)
            waterColorArgb    = prefs.getInt("water_color_argb", Color.argb(153, 0, 191, 255))
            waterR = Color.red(waterColorArgb)
            waterG = Color.green(waterColorArgb)
            waterB = Color.blue(waterColorArgb)
            waterA = Color.alpha(waterColorArgb)
            iceCount          = prefs.getInt("ice_count", 3).coerceIn(0, 5)
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
            val sw = (raw.width * scale).toInt().coerceAtLeast(1)
            val sh = (raw.height * scale).toInt().coerceAtLeast(1)
            baseBitmap?.recycle()
            val scaled = Bitmap.createScaledBitmap(raw, sw, sh, true)
            if (raw != scaled) raw.recycle()
            baseBitmap = scaled
        }

        private fun buildSimulations() {
            iceList = emptyList(); particles = null
            if (surfaceW <= 0 || surfaceH <= 0) return
            if (isWaterEnabled && iceCount > 0) {
                val rng = Random(42)
                iceList = List(iceCount) { i ->
                    val sc = i % 3
                    val bw = floatArrayOf(30f, 48f, 68f)[sc]
                    val bh = floatArrayOf(20f, 30f, 42f)[sc]
                    IceCubeNative(
                        // Evenly distributed so they never start merged
                        xFrac = if (iceCount == 1) 0.5f
                                else 0.12f + (i.toFloat() / (iceCount - 1)) * 0.76f,
                        w = bw + rng.nextFloat() * 10f,
                        h = bh + rng.nextFloat() * 6f,
                        bobPhase = rng.nextFloat() * 2f * Math.PI.toFloat(),
                        bobSpeed = 0.25f + rng.nextFloat() * 0.3f,
                        bobAmp = 1.0f + rng.nextFloat() * 1.5f,
                        crackSeed = rng.nextInt(10000)
                    )
                }
            }
            if (isParticles) {
                particles = ParticleSys(particleCount, particleTypeIdx, surfaceW.toFloat(), surfaceH.toFloat())
            }
        }

        // ---- water surface ----

        // Matching Flutter: bigger amplitudes + stronger tilt (0.55).
        private fun surfaceY(x: Float, sw: Float, sh: Float, phase: Float, tilt: Float): Float {
            val baseY = sh * (1f - waterLevel)
            val tiltOffset = -(x / sw - 0.5f) * tilt * sh * 0.55f
            val r1 = sin((phase * 0.35f + x * 0.008f).toDouble()).toFloat() * 6.0f
            val r2 = sin((phase * 0.8f + x * 0.018f + 2f).toDouble()).toFloat() * 3.5f
            val r3 = cos((phase * 1.5f + x * 0.04f - 1f).toDouble()).toFloat() * 1.5f
            return baseY + tiltOffset + r1 + r2 + r3
        }

        // Build smooth Catmull-Rom cubic bezier path (not straight line segments).
        private fun buildSurfacePath(
            sw: Float, sh: Float, phase: Float, tilt: Float, yOff: Float = 0f
        ): Path {
            val step = 24f
            val pts = mutableListOf<FloatArray>()
            var x = 0f
            while (x <= sw) {
                pts.add(floatArrayOf(x, surfaceY(x, sw, sh, phase, tilt) + yOff))
                x += step
            }
            if (pts.last()[0] < sw)
                pts.add(floatArrayOf(sw, surfaceY(sw, sw, sh, phase, tilt) + yOff))

            val path = Path()
            path.moveTo(pts[0][0], pts[0][1])
            for (i in 0 until pts.size - 1) {
                val p0 = pts[max(0, i - 1)]
                val p1 = pts[i]
                val p2 = pts[min(pts.size - 1, i + 1)]
                val p3 = pts[min(pts.size - 1, i + 2)]
                val cp1x = p1[0] + (p2[0] - p0[0]) / 6f
                val cp1y = p1[1] + (p2[1] - p0[1]) / 6f
                val cp2x = p2[0] - (p3[0] - p1[0]) / 6f
                val cp2y = p2[1] - (p3[1] - p1[1]) / 6f
                path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2[0], p2[1])
            }
            return path
        }

        // ---- draw loop ----

        private fun tickAndDraw() {
            animTime += 0.016f

            // Faster tilt smoothing: 0.12 (was 0.06)
            val tiltRaw = (-gravX / 9.81f).coerceIn(-1f, 1f)
            smoothTilt += 0.12f * (tiltRaw - smoothTilt)

            // Ice drift: OPPOSITE direction to water tilt
            for (ice in iceList) {
                ice.vx -= smoothTilt * 0.001f   // REVERSED
                ice.vx *= 0.975f
                ice.xFrac += ice.vx
                if (ice.xFrac < 0.06f) { ice.xFrac = 0.06f; ice.vx = abs(ice.vx) * 0.15f }
                if (ice.xFrac > 0.94f) { ice.xFrac = 0.94f; ice.vx = -abs(ice.vx) * 0.15f }
            }

            // Ice-ice repulsion: prevent merging
            for (a in iceList.indices) {
                for (b in a + 1 until iceList.size) {
                    val diff = iceList[a].xFrac - iceList[b].xFrac
                    val minSep = 0.16f
                    if (abs(diff) < minSep) {
                        val push = (minSep - abs(diff)) * 0.04f
                        if (diff >= 0) {
                            iceList[a].xFrac += push
                            iceList[b].xFrac -= push
                        } else {
                            iceList[a].xFrac -= push
                            iceList[b].xFrac += push
                        }
                    }
                }
            }

            particles?.step(
                (-gravX / 10f).coerceIn(-1f, 1f),
                (-gravY / 10f).coerceIn(-1f, 1f)
            )
            drawFrame()
        }

        private fun drawFrame() {
            val holder = surfaceHolder
            var canvas: Canvas? = null
            try {
                canvas = holder.lockCanvas() ?: return
                val cw = canvas.width.toFloat()
                val ch = canvas.height.toFloat()
                val bmp = baseBitmap
                if (bmp == null || bmp.isRecycled) {
                    canvas.drawARGB(255, 0, 0, 0); return
                }
                val imgLeft = (cw - bmp.width) / 2f + if (isGyroEnabled) offsetX else 0f
                val imgTop  = (ch - bmp.height) / 2f + if (isGyroEnabled) offsetY else 0f
                canvas.drawARGB(255, 0, 0, 0)
                canvas.drawBitmap(bmp, imgLeft, imgTop, drawPaint)

                if (isColorOverlay) {
                    overlayPaint.color = colorOverlayColor
                    canvas.drawRect(0f, 0f, cw, ch, overlayPaint)
                }
                particles?.draw(canvas)
                if (isWaterEnabled) drawWater(canvas, cw, ch)
            } finally {
                canvas?.let { holder.unlockCanvasAndPost(it) }
            }
        }

        private fun drawWater(canvas: Canvas, cw: Float, ch: Float) {
            val phase = animTime * 2f * Math.PI.toFloat() / 12f
            val tilt = smoothTilt

            // Floor alpha at 140/255 (~0.55) so water is always clearly visible
            val alphaBase = max(waterA, 140)

            // --- main water body (cubic bezier surface) ---
            val surfLine = buildSurfacePath(cw, ch, phase, tilt)
            val surfFill = Path(surfLine)
            surfFill.lineTo(cw, ch)
            surfFill.lineTo(0f, ch)
            surfFill.close()

            val topY = ch * (1f - waterLevel) - ch * 0.12f
            val a1 = (alphaBase * 0.55f).toInt().coerceIn(0, 255)
            val a2 = (alphaBase * 0.72f).toInt().coerceIn(0, 255)
            val a3 = (alphaBase * 0.88f).toInt().coerceIn(0, 255)
            val a4 = (alphaBase * 0.96f).toInt().coerceIn(0, 255)
            waterPaint.shader = LinearGradient(
                cw / 2f, topY, cw / 2f, ch,
                intArrayOf(
                    Color.argb(a1, waterR, waterG, waterB),
                    Color.argb(a2, waterR, waterG, waterB),
                    Color.argb(a3, waterR, waterG, waterB),
                    Color.argb(a4, waterR, waterG, waterB)
                ),
                floatArrayOf(0f, 0.30f, 0.65f, 1f),
                Shader.TileMode.CLAMP
            )
            waterPaint.style = Paint.Style.FILL
            canvas.drawPath(surfFill, waterPaint)

            // --- deeper secondary wave ---
            val deepLine = buildSurfacePath(cw, ch, phase + 1.8f, tilt, 20f)
            val deepFill = Path(deepLine)
            deepFill.lineTo(cw, ch); deepFill.lineTo(0f, ch); deepFill.close()
            waterPaint.shader = null
            waterPaint.color = Color.argb((alphaBase * 0.15f).toInt().coerceIn(0, 255), waterR, waterG, waterB)
            canvas.drawPath(deepFill, waterPaint)

            // --- surface highlight ---
            hlPaint.strokeWidth = 1.8f
            hlPaint.color = Color.argb(65, 255, 255, 255)
            canvas.drawPath(surfLine, hlPaint)
            hlPaint.strokeWidth = 0.6f
            hlPaint.color = Color.argb(35, 255, 255, 255)
            canvas.drawPath(surfLine, hlPaint)

            // --- ice ---
            for (ice in iceList) drawIce(canvas, ice, cw, ch, phase, tilt)
        }

        private fun drawIce(canvas: Canvas, ice: IceCubeNative,
                            cw: Float, ch: Float, phase: Float, tilt: Float) {
            val cx = ice.xFrac * cw
            val surfY = surfaceY(cx, cw, ch, phase, tilt)
            val bob = sin((phase * ice.bobSpeed + ice.bobPhase).toDouble()).toFloat() * ice.bobAmp

            val yL = surfaceY(cx - 8f, cw, ch, phase, tilt)
            val yR = surfaceY(cx + 8f, cw, ch, phase, tilt)
            val angle = atan2((yR - yL).toDouble(), 16.0).toFloat() * 0.6f

            canvas.save()
            canvas.translate(cx, surfY + bob - ice.h * 0.58f)
            canvas.rotate(Math.toDegrees(angle.toDouble()).toFloat())

            val hw = ice.w / 2f; val hh = ice.h / 2f
            val rect = RectF(-hw, -hh, hw, hh)

            // More opaque ice body
            icePaint.style = Paint.Style.FILL
            icePaint.shader = LinearGradient(
                -hw, -hh, hw, hh,
                intArrayOf(
                    Color.argb(238, 240, 248, 255),  // 0xEEF0F8FF
                    Color.argb(221, 224, 239, 248),  // 0xDDE0EFF8
                    Color.argb(204, 208, 232, 245),  // 0xCCD0E8F5
                    Color.argb(187, 192, 224, 240)   // 0xBBC0E0F0
                ),
                floatArrayOf(0f, 0.30f, 0.60f, 1f),
                Shader.TileMode.CLAMP
            )
            canvas.drawRoundRect(rect, 6f, 6f, icePaint)
            icePaint.shader = null

            // Edge
            icePaint.style = Paint.Style.STROKE
            icePaint.strokeWidth = 1.0f
            icePaint.color = Color.argb(140, 255, 255, 255)
            canvas.drawRoundRect(rect, 6f, 6f, icePaint)

            // Cracks
            val crng = Random(ice.crackSeed)
            icePaint.strokeWidth = 0.6f
            icePaint.color = Color.argb(75, 255, 255, 255)
            for (c in 0 until 3) {
                val sx = (crng.nextFloat() - 0.5f) * ice.w * 0.6f
                val sy = (crng.nextFloat() - 0.5f) * ice.h * 0.5f
                val ex = sx + (crng.nextFloat() - 0.5f) * ice.w * 0.45f
                val ey = sy + (crng.nextFloat() - 0.5f) * ice.h * 0.45f
                canvas.drawLine(sx, sy, ex, ey, icePaint)
            }

            // Gloss
            icePaint.style = Paint.Style.FILL
            icePaint.color = Color.argb(90, 255, 255, 255)
            canvas.drawOval(
                RectF(-hw * 0.45f, -hh * 0.55f, -hw * 0.45f + ice.w * 0.38f, -hh * 0.55f + ice.h * 0.28f),
                icePaint
            )

            // Submerged tint
            canvas.save()
            canvas.clipRect(-hw - 5f, ice.h * 0.10f, hw + 5f, hh + 5f)
            icePaint.color = Color.argb(55, waterR, waterG, waterB)
            canvas.drawRoundRect(rect, 6f, 6f, icePaint)
            canvas.restore()

            canvas.restore()
        }
    }
}
