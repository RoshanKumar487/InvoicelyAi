package com.example.data.repository

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import com.example.data.api.ApiConfig
import com.example.data.api.InvoicelyApiManager
import com.example.data.api.client.ApiClient
import com.example.data.api.model.RegisterCompanyRequest
import com.example.data.api.model.RegisterDeveloperRequest
import com.example.data.api.model.RegisterEmployeeRequest
import com.example.data.local.AppDatabase
import com.example.data.model.CompanyInfo
import com.example.data.model.EmployeeJoinRequest
import com.example.data.model.UserAccount
import com.example.data.model.UserRole
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.util.Locale

/**
 * Production-ready Authentication and Organization Session Manager.
 * Communicates directly with PostgreSQL Spring Boot Backend REST APIs.
 * Persists user session and JWT token securely in SharedPreferences.
 */
object AuthSessionManager {

    private const val TAG = "AuthSessionManager"
    private const val PREFS_NAME = "invoicely_auth_session"

    // SharedPreferences Keys
    private const val KEY_JWT_TOKEN = "jwt_token"
    private const val KEY_USER_ID = "user_id"
    private const val KEY_USER_FULL_NAME = "user_full_name"
    private const val KEY_USER_EMAIL = "user_email"
    private const val KEY_USER_MOBILE = "user_mobile"
    private const val KEY_USER_ROLE = "user_role"
    private const val KEY_USER_STATUS = "user_status"

    private const val KEY_COMPANY_ID = "company_id"
    private const val KEY_COMPANY_CODE = "company_code"
    private const val KEY_COMPANY_NAME = "company_name"
    private const val KEY_COMPANY_GSTIN = "company_gstin"
    private const val KEY_COMPANY_LOCATION = "company_location"
    private const val KEY_COMPANY_DETAILS = "company_details"
    private const val KEY_COMPANY_EMAIL = "company_email"
    private const val KEY_COMPANY_PHONE = "company_phone"
    private const val KEY_SAVED_BASE_URL = "saved_base_url"

    private val authScope = CoroutineScope(Dispatchers.IO)
    private var prefs: SharedPreferences? = null
    private var applicationContext: Context? = null

    // Session State Flows - Default to unauthenticated until initialized
    private val _currentUser = MutableStateFlow<UserAccount?>(null)
    val currentUser: StateFlow<UserAccount?> = _currentUser.asStateFlow()

    private val _currentCompany = MutableStateFlow<CompanyInfo?>(null)
    val currentCompany: StateFlow<CompanyInfo?> = _currentCompany.asStateFlow()

    private val _isLoggedIn = MutableStateFlow(false)
    val isLoggedIn: StateFlow<Boolean> = _isLoggedIn.asStateFlow()

    private val _joinRequests = MutableStateFlow<List<EmployeeJoinRequest>>(emptyList())
    val joinRequests: StateFlow<List<EmployeeJoinRequest>> = _joinRequests.asStateFlow()

    private val _allCompanies = MutableStateFlow<List<CompanyInfo>>(emptyList())
    val allCompanies: StateFlow<List<CompanyInfo>> = _allCompanies.asStateFlow()

    private val _jwtToken = MutableStateFlow<String?>(null)
    val jwtToken: StateFlow<String?> = _jwtToken.asStateFlow()

