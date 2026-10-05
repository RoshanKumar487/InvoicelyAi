package com.example.data.api.service

import com.example.data.api.model.ApiResponse
import com.example.data.api.model.AiChatRequest
import com.example.data.api.model.AiChatResponseDto
import com.example.data.api.model.AiInvoiceDraftResponseDto
import com.example.data.api.model.ReceiptScanRequest
import com.example.data.api.model.ReceiptScanResponseDto
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
import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.DELETE
import retrofit2.http.GET
import retrofit2.http.PATCH
import retrofit2.http.POST
import retrofit2.http.PUT
import retrofit2.http.Path
import retrofit2.http.Query

/**
 * Retrofit REST API interface defining all Spring Boot endpoints for InvoicelyAi.
 */
interface InvoicelyApiService {

    // =========================================================================
    // AI ASSISTANT
    // =========================================================================

    @POST("api/v1/ai/chat")
    suspend fun askAi(
        @Body request: AiChatRequest
    ): Response<ApiResponse<AiChatResponseDto>>

    @POST("api/v1/ai/commands/{commandId}/confirm")
    suspend fun confirmAiCommand(
        @Path("commandId") commandId: String
    ): Response<ApiResponse<AiChatResponseDto>>

    @POST("api/v1/ai/invoice-draft")
    suspend fun prepareAiInvoiceDraft(
        @Body request: AiChatRequest
    ): Response<ApiResponse<AiInvoiceDraftResponseDto>>

    @POST("api/v1/ai/receipt-scan")
    suspend fun scanAiReceipt(
        @Body request: ReceiptScanRequest
    ): Response<ApiResponse<ReceiptScanResponseDto>>

    // =========================================================================
    // AUTHENTICATION & MULTI-TENANT ONBOARDING
    // =========================================================================

    @POST("api/v1/auth/register-company")
    suspend fun registerCompany(
        @Body request: RegisterCompanyRequest
    ): Response<ApiResponse<AuthResponseDto>>

    @POST("api/v1/auth/register-employee")
    suspend fun registerEmployee(
        @Body request: RegisterEmployeeRequest
    ): Response<ApiResponse<AuthResponseDto>>

    @POST("api/v1/auth/register-developer")
    suspend fun registerDeveloper(
        @Body request: RegisterDeveloperRequest
    ): Response<ApiResponse<AuthResponseDto>>

    @POST("api/v1/auth/login")
    suspend fun login(
        @Body request: LoginRequest
    ): Response<ApiResponse<AuthResponseDto>>

    @POST("api/v1/auth/reset-password")
    suspend fun resetPassword(
        @Body request: com.example.data.api.model.ResetPasswordRequest
    ): Response<ApiResponse<AuthResponseDto>>

    @GET("api/v1/auth/me")
    suspend fun getMe(): Response<ApiResponse<AuthResponseDto>>

    @GET("api/v1/health")
    suspend fun checkHealth(): Response<ApiResponse<Map<String, Any>>>

    // =========================================================================
    // DASHBOARD & ANALYTICS
    // =========================================================================

    @GET("api/v1/dashboard/stats")
    suspend fun getDashboardStats(
        @Query("companyId") companyId: Long? = null
    ): Response<ApiResponse<DashboardStatsResponse>>

    @GET("api/v1/dashboard/developer-overview")
    suspend fun getDeveloperOverview(): Response<ApiResponse<com.example.data.api.model.DeveloperOverviewDto>>

    // =========================================================================
    // CLIENTS
    // =========================================================================

    @GET("api/v1/clients")
    suspend fun getAllClients(
        @Query("search") search: String? = null
    ): Response<ApiResponse<List<BackendClientDto>>>

    @GET("api/v1/clients/{id}")
    suspend fun getClientById(
        @Path("id") id: Long
    ): Response<ApiResponse<BackendClientDto>>

    @POST("api/v1/clients")
    suspend fun createClient(
        @Body client: BackendClientDto
    ): Response<ApiResponse<BackendClientDto>>

    @PUT("api/v1/clients/{id}")
    suspend fun updateClient(
        @Path("id") id: Long,
        @Body client: BackendClientDto
    ): Response<ApiResponse<BackendClientDto>>

    @DELETE("api/v1/clients/{id}")
    suspend fun deleteClient(
        @Path("id") id: Long
    ): Response<ApiResponse<Unit>>

