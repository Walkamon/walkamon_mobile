package com.example.walkamon_mobile

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import org.json.JSONArray
import org.json.JSONObject

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
    val json: JSONObject,
)

data class PendingStepBatch(
    val payloadHash: String,
    val body: JSONObject,
    val eventIds: List<Long>,
    val windowIds: List<Long>,
    val attestationToken: String?,
)

class BackgroundStepStore(context: Context) :
    SQLiteOpenHelper(context, DATABASE_NAME, null, DATABASE_VERSION) {

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
                attestation_token TEXT NULL
            )
            """.trimIndent(),
        )
        db.execSQL("CREATE INDEX ix_pending_step_events_recorded ON pending_step_events(recorded_at_ms)")
        db.execSQL("CREATE INDEX ix_pending_motion_windows_time ON pending_motion_windows(window_started_at_ms, window_ended_at_ms)")
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) = Unit

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
    fun windows(startMs: Long, endMs: Long): List<StoredMotionWindow> {
        val result = mutableListOf<StoredMotionWindow>()
        readableDatabase.query(
            "pending_motion_windows",
            arrayOf("id", "window_started_at_ms", "window_ended_at_ms", "payload_json"),
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
                    JSONObject(cursor.getString(3)),
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
                put("attestation_token", batch.attestationToken)
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
            "attestation_token",
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
            attestationToken = if (cursor.isNull(4)) null else cursor.getString(4),
        )
    }

    @Synchronized
    fun setPendingAttestation(token: String) {
        writableDatabase.update(
            "pending_step_batch",
            ContentValues().apply { put("attestation_token", token) },
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
    fun prune(cutoffMs: Long) {
        if (pendingBatch() != null) return
        writableDatabase.delete(
            "pending_step_events",
            "recorded_at_ms < ?",
            arrayOf(cutoffMs.toString()),
        )
        writableDatabase.delete(
            "pending_motion_windows",
            "window_ended_at_ms < ?",
            arrayOf(cutoffMs.toString()),
        )
    }

    @Synchronized
    fun clear() {
        writableDatabase.delete("pending_step_batch", null, null)
        writableDatabase.delete("pending_step_events", null, null)
        writableDatabase.delete("pending_motion_windows", null, null)
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

    companion object {
        private const val DATABASE_NAME = "background_steps.db"
        private const val DATABASE_VERSION = 1
    }
}