    /**
     * Initializes the Session Manager with Application Context.
     * Restores saved JWT token and user profile from SharedPreferences.
     * Validates session asynchronously against PostgreSQL backend.
     */
    fun init(context: Context) {
        val appCtx = context.applicationContext
        applicationContext = appCtx
        val sharedPrefs = appCtx.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs = sharedPrefs

        // Always enforce Render Cloud by default
        ApiConfig.resetToDefaultCloudUrl()

        // Clean out any stale emulator/localhost URLs from previous testing
        val savedUrl = sharedPrefs.getString(KEY_SAVED_BASE_URL, null)
        val roleStr = sharedPrefs.getString(KEY_USER_ROLE, "ADMIN") ?: "ADMIN"
        val isDev = roleStr.equals("DEVELOPER", ignoreCase = true)

        if (isDev && !savedUrl.isNullOrBlank() && !savedUrl.contains("10.0.2.2") && !savedUrl.contains("localhost")) {
            ApiConfig.updateBaseUrl(savedUrl)
        } else {
            if (!savedUrl.isNullOrBlank()) {
                sharedPrefs.edit().remove(KEY_SAVED_BASE_URL).apply()
            }
            ApiConfig.resetToDefaultCloudUrl()
        }

        val token = sharedPrefs.getString(KEY_JWT_TOKEN, null)
        if (!token.isNullOrBlank()) {
            _jwtToken.value = token
            ApiClient.setAuthToken(token)

            val roleStr = sharedPrefs.getString(KEY_USER_ROLE, "ADMIN") ?: "ADMIN"
            val userRole = try {
                UserRole.valueOf(roleStr.uppercase(Locale.ROOT))
            } catch (_: Exception) {
                UserRole.ADMIN
            }

            val savedCompanyId = sharedPrefs.getLong(KEY_COMPANY_ID, -1L)
            val company = if (savedCompanyId > 0) {
                CompanyInfo(
                    id = savedCompanyId,
                    companyCode = sharedPrefs.getString(KEY_COMPANY_CODE, "") ?: "",
                    companyName = sharedPrefs.getString(KEY_COMPANY_NAME, "") ?: "",
                    gstin = sharedPrefs.getString(KEY_COMPANY_GSTIN, "") ?: "",
                    location = sharedPrefs.getString(KEY_COMPANY_LOCATION, "") ?: "",
                    details = sharedPrefs.getString(KEY_COMPANY_DETAILS, "") ?: "",
                    email = sharedPrefs.getString(KEY_COMPANY_EMAIL, "") ?: "",
                    phone = sharedPrefs.getString(KEY_COMPANY_PHONE, "") ?: ""
                )
            } else null

            val user = UserAccount(
                id = sharedPrefs.getLong(KEY_USER_ID, 0L),
                fullName = sharedPrefs.getString(KEY_USER_FULL_NAME, "User") ?: "User",
                email = sharedPrefs.getString(KEY_USER_EMAIL, "") ?: "",
                mobile = sharedPrefs.getString(KEY_USER_MOBILE, "") ?: "",
                role = userRole,
                status = sharedPrefs.getString(KEY_USER_STATUS, "ACTIVE") ?: "ACTIVE",
                companyId = company?.id,
                companyName = company?.companyName,
                companyCode = company?.companyCode
            )

            _currentUser.value = user
            _currentCompany.value = company
            _isLoggedIn.value = true

            // Verify live token with PostgreSQL backend
            authScope.launch {
                val meResult = InvoicelyApiManager.getMe()
                if (meResult.isSuccess) {
                    val me = meResult.getOrNull()
                    if (me != null) {
                        val remoteComp = me.company?.toCompanyInfo()
                        val remoteUser = me.user?.toUserAccount(remoteComp?.companyCode, remoteComp?.companyName)
                        if (remoteUser != null) {
                            _currentUser.value = remoteUser
                            _currentCompany.value = remoteComp
                            saveUserSession(token, remoteUser, remoteComp)
                        }
                    }
                    fetchRemoteMetadata()
                } else {
                    val errorMsg = meResult.exceptionOrNull()?.message ?: ""
                    if (errorMsg.contains("401") || errorMsg.contains("Unauthorized") || errorMsg.contains("Forbidden")) {
                        Log.w(TAG, "Stored session expired, logging out.")
                        logout()
                    }
                }
            }
        } else {
            _isLoggedIn.value = false
            _currentUser.value = null
            _currentCompany.value = null
        }
    }

