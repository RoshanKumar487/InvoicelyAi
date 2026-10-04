package com.example.data.api

import android.util.Log
import com.example.data.api.client.ApiClient
import com.example.data.api.model.ApiResponse
import com.example.data.api.model.AuthResponseDto
import com.example.data.api.model.BackendBusinessProfileDto
import com.example.data.api.model.BackendClientDto
import com.example.data.api.model.BackendExpenseDto
import com.example.data.api.model.BackendInvoiceDto
import com.example.data.api.model.CompanyJoinRequestDto
import com.example.data.api.model.CompanySummaryDto
import com.example.data.api.model.DashboardStatsResponse
import com.example.data.api.model.JoinRequestActionRequest
import com.example.data.api.model.LoginRequest
import com.example.data.api.model.RegisterCompanyRequest
import com.example.data.api.model.RegisterDeveloperRequest
import com.example.data.api.model.RegisterEmployeeRequest
import com.example.data.api.model.UserSummaryDto
import com.example.data.api.model.toBackendDto
import com.example.data.model.BusinessProfile
import com.example.data.model.ClientEntity
import com.example.data.model.ExpenseEntity
import com.example.data.model.InvoiceEntity
import com.example.data.repository.BusinessRepository
import com.example.data.repository.ClientRepository
import com.example.data.repository.ExpenseRepository
import com.example.data.repository.InvoiceRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.withContext
import retrofit2.Response

/**
 * Centralized API Manager:
 * Handles all backend REST API invocations, error handling, network state updates,
 * and bi-directional offline-first data synchronization.
 */
object InvoicelyApiManager {

    private const val TAG = "InvoicelyApiManager"

    // =========================================================================
    // SAFE API EXECUTION WRAPPER
    // =========================================================================

    private fun parseErrorBody(code: Int, errorBodyStr: String?, fallback: String?): String {
        if (!errorBodyStr.isNullOrBlank()) {
            try {
                val json = org.json.JSONObject(errorBodyStr)
                val msg = json.optString("message", "")
                if (msg.isNotBlank()) {
                    if (msg.contains("Full authentication is required", ignoreCase = true) ||
                        msg.contains("Unauthorized", ignoreCase = true)) {
                        return "Authentication required. Please sign in to access cloud features."
                    }
                    return msg
                }
            } catch (_: Exception) {}
        }
        return when (code) {
            401 -> "Authentication required. Please sign in to access cloud features."
            403 -> "Access denied: You do not have permission for this resource."
            404 -> "Requested cloud resource not found."
            500, 502, 503 -> "Cloud server temporarily busy. Please retry shortly."
            else -> fallback?.ifBlank { null } ?: "Request failed (HTTP $code)"
        }
    }

    private suspend fun <T> safeApiCall(
        callName: String,
        apiCall: suspend () -> Response<ApiResponse<T>>
    ): Result<T> = withContext(Dispatchers.IO) {
        try {
            val response = apiCall()
            if (response.isSuccessful) {
                val body = response.body()
                if (body != null && body.success && body.data != null) {
                    ApiConfig.setReachable(true)
                    Result.success(body.data)
                } else if (body != null && body.data != null) {
                    ApiConfig.setReachable(true)
                    Result.success(body.data)
                } else if (response.code() in 200..204) {
                    ApiConfig.setReachable(true)
                    @Suppress("UNCHECKED_CAST")
                    Result.success(Unit as T)
                } else {
                    val errorMsg = body?.message ?: "Unknown server response (${response.code()})"
                    ApiConfig.recordSyncError(errorMsg)
                    Result.failure(Exception(errorMsg))
                }
            } else {
                val errorBodyStr = response.errorBody()?.string()
                val cleanMsg = parseErrorBody(response.code(), errorBodyStr, response.message())
                Log.w(TAG, "[$callName] Failed HTTP ${response.code()}: $cleanMsg")

                if (response.code() == 401) {
                    com.example.data.repository.AuthSessionManager.notifySessionExpired()
                    if (com.example.data.repository.AuthSessionManager.isLoggedIn.value) {
                        ApiConfig.recordSyncError(cleanMsg)
                    }
                } else {
                    ApiConfig.recordSyncError(cleanMsg)
                }
                Result.failure(Exception(cleanMsg))
            }
        } catch (e: Exception) {
            Log.e(TAG, "[$callName] Network Exception: ${e.message}", e)
            ApiConfig.setReachable(false)
            val netMsg = e.localizedMessage ?: "Network connection failed"
            ApiConfig.recordSyncError(netMsg)
            Result.failure(e)
        }
    }

    // =========================================================================
    // HEALTH CHECK & CONNECTIVITY
    // =========================================================================

