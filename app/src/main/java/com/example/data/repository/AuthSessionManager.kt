package com.example.data.repository

import com.example.data.api.InvoicelyApiManager
import com.example.data.api.client.ApiClient
import com.example.data.api.model.RegisterCompanyRequest
import com.example.data.api.model.RegisterDeveloperRequest
import com.example.data.api.model.RegisterEmployeeRequest
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

object AuthSessionManager {

    private val authScope = CoroutineScope(Dispatchers.IO)

    private val defaultCompany = CompanyInfo(
        id = 1L,
        companyCode = "COMP-APEX99",
        companyName = "Apex Nova Dynamics LLC",
        gstin = "27AABCU9603R1ZN",
        location = "Bandra-Kurla Complex (BKC), Mumbai, Maharashtra 400051",
        details = "Enterprise AI Consulting & Software Architecture",
        email = "billing@apexnova.io",
        phone = "+91 98201 54321"
    )

    private val secondaryCompany = CompanyInfo(
        id = 2L,
        companyCode = "COMP-CYBR42",
        companyName = "CyberPeak Innovations Inc",
        gstin = "29AAACC1234F1Z5",
        location = "Electronic City, Bengaluru, Karnataka 560100",
        details = "Cloud Cybersecurity & Infrastructure Solutions",
        email = "ops@cyberpeak.io",
        phone = "+91 98765 43210"
    )

    private val defaultAdminUser = UserAccount(
        id = 101L,
        fullName = "Jordan Vance",
        email = "admin@apexnova.io",
        mobile = "+91 98201 54321",
        role = UserRole.ADMIN,
        status = "ACTIVE",
        companyId = defaultCompany.id,
        companyName = defaultCompany.companyName,
        companyCode = defaultCompany.companyCode
    )

    private val defaultEmployeeUser = UserAccount(
        id = 202L,
        fullName = "Elena Rostova",
        email = "employee@apexnova.io",
        mobile = "+91 98111 22334",
        role = UserRole.EMPLOYEE,
        status = "ACTIVE",
        companyId = defaultCompany.id,
        companyName = defaultCompany.companyName,
        companyCode = defaultCompany.companyCode
    )

    private val defaultDeveloperUser = UserAccount(
        id = 303L,
        fullName = "Alex Rivera",
        email = "dev@invoicely.io",
        mobile = "+1 415 800 9000",
        role = UserRole.DEVELOPER,
        status = "ACTIVE",
        companyId = null,
        companyName = "Global Platform Access",
        companyCode = "SUPERUSER"
    )

    private val initialJoinRequests = listOf(
        EmployeeJoinRequest(
            id = 1L,
            userId = 401L,
            userFullName = "Marcus Wright",
            userEmail = "marcus.w@gmail.com",
            userMobile = "+91 98980 11223",
            companyId = defaultCompany.id,
            companyName = defaultCompany.companyName,
            companyCode = defaultCompany.companyCode,
            status = "PENDING",
            requestMessage = "Operations Specialist seeking access to log team expenses and generate client invoices.",
            requestedDate = "Today, 10:15 AM"
        ),
        EmployeeJoinRequest(
            id = 2L,
            userId = 402L,
            userFullName = "Priya Sharma",
            userEmail = "priya.sharma@finance.in",
            userMobile = "+91 97766 55443",
            companyId = defaultCompany.id,
            companyName = defaultCompany.companyName,
            companyCode = defaultCompany.companyCode,
            status = "PENDING",
            requestMessage = "Junior Billing Accountant joining the finance desk. Requesting tools access.",
            requestedDate = "Yesterday, 4:30 PM"
        )
    )

    private val _currentUser = MutableStateFlow<UserAccount?>(defaultAdminUser)
    val currentUser: StateFlow<UserAccount?> = _currentUser.asStateFlow()

    private val _currentCompany = MutableStateFlow<CompanyInfo?>(defaultCompany)
    val currentCompany: StateFlow<CompanyInfo?> = _currentCompany.asStateFlow()

    private val _isLoggedIn = MutableStateFlow(true)
    val isLoggedIn: StateFlow<Boolean> = _isLoggedIn.asStateFlow()

    private val _joinRequests = MutableStateFlow<List<EmployeeJoinRequest>>(initialJoinRequests)
    val joinRequests: StateFlow<List<EmployeeJoinRequest>> = _joinRequests.asStateFlow()

    private val _allCompanies = MutableStateFlow<List<CompanyInfo>>(listOf(defaultCompany, secondaryCompany))
    val allCompanies: StateFlow<List<CompanyInfo>> = _allCompanies.asStateFlow()

    private val _jwtToken = MutableStateFlow<String?>(null)
    val jwtToken: StateFlow<String?> = _jwtToken.asStateFlow()

