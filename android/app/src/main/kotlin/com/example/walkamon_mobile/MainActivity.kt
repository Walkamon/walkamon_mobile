package com.example.walkamon_mobile

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var capabilityCollector: MotionSensorCollector
    private lateinit var integrityBridge: PlayIntegrityBridge

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        capabilityCollector = MotionSensorCollector(applicationContext)
        integrityBridge = PlayIntegrityBridge(applicationContext)

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL,
        ).setStreamHandler(MotionEventRelay)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CONTROL_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCapabilities" -> result.success(capabilityCollector.capabilities())
                "startCollector" -> {
                    val sessionId = call.argument<String>("sessionId")
                    val nonce = call.argument<String>("nonce")
                    val apiBaseUrl = call.argument<String>("apiBaseUrl")
                    val accessToken = call.argument<String>("accessToken")
                    if (sessionId.isNullOrBlank() ||
                        nonce.isNullOrBlank() ||
                        apiBaseUrl.isNullOrBlank() ||
                        accessToken.isNullOrBlank()
                    ) {
                        result.error(
                            "BACKGROUND_STEP_CONFIG_INVALID",
                            "sessionId, nonce, apiBaseUrl and accessToken are required.",
                            null,
                        )
                        return@setMethodCallHandler
                    }
                    BackgroundStepService.start(
                        applicationContext,
                        Intent().apply {
                            putExtra(
                                BackgroundStepService.EXTRA_USER_ID,
                                call.argument<String>("userId"),
                            )
                            putExtra(
                                BackgroundStepService.EXTRA_STEP_DATE,
                                call.argument<String>("stepDate"),
                            )
                            putExtra(BackgroundStepService.EXTRA_API_BASE_URL, apiBaseUrl)
                            putExtra(BackgroundStepService.EXTRA_ACCESS_TOKEN, accessToken)
                            putExtra(
                                BackgroundStepService.EXTRA_SENSOR_MODE,
                                call.argument<String>("sensorMode") ?: "counter",
                            )
                            putExtra(
                                BackgroundStepService.EXTRA_WINDOW_MS,
                                call.argument<Int>("windowMilliseconds") ?: 1000,
                            )
                            putExtra(
                                BackgroundStepService.EXTRA_SAMPLE_HZ,
                                call.argument<Int>("targetSampleHz") ?: 25,
                            )
                            putExtra(
                                BackgroundStepService.EXTRA_CONTRACT_VERSION,
                                call.argument<Int>("contractVersion") ?: 2,
                            )
                            putExtra(BackgroundStepService.EXTRA_SESSION_ID, sessionId)
                            putExtra(BackgroundStepService.EXTRA_NONCE, nonce)
                            putExtra(
                                BackgroundStepService.EXTRA_EXPIRES_AT_MS,
                                call.argument<Number>("expiresAtMs")?.toLong() ?: 0L,
                            )
                            putExtra(
                                BackgroundStepService.EXTRA_NEXT_SEQUENCE,
                                call.argument<Int>("nextSequence") ?: 1,
                            )
                            putExtra(
                                BackgroundStepService.EXTRA_ATTESTED,
                                call.argument<Boolean>("attested") ?: false,
                            )
                            putExtra(
                                BackgroundStepService.EXTRA_ALLOW_DEV_BYPASS,
                                call.argument<Boolean>("allowDevelopmentBypass") ?: false,
                            )
                            putExtra(
                                BackgroundStepService.EXTRA_DIAGNOSTIC_CONTINUOUS_WAKE_LOCK,
                                call.argument<Boolean>("diagnosticContinuousWakeLock") ?: false,
                            )
                            putExtra(
                                BackgroundStepService.EXTRA_ACCEPTED_TOTAL,
                                call.argument<Int>("acceptedTotal") ?: 0,
                            )
                        },
                    )
                    result.success(null)
                }
                "stopCollector" -> {
                    BackgroundStepService.stop(applicationContext)
                    result.success(null)
                }
                "getTrackingStatus" ->
                    result.success(BackgroundStepService.status(applicationContext))
                "prepareIntegrity" -> integrityBridge.prepare(result)
                "requestIntegrityToken" -> {
                    val requestHash = call.argument<String>("requestHash")
                    if (requestHash.isNullOrBlank()) {
                        result.error("INVALID_REQUEST_HASH", "requestHash is required.", null)
                    } else {
                        integrityBridge.requestToken(requestHash, result)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    companion object {
        private const val CONTROL_CHANNEL = "walkamon/validated_steps"
        private const val EVENT_CHANNEL = "walkamon/motion_events"
    }
}