    suspend fun checkHealth(): Result<Boolean> = withContext(Dispatchers.IO) {
        try {
            val response = ApiClient.getService().checkHealth()
            if (response.isSuccessful && (response.body()?.success == true || response.code() in 200..204)) {
                ApiConfig.setReachable(true)
                Result.success(true)
            } else {
                ApiConfig.setReachable(false)
                Result.failure(Exception("Cloud backend service is waking up or temporarily unavailable"))
            }
        } catch (e: Exception) {
            Log.w(TAG, "Health check failed: ${e.message}")
            ApiConfig.setReachable(false)
            Result.failure(e)
        }
    }

    suspend fun checkConnection(): Result<Boolean> {
        val healthResult = checkHealth()
        if (healthResult.isSuccess) {
            return Result.success(true)
        }
        // If user is authenticated with a token, optionally verify with getMe()
        if (com.example.data.repository.AuthSessionManager.isLoggedIn.value && !ApiClient.getAuthToken().isNullOrBlank()) {
            val meResult = getMe()
            if (meResult.isSuccess) {
                ApiConfig.setReachable(true)
                return Result.success(true)
            }
        }
        return healthResult
    }

    // =========================================================================
    // AUTHENTICATION APIS
    // =========================================================================

    suspend fun login(identifier: String, password: String): Result<AuthResponseDto> {
        val result = safeApiCall("login") {
            ApiClient.getService().login(LoginRequest(identifier.trim(), password))
        }
        result.onSuccess { auth ->
            auth.token?.let { ApiClient.setAuthToken(it) }
        }
        return result
    }

    suspend fun resetPassword(identifier: String, newPassword: String): Result<AuthResponseDto> {
        val result = safeApiCall("resetPassword") {
            ApiClient.getService().resetPassword(
                com.example.data.api.model.ResetPasswordRequest(
                    identifier = identifier.trim(),
                    newPassword = newPassword.trim()
                )
            )
        }
        result.onSuccess { auth ->
            auth.token?.let { ApiClient.setAuthToken(it) }
        }
        return result
    }

    suspend fun registerCompany(request: RegisterCompanyRequest): Result<AuthResponseDto> {
        val result = safeApiCall("registerCompany") {
            ApiClient.getService().registerCompany(request)
        }
        result.onSuccess { auth ->
            auth.token?.let { ApiClient.setAuthToken(it) }
        }
        return result
    }

    suspend fun registerEmployee(request: RegisterEmployeeRequest): Result<AuthResponseDto> {
        return safeApiCall("registerEmployee") {
            ApiClient.getService().registerEmployee(request)
        }
    }

    suspend fun registerDeveloper(request: RegisterDeveloperRequest): Result<AuthResponseDto> {
        val result = safeApiCall("registerDeveloper") {
            ApiClient.getService().registerDeveloper(request)
        }
        result.onSuccess { auth ->
            auth.token?.let { ApiClient.setAuthToken(it) }
        }
        return result
    }

    suspend fun getMe(): Result<AuthResponseDto> {
        return safeApiCall("getMe") {
            ApiClient.getService().getMe()
        }
    }

    // =========================================================================
    // DASHBOARD APIS
    // =========================================================================

    suspend fun getDashboardStats(companyId: Long? = null): Result<DashboardStatsResponse> {
        return safeApiCall("getDashboardStats") {
            ApiClient.getService().getDashboardStats(companyId)
        }
    }

    suspend fun getDeveloperOverview(): Result<com.example.data.api.model.DeveloperOverviewDto> {
        return safeApiCall("getDeveloperOverview") {
            ApiClient.getService().getDeveloperOverview()
        }
    }

    // =========================================================================
    // CLIENTS APIS
    // =========================================================================

    suspend fun getAllClients(search: String? = null): Result<List<BackendClientDto>> {
        return safeApiCall("getAllClients") {
            ApiClient.getService().getAllClients(search)
        }
    }

    suspend fun getClientById(id: Long): Result<BackendClientDto> {
        return safeApiCall("getClientById") {
            ApiClient.getService().getClientById(id)
        }
    }

    suspend fun createClient(client: BackendClientDto): Result<BackendClientDto> {
        return safeApiCall("createClient") {
            ApiClient.getService().createClient(client)
        }
    }

    suspend fun updateClient(id: Long, client: BackendClientDto): Result<BackendClientDto> {
        return safeApiCall("updateClient") {
            ApiClient.getService().updateClient(id, client)
        }
    }

    suspend fun deleteClient(id: Long): Result<Unit> {
        return safeApiCall("deleteClient") {
            ApiClient.getService().deleteClient(id)
        }
    }

    // =========================================================================
    // EXPENSES APIS
    // =========================================================================

