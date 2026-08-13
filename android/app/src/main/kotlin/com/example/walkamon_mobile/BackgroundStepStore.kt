package com.example.walkamon_mobile

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import android.os.SystemClock
import android.provider.Settings
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

data class StoredSensorEvent(
    val id: Long,
    val intervalStartedAtMs: Long,
    val recordedAtMs: Long,
    val json: JSONObject,
)

data class StoredMotionWindow(
    val id: Long,
    val windowStartedAtMs: Long,
    val windowEndedAtMs: Long,
    val bootSessionId: String?,
    val windowStartElapsedRealtimeNs: Long?,
    val windowEndElapsedRealtimeNs: Long?,
    val json: JSONObject,
)

data class StoredDetectorEvent(
    val id: Long,
    val bootSessionId: String,
    val sensorElapsedRealtimeNs: Long,
    val recordedAtMs: Long,
    val json: JSONObject,
)

data class StoredCounterSample(
    val id: Long,
    val observedAtMs: Long,
    val json: JSONObject,
)

data class PendingStepBatch(
    val payloadHash: String,
    val body: JSONObject,
    val eventIds: List<Long>,
    val windowIds: List<Long>,
    val detectorIds: List<Long> = emptyList(),
    val counterIds: List<Long> = emptyList(),
    val attestationToken: String?,
    val attestationRequestedAtMs: Long?,
)