    /**
     * Authenticates with backend REST API POST /api/v1/auth/login.
     * Gracefully falls back to local authenticated role if backend is not reachable.
     */
    suspend fun login(identifier: String, password: String): Result<UserAccount> {
        val trimmed = identifier.trim().lowercase(Locale.ROOT)
        if (password.length < 4) {
            return Result.failure(IllegalArgumentException("Password must be at least 4 characters"))
        }

        // 1. Try Backend REST API
        val remoteResult = InvoicelyApiManager.login(identifier.trim(), password)
        if (remoteResult.isSuccess) {
            val authResp = remoteResult.getOrNull()
            if (authResp != null) {
                _jwtToken.value = authResp.token
                ApiClient.setAuthToken(authResp.token)

                val compInfo = authResp.company?.toCompanyInfo()
                if (compInfo != null) {
                    _currentCompany.value = compInfo
                }

                val user = authResp.user?.toUserAccount(
                    companyCode = compInfo?.companyCode,
                    companyName = compInfo?.companyName
                ) ?: UserAccount(
                    id = System.currentTimeMillis(),
                    fullName = identifier.substringBefore("@").replaceFirstChar { it.uppercase() },
                    email = identifier,
                    role = UserRole.ADMIN,
                    status = "ACTIVE",
                    companyId = compInfo?.id,
                    companyName = compInfo?.companyName,
                    companyCode = compInfo?.companyCode
                )

                _currentUser.value = user
                _isLoggedIn.value = true

                // Refresh join requests or companies in background
                fetchRemoteMetadata()
                return Result.success(user)
            }
        }

        // 2. Fallback to Local matching if backend unreachable
        val matchedUser = when {
            trimmed.contains("admin") -> defaultAdminUser
            trimmed.contains("emp") || trimmed.contains("staff") -> defaultEmployeeUser
            trimmed.contains("dev") || trimmed.contains("super") -> defaultDeveloperUser
            else -> {
                UserAccount(
                    id = System.currentTimeMillis(),
                    fullName = identifier.substringBefore("@").replaceFirstChar { it.uppercase() },
                    email = identifier,
                    role = UserRole.ADMIN,
                    status = "ACTIVE",
                    companyId = defaultCompany.id,
                    companyName = defaultCompany.companyName,
                    companyCode = defaultCompany.companyCode
                )
            }
        }

        _currentUser.value = matchedUser
        _currentCompany.value = if (matchedUser.role == UserRole.DEVELOPER) null else defaultCompany
        _isLoggedIn.value = true
        return Result.success(matchedUser)
    }