    suspend fun getAllExpenses(category: String? = null, companyId: Long? = null): Result<List<BackendExpenseDto>> {
        return safeApiCall("getAllExpenses") {
            ApiClient.getService().getAllExpenses(category, companyId)
        }
    }

    suspend fun getExpenseById(id: Long): Result<BackendExpenseDto> {
        return safeApiCall("getExpenseById") {
            ApiClient.getService().getExpenseById(id)
        }
    }

    suspend fun createExpense(expense: BackendExpenseDto): Result<BackendExpenseDto> {
        return safeApiCall("createExpense") {
            ApiClient.getService().createExpense(expense)
        }
    }

    suspend fun updateExpense(id: Long, expense: BackendExpenseDto): Result<BackendExpenseDto> {
        return safeApiCall("updateExpense") {
            ApiClient.getService().updateExpense(id, expense)
        }
    }

    suspend fun deleteExpense(id: Long): Result<Unit> {
        return safeApiCall("deleteExpense") {
            ApiClient.getService().deleteExpense(id)
        }
    }

    // =========================================================================
    // INVOICES APIS
    // =========================================================================

    suspend fun getAllInvoices(status: String? = null, clientId: Long? = null, companyId: Long? = null): Result<List<BackendInvoiceDto>> {
        return safeApiCall("getAllInvoices") {
            ApiClient.getService().getAllInvoices(status, clientId, companyId)
        }
    }

    suspend fun getInvoiceById(id: Long): Result<BackendInvoiceDto> {
        return safeApiCall("getInvoiceById") {
            ApiClient.getService().getInvoiceById(id)
        }
    }

    suspend fun getInvoiceByNumber(invoiceNumber: String): Result<BackendInvoiceDto> {
        return safeApiCall("getInvoiceByNumber") {
            ApiClient.getService().getInvoiceByNumber(invoiceNumber)
        }
    }

    suspend fun createInvoice(invoice: BackendInvoiceDto): Result<BackendInvoiceDto> {
        return safeApiCall("createInvoice") {
            ApiClient.getService().createInvoice(invoice)
        }
    }

    suspend fun updateInvoice(id: Long, invoice: BackendInvoiceDto): Result<BackendInvoiceDto> {
        return safeApiCall("updateInvoice") {
            ApiClient.getService().updateInvoice(id, invoice)
        }
    }

    suspend fun updateInvoiceStatus(id: Long, status: String): Result<BackendInvoiceDto> {
        return safeApiCall("updateInvoiceStatus") {
            ApiClient.getService().updateInvoiceStatus(id, status)
        }
    }

    suspend fun deleteInvoice(id: Long): Result<Unit> {
        return safeApiCall("deleteInvoice") {
            ApiClient.getService().deleteInvoice(id)
        }
    }

    // =========================================================================
    // COMPANIES & JOIN REQUESTS APIS
    // =========================================================================

    suspend fun getMyCompany(): Result<CompanySummaryDto> {
        return safeApiCall("getMyCompany") {
            ApiClient.getService().getMyCompany()
        }
    }

    suspend fun getJoinRequests(status: String? = null): Result<List<CompanyJoinRequestDto>> {
        return safeApiCall("getJoinRequests") {
            ApiClient.getService().getJoinRequests(status)
        }
    }

    suspend fun processJoinRequest(id: Long, action: String): Result<CompanyJoinRequestDto> {
        return safeApiCall("processJoinRequest") {
            ApiClient.getService().processJoinRequest(id, JoinRequestActionRequest(action))
        }
    }

    suspend fun getCompanyEmployees(): Result<List<UserSummaryDto>> {
        return safeApiCall("getCompanyEmployees") {
            ApiClient.getService().getCompanyEmployees()
        }
    }

    suspend fun updateEmployeePermissions(id: Long, permissions: String): Result<UserSummaryDto> {
        return safeApiCall("updateEmployeePermissions") {
            ApiClient.getService().updateEmployeePermissions(id, com.example.data.api.model.UpdateEmployeePermissionsRequest(permissions))
        }
    }

    suspend fun getAllCompanies(): Result<List<CompanySummaryDto>> {
        return safeApiCall("getAllCompanies") {
            ApiClient.getService().getAllCompanies()
        }
    }

    // =========================================================================
    // BUSINESS PROFILE APIS
    // =========================================================================

    suspend fun getBusinessProfile(): Result<BackendBusinessProfileDto> {
        return safeApiCall("getBusinessProfile") {
            ApiClient.getService().getProfile()
        }
    }

    suspend fun updateBusinessProfile(profile: BackendBusinessProfileDto): Result<BackendBusinessProfileDto> {
        return safeApiCall("updateBusinessProfile") {
            ApiClient.getService().updateProfile(profile)
        }
    }