class BackgroundStepStore(private val appContext: Context) :
    SQLiteOpenHelper(appContext, DATABASE_NAME, null, DATABASE_VERSION) {

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL(
            """
            CREATE TABLE pending_step_events (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                interval_started_at_ms INTEGER NOT NULL,
                recorded_at_ms INTEGER NOT NULL,
                payload_json TEXT NOT NULL
            )
            """.trimIndent(),
        )
        db.execSQL(
            """
            CREATE TABLE pending_motion_windows (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                window_started_at_ms INTEGER NOT NULL,
                window_ended_at_ms INTEGER NOT NULL,
                boot_session_id TEXT NULL,
                window_start_elapsed_ns INTEGER NULL,
                window_end_elapsed_ns INTEGER NULL,
                payload_json TEXT NOT NULL
            )
            """.trimIndent(),
        )
        db.execSQL(
            """
            CREATE TABLE pending_step_batch (
                singleton_id INTEGER PRIMARY KEY CHECK (singleton_id = 1),
                payload_hash TEXT NOT NULL,
                body_json TEXT NOT NULL,
                event_ids_json TEXT NOT NULL,
                window_ids_json TEXT NOT NULL,
                detector_ids_json TEXT NULL,
                counter_ids_json TEXT NULL,
                attestation_token TEXT NULL,
                attestation_requested_at_ms INTEGER NULL
            )
            """.trimIndent(),
        )
        db.execSQL("CREATE INDEX ix_pending_step_events_recorded ON pending_step_events(recorded_at_ms)")
        db.execSQL("CREATE INDEX ix_pending_motion_windows_time ON pending_motion_windows(window_started_at_ms, window_ended_at_ms)")
        db.execSQL(
            "CREATE INDEX ix_pending_motion_windows_boot_elapsed " +
                "ON pending_motion_windows(boot_session_id, window_start_elapsed_ns, window_end_elapsed_ns)",
        )
        createV3Tables(db)
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        if (oldVersion < 2) {
            db.execSQL(
                "ALTER TABLE pending_step_batch ADD COLUMN attestation_requested_at_ms INTEGER NULL",
            )
        }
        if (oldVersion < 3) {
            db.execSQL("ALTER TABLE pending_step_batch ADD COLUMN detector_ids_json TEXT NULL")
            db.execSQL("ALTER TABLE pending_step_batch ADD COLUMN counter_ids_json TEXT NULL")
            createV3Tables(db)
        }
        if (oldVersion < 4) {
            db.execSQL("ALTER TABLE pending_motion_windows ADD COLUMN boot_session_id TEXT NULL")
            db.execSQL("ALTER TABLE pending_motion_windows ADD COLUMN window_start_elapsed_ns INTEGER NULL")
            db.execSQL("ALTER TABLE pending_motion_windows ADD COLUMN window_end_elapsed_ns INTEGER NULL")
            db.execSQL(
                "CREATE INDEX IF NOT EXISTS ix_pending_motion_windows_boot_elapsed " +
                    "ON pending_motion_windows(boot_session_id, window_start_elapsed_ns, window_end_elapsed_ns)",
            )
            // The immutable envelope contains the pre-patch v3 hash. Keep raw
            // detector/counter evidence and let the service build a fresh batch.
            db.delete("pending_step_batch", "singleton_id = 1", null)
        }
    }

    private fun createV3Tables(db: SQLiteDatabase) {
        db.execSQL(
            """
            CREATE TABLE IF NOT EXISTS pending_detector_events (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                client_event_id TEXT NOT NULL UNIQUE,
                boot_session_id TEXT NOT NULL,
                sensor_elapsed_ns INTEGER NOT NULL,
                recorded_at_ms INTEGER NOT NULL,
                state TEXT NOT NULL DEFAULT 'local_pending',
                payload_json TEXT NOT NULL
            )
            """.trimIndent(),
        )
        db.execSQL(
            """
            CREATE TABLE IF NOT EXISTS pending_counter_samples (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                client_sample_id TEXT NOT NULL UNIQUE,
                boot_session_id TEXT NOT NULL,
                sensor_elapsed_ns INTEGER NOT NULL,
                observed_at_ms INTEGER NOT NULL,
                payload_json TEXT NOT NULL
            )
            """.trimIndent(),
        )
        db.execSQL(
            """
            CREATE TABLE IF NOT EXISTS capture_boot_state (
                singleton_id INTEGER PRIMARY KEY CHECK (singleton_id = 1),
                boot_session_id TEXT NOT NULL,
                observed_boot_count INTEGER NOT NULL,
                last_elapsed_ns INTEGER NOT NULL,
                counter_baseline_total INTEGER NULL,
                last_counter_total INTEGER NULL
            )
            """.trimIndent(),
        )
        db.execSQL(
            "CREATE INDEX IF NOT EXISTS ix_pending_detector_state_time " +
                "ON pending_detector_events(state, recorded_at_ms)",
        )
        db.execSQL(
            "CREATE INDEX IF NOT EXISTS ix_pending_counter_time " +
                "ON pending_counter_samples(observed_at_ms)",
        )
    }

    @Synchronized
    fun currentBootSessionId(): String {
        val bootCount = runCatching {
            Settings.Global.getInt(appContext.contentResolver, Settings.Global.BOOT_COUNT)
        }.getOrDefault(-1)
        val elapsedNs = SystemClock.elapsedRealtimeNanos()
        var existingId: String? = null
        var existingBootCount = Int.MIN_VALUE
        var lastElapsedNs = Long.MAX_VALUE
        readableDatabase.query(
            "capture_boot_state",
            arrayOf("boot_session_id", "observed_boot_count", "last_elapsed_ns"),
            "singleton_id = 1",
            null,
            null,
            null,
            null,
        ).use { cursor ->
            if (cursor.moveToFirst()) {
                existingId = cursor.getString(0)
                existingBootCount = cursor.getInt(1)
                lastElapsedNs = cursor.getLong(2)
            }
        }
        val rebooted = existingId == null ||
            (bootCount >= 0 && existingBootCount != bootCount) ||
            elapsedNs < lastElapsedNs
        val bootSessionId = if (rebooted) UUID.randomUUID().toString() else existingId!!
        writableDatabase.insertWithOnConflict(
            "capture_boot_state",
            null,
            ContentValues().apply {
                put("singleton_id", 1)
                put("boot_session_id", bootSessionId)
                put("observed_boot_count", bootCount)
                put("last_elapsed_ns", elapsedNs)
                if (rebooted) {
                    putNull("counter_baseline_total")
                    putNull("last_counter_total")
                }
            },
            SQLiteDatabase.CONFLICT_REPLACE,
        )
        return bootSessionId
    }

    @Synchronized
    fun resetCaptureBaseline() {
        writableDatabase.update(
            "capture_boot_state",
            ContentValues().apply {
                putNull("counter_baseline_total")
                putNull("last_counter_total")
            },
            "singleton_id = 1",
            null,
        )
    }

    @Synchronized
    fun addDetectorEvent(payload: JSONObject) {
        writableDatabase.insertOrThrow(
            "pending_detector_events",
            null,
            ContentValues().apply {
                put("client_event_id", payload.getString("clientEventId"))
                put("boot_session_id", payload.getString("bootSessionId"))
                put("sensor_elapsed_ns", payload.getLong("sensorElapsedRealtimeNs"))
                put("recorded_at_ms", payload.getLong("recordedAtMs"))
                put("state", "local_pending")
                put("payload_json", payload.toString())
            },
        )
    }

    @Synchronized
    fun addCounterSample(payload: JSONObject): Boolean {
        val total = payload.getLong("counterTotal")
        val state = readableDatabase.query(
            "capture_boot_state",
            arrayOf("counter_baseline_total", "last_counter_total"),
            "singleton_id = 1",
            null,
            null,
            null,
            null,
        ).use { cursor ->
            if (!cursor.moveToFirst()) null to null else {
                val baseline = if (cursor.isNull(0)) null else cursor.getLong(0)
                val last = if (cursor.isNull(1)) null else cursor.getLong(1)
                baseline to last
            }
        }
        val establishesBaseline = state.first == null ||
            (state.second != null && total < state.second!!)
        writableDatabase.beginTransaction()
        try {
            writableDatabase.insertOrThrow(
                "pending_counter_samples",
                null,
                ContentValues().apply {
                    put("client_sample_id", payload.getString("clientSampleId"))
                    put("boot_session_id", payload.getString("bootSessionId"))
                    put("sensor_elapsed_ns", payload.getLong("sensorElapsedRealtimeNs"))
                    put("observed_at_ms", payload.getLong("observedAtMs"))
                    put("payload_json", payload.toString())
                },
            )
            writableDatabase.update(
                "capture_boot_state",
                ContentValues().apply {
                    if (establishesBaseline) put("counter_baseline_total", total)
                    put("last_counter_total", total)
                    put("last_elapsed_ns", payload.getLong("sensorElapsedRealtimeNs"))
                },
                "singleton_id = 1",
                null,
            )
            writableDatabase.setTransactionSuccessful()
        } finally {
            writableDatabase.endTransaction()
        }
        return establishesBaseline
    }

    @Synchronized
    fun addSensorEvent(payload: JSONObject) {
        writableDatabase.insertOrThrow(
            "pending_step_events",
            null,
            ContentValues().apply {
                put("interval_started_at_ms", payload.getLong("intervalStartedAtMs"))
                put("recorded_at_ms", payload.getLong("recordedAtMs"))
                put("payload_json", payload.toString())
            },
        )
    }

    @Synchronized
    fun addMotionWindow(payload: JSONObject) {
        writableDatabase.insertOrThrow(
            "pending_motion_windows",
            null,
            ContentValues().apply {
                put("window_started_at_ms", payload.getLong("windowStartedAtMs"))
                put("window_ended_at_ms", payload.getLong("windowEndedAtMs"))
                put("boot_session_id", payload.optString("bootSessionId").takeIf(String::isNotBlank))
                payload.optLongOrNull("windowStartElapsedRealtimeNs")?.let {
                    put("window_start_elapsed_ns", it)
                }
                payload.optLongOrNull("windowEndElapsedRealtimeNs")?.let {
                    put("window_end_elapsed_ns", it)
                }
                put("payload_json", payload.toString())
            },
        )
    }

    @Synchronized
    fun events(limit: Int): List<StoredSensorEvent> {
        val result = mutableListOf<StoredSensorEvent>()
        readableDatabase.query(
            "pending_step_events",
            arrayOf("id", "interval_started_at_ms", "recorded_at_ms", "payload_json"),
            null,
            null,
            null,
            null,
            "id ASC",
            limit.toString(),
        ).use { cursor ->
            while (cursor.moveToNext()) {
                result += StoredSensorEvent(
                    cursor.getLong(0),
                    cursor.getLong(1),
                    cursor.getLong(2),
                    JSONObject(cursor.getString(3)),
                )
            }
        }
        return result
    }

    @Synchronized
    fun detectorEvents(limit: Int): List<StoredDetectorEvent> {
        return detectorEventsByState("local_pending", limit, "id ASC")
    }

    @Synchronized
    fun serverPendingDetectorEvents(limit: Int): List<StoredDetectorEvent> {
        return detectorEventsByState("server_pending_reconciliation", limit, "id DESC")
            .sortedBy(StoredDetectorEvent::id)
    }

    private fun detectorEventsByState(
        state: String,
        limit: Int,
        orderBy: String,
    ): List<StoredDetectorEvent> {
        val result = mutableListOf<StoredDetectorEvent>()
        readableDatabase.query(
            "pending_detector_events",
            arrayOf("id", "boot_session_id", "sensor_elapsed_ns", "recorded_at_ms", "payload_json"),
            "state = ?",
            arrayOf(state),
            null,
            null,
            orderBy,
            limit.toString(),
        ).use { cursor ->
            while (cursor.moveToNext()) {
                result += StoredDetectorEvent(
                    cursor.getLong(0),
                    cursor.getString(1),
                    cursor.getLong(2),
                    cursor.getLong(3),
                    JSONObject(cursor.getString(4)),
                )
            }
        }
        return result
    }

    @Synchronized
    fun counterSamples(limit: Int): List<StoredCounterSample> {
        val result = mutableListOf<StoredCounterSample>()
        readableDatabase.query(
            "pending_counter_samples",
            arrayOf("id", "observed_at_ms", "payload_json"),
            null,
            null,
            null,
            null,
            "id ASC",
            limit.toString(),
        ).use { cursor ->
            while (cursor.moveToNext()) {
                result += StoredCounterSample(
                    cursor.getLong(0),
                    cursor.getLong(1),
                    JSONObject(cursor.getString(2)),
                )
            }
        }
        return result
    }

    @Synchronized
    fun hasServerPendingDetectorEvents(): Boolean = readableDatabase.rawQuery(
        "SELECT 1 FROM pending_detector_events WHERE state = 'server_pending_reconciliation' LIMIT 1",
        null,
    ).use { it.moveToFirst() }

    @Synchronized
    fun latestWindowEnd(): Long? = readableDatabase.rawQuery(
        "SELECT MAX(window_ended_at_ms) FROM pending_motion_windows",
        null,
    ).use { cursor ->
        if (cursor.moveToFirst() && !cursor.isNull(0)) cursor.getLong(0) else null
    }

    @Synchronized
    fun pendingCounts(): Pair<Int, Int> {
        fun count(table: String): Int = readableDatabase.rawQuery(
            "SELECT COUNT(*) FROM $table",
            null,
        ).use { cursor -> if (cursor.moveToFirst()) cursor.getInt(0) else 0 }
        return count("pending_step_events") to count("pending_motion_windows")
    }

    @Synchronized
    fun v3PendingCounts(): Triple<Int, Int, Int> {
        fun count(table: String, where: String? = null): Int = readableDatabase.rawQuery(
            "SELECT COUNT(*) FROM $table${where?.let { " WHERE $it" }.orEmpty()}",
            null,
        ).use { cursor -> if (cursor.moveToFirst()) cursor.getInt(0) else 0 }
        return Triple(
            count("pending_detector_events", "state = 'local_pending'"),
            count("pending_detector_events", "state = 'server_pending_reconciliation'"),
            count("pending_counter_samples"),
        )
    }

    @Synchronized
    fun pendingStepTotal(): Int {
        var total = 0L
        readableDatabase.query(
            "pending_step_events",
            arrayOf("payload_json"),
            null,
            null,
            null,
            null,
            "id ASC",
        ).use { cursor ->
            while (cursor.moveToNext()) {
                total += runCatching {
                    JSONObject(cursor.getString(0)).optLong("stepCount", 0L)
                }.getOrDefault(0L).coerceAtLeast(0L)
                if (total >= Int.MAX_VALUE) return@use
            }
        }
        val v3Pending = readableDatabase.rawQuery(
            "SELECT COUNT(*) FROM pending_detector_events " +
                "WHERE state IN ('local_pending', 'server_pending_reconciliation')",
            null,
        ).use { cursor -> if (cursor.moveToFirst()) cursor.getLong(0) else 0L }
        return (total + v3Pending).coerceAtMost(Int.MAX_VALUE.toLong()).toInt()
    }

    @Synchronized
    fun windows(startMs: Long, endMs: Long): List<StoredMotionWindow> {
        val result = mutableListOf<StoredMotionWindow>()
        readableDatabase.query(
            "pending_motion_windows",
            arrayOf(
                "id",
                "window_started_at_ms",
                "window_ended_at_ms",
                "boot_session_id",
                "window_start_elapsed_ns",
                "window_end_elapsed_ns",
                "payload_json",
            ),
            "window_ended_at_ms > ? AND window_started_at_ms <= ?",
            arrayOf(startMs.toString(), endMs.toString()),
            null,
            null,
            "id ASC",
        ).use { cursor ->
            while (cursor.moveToNext()) {
                result += StoredMotionWindow(
                    cursor.getLong(0),
                    cursor.getLong(1),
                    cursor.getLong(2),
                    if (cursor.isNull(3)) null else cursor.getString(3),
                    if (cursor.isNull(4)) null else cursor.getLong(4),
                    if (cursor.isNull(5)) null else cursor.getLong(5),
                    JSONObject(cursor.getString(6)),
                )
            }
        }
        return result
    }

    @Synchronized
    fun v3Windows(
        bootSessionId: String,
        startElapsedNs: Long,
        endElapsedNs: Long,
    ): List<StoredMotionWindow> {
        val result = mutableListOf<StoredMotionWindow>()
        readableDatabase.query(
            "pending_motion_windows",
            arrayOf(
                "id",
                "window_started_at_ms",
                "window_ended_at_ms",
                "boot_session_id",
                "window_start_elapsed_ns",
                "window_end_elapsed_ns",
                "payload_json",
            ),
            "boot_session_id = ? AND window_end_elapsed_ns > ? AND window_start_elapsed_ns <= ?",
            arrayOf(bootSessionId, startElapsedNs.toString(), endElapsedNs.toString()),
            null,
            null,
            "window_start_elapsed_ns ASC, id ASC",
        ).use { cursor ->
            while (cursor.moveToNext()) {
                result += StoredMotionWindow(
                    cursor.getLong(0),
                    cursor.getLong(1),
                    cursor.getLong(2),
                    cursor.getString(3),
                    cursor.getLong(4),
                    cursor.getLong(5),
                    JSONObject(cursor.getString(6)),
                )
            }
        }
        return result
    }

    @Synchronized
    fun savePendingBatch(batch: PendingStepBatch) {
        writableDatabase.insertWithOnConflict(
            "pending_step_batch",
            null,
            ContentValues().apply {
                put("singleton_id", 1)
                put("payload_hash", batch.payloadHash)
                put("body_json", batch.body.toString())
                put("event_ids_json", JSONArray(batch.eventIds).toString())
                put("window_ids_json", JSONArray(batch.windowIds).toString())
                put("detector_ids_json", JSONArray(batch.detectorIds).toString())
                put("counter_ids_json", JSONArray(batch.counterIds).toString())
                put("attestation_token", batch.attestationToken)
                put("attestation_requested_at_ms", batch.attestationRequestedAtMs)
            },
            SQLiteDatabase.CONFLICT_REPLACE,
        )
    }

    @Synchronized
    fun pendingBatch(): PendingStepBatch? = readableDatabase.query(
        "pending_step_batch",
        arrayOf(
            "payload_hash",
            "body_json",
            "event_ids_json",
            "window_ids_json",
            "detector_ids_json",
            "counter_ids_json",
            "attestation_token",
            "attestation_requested_at_ms",
        ),
        "singleton_id = 1",
        null,
        null,
        null,
        null,
    ).use { cursor ->
        if (!cursor.moveToFirst()) return@use null
        PendingStepBatch(
            payloadHash = cursor.getString(0),
            body = JSONObject(cursor.getString(1)),
            eventIds = JSONArray(cursor.getString(2)).toLongList(),
            windowIds = JSONArray(cursor.getString(3)).toLongList(),
            detectorIds = if (cursor.isNull(4)) emptyList() else JSONArray(cursor.getString(4)).toLongList(),
            counterIds = if (cursor.isNull(5)) emptyList() else JSONArray(cursor.getString(5)).toLongList(),
            attestationToken = if (cursor.isNull(6)) null else cursor.getString(6),
            attestationRequestedAtMs = if (cursor.isNull(7)) null else cursor.getLong(7),
        )
    }

    @Synchronized
    fun setPendingAttestation(token: String, requestedAtMs: Long) {
        writableDatabase.update(
            "pending_step_batch",
            ContentValues().apply {
                put("attestation_token", token)
                put("attestation_requested_at_ms", requestedAtMs)
            },
            "singleton_id = 1",
            null,
        )
    }

    @Synchronized
    fun clearPendingAttestation() {
        writableDatabase.update(
            "pending_step_batch",
            ContentValues().apply {
                putNull("attestation_token")
                putNull("attestation_requested_at_ms")
            },
            "singleton_id = 1",
            null,
        )
    }

    @Synchronized
    fun discardPendingBatch() {
        writableDatabase.delete("pending_step_batch", "singleton_id = 1", null)
    }

    @Synchronized
    fun completeBatch(batch: PendingStepBatch) {
        writableDatabase.beginTransaction()
        try {
            deleteIds(writableDatabase, "pending_step_events", batch.eventIds)
            deleteIds(writableDatabase, "pending_motion_windows", batch.windowIds)
            writableDatabase.delete("pending_step_batch", "singleton_id = 1", null)
            writableDatabase.setTransactionSuccessful()
        } finally {
            writableDatabase.endTransaction()
        }
    }

    @Synchronized
    fun completeV3Batch(batch: PendingStepBatch, resolutions: JSONArray) {
        writableDatabase.beginTransaction()
        try {
            val resolvedClientIds = mutableSetOf<String>()
            for (index in 0 until resolutions.length()) {
                val resolution = resolutions.getJSONObject(index)
                val clientEventId = resolution.getString("clientEventId")
                val status = resolution.optString("status", "pending")
                resolvedClientIds += clientEventId
                if (status == "pending") {
                    writableDatabase.update(
                        "pending_detector_events",
                        ContentValues().apply {
                            put("state", "server_pending_reconciliation")
                        },
                        "client_event_id = ?",
                        arrayOf(clientEventId),
                    )
                } else {
                    writableDatabase.delete(
                        "pending_detector_events",
                        "client_event_id = ?",
                        arrayOf(clientEventId),
                    )
                }
            }
            if (batch.detectorIds.isNotEmpty()) {
                val placeholders = batch.detectorIds.joinToString(",") { "?" }
                val unresolvedIds = mutableListOf<Long>()
                writableDatabase.query(
                    "pending_detector_events",
                    arrayOf("id", "client_event_id"),
                    "id IN ($placeholders)",
                    batch.detectorIds.map(Long::toString).toTypedArray(),
                    null,
                    null,
                    null,
                ).use { cursor ->
                    while (cursor.moveToNext()) {
                        if (cursor.getString(1) !in resolvedClientIds) {
                            unresolvedIds += cursor.getLong(0)
                        }
                    }
                }
                unresolvedIds.forEach { id ->
                    writableDatabase.update(
                        "pending_detector_events",
                        ContentValues().apply {
                            put("state", "server_pending_reconciliation")
                        },
                        "id = ?",
                        arrayOf(id.toString()),
                    )
                }
            }
            deleteIds(writableDatabase, "pending_counter_samples", batch.counterIds)
            deleteIds(writableDatabase, "pending_motion_windows", batch.windowIds)
            writableDatabase.delete("pending_step_batch", "singleton_id = 1", null)
            writableDatabase.setTransactionSuccessful()
        } finally {
            writableDatabase.endTransaction()
        }
    }

    @Synchronized
    fun prune(evidenceCutoffMs: Long, motionCutoffMs: Long): Int {
        if (pendingBatch() != null) return 0
        writableDatabase.delete(
            "pending_step_events",
            "recorded_at_ms < ?",
            arrayOf(evidenceCutoffMs.toString()),
        )
        writableDatabase.delete(
            "pending_motion_windows",
            "window_ended_at_ms < ?",
            arrayOf(motionCutoffMs.toString()),
        )
        val expiredDetectorCount = writableDatabase.update(
            "pending_detector_events",
            ContentValues().apply { put("state", "expired_unverified") },
            "state = 'local_pending' AND recorded_at_ms < ?",
            arrayOf(evidenceCutoffMs.toString()),
        )
        writableDatabase.delete(
            "pending_counter_samples",
            "observed_at_ms < ?",
            arrayOf(evidenceCutoffMs.toString()),
        )
        return expiredDetectorCount
    }

    @Synchronized
    fun clear() {
        writableDatabase.delete("pending_step_batch", null, null)
        writableDatabase.delete("pending_step_events", null, null)
        writableDatabase.delete("pending_motion_windows", null, null)
        writableDatabase.delete("pending_detector_events", null, null)
        writableDatabase.delete("pending_counter_samples", null, null)
        resetCaptureBaseline()
    }

    private fun deleteIds(db: SQLiteDatabase, table: String, ids: List<Long>) {
        if (ids.isEmpty()) return
        db.delete(
            table,
            "id IN (${ids.joinToString(",") { "?" }})",
            ids.map(Long::toString).toTypedArray(),
        )
    }

    private fun JSONArray.toLongList(): List<Long> =
        (0 until length()).map { getLong(it) }

    private fun JSONObject.optLongOrNull(name: String): Long? =
        if (has(name) && !isNull(name)) optLong(name) else null

    companion object {
        private const val DATABASE_NAME = "background_steps.db"
        private const val DATABASE_VERSION = 4
    }
}