    // =========================================================================
    // EXPENSES
    // =========================================================================

    @GET("api/v1/expenses")
    suspend fun getAllExpenses(
        @Query("category") category: String? = null,
        @Query("companyId") companyId: Long? = null
    ): Response<ApiResponse<List<BackendExpenseDto>>>

    @GET("api/v1/expenses/{id}")
    suspend fun getExpenseById(
        @Path("id") id: Long
    ): Response<ApiResponse<BackendExpenseDto>>

    @POST("api/v1/expenses")
    suspend fun createExpense(
        @Body expense: BackendExpenseDto
    ): Response<ApiResponse<BackendExpenseDto>>

    @PUT("api/v1/expenses/{id}")
    suspend fun updateExpense(
        @Path("id") id: Long,
        @Body expense: BackendExpenseDto
    ): Response<ApiResponse<BackendExpenseDto>>

    @DELETE("api/v1/expenses/{id}")
    suspend fun deleteExpense(
        @Path("id") id: Long
    ): Response<ApiResponse<Unit>>

    // =========================================================================
    // INVOICES
    // =========================================================================

    @GET("api/v1/invoices")
    suspend fun getAllInvoices(
        @Query("status") status: String? = null,
        @Query("clientId") clientId: Long? = null,
        @Query("companyId") companyId: Long? = null
    ): Response<ApiResponse<List<BackendInvoiceDto>>>

    @GET("api/v1/invoices/{id}")
    suspend fun getInvoiceById(
        @Path("id") id: Long
    ): Response<ApiResponse<BackendInvoiceDto>>

    @GET("api/v1/invoices/by-number/{invoiceNumber}")
    suspend fun getInvoiceByNumber(
        @Path("invoiceNumber") invoiceNumber: String
    ): Response<ApiResponse<BackendInvoiceDto>>

    @POST("api/v1/invoices")
    suspend fun createInvoice(
        @Body invoice: BackendInvoiceDto
    ): Response<ApiResponse<BackendInvoiceDto>>

    @PUT("api/v1/invoices/{id}")
    suspend fun updateInvoice(
        @Path("id") id: Long,
        @Body invoice: BackendInvoiceDto
    ): Response<ApiResponse<BackendInvoiceDto>>

    @PATCH("api/v1/invoices/{id}/status")
    suspend fun updateInvoiceStatus(
        @Path("id") id: Long,
        @Query("status") status: String
    ): Response<ApiResponse<BackendInvoiceDto>>

    @DELETE("api/v1/invoices/{id}")
    suspend fun deleteInvoice(
        @Path("id") id: Long
    ): Response<ApiResponse<Unit>>

    // =========================================================================
    // COMPANIES & TEAM MANAGEMENT
    // =========================================================================

    @GET("api/v1/companies/my-company")
    suspend fun getMyCompany(): Response<ApiResponse<CompanySummaryDto>>

    @GET("api/v1/companies/join-requests")
    suspend fun getJoinRequests(
        @Query("status") status: String? = null
    ): Response<ApiResponse<List<CompanyJoinRequestDto>>>

    @POST("api/v1/companies/join-requests/{id}/action")
    suspend fun processJoinRequest(
        @Path("id") id: Long,
        @Body request: JoinRequestActionRequest
    ): Response<ApiResponse<CompanyJoinRequestDto>>

    @GET("api/v1/companies/employees")
    suspend fun getCompanyEmployees(): Response<ApiResponse<List<UserSummaryDto>>>

    @PUT("api/v1/companies/employees/{id}/permissions")
    suspend fun updateEmployeePermissions(
        @Path("id") id: Long,
        @Body request: com.example.data.api.model.UpdateEmployeePermissionsRequest
    ): Response<ApiResponse<UserSummaryDto>>

    @GET("api/v1/companies/all")
    suspend fun getAllCompanies(): Response<ApiResponse<List<CompanySummaryDto>>>

    // =========================================================================
    // BUSINESS PROFILE & BANKING SETTINGS
    // =========================================================================

    @GET("api/v1/profile")
    suspend fun getProfile(): Response<ApiResponse<BackendBusinessProfileDto>>

    @PUT("api/v1/profile")
    suspend fun updateProfile(
        @Body profile: BackendBusinessProfileDto
    ): Response<ApiResponse<BackendBusinessProfileDto>>
}