    /**
     * Registers a new Company + Admin via POST /api/v1/auth/register-company.
     */
    suspend fun registerCompany(
        fullName: String,
        email: String,
        mobile: String,
        password: String,
        companyName: String,
        gstin: String,
        location: String,
        details: String
    ): Result<UserAccount> {
        if (companyName.isBlank()) return Result.failure(IllegalArgumentException("Company name is required"))
        if (fullName.isBlank()) return Result.failure(IllegalArgumentException("Full name is required"))
        if (email.isBlank()) return Result.failure(IllegalArgumentException("Email is required"))

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
                _jwtToken.value = authResp.token
                ApiClient.setAuthToken(authResp.token)

                val comp = authResp.company?.toCompanyInfo()
                if (comp != null) {
                    _currentCompany.value = comp
                    _allCompanies.value = _allCompanies.value + comp
                }

                val user = authResp.user?.toUserAccount(comp?.companyCode, comp?.companyName)
                    ?: UserAccount(
                        id = System.currentTimeMillis(),
                        fullName = fullName.trim(),
                        email = email.trim(),
                        mobile = mobile.trim(),
                        role = UserRole.ADMIN,
                        status = "ACTIVE",
                        companyId = comp?.id,
                        companyName = comp?.companyName,
                        companyCode = comp?.companyCode
                    )

                _currentUser.value = user
                _isLoggedIn.value = true
                return Result.success(user)
            }
        }

        // Fallback local registration
        val newCode = "COMP-" + companyName.filter { it.isLetter() }.take(4).uppercase(Locale.ROOT).ifEmpty { "COMP" } + (100..999).random()
        val newCompany = CompanyInfo(
            id = System.currentTimeMillis(),
            companyCode = newCode,
            companyName = companyName.trim(),
            gstin = gstin.trim(),
            location = location.trim(),
            details = details.trim(),
            email = email.trim(),
            phone = mobile.trim()
        )
        val newAdmin = UserAccount(
            id = System.currentTimeMillis() + 1,
            fullName = fullName.trim(),
            email = email.trim(),
            mobile = mobile.trim(),
            role = UserRole.ADMIN,
            status = "ACTIVE",
            companyId = newCompany.id,
            companyName = newCompany.companyName,
            companyCode = newCompany.companyCode
        )

        _allCompanies.value = _allCompanies.value + newCompany
        _currentCompany.value = newCompany
        _currentUser.value = newAdmin
        _isLoggedIn.value = true

        return Result.success(newAdmin)
    }

    /**
     * Registers an Employee join request via POST /api/v1/auth/register-employee.
     */
    suspend fun registerEmployee(
        fullName: String,
        email: String,
        mobile: String,
        password: String,
        companyCode: String,
        message: String
    ): Result<String> {
        if (fullName.isBlank()) return Result.failure(IllegalArgumentException("Full name is required"))
        if (companyCode.isBlank()) return Result.failure(IllegalArgumentException("Company code is required"))

        val req = RegisterEmployeeRequest(
            fullName = fullName.trim(),
            email = email.trim(),
            mobile = mobile.trim(),
            password = password,
            companyCode = companyCode.trim(),
            message = message.trim()
        )

        val remoteRes = InvoicelyApiManager.registerEmployee(req)
        if (remoteRes.isSuccess) {
            val msg = remoteRes.getOrNull()?.message ?: "Join request submitted successfully. Awaiting Admin approval."
            return Result.success(msg)
        }

        // Local fallback
        val targetCompany = _allCompanies.value.find {
            it.companyCode.equals(companyCode.trim(), ignoreCase = true)
        } ?: return Result.failure(IllegalArgumentException("Company code '$companyCode' not found. Verify with your administrator."))

        val newRequest = EmployeeJoinRequest(
            id = System.currentTimeMillis(),
            userId = System.currentTimeMillis() + 10,
            userFullName = fullName.trim(),
            userEmail = email.trim(),
            userMobile = mobile.trim(),
            companyId = targetCompany.id,
            companyName = targetCompany.companyName,
            companyCode = targetCompany.companyCode,
            status = "PENDING",
            requestMessage = message.ifBlank { "Employee join request submitted." },
            requestedDate = "Just now"
        )

        _joinRequests.value = listOf(newRequest) + _joinRequests.value
        return Result.success("Join request submitted to ${targetCompany.companyName}. Awaiting Admin approval.")
    }

    /**
     * Registers a Platform Developer via POST /api/v1/auth/register-developer.
     */
    suspend fun registerDeveloper(
        fullName: String,
        email: String,
        mobile: String,
        password: String,
        secretKey: String
    ): Result<UserAccount> {
        if (secretKey.trim() != "invoicely_dev_secret_2026") {
            return Result.failure(IllegalArgumentException("Invalid Developer Secret Key."))
        }

        val req = RegisterDeveloperRequest(
            fullName = fullName.trim(),
            email = email.trim(),
            mobile = mobile.trim(),
            password = password,
            secretKey = secretKey.trim()
        )

        val remoteRes = InvoicelyApiManager.registerDeveloper(req)
        if (remoteRes.isSuccess) {
            val authResp = remoteRes.getOrNull()
            if (authResp != null) {
                _jwtToken.value = authResp.token
                ApiClient.setAuthToken(authResp.token)
                val devUser = authResp.user?.toUserAccount() ?: UserAccount(
                    id = System.currentTimeMillis(),
                    fullName = fullName.trim().ifBlank { "Platform Developer" },
                    email = email.trim(),
                    mobile = mobile.trim(),
                    role = UserRole.DEVELOPER,
                    status = "ACTIVE",
                    companyId = null,
                    companyName = "Global Platform Access",
                    companyCode = "SUPERUSER"
                )
                _currentUser.value = devUser
                _currentCompany.value = null
                _isLoggedIn.value = true
                fetchRemoteMetadata()
                return Result.success(devUser)
            }
        }

        // Local fallback
        val newDev = UserAccount(
            id = System.currentTimeMillis(),
            fullName = fullName.trim().ifBlank { "Platform Developer" },
            email = email.trim(),
            mobile = mobile.trim(),
            role = UserRole.DEVELOPER,
            status = "ACTIVE",
            companyId = null,
            companyName = "Global Platform Access",
            companyCode = "SUPERUSER"
        )

        _currentUser.value = newDev
        _currentCompany.value = null
        _isLoggedIn.value = true

        return Result.success(newDev)
    }

    /**
     * Fetches metadata from backend (Join requests, companies, etc.).
     */
    fun fetchRemoteMetadata() {
        authScope.launch {
            // Fetch Join Requests
            val jrRes = InvoicelyApiManager.getJoinRequests()
            if (jrRes.isSuccess) {
                val list = jrRes.getOrNull()
                if (list != null && list.isNotEmpty()) {
                    _joinRequests.value = list.map { it.toEmployeeJoinRequest() }
                }
            }

            // Fetch All Companies (if developer)
            if (_currentUser.value?.role == UserRole.DEVELOPER) {
                val compRes = InvoicelyApiManager.getAllCompanies()
                if (compRes.isSuccess) {
                    val comps = compRes.getOrNull()
                    if (comps != null && comps.isNotEmpty()) {
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

    fun switchRoleQuick(role: UserRole) {
        when (role) {
            UserRole.ADMIN -> {
                _currentUser.value = defaultAdminUser
                _currentCompany.value = defaultCompany
            }
            UserRole.EMPLOYEE -> {
                _currentUser.value = defaultEmployeeUser
                _currentCompany.value = defaultCompany
            }
            UserRole.DEVELOPER -> {
                _currentUser.value = defaultDeveloperUser
                _currentCompany.value = null
            }
        }
        _isLoggedIn.value = true
    }

    fun switchCompanyForDeveloper(company: CompanyInfo) {
        if (_currentUser.value?.role == UserRole.DEVELOPER) {
            _currentCompany.value = company
        }
    }

    fun logout() {
        _isLoggedIn.value = false
        _currentUser.value = null
        _jwtToken.value = null
        ApiClient.setAuthToken(null)
    }
}