    /**
     * Authenticates with real PostgreSQL backend via POST /api/v1/auth/login.
     */
    suspend fun login(identifier: String, password: String): Result<UserAccount> {
        val trimmed = identifier.trim()
        if (trimmed.isBlank()) {
            return Result.failure(IllegalArgumentException("Please enter your email or mobile number"))
        }
        if (password.length < 4) {
            return Result.failure(IllegalArgumentException("Password must be at least 4 characters"))
        }

        val remoteResult = InvoicelyApiManager.login(trimmed, password)
        if (remoteResult.isSuccess) {
            val authResp = remoteResult.getOrNull()
            if (authResp != null) {
                val token = authResp.token ?: ""
                _jwtToken.value = token
                ApiClient.setAuthToken(token)

                val compInfo = authResp.company?.toCompanyInfo()
                val user = authResp.user?.toUserAccount(
                    companyCode = compInfo?.companyCode,
                    companyName = compInfo?.companyName
                ) ?: return Result.failure(Exception("Authentication failed: Server did not return a valid user profile"))

                // Clean local cache before populating real authenticated user data
                applicationContext?.let { ctx ->
                    try {
                        AppDatabase.clearAllData(AppDatabase.getDatabase(ctx))
                    } catch (e: Exception) {
                        Log.w(TAG, "Notice clearing cache on login", e)
                    }
                }

                _currentUser.value = user
                _currentCompany.value = compInfo
                _isLoggedIn.value = true

                saveUserSession(token, user, compInfo)
                fetchRemoteMetadata()
                return Result.success(user)
            }
        }

        val errorMsg = remoteResult.exceptionOrNull()?.message ?: "Login failed. Check your credentials."
        return Result.failure(Exception(cleanErrorMessage(errorMsg)))
    }

    /**
     * Registers a new Organization & Admin in PostgreSQL via POST /api/v1/auth/register-company.
     */
    suspend fun registerCompany(
        fullName: String,
        email: String,
        mobile: String,
        password: String,
        companyName: String,
        gstin: String = "",
        location: String = "",
        details: String = ""
    ): Result<UserAccount> {
        if (fullName.isBlank()) return Result.failure(IllegalArgumentException("Full name is required"))
        if (email.isBlank()) return Result.failure(IllegalArgumentException("Email is required"))
        if (mobile.isBlank()) return Result.failure(IllegalArgumentException("Mobile number is required"))
        if (password.length < 6) return Result.failure(IllegalArgumentException("Password must be at least 6 characters"))
        if (companyName.isBlank()) return Result.failure(IllegalArgumentException("Company name is required"))

        val req = RegisterCompanyRequest(
            fullName = fullName.trim(),
            email = email.trim(),
            mobile = mobile.trim(),
            password = password,
            companyName = companyName.trim(),
            gstin = gstin.trim(),
            location = location.trim(),
            details = details.trim()
        )

        val remoteRes = InvoicelyApiManager.registerCompany(req)
        if (remoteRes.isSuccess) {
            val authResp = remoteRes.getOrNull()
            if (authResp != null) {
                val token = authResp.token ?: ""
                _jwtToken.value = token
                ApiClient.setAuthToken(token)

                val comp = authResp.company?.toCompanyInfo()
                val user = authResp.user?.toUserAccount(comp?.companyCode, comp?.companyName)
                    ?: return Result.failure(Exception("Registration failed: Server did not return a valid user profile"))

                applicationContext?.let { ctx ->
                    try {
                        AppDatabase.clearAllData(AppDatabase.getDatabase(ctx))
                    } catch (e: Exception) {
                        Log.w(TAG, "Notice clearing cache on register", e)
                    }
                }

                _currentUser.value = user
                _currentCompany.value = comp
                _isLoggedIn.value = true

                saveUserSession(token, user, comp)
                fetchRemoteMetadata()
                return Result.success(user)
            }
        }

        val errorMsg = remoteRes.exceptionOrNull()?.message ?: "Failed to register organization."
        return Result.failure(Exception(cleanErrorMessage(errorMsg)))
    }

    /**
     * Submits an Employee join request to PostgreSQL via POST /api/v1/auth/register-employee.
     */
    suspend fun registerEmployee(
        fullName: String,
        email: String,
        mobile: String,
        password: String,
        companyCode: String,
        message: String = ""
    ): Result<String> {
        if (fullName.isBlank()) return Result.failure(IllegalArgumentException("Full name is required"))
        if (email.isBlank()) return Result.failure(IllegalArgumentException("Email is required"))
        if (mobile.isBlank()) return Result.failure(IllegalArgumentException("Mobile number is required"))
        if (password.length < 6) return Result.failure(IllegalArgumentException("Password must be at least 6 characters"))
        if (companyCode.isBlank()) return Result.failure(IllegalArgumentException("Company Code is required"))

        val req = RegisterEmployeeRequest(
            fullName = fullName.trim(),
            email = email.trim(),
            mobile = mobile.trim(),
            password = password,
            companyCode = companyCode.trim().uppercase(Locale.ROOT),
            message = message.trim()
        )

        val remoteRes = InvoicelyApiManager.registerEmployee(req)
        if (remoteRes.isSuccess) {
            val msg = remoteRes.getOrNull()?.message
                ?: "Join request submitted to company. Once the administrator approves, you will be able to log in."
            return Result.success(msg)
        }

        val errorMsg = remoteRes.exceptionOrNull()?.message ?: "Failed to submit employee join request."
        return Result.failure(Exception(cleanErrorMessage(errorMsg)))
    }

