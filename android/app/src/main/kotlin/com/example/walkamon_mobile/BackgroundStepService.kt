package com.example.walkamon_mobile

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.nio.charset.StandardCharsets
import java.security.MessageDigest
import java.time.Instant
import java.time.LocalDateTime
import java.time.ZoneOffset
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

class BackgroundStepService : Service() {
    private lateinit var collector: MotionSensorCollector
    private lateinit var store: BackgroundStepStore
    private lateinit var tokenStore: SecureTokenStore
    private lateinit var integrityBridge: PlayIntegrityBridge
    private lateinit var executor: ScheduledExecutorService
    private var wakeLock: PowerManager.WakeLock? = null
    private val uploadInProgress = AtomicBoolean(false)
    private var explicitStop = false
    private var nextAttemptAtMs = 0L
    private var uploadScheduled = false

    override fun onCreate() {
        super.onCreate()
        serviceAlive = true
        createNotificationChannel()
        store = BackgroundStepStore(applicationContext)
        tokenStore = SecureTokenStore(applicationContext)
        integrityBridge = PlayIntegrityBridge(applicationContext)
        executor = Executors.newSingleThreadScheduledExecutor()
        collector = MotionSensorCollector(applicationContext, ::onCollectorEvent)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopTracking(clearState = true)
                return START_NOT_STICKY
            }
            ACTION_START -> saveIncomingConfiguration(intent)
        }

        val config = loadConfig()
        if (config == null || !preferences().getBoolean(KEY_RUNNING, false)) {
            stopSelf()
            return START_NOT_STICKY
        }
        if (collector.capabilities()["activityRecognitionAvailable"] != true) {
            preferences().edit().putBoolean(KEY_RUNNING, false).apply()
            MotionEventRelay.emit(
                mapOf(
                    "eventType" to "tracking_status",
                    "running" to false,
                    "userId" to config.userId,
                    "message" to "activity_permission_required",
                ),
            )
            stopSelf()
            return START_NOT_STICKY
        }

        startAsForeground(config.acceptedTotal)
        acquireWakeLock()
        collector.start(config.sensorMode, config.windowMilliseconds, config.targetSampleHz)
        if (!executor.isShutdown && !uploadScheduled) {
            uploadScheduled = true
            executor.scheduleWithFixedDelay(::uploadTick, 2, 5, TimeUnit.SECONDS)
        }
        emitStatus(config, "tracking")
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        serviceAlive = false
        collector.stop()
        if (::executor.isInitialized) executor.shutdownNow()
        wakeLock?.takeIf { it.isHeld }?.release()
        wakeLock = null
        if (!explicitStop && preferences().getBoolean(KEY_RUNNING, false)) {
            MotionEventRelay.emit(
                mapOf(
                    "eventType" to "tracking_status",
                    "running" to false,
                    "message" to "service_restarting",
                ),
            )
        }
        super.onDestroy()
    }

    private fun saveIncomingConfiguration(intent: Intent) {
        val sessionId = intent.getStringExtra(EXTRA_SESSION_ID) ?: return
        val oldSessionId = preferences().getString(KEY_SESSION_ID, null)
        val sameSession = oldSessionId == sessionId
        if (!sameSession) store.clear()

        val incomingSequence = intent.getIntExtra(EXTRA_NEXT_SEQUENCE, 1)
        val savedSequence = if (sameSession) preferences().getInt(KEY_NEXT_SEQUENCE, 1) else 1
        val incomingTotal = intent.getIntExtra(EXTRA_ACCEPTED_TOTAL, 0)
        val incomingStepDate = intent.getStringExtra(EXTRA_STEP_DATE) ?: vietnamDate()
        val sameDate = preferences().getString(KEY_STEP_DATE, null) == incomingStepDate
        if (!sameDate) store.clear()
        val savedTotal = if (sameSession && sameDate) {
            preferences().getInt(KEY_ACCEPTED_TOTAL, 0)
        } else {
            0
        }
        intent.getStringExtra(EXTRA_ACCESS_TOKEN)
            ?.takeIf(String::isNotBlank)
            ?.let(tokenStore::save)

        preferences().edit()
            .putBoolean(KEY_RUNNING, true)
            .putString(KEY_USER_ID, intent.getStringExtra(EXTRA_USER_ID))
            .putString(KEY_STEP_DATE, incomingStepDate)
            .putString(KEY_API_BASE_URL, intent.getStringExtra(EXTRA_API_BASE_URL)?.trimEnd('/'))
            .putString(KEY_SENSOR_MODE, intent.getStringExtra(EXTRA_SENSOR_MODE) ?: "counter")
            .putInt(KEY_WINDOW_MS, intent.getIntExtra(EXTRA_WINDOW_MS, 1000))
            .putInt(KEY_SAMPLE_HZ, intent.getIntExtra(EXTRA_SAMPLE_HZ, 25))
            .putInt(KEY_CONTRACT_VERSION, intent.getIntExtra(EXTRA_CONTRACT_VERSION, 2))
            .putString(KEY_SESSION_ID, sessionId)
            .putString(KEY_NONCE, intent.getStringExtra(EXTRA_NONCE))
            .putLong(KEY_EXPIRES_AT_MS, intent.getLongExtra(EXTRA_EXPIRES_AT_MS, 0L))
            .putInt(KEY_NEXT_SEQUENCE, maxOf(savedSequence, incomingSequence))
            .putBoolean(
                KEY_ATTESTED,
                if (sameSession) {
                    preferences().getBoolean(KEY_ATTESTED, false) ||
                        intent.getBooleanExtra(EXTRA_ATTESTED, false)
                } else {
                    intent.getBooleanExtra(EXTRA_ATTESTED, false)
                },
            )
            .putBoolean(KEY_ALLOW_DEV_BYPASS, intent.getBooleanExtra(EXTRA_ALLOW_DEV_BYPASS, false))
            .putInt(KEY_ACCEPTED_TOTAL, maxOf(savedTotal, incomingTotal))
            .apply()
    }

    private fun onCollectorEvent(event: Map<String, Any?>) {
        if (executor.isShutdown) return
        executor.execute {
            runCatching {
                when (event["eventType"]) {
                    "step" -> {
                        store.addSensorEvent(sensorEventJson(event))
                        val counts = store.pendingCounts()
                        Log.i(TAG, "Stored step event; pendingEvents=${counts.first}, pendingWindows=${counts.second}")
                    }
                    "motion" -> store.addMotionWindow(motionWindowJson(event))
                }
            }.onFailure { Log.e(TAG, "Failed to persist sensor event", it) }
        }
    }

    private fun sensorEventJson(event: Map<String, Any?>): JSONObject {
        val interval = Instant.parse(event["intervalStartedAt"].toString())
        val recorded = Instant.parse(event["recordedAt"].toString())
        return JSONObject()
            .put("intervalStartedAt", interval.toString())
            .put("recordedAt", recorded.toString())
            .put("intervalStartedAtMs", interval.toEpochMilli())
            .put("recordedAtMs", recorded.toEpochMilli())
            .put("stepCount", event["stepCount"])
            .putNullable("sensorStartTotal", event["sensorStartTotal"])
            .putNullable("sensorEndTotal", event["sensorEndTotal"])
    }

    private fun motionWindowJson(event: Map<String, Any?>): JSONObject {
        val started = Instant.parse(event["windowStartedAt"].toString())
        val ended = Instant.parse(event["windowEndedAt"].toString())
        return JSONObject()
            .put("windowStartedAt", started.toString())
            .put("windowEndedAt", ended.toString())
            .put("windowStartedAtMs", started.toEpochMilli())
            .put("windowEndedAtMs", ended.toEpochMilli())
            .put("sampleCount", event["sampleCount"])
            .put("accelerometerSource", event["accelerometerSource"])
            .put("gyroscopeAvailable", event["gyroscopeAvailable"])
            .put("activityAvailable", event["activityAvailable"])
            .put("accelerationRmsMilli", event["accelerationRmsMilli"])
            .put("accelerationPeakMilli", event["accelerationPeakMilli"])
            .put("jerkRmsMilli", event["jerkRmsMilli"])
            .putNullable("gyroscopeRmsMilli", event["gyroscopeRmsMilli"])
            .putNullable("gyroscopePeakMilli", event["gyroscopePeakMilli"])
            .putNullable("orientationDeltaMilliDegrees", event["orientationDeltaMilliDegrees"])
            .put("dominantFrequencyMilliHz", event["dominantFrequencyMilliHz"])
            .put("periodicityBps", event["periodicityBps"])
            .put("gaitCycleCount", event["gaitCycleCount"])
            .put("activityCode", event["activityCode"])
            .put("activityConfidence", event["activityConfidence"])
    }

    private fun uploadTick() {
        if (System.currentTimeMillis() < nextAttemptAtMs) return
        if (!uploadInProgress.compareAndSet(false, true)) return
        try {
            rollVietnamDateIfNeeded()
            store.prune(System.currentTimeMillis() - MAX_LOCAL_AGE_MS)
            var config = loadConfig() ?: return
            if (config.expiresAtMs <= System.currentTimeMillis()) {
                config = createDailySession(config) ?: return
            }
            val batch = store.pendingBatch() ?: createPendingBatch(config) ?: return
            if (batch.attestationToken.isNullOrBlank() ||
                batch.attestationRequestedAtMs == null ||
                System.currentTimeMillis() - batch.attestationRequestedAtMs > ATTESTATION_REFRESH_MS
            ) {
                if (!batch.attestationToken.isNullOrBlank()) {
                    store.clearPendingAttestation()
                }
                if (BuildConfig.DEBUG && config.allowDevelopmentBypass) {
                    store.setPendingAttestation(
                        "DEV_BYPASS:${batch.payloadHash}",
                        System.currentTimeMillis(),
                    )
                    return
                }
                requestAttestation(batch)
                return
            }
            val token = batch.attestationToken
                ?: error("Pending attestation token is missing.")
            submitBatch(config, batch, token)
        } catch (error: Exception) {
            Log.e(TAG, "Background step upload failed", error)
            nextAttemptAtMs = System.currentTimeMillis() + RETRY_DELAY_MS
        } finally {
            uploadInProgress.set(false)
        }
    }

    private fun createPendingBatch(config: ServiceConfig): PendingStepBatch? {
        val latestWindowEnd = store.latestWindowEnd() ?: return null
        val candidates = store.events(MAX_BATCH_EVENTS)
            .takeWhile { it.recordedAtMs < latestWindowEnd }
        if (candidates.isEmpty()) {
            val counts = store.pendingCounts()
            if (counts.first > 0) {
                Log.i(TAG, "Waiting for motion coverage; pendingEvents=${counts.first}, pendingWindows=${counts.second}")
            }
            return null
        }
        val newestEventAtMs = candidates.maxOf { it.recordedAtMs }
        if (candidates.size < MAX_BATCH_EVENTS &&
            System.currentTimeMillis() - newestEventAtMs < MIN_BATCH_AGE_MS
        ) {
            return null
        }

        val queryStart = candidates.minOf { it.intervalStartedAtMs } - 1000L
        val queryEnd = candidates.maxOf { it.recordedAtMs }
        val availableWindows = store.windows(queryStart, queryEnd)
        if (availableWindows.isEmpty()) return null

        val events = mutableListOf<StoredSensorEvent>()
        for (event in candidates) {
            val proposedStart = minOf(
                events.minOfOrNull { it.intervalStartedAtMs } ?: event.intervalStartedAtMs,
                event.intervalStartedAtMs,
            ) - 1000L
            val proposedEnd = maxOf(
                events.maxOfOrNull { it.recordedAtMs } ?: event.recordedAtMs,
                event.recordedAtMs,
            )
            val proposedWindowCount = availableWindows.count {
                it.windowEndedAtMs > proposedStart &&
                    it.windowStartedAtMs <= proposedEnd
            }
            if (proposedWindowCount > MAX_BATCH_MOTION_WINDOWS) break
            val covered = hasCoverage(event, availableWindows)
            val evidencePassed = latestWindowEnd >= event.recordedAtMs + 1000L
            if (!covered && !evidencePassed) break
            events += event
        }
        if (events.isEmpty()) return null

        val rangeStart = events.minOf { it.intervalStartedAtMs } - 1000L
        val rangeEnd = events.maxOf { it.recordedAtMs }
        val windows = availableWindows.filter {
            it.windowEndedAtMs > rangeStart && it.windowStartedAtMs <= rangeEnd
        }
        if (windows.isEmpty()) return null

        val hash = canonicalHash(config, events, windows)
        val body = JSONObject()
            .put("contractVersion", config.contractVersion)
            .put("sequence", config.nextSequence)
            .put("nonce", config.nonce)
            .put("payloadHash", hash)
            .put("attestationToken", "")
            .put("events", JSONArray(events.map { it.json.forApi() }))
            .put("motionWindows", JSONArray(windows.map { it.json.forApi() }))
        return PendingStepBatch(
            payloadHash = hash,
            body = body,
            eventIds = events.map(StoredSensorEvent::id),
            windowIds = windows.map(StoredMotionWindow::id),
            attestationToken = null,
            attestationRequestedAtMs = null,
        ).also {
            store.savePendingBatch(it)
            Log.i(TAG, "Prepared batch sequence=${config.nextSequence}, events=${events.size}, windows=${windows.size}")
        }
    }

    private fun hasCoverage(
        event: StoredSensorEvent,
        windows: List<StoredMotionWindow>,
    ): Boolean {
        if (event.intervalStartedAtMs == event.recordedAtMs) {
            return windows.any {
                it.windowStartedAtMs <= event.recordedAtMs &&
                    it.windowEndedAtMs > event.recordedAtMs
            }
        }
        val duration = event.recordedAtMs - event.intervalStartedAtMs
        if (duration <= 0L) return false
        val covered = windows.sumOf {
            val start = maxOf(it.windowStartedAtMs, event.intervalStartedAtMs)
            val end = minOf(it.windowEndedAtMs, event.recordedAtMs)
            (end - start).coerceAtLeast(0L)
        }
        return covered * 10_000L / duration >= 8_000L
    }

    private fun canonicalHash(
        config: ServiceConfig,
        events: List<StoredSensorEvent>,
        windows: List<StoredMotionWindow>,
    ): String {
        val lines = mutableListOf(
            "V2",
            config.sessionId.lowercase(),
            config.nextSequence.toString(),
            config.nonce,
            config.sensorMode,
        )
        events.forEach { stored ->
            val value = stored.json
            lines += "E:${stored.intervalStartedAtMs}:${stored.recordedAtMs}:" +
                "${value.getInt("stepCount")}:${value.nullableString("sensorStartTotal")}:" +
                value.nullableString("sensorEndTotal")
        }
        windows.forEach { stored ->
            val value = stored.json
            lines += "M:${stored.windowStartedAtMs}:${stored.windowEndedAtMs}:" +
                "${value.getInt("sampleCount")}:${value.getString("accelerometerSource")}:" +
                "${value.booleanInt("gyroscopeAvailable")}:${value.booleanInt("activityAvailable")}:" +
                "${value.getInt("accelerationRmsMilli")}:${value.getInt("accelerationPeakMilli")}:" +
                "${value.getInt("jerkRmsMilli")}:${value.nullableString("gyroscopeRmsMilli")}:" +
                "${value.nullableString("gyroscopePeakMilli")}:" +
                "${value.nullableString("orientationDeltaMilliDegrees")}:" +
                "${value.getInt("dominantFrequencyMilliHz")}:${value.getInt("periodicityBps")}:" +
                "${value.getInt("gaitCycleCount")}:${value.getString("activityCode")}:" +
                value.getInt("activityConfidence")
        }
        return MessageDigest.getInstance("SHA-256")
            .digest(lines.joinToString("\n").toByteArray(StandardCharsets.UTF_8))
            .joinToString("") { "%02X".format(it) }
    }

    private fun requestAttestation(batch: PendingStepBatch) {
        uploadInProgress.set(false)
        integrityBridge.prepare(
            onSuccess = {
                integrityBridge.requestToken(
                    requestHash = batch.payloadHash,
                    onSuccess = { token ->
                        executor.execute {
                            store.setPendingAttestation(token, System.currentTimeMillis())
                            uploadTick()
                        }
                    },
                    onError = { _, _ -> scheduleRetry() },
                )
            },
            onError = { code, message ->
                Log.w(TAG, "Play Integrity prepare failed: $code $message")
                scheduleRetry()
            },
        )
    }

    private fun submitBatch(
        config: ServiceConfig,
        batch: PendingStepBatch,
        attestationToken: String,
    ) {
        val body = JSONObject(batch.body.toString()).put("attestationToken", attestationToken)
        val response = postJson(
            "${config.apiBaseUrl}/api/step-sensor/sessions/${config.sessionId}/batches",
            body,
        )
        Log.i(TAG, "Batch sequence=${config.nextSequence} returned HTTP ${response.status}")
        when {
            response.status in 200..299 -> {
                val data = response.dataObject()
                val accepted = data.optInt("acceptedSteps", 0)
                val nextSequence = data.optInt("nextSequence", config.nextSequence + 1)
                val attestationStatus = data.optString("attestationStatus")
                val serverDate = data.optString("dailyStepDate")
                val serverTotal = if (data.has("dailyAcceptedTotal")) {
                    data.optInt("dailyAcceptedTotal", -1)
                } else {
                    -1
                }
                val newTotal = if (serverDate == config.stepDate && serverTotal >= 0) {
                    serverTotal
                } else {
                    config.acceptedTotal + accepted
                }
                preferences().edit()
                    .putInt(KEY_NEXT_SEQUENCE, nextSequence)
                    .putInt(KEY_ACCEPTED_TOTAL, newTotal)
                    .putBoolean(
                        KEY_ATTESTED,
                        attestationStatus == "verified" ||
                            attestationStatus == "development_bypass" ||
                            attestationStatus == "session_cached" ||
                            attestationStatus == "legacy_session_cached",
                    )
                    .apply()
                store.completeBatch(batch)
                val updated = loadConfig() ?: config
                updateNotification(updated.acceptedTotal, "Đang ghi nhận bước")
                emitStatus(updated, data.optString("motionStatus", "accepted"))
            }
            response.status == 429 -> {
                nextAttemptAtMs = System.currentTimeMillis() +
                    response.retryAfterSeconds.coerceAtLeast(60) * 1000L
            }
            response.status == 404 || response.status == 409 -> {
                store.discardPendingBatch()
                preferences().edit().putLong(KEY_EXPIRES_AT_MS, 0L).apply()
                nextAttemptAtMs = System.currentTimeMillis() + RETRY_DELAY_MS
            }
            response.status == 401 || response.status == 403 -> {
                nextAttemptAtMs = System.currentTimeMillis() + AUTH_RETRY_DELAY_MS
                updateNotification(config.acceptedTotal, "Mở Walkamon để đăng nhập lại")
                emitStatus(config, "authentication_required")
            }
            else -> scheduleRetry()
        }
    }

    private fun createDailySession(current: ServiceConfig): ServiceConfig? {
        val response = postJson(
            "${current.apiBaseUrl}/api/step-sensor/session",
            JSONObject()
                .put("platformCode", "android")
                .put("sensorModeCode", current.sensorMode),
        )
        if (response.status !in 200..299) {
            if (response.status == 401 || response.status == 403) {
                updateNotification(current.acceptedTotal, "Mở Walkamon để đăng nhập lại")
            }
            nextAttemptAtMs = System.currentTimeMillis() + RETRY_DELAY_MS
            return null
        }
        val data = response.dataObject()
        val sessionId = data.optString("stepSessionId")
        val nonce = data.optString("nonce")
        if (sessionId.isBlank() || nonce.isBlank()) return null
        store.discardPendingBatch()
        preferences().edit()
            .putString(KEY_SESSION_ID, sessionId)
            .putString(KEY_NONCE, nonce)
            .putLong(KEY_EXPIRES_AT_MS, parseServerUtcMillis(data.getString("expiresAt")))
            .putInt(KEY_NEXT_SEQUENCE, data.optInt("nextSequence", 1))
            .putBoolean(KEY_ATTESTED, false)
            .apply()
        return loadConfig()
    }

    private fun postJson(url: String, body: JSONObject): HttpResponse {
        val connection = URL(url).openConnection() as HttpURLConnection
        return try {
            connection.requestMethod = "POST"
            connection.connectTimeout = 30_000
            connection.readTimeout = 30_000
            connection.doOutput = true
            connection.setRequestProperty("Accept", "application/json")
            connection.setRequestProperty("Content-Type", "application/json")
            tokenStore.read()?.takeIf(String::isNotBlank)?.let {
                connection.setRequestProperty("Authorization", "Bearer $it")
            }
            connection.outputStream.use {
                it.write(body.toString().toByteArray(StandardCharsets.UTF_8))
            }
            val status = connection.responseCode
            val stream = if (status in 200..299) connection.inputStream else connection.errorStream
            val responseBody = stream?.bufferedReader()?.use { it.readText() }.orEmpty()
            HttpResponse(
                status = status,
                json = runCatching { JSONObject(responseBody) }.getOrElse { JSONObject() },
                retryAfterSeconds = connection.getHeaderField("Retry-After")?.toLongOrNull() ?: 60L,
            )
        } finally {
            connection.disconnect()
        }
    }

    private fun startAsForeground(acceptedTotal: Int) {
        ServiceCompat.startForeground(
            this,
            NOTIFICATION_ID,
            notification(acceptedTotal, "Đang ghi nhận bước"),
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_HEALTH
            } else {
                0
            },
        )
    }

    private fun updateNotification(acceptedTotal: Int, message: String) {
        getSystemService(NotificationManager::class.java)
            .notify(NOTIFICATION_ID, notification(acceptedTotal, message))
    }

    private fun notification(acceptedTotal: Int, message: String): Notification {
        val openIntent = PendingIntent.getActivity(
            this,
            2001,
            packageManager.getLaunchIntentForPackage(packageName),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val stopIntent = PendingIntent.getService(
            this,
            2002,
            Intent(this, BackgroundStepService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL)
            .setSmallIcon(R.drawable.ic_walkamon_steps)
            .setContentTitle("Walkamon đang ghi nhận bước")
            .setContentText("$message · Hôm nay: $acceptedTotal bước")
            .setContentIntent(openIntent)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .addAction(0, "Dừng", stopIntent)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        getSystemService(NotificationManager::class.java).createNotificationChannel(
            NotificationChannel(
                NOTIFICATION_CHANNEL,
                "Theo dõi bước",
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Thông báo khi Walkamon ghi nhận bước ở chế độ nền."
                setShowBadge(false)
            },
        )
    }

    private fun acquireWakeLock() {
        if (wakeLock?.isHeld == true) return
        wakeLock = (getSystemService(Context.POWER_SERVICE) as PowerManager)
            .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "$packageName:background_steps")
            .apply { acquire() }
    }

    private fun rollVietnamDateIfNeeded() {
        val today = vietnamDate()
        if (preferences().getString(KEY_STEP_DATE, null) == today) return
        store.clear()
        preferences().edit()
            .putString(KEY_STEP_DATE, today)
            .putInt(KEY_ACCEPTED_TOTAL, 0)
            .putLong(KEY_EXPIRES_AT_MS, 0L)
            .putBoolean(KEY_ATTESTED, false)
            .apply()
        updateNotification(0, "Đang ghi nhận bước")
    }

    private fun vietnamDate(): String =
        Instant.now().atOffset(ZoneOffset.ofHours(7)).toLocalDate().toString()

    private fun parseServerUtcMillis(value: String): Long =
        runCatching { Instant.parse(value).toEpochMilli() }
            .getOrElse {
                LocalDateTime.parse(value).toInstant(ZoneOffset.UTC).toEpochMilli()
            }

    private fun stopTracking(clearState: Boolean) {
        explicitStop = true
        preferences().edit().putBoolean(KEY_RUNNING, false).apply()
        collector.stop()
        if (clearState) {
            store.clear()
            tokenStore.clear()
        }
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
        stopSelf()
        MotionEventRelay.emit(
            mapOf(
                "eventType" to "tracking_status",
                "running" to false,
                "message" to "stopped",
            ),
        )
    }

    private fun loadConfig(): ServiceConfig? {
        val prefs = preferences()
        val sessionId = prefs.getString(KEY_SESSION_ID, null) ?: return null
        val nonce = prefs.getString(KEY_NONCE, null) ?: return null
        val apiBaseUrl = prefs.getString(KEY_API_BASE_URL, null) ?: return null
        return ServiceConfig(
            userId = prefs.getString(KEY_USER_ID, "").orEmpty(),
            stepDate = prefs.getString(KEY_STEP_DATE, "").orEmpty(),
            apiBaseUrl = apiBaseUrl,
            sensorMode = prefs.getString(KEY_SENSOR_MODE, "counter") ?: "counter",
            windowMilliseconds = prefs.getInt(KEY_WINDOW_MS, 1000),
            targetSampleHz = prefs.getInt(KEY_SAMPLE_HZ, 25),
            contractVersion = prefs.getInt(KEY_CONTRACT_VERSION, 2),
            sessionId = sessionId,
            nonce = nonce,
            expiresAtMs = prefs.getLong(KEY_EXPIRES_AT_MS, 0L),
            nextSequence = prefs.getInt(KEY_NEXT_SEQUENCE, 1),
            attested = prefs.getBoolean(KEY_ATTESTED, false),
            allowDevelopmentBypass = prefs.getBoolean(KEY_ALLOW_DEV_BYPASS, false),
            acceptedTotal = prefs.getInt(KEY_ACCEPTED_TOTAL, 0),
        )
    }

    private fun emitStatus(config: ServiceConfig, message: String) {
        MotionEventRelay.emit(
            mapOf(
                "eventType" to "tracking_status",
                "running" to preferences().getBoolean(KEY_RUNNING, false),
                "userId" to config.userId,
                "acceptedTotal" to config.acceptedTotal,
                "nextSequence" to config.nextSequence,
                "attested" to config.attested,
                "message" to message,
            ),
        )
    }

    private fun scheduleRetry() {
        nextAttemptAtMs = System.currentTimeMillis() + RETRY_DELAY_MS
        uploadInProgress.set(false)
    }

    private fun preferences() =
        getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    private fun JSONObject.putNullable(key: String, value: Any?): JSONObject =
        put(key, value ?: JSONObject.NULL)

    private fun JSONObject.nullableString(key: String): String =
        if (isNull(key)) "" else get(key).toString()

    private fun JSONObject.booleanInt(key: String): Int = if (getBoolean(key)) 1 else 0

    private fun JSONObject.forApi(): JSONObject = JSONObject(toString()).apply {
        remove("intervalStartedAtMs")
        remove("recordedAtMs")
        remove("windowStartedAtMs")
        remove("windowEndedAtMs")
    }

    private fun HttpResponse.dataObject(): JSONObject =
        json.optJSONObject("data")
            ?: json.optJSONObject("Data")
            ?: json

    data class ServiceConfig(
        val userId: String,
        val stepDate: String,
        val apiBaseUrl: String,
        val sensorMode: String,
        val windowMilliseconds: Int,
        val targetSampleHz: Int,
        val contractVersion: Int,
        val sessionId: String,
        val nonce: String,
        val expiresAtMs: Long,
        val nextSequence: Int,
        val attested: Boolean,
        val allowDevelopmentBypass: Boolean,
        val acceptedTotal: Int,
    )

    data class HttpResponse(
        val status: Int,
        val json: JSONObject,
        val retryAfterSeconds: Long,
    )

    companion object {
        const val ACTION_START = "com.example.walkamon_mobile.background_steps.START"
        const val ACTION_STOP = "com.example.walkamon_mobile.background_steps.STOP"
        const val EXTRA_USER_ID = "userId"
        const val EXTRA_STEP_DATE = "stepDate"
        const val EXTRA_API_BASE_URL = "apiBaseUrl"
        const val EXTRA_ACCESS_TOKEN = "accessToken"
        const val EXTRA_SENSOR_MODE = "sensorMode"
        const val EXTRA_WINDOW_MS = "windowMilliseconds"
        const val EXTRA_SAMPLE_HZ = "targetSampleHz"
        const val EXTRA_CONTRACT_VERSION = "contractVersion"
        const val EXTRA_SESSION_ID = "sessionId"
        const val EXTRA_NONCE = "nonce"
        const val EXTRA_EXPIRES_AT_MS = "expiresAtMs"
        const val EXTRA_NEXT_SEQUENCE = "nextSequence"
        const val EXTRA_ATTESTED = "attested"
        const val EXTRA_ALLOW_DEV_BYPASS = "allowDevelopmentBypass"
        const val EXTRA_ACCEPTED_TOTAL = "acceptedTotal"

        private const val PREFS_NAME = "walkamon_background_steps"
        private const val KEY_RUNNING = "running"
        private const val KEY_USER_ID = "user_id"
        private const val KEY_STEP_DATE = "step_date"
        private const val KEY_API_BASE_URL = "api_base_url"
        private const val KEY_SENSOR_MODE = "sensor_mode"
        private const val KEY_WINDOW_MS = "window_ms"
        private const val KEY_SAMPLE_HZ = "sample_hz"
        private const val KEY_CONTRACT_VERSION = "contract_version"
        private const val KEY_SESSION_ID = "session_id"
        private const val KEY_NONCE = "nonce"
        private const val KEY_EXPIRES_AT_MS = "expires_at_ms"
        private const val KEY_NEXT_SEQUENCE = "next_sequence"
        private const val KEY_ATTESTED = "attested"
        private const val KEY_ALLOW_DEV_BYPASS = "allow_dev_bypass"
        private const val KEY_ACCEPTED_TOTAL = "accepted_total"
        private const val NOTIFICATION_CHANNEL = "walkamon_background_steps"
        private const val NOTIFICATION_ID = 42017
        private const val MAX_BATCH_EVENTS = 100
        private const val MAX_BATCH_MOTION_WINDOWS = 130
        private const val MIN_BATCH_AGE_MS = 30_000L
        private const val ATTESTATION_REFRESH_MS = 90_000L
        private const val MAX_LOCAL_AGE_MS = 120_000L
        private const val RETRY_DELAY_MS = 15_000L
        private const val AUTH_RETRY_DELAY_MS = 300_000L
        private const val TAG = "WalkamonBackgroundSteps"
        @Volatile
        private var serviceAlive = false

        fun start(context: Context, intent: Intent) {
            ContextCompat.startForegroundService(
                context,
                intent.setClass(context, BackgroundStepService::class.java)
                    .setAction(ACTION_START),
            )
        }

        fun stop(context: Context) {
            context.startService(
                Intent(context, BackgroundStepService::class.java).setAction(ACTION_STOP),
            )
        }

        fun status(context: Context): Map<String, Any?> {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            return mapOf(
                "running" to (serviceAlive && prefs.getBoolean(KEY_RUNNING, false)),
                "userId" to prefs.getString(KEY_USER_ID, ""),
                "acceptedTotal" to prefs.getInt(KEY_ACCEPTED_TOTAL, 0),
                "nextSequence" to prefs.getInt(KEY_NEXT_SEQUENCE, 1),
                "attested" to prefs.getBoolean(KEY_ATTESTED, false),
            )
        }
    }
}