    // =========================================================================
    // BI-DIRECTIONAL SEAMLESS SYNCHRONIZATION
    // =========================================================================

    suspend fun syncAllWithBackend(
        invoiceRepository: InvoiceRepository,
        clientRepository: ClientRepository,
        expenseRepository: ExpenseRepository,
        businessRepository: BusinessRepository,
        companyId: Long? = null
    ): Result<String> = withContext(Dispatchers.IO) {
        if (!com.example.data.repository.AuthSessionManager.isLoggedIn.value || ApiClient.getAuthToken().isNullOrBlank()) {
            return@withContext Result.failure(Exception("Authentication required. Please sign in to access cloud data."))
        }

        ApiConfig.setSyncing(true)
        val syncLog = StringBuilder()

        try {
            // 1. Sync Business Profile
            val remoteProfileRes = getBusinessProfile()
            if (remoteProfileRes.isSuccess) {
                val remoteProfile = remoteProfileRes.getOrNull()
                if (remoteProfile != null) {
                    val currentLocal = businessRepository.getProfileDirect() ?: BusinessProfile()
                    val mergedProfile = remoteProfile.toEntity(currentLocal)
                    businessRepository.saveProfile(mergedProfile)
                    syncLog.append("✓ Profile synced. ")
                }
            }

            // 2. Sync Clients (Real Backend Storage)
            val remoteClientsRes = getAllClients()
            if (remoteClientsRes.isSuccess) {
                val remoteClients = remoteClientsRes.getOrNull() ?: emptyList()
                val localClients = clientRepository.allClients.firstOrNull() ?: emptyList()
                val remoteIds = remoteClients.map { it.id }.toSet()

                // Insert/update remote clients
                for (rc in remoteClients) {
                    val entity = rc.toEntity()
                    val exists = localClients.any { it.id == entity.id }
                    if (exists) {
                        clientRepository.updateClient(entity)
                    } else {
                        clientRepository.insertClient(entity)
                    }
                }

                // Clean up any local client records that no longer exist in real backend storage
                for (lc in localClients) {
                    if (lc.id !in remoteIds) {
                        clientRepository.deleteClient(lc)
                    }
                }
                syncLog.append("✓ ${remoteClients.size} clients synced. ")
            }

            // 3. Sync Expenses (Real Backend Storage)
            val remoteExpensesRes = getAllExpenses(companyId = companyId)
            if (remoteExpensesRes.isSuccess) {
                val remoteExpenses = remoteExpensesRes.getOrNull() ?: emptyList()
                val localExpenses = expenseRepository.allExpenses.firstOrNull() ?: emptyList()
                val remoteExpIds = remoteExpenses.map { it.id }.toSet()

                for (re in remoteExpenses) {
                    val entity = re.toEntity()
                    val exists = localExpenses.any { it.id == entity.id }
                    if (exists) {
                        expenseRepository.updateExpense(entity)
                    } else {
                        expenseRepository.insertExpense(entity)
                    }
                }

                for (le in localExpenses) {
                    if (le.id !in remoteExpIds) {
                        expenseRepository.deleteExpense(le)
                    }
                }
                syncLog.append("✓ ${remoteExpenses.size} expenses synced. ")
            }

            // 4. Sync Invoices (Real Backend Storage)
            val remoteInvoicesRes = getAllInvoices(companyId = companyId)
            if (remoteInvoicesRes.isSuccess) {
                val remoteInvoices = remoteInvoicesRes.getOrNull() ?: emptyList()
                val localInvoices = invoiceRepository.allInvoices.firstOrNull() ?: emptyList()
                val remoteInvNumbers = remoteInvoices.map { it.invoiceNumber }.toSet()

                for (ri in remoteInvoices) {
                    val entity = ri.toEntity()
                    val localMatch = localInvoices.find { it.invoiceNumber == entity.invoiceNumber }
                    if (localMatch != null) {
                        invoiceRepository.updateInvoice(entity.copy(id = localMatch.id))
                    } else {
                        invoiceRepository.insertInvoice(entity)
                    }
                }

                for (li in localInvoices) {
                    if (li.invoiceNumber !in remoteInvNumbers) {
                        invoiceRepository.deleteInvoice(li)
                    }
                }
                syncLog.append("✓ ${remoteInvoices.size} invoices synced.")
            }

            ApiConfig.recordSyncSuccess()
            Result.success("Sync complete: $syncLog")
        } catch (e: Exception) {
            Log.e(TAG, "Sync error: ${e.message}", e)
            ApiConfig.recordSyncError(e.localizedMessage ?: "Sync error")
            Result.failure(e)
        } finally {
            ApiConfig.setSyncing(false)
        }
    }
}