    /**
     * Registers a Platform Developer in PostgreSQL via POST /api/v1/auth/register-developer.
     */
    suspend fun registerDeveloper(
        fullName: String,
        email: String,
        mobile: String,
        password: String,
        developerSecretKey: String
    ): Result<UserAccount> {
        if (fullName.isBlank()) return Result.failure(IllegalArgumentException("Full name is required"))
        if (email.isBlank()) return Result.failure(IllegalArgumentException("Email is required"))
        if (mobile.isBlank()) return Result.failure(IllegalArgumentException("Mobile number is required"))
        if (password.length < 6) return Result.failure(IllegalArgumentException("Password must be at least 6 characters"))
        if (developerSecretKey.isBlank()) return Result.failure(IllegalArgumentException("Developer secret registration key is required"))

        val req = RegisterDeveloperRequest(
            fullName = fullName.trim(),
            email = email.trim(),
            mobile = mobile.trim(),
            password = password,
            developerSecretKey = developerSecretKey.trim(),
            secretKey = developerSecretKey.trim()
        )

        val remoteRes = InvoicelyApiManager.registerDeveloper(req)
        if (remoteRes.isSuccess) {
            val authResp = remoteRes.getOrNull()
            if (authResp != null) {
                val token = authResp.token ?: ""
                _jwtToken.value = token
                ApiClient.setAuthToken(token)

                val devUser = authResp.user?.toUserAccount()
                    ?: return Result.failure(Exception("Developer registration failed: Server did not return a valid profile"))

                applicationContext?.let { ctx ->
                    try {
                        AppDatabase.clearAllData(AppDatabase.getDatabase(ctx))
                    } catch (e: Exception) {
                        Log.w(TAG, "Notice clearing cache on dev register", e)
                    }
                }

                _currentUser.value = devUser
                _currentCompany.value = null
                _isLoggedIn.value = true

                saveUserSession(token, devUser, null)
                fetchRemoteMetadata()
                return Result.success(devUser)
            }
        }

        val errorMsg = remoteRes.exceptionOrNull()?.message ?: "Developer registration failed. Verify your secret key."
        return Result.failure(Exception(cleanErrorMessage(errorMsg)))
    }

    /**
     * Fetches metadata from PostgreSQL (Join requests, companies, etc.).
     */
    fun fetchRemoteMetadata() {
        authScope.launch {
            try {
                // Fetch Join Requests if user is Admin
                if (_currentUser.value?.role == UserRole.ADMIN) {
                    val jrRes = InvoicelyApiManager.getJoinRequests()
                    if (jrRes.isSuccess) {
                        val list = jrRes.getOrNull()
                        if (list != null) {
                            _joinRequests.value = list.map { it.toEmployeeJoinRequest() }
                        }
                    }
                }

                // Fetch All Companies if user is Developer
                if (_currentUser.value?.role == UserRole.DEVELOPER) {
                    val compRes = InvoicelyApiManager.getAllCompanies()
                    if (compRes.isSuccess) {
                        val comps = compRes.getOrNull()
                        if (comps != null) {
                            _allCompanies.value = comps.map { it.toCompanyInfo() }
                        }
                    }
                } else {
                    // Fetch My Company
                    val myCompRes = InvoicelyApiManager.getMyCompany()
                    if (myCompRes.isSuccess) {
                        val comp = myCompRes.getOrNull()
                        if (comp != null) {
                            _currentCompany.value = comp.toCompanyInfo()
                        }
                    }
                }
            } catch (e: Exception) {
                Log.w(TAG, "Error fetching remote metadata: ${e.message}")
            }
        }
    }

    fun approveJoinRequest(requestId: Long) {
        _joinRequests.value = _joinRequests.value.map {
            if (it.id == requestId) it.copy(status = "APPROVED") else it
        }
        authScope.launch {
            InvoicelyApiManager.processJoinRequest(requestId, "APPROVE")
        }
    }

