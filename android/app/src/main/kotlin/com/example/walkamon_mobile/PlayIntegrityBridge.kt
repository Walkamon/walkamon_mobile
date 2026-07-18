package com.example.walkamon_mobile

import android.content.Context
import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.StandardIntegrityManager
import io.flutter.plugin.common.MethodChannel

class PlayIntegrityBridge(context: Context) {
    private val integrityManager = IntegrityManagerFactory.createStandard(context)
    private var tokenProvider: StandardIntegrityManager.StandardIntegrityTokenProvider? = null

    fun prepare(result: MethodChannel.Result) {
        prepare(
            onSuccess = { result.success(null) },
            onError = { code, message -> result.error(code, message, null) },
        )
    }

    fun prepare(
        onSuccess: () -> Unit,
        onError: (String, String?) -> Unit,
    ) {
        if (tokenProvider != null) {
            onSuccess()
            return
        }
        if (BuildConfig.PLAY_INTEGRITY_CLOUD_PROJECT_NUMBER <= 0L) {
            onError(
                "PLAY_INTEGRITY_NOT_CONFIGURED",
                "Set PLAY_INTEGRITY_CLOUD_PROJECT_NUMBER or play.integrity.cloudProjectNumber.",
            )
            return
        }
        val request = StandardIntegrityManager.PrepareIntegrityTokenRequest
            .builder()
            .setCloudProjectNumber(BuildConfig.PLAY_INTEGRITY_CLOUD_PROJECT_NUMBER)
            .build()
        integrityManager.prepareIntegrityToken(request)
            .addOnSuccessListener { provider ->
                tokenProvider = provider
                onSuccess()
            }
            .addOnFailureListener { error ->
                onError("PLAY_INTEGRITY_PREPARE_FAILED", error.message)
            }
    }

    fun requestToken(requestHash: String, result: MethodChannel.Result) {
        requestToken(
            requestHash = requestHash,
            onSuccess = result::success,
            onError = { code, message -> result.error(code, message, null) },
        )
    }

    fun requestToken(
        requestHash: String,
        onSuccess: (String) -> Unit,
        onError: (String, String?) -> Unit,
    ) {
        val provider = tokenProvider
        if (provider == null) {
            onError(
                "PLAY_INTEGRITY_NOT_PREPARED",
                "Call prepareIntegrity before requesting a token.",
            )
            return
        }
        val request = StandardIntegrityManager.StandardIntegrityTokenRequest
            .builder()
            .setRequestHash(requestHash)
            .build()
        provider.request(request)
            .addOnSuccessListener { token -> onSuccess(token.token()) }
            .addOnFailureListener { error ->
                tokenProvider = null
                onError("PLAY_INTEGRITY_REQUEST_FAILED", error.message)
            }
    }
}
