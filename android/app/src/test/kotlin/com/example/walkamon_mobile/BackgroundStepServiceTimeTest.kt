package com.example.walkamon_mobile

import org.junit.Assert.assertEquals
import org.junit.Test
import java.time.Instant

class BackgroundStepServiceTimeTest {
    @Test
    fun parsesServerTimestampWithVietnamOffset() {
        assertEquals(
            Instant.parse("2026-08-10T17:05:00Z").toEpochMilli(),
            parseServerUtcMillis("2026-08-11T00:05:00+07:00"),
        )
    }

    @Test
    fun preservesUtcAndLegacyLocalTimestampSupport() {
        val expected = Instant.parse("2026-08-10T17:05:00Z").toEpochMilli()

        assertEquals(expected, parseServerUtcMillis("2026-08-10T17:05:00Z"))
        assertEquals(expected, parseServerUtcMillis("2026-08-10T17:05:00"))
    }
}