    fun rejectJoinRequest(requestId: Long) {
        _joinRequests.value = _joinRequests.value.map {
            if (it.id == requestId) it.copy(status = "REJECTED") else it
        }
        authScope.launch {
            InvoicelyApiManager.processJoinRequest(requestId, "REJECT")
        }
    }

    fun switchCompanyForDeveloper(company: CompanyInfo) {
        if (_currentUser.value?.role == UserRole.DEVELOPER) {
            _currentCompany.value = company
        }
    }

    fun saveCustomServerUrl(url: String) {
        if (_currentUser.value?.role == UserRole.DEVELOPER) {
            ApiConfig.updateBaseUrl(url)
            prefs?.edit()?.putString(KEY_SAVED_BASE_URL, url)?.apply()
        }
    }

    fun notifySessionExpired() {
        if (!_isLoggedIn.value && _jwtToken.value == null) return
        Log.w(TAG, "Active session token expired or invalid (401 Unauthorized received).")
        prefs?.edit()?.remove(KEY_JWT_TOKEN)?.apply()
        _jwtToken.value = null
        _isLoggedIn.value = false
        _currentUser.value = null
        _currentCompany.value = null
        ApiClient.setAuthToken(null)
        ApiConfig.clearSyncError()
    }

    fun logout() {
        prefs?.edit()?.clear()?.apply()
        _isLoggedIn.value = false
        _currentUser.value = null
        _currentCompany.value = null
        _jwtToken.value = null
        _joinRequests.value = emptyList()
        ApiClient.setAuthToken(null)
        ApiConfig.resetToDefaultCloudUrl()
        ApiConfig.clearSyncError()

        applicationContext?.let { ctx ->
            authScope.launch(Dispatchers.IO) {
                try {
                    AppDatabase.clearAllData(AppDatabase.getDatabase(ctx))
                } catch (e: Exception) {
                    Log.w(TAG, "Notice clearing local database on logout", e)
                }
            }
        }
    }

    private fun saveUserSession(token: String, user: UserAccount, company: CompanyInfo?) {
        prefs?.edit()?.apply {
            putString(KEY_JWT_TOKEN, token)
            putLong(KEY_USER_ID, user.id)
            putString(KEY_USER_FULL_NAME, user.fullName)
            putString(KEY_USER_EMAIL, user.email)
            putString(KEY_USER_MOBILE, user.mobile)
            putString(KEY_USER_ROLE, user.role.name)
            putString(KEY_USER_STATUS, user.status)

            if (company != null) {
                putLong(KEY_COMPANY_ID, company.id)
                putString(KEY_COMPANY_CODE, company.companyCode)
                putString(KEY_COMPANY_NAME, company.companyName)
                putString(KEY_COMPANY_GSTIN, company.gstin)
                putString(KEY_COMPANY_LOCATION, company.location)
                putString(KEY_COMPANY_DETAILS, company.details)
                putString(KEY_COMPANY_EMAIL, company.email)
                putString(KEY_COMPANY_PHONE, company.phone)
            } else {
                remove(KEY_COMPANY_ID)
                remove(KEY_COMPANY_CODE)
                remove(KEY_COMPANY_NAME)
            }
            apply()
        }
    }

    private fun cleanErrorMessage(raw: String): String {
        return when {
            raw.contains("Invalid email/mobile or password", ignoreCase = true) ->
                "Invalid email/mobile or password. Please try again."
            raw.contains("pending approval", ignoreCase = true) ->
                "Your account registration is pending approval by your company administrator."
            raw.contains("rejected", ignoreCase = true) ->
                "Your registration request was rejected by the company administrator."
            raw.contains("disabled", ignoreCase = true) || raw.contains("inactive", ignoreCase = true) ->
                "Your account is currently disabled. Contact your company administrator."
            raw.contains("already registered", ignoreCase = true) || raw.contains("already exists", ignoreCase = true) ->
                "An account with this email is already registered. Please sign in."
            raw.contains("not found", ignoreCase = true) ->
                "Company code not found. Please verify with your organization administrator."
            raw.contains("timeout", ignoreCase = true) || raw.contains("connection", ignoreCase = true) ->
                "Could not connect to database server. Please check your internet connection."
            else -> raw.removePrefix("Server error: ").take(160)
        }
    }
}
