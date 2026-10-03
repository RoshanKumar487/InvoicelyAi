package com.example.data.api

import com.example.data.api.client.ApiClient
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Global configuration and runtime state for Backend REST API communication.
 */
object ApiConfig {
    /**
     * Default host URLs:
     * - Android Emulator: "http://10.0.2.2:8080/" (maps to host machine's localhost:8080)
     * - Physical Device: "http://<YOUR_LAN_IP>:8080/" (e.g. 192.168.1.100)
     * - Localhost: "http://127.0.0.1:8080/"
     */
    const val EMULATOR_BASE_URL = "http://10.0.2.2:8080/"
    const val LOCALHOST_BASE_URL = "http://127.0.0.1:8080/"

    private val _baseUrl = MutableStateFlow(EMULATOR_BASE_URL)
    val baseUrl: StateFlow<String> = _baseUrl.asStateFlow()

    private val _isBackendReachable = MutableStateFlow(false)
    val isBackendReachable: StateFlow<Boolean> = _isBackendReachable.asStateFlow()

    private val _lastSyncTimestamp = MutableStateFlow(0L)
    val lastSyncTimestamp: StateFlow<Long> = _lastSyncTimestamp.asStateFlow()

    private val _isSyncing = MutableStateFlow(false)
    val isSyncing: StateFlow<Boolean> = _isSyncing.asStateFlow()

    private val _lastErrorMessage = MutableStateFlow<String?>(null)
    val lastErrorMessage: StateFlow<String?> = _lastErrorMessage.asStateFlow()

    fun updateBaseUrl(newUrl: String) {
        val sanitized = if (newUrl.endsWith("/")) newUrl.trim() else "${newUrl.trim()}/"
        _baseUrl.value = sanitized
        // Reset client to re-initialize with new baseUrl
        ApiClient.resetClient()
    }

    fun setReachable(reachable: Boolean) {
        _isBackendReachable.value = reachable
    }

    fun setSyncing(syncing: Boolean) {
        _isSyncing.value = syncing
    }

    fun recordSyncSuccess() {
        _lastSyncTimestamp.value = System.currentTimeMillis()
        _isBackendReachable.value = true
        _lastErrorMessage.value = null
    }

    fun recordSyncError(error: String) {
        _lastErrorMessage.value = error
    }
}
