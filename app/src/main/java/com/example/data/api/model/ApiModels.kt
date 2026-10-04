package com.example.data.api.model

import com.example.data.model.BusinessProfile
import com.example.data.model.ClientEntity
import com.example.data.model.CompanyInfo
import com.example.data.model.EmployeeJoinRequest
import com.example.data.model.ExpenseEntity
import com.example.data.model.InvoiceEntity
import com.example.data.model.UserAccount
import com.example.data.model.UserRole
import java.util.Locale

/**
 * Standard generic response envelope matching Spring Boot ApiResponse<T>.
 */
data class ApiResponse<T>(
    val success: Boolean = false,
    val message: String? = null,
    val data: T? = null,
    val timestamp: Long = System.currentTimeMillis()
)

// =========================================================================
// AUTH REQUEST & RESPONSE MODELS
// =========================================================================

data class LoginRequest(
    val identifier: String,
    val password: String
)

data class RegisterCompanyRequest(
    val fullName: String,
    val email: String,
    val mobile: String = "",
    val password: String,
    val companyName: String,
    val gstin: String = "",
    val location: String = "",
    val details: String = ""
)

data class RegisterEmployeeRequest(
    val fullName: String,
    val email: String,
    val mobile: String = "",
    val password: String,
    val companyCode: String,
    val message: String = ""
)

data class RegisterDeveloperRequest(
    val fullName: String,
    val email: String,
    val mobile: String = "",
    val password: String,
    @com.squareup.moshi.Json(name = "developerSecretKey")
    val developerSecretKey: String = "",
    val secretKey: String = developerSecretKey
)

data class ResetPasswordRequest(
    val identifier: String,
    val newPassword: String
)

data class AuthResponseDto(
    val token: String? = null,
    val tokenType: String = "Bearer",
    val user: UserSummaryDto? = null,
    val company: CompanySummaryDto? = null,
    val message: String? = null
)

data class UserSummaryDto(
    val id: Long = 0L,
    val fullName: String = "",
    val email: String = "",
    val mobile: String = "",
    val role: String = "EMPLOYEE",
    val status: String = "ACTIVE",
    val companyId: Long? = null,
    val permissions: String? = "INVOICES,EXPENSES,CLIENTS,REPORTS"
) {
    fun toUserAccount(companyCode: String? = null, companyName: String? = null): UserAccount {
        val userRole = try {
            UserRole.valueOf(role.uppercase(Locale.ROOT))
        } catch (_: Exception) {
            when {
                role.contains("DEV", ignoreCase = true) -> UserRole.DEVELOPER
                role.contains("ADMIN", ignoreCase = true) -> UserRole.ADMIN
                else -> UserRole.EMPLOYEE
            }
        }
        return UserAccount(
            id = id,
            fullName = fullName,
            email = email,
            mobile = mobile,
            role = userRole,
            status = status,
            companyId = companyId,
            companyName = companyName,
            companyCode = companyCode,
            permissions = permissions ?: "INVOICES,EXPENSES,CLIENTS,REPORTS"
        )
    }
}

data class CompanySummaryDto(
    val id: Long = 0L,
    val companyCode: String = "",
    val companyName: String = "",
    val gstin: String = "",
    val location: String = "",
    val details: String = "",
    val email: String = "",
    val phone: String = "",
    val totalEmployees: Int = 0,
    val activeInvoicesCount: Int = 0
) {
    fun toCompanyInfo(): CompanyInfo {
        return CompanyInfo(
            id = id,
            companyCode = companyCode,
            companyName = companyName,
            gstin = gstin,
            location = location,
            details = details,
            email = email,
            phone = phone
        )
    }
}

data class CompanyJoinRequestDto(
    val id: Long = 0L,
    val userId: Long = 0L,
    val userFullName: String = "",
    val userEmail: String = "",
    val userMobile: String = "",
    val companyId: Long = 0L,
    val companyName: String = "",
    val companyCode: String = "",
    val status: String = "PENDING",
    val requestMessage: String = "",
    val requestedDate: String = "",
    val resolvedDate: String? = null,
    val resolvedBy: String? = null
) {
    fun toEmployeeJoinRequest(): EmployeeJoinRequest {
        return EmployeeJoinRequest(
            id = id,
            userId = userId,
            userFullName = userFullName,
            userEmail = userEmail,
            userMobile = userMobile,
            companyId = companyId,
            companyName = companyName,
            companyCode = companyCode,
            status = status,
            requestMessage = requestMessage,
            requestedDate = requestedDate.ifBlank { "Recent" }
        )
    }
}

data class JoinRequestActionRequest(
    val action: String // "APPROVE" or "REJECT"
)

// =========================================================================
// DASHBOARD STATS
// =========================================================================

data class DashboardStatsResponse(
    val totalInvoices: Long = 0L,
    val paidInvoices: Long = 0L,
    val overdueInvoices: Long = 0L,
    val draftInvoices: Long = 0L,
    val totalRevenue: Double = 0.0,
    val outstandingAmount: Double = 0.0,
    val totalExpenses: Double = 0.0,
    val totalClients: Long = 0L
)

// =========================================================================
// CLIENT DTO & EXTENSIONS
// =========================================================================

data class BackendClientDto(
    val id: Long? = null,
    val companyId: Long? = null,
    val name: String = "",
    val companyName: String = "",
    val email: String = "",
    val phone: String = "",
    val address: String = "",
    val taxId: String = "",
    val preferredCurrency: String = "USD",
    val defaultPaymentTerms: String = "Net 30",
    val notes: String = "",
    val createdAt: Long = System.currentTimeMillis()
) {
    fun toEntity(): ClientEntity {
        return ClientEntity(
            id = id ?: 0L,
            name = name,
            companyName = companyName,
            email = email,
            phone = phone,
            address = address,
            taxId = taxId,
            preferredCurrency = preferredCurrency,
            defaultPaymentTerms = defaultPaymentTerms,
            notes = notes,
            createdAt = createdAt
        )
    }
}

fun ClientEntity.toBackendDto(): BackendClientDto {
    return BackendClientDto(
        id = if (id > 0) id else null,
        name = name,
        companyName = companyName,
        email = email,
        phone = phone,
        address = address,
        taxId = taxId,
        preferredCurrency = preferredCurrency,
        defaultPaymentTerms = defaultPaymentTerms,
        notes = notes,
        createdAt = createdAt
    )
}

// =========================================================================
// EXPENSE DTO & EXTENSIONS
// =========================================================================

data class BackendExpenseDto(
    val id: Long? = null,
    val companyId: Long? = null,
    val createdByUserId: Long? = null,
    val createdByUserName: String? = null,
    val title: String = "",
    val category: String = "General",
    val amount: Double = 0.0,
    val currency: String = "USD",
    val currencySymbol: String = "$",
    val date: String = "",
    val vendor: String = "",
    val paymentMethod: String = "Credit Card",
    val taxDeductible: Boolean = true,
    val taxAmount: Double = 0.0,
    val receiptImageUri: String? = null,
    val notes: String = ""
) {
    fun toEntity(): ExpenseEntity {
        return ExpenseEntity(
            id = id ?: 0L,
            title = title,
            category = category,
            amount = amount,
            currency = currency,
            currencySymbol = currencySymbol,
            date = date,
            vendor = vendor,
            paymentMethod = paymentMethod,
            taxDeductible = taxDeductible,
            taxAmount = taxAmount,
            receiptImageUri = receiptImageUri,
            notes = notes,
            companyId = companyId,
            createdByUserId = createdByUserId,
            createdByUserName = createdByUserName
        )
    }
}

fun ExpenseEntity.toBackendDto(): BackendExpenseDto {
    return BackendExpenseDto(
        id = if (id > 0) id else null,
        companyId = companyId,
        createdByUserId = createdByUserId,
        createdByUserName = createdByUserName,
        title = title,
        category = category,
        amount = amount,
        currency = currency,
        currencySymbol = currencySymbol,
        date = date,
        vendor = vendor,
        paymentMethod = paymentMethod,
        taxDeductible = taxDeductible,
        taxAmount = taxAmount,
        receiptImageUri = receiptImageUri,
        notes = notes
    )
}

// =========================================================================
// INVOICE DTO & EXTENSIONS
// =========================================================================

data class BackendInvoiceDto(
    val id: Long? = null,
    val companyId: Long? = null,
    val createdByUserId: Long? = null,
    val createdByUserName: String? = null,
    val invoiceNumber: String = "",
    val clientId: Long? = null,
    val clientName: String = "",
    val clientCompany: String = "",
    val clientEmail: String = "",
    val clientPhone: String = "",
    val clientAddress: String = "",
    val clientTaxId: String = "",
    val issueDate: String = "",
    val dueDate: String = "",
    val poNumber: String = "",
    val paymentTerms: String = "Net 30",
    val currencyCode: String = "USD",
    val currencySymbol: String = "$",
    val itemsJson: String = "[]",
    val notes: String = "",
    val terms: String = "",
    val paymentInstructions: String = "",
    val taxRate: Double = 0.0,
    val taxLabel: String = "Tax",
    val taxType: String = "GST",
    val isTaxInclusive: Boolean = false,
    val discountPercent: Double = 0.0,
    val discountAmount: Double = 0.0,
    val shippingFee: Double = 0.0,
    val additionalCharges: Double = 0.0,
    val roundOff: Double = 0.0,
    val amountPaid: Double = 0.0,
    val status: String = "Draft",
    val templateId: String = "gst_tax"
) {
    fun toEntity(): InvoiceEntity {
        return InvoiceEntity(
            id = id ?: 0L,
            invoiceNumber = invoiceNumber,
            clientId = clientId,
            clientName = clientName,
            clientCompany = clientCompany,
            clientEmail = clientEmail,
            clientPhone = clientPhone,
            clientAddress = clientAddress,
            clientTaxId = clientTaxId,
            issueDate = issueDate,
            dueDate = dueDate,
            poNumber = poNumber,
            paymentTerms = paymentTerms,
            currencyCode = currencyCode,
            currencySymbol = currencySymbol,
            itemsJson = itemsJson,
            notes = notes,
            terms = terms,
            paymentInstructions = paymentInstructions,
            taxRate = taxRate,
            taxLabel = taxLabel,
            taxType = taxType,
            isTaxInclusive = isTaxInclusive,
            discountPercent = discountPercent,
            discountAmount = discountAmount,
            shippingFee = shippingFee,
            additionalCharges = additionalCharges,
            roundOff = roundOff,
            amountPaid = amountPaid,
            status = status,
            templateId = templateId,
            companyId = companyId,
            createdByUserId = createdByUserId,
            createdByUserName = createdByUserName
        )
    }
}

fun InvoiceEntity.toBackendDto(): BackendInvoiceDto {
    return BackendInvoiceDto(
        id = if (id > 0) id else null,
        companyId = companyId,
        createdByUserId = createdByUserId,
        createdByUserName = createdByUserName,
        invoiceNumber = invoiceNumber,
        clientId = clientId,
        clientName = clientName,
        clientCompany = clientCompany,
        clientEmail = clientEmail,
        clientPhone = clientPhone,
        clientAddress = clientAddress,
        clientTaxId = clientTaxId,
        issueDate = issueDate,
        dueDate = dueDate,
        poNumber = poNumber,
        paymentTerms = paymentTerms,
        currencyCode = currencyCode,
        currencySymbol = currencySymbol,
        itemsJson = itemsJson,
        notes = notes,
        terms = terms,
        paymentInstructions = paymentInstructions,
        taxRate = taxRate,
        taxLabel = taxLabel,
        taxType = taxType,
        isTaxInclusive = isTaxInclusive,
        discountPercent = discountPercent,
        discountAmount = discountAmount,
        shippingFee = shippingFee,
        additionalCharges = additionalCharges,
        roundOff = roundOff,
        amountPaid = amountPaid,
        status = status,
        templateId = templateId
    )
}

// =========================================================================
// BUSINESS PROFILE DTO & EXTENSIONS
// =========================================================================

data class BackendBusinessProfileDto(
    val id: Int? = null,
    val companyId: Long? = null,
    val businessName: String = "",
    val legalName: String = "",
    val email: String = "",
    val phone: String = "",
    val website: String = "",
    val address: String = "",
    val taxId: String = "",
    val gstin: String = "",
    val panNumber: String = "",
    val placeOfSupply: String = "",
    val upiId: String = "",
    val bankName: String = "",
    val accountHolder: String = "",
    val accountNumber: String = "",
    val ifscCode: String = "",
    val routingNumber: String = "",
    val swiftBic: String = "",
    val paymentLink: String = "",
    val defaultCurrency: String = "INR",
    val defaultCurrencySymbol: String = "₹",
    val defaultCurrencyFormat: String = "before",
    val defaultTaxRate: Double = 0.0,
    val defaultTaxLabel: String = "Tax",
    val defaultPaymentTerms: String = "Net 30",
    val defaultNotes: String = "",
    val defaultTerms: String = "",
    val signeeName: String = "",
    val signeeTitle: String = "",
    val brandColorHex: String = "#1E3A8A"
) {
    fun toEntity(base: BusinessProfile = BusinessProfile()): BusinessProfile {
        return base.copy(
            id = id ?: base.id,
            businessName = businessName.ifBlank { base.businessName },
            legalName = legalName.ifBlank { base.legalName },
            email = email.ifBlank { base.email },
            phone = phone.ifBlank { base.phone },
            website = website.ifBlank { base.website },
            address = address.ifBlank { base.address },
            taxId = taxId.ifBlank { base.taxId },
            gstin = gstin.ifBlank { base.gstin },
            panNumber = panNumber.ifBlank { base.panNumber },
            placeOfSupply = placeOfSupply.ifBlank { base.placeOfSupply },
            upiId = upiId.ifBlank { base.upiId },
            bankName = bankName.ifBlank { base.bankName },
            accountHolder = accountHolder.ifBlank { base.accountHolder },
            accountNumber = accountNumber.ifBlank { base.accountNumber },
            ifscCode = ifscCode.ifBlank { base.ifscCode },
            routingNumber = routingNumber.ifBlank { base.routingNumber },
            swiftBic = swiftBic.ifBlank { base.swiftBic },
            paymentLink = paymentLink.ifBlank { base.paymentLink },
            defaultCurrency = defaultCurrency.ifBlank { base.defaultCurrency },
            defaultCurrencySymbol = defaultCurrencySymbol.ifBlank { base.defaultCurrencySymbol },
            defaultCurrencyFormat = defaultCurrencyFormat.ifBlank { base.defaultCurrencyFormat },
            defaultTaxRate = defaultTaxRate,
            defaultTaxLabel = defaultTaxLabel.ifBlank { base.defaultTaxLabel },
            defaultPaymentTerms = defaultPaymentTerms.ifBlank { base.defaultPaymentTerms },
            defaultNotes = defaultNotes.ifBlank { base.defaultNotes },
            defaultTerms = defaultTerms.ifBlank { base.defaultTerms },
            signeeName = signeeName.ifBlank { base.signeeName },
            signeeTitle = signeeTitle.ifBlank { base.signeeTitle },
            brandColorHex = brandColorHex.ifBlank { base.brandColorHex }
        )
    }
}

fun BusinessProfile.toBackendDto(): BackendBusinessProfileDto {
    return BackendBusinessProfileDto(
        id = id,
        businessName = businessName,
        legalName = legalName,
        email = email,
        phone = phone,
        website = website,
        address = address,
        taxId = taxId,
        gstin = gstin,
        panNumber = panNumber,
        placeOfSupply = placeOfSupply,
        upiId = upiId,
        bankName = bankName,
        accountHolder = accountHolder,
        accountNumber = accountNumber,
        ifscCode = ifscCode,
        routingNumber = routingNumber,
        swiftBic = swiftBic,
        paymentLink = paymentLink,
        defaultCurrency = defaultCurrency,
        defaultCurrencySymbol = defaultCurrencySymbol,
        defaultCurrencyFormat = defaultCurrencyFormat,
        defaultTaxRate = defaultTaxRate,
        defaultTaxLabel = defaultTaxLabel,
        defaultPaymentTerms = defaultPaymentTerms,
        defaultNotes = defaultNotes,
        defaultTerms = defaultTerms,
        signeeName = signeeName,
        signeeTitle = signeeTitle,
        brandColorHex = brandColorHex
    )
}

// =========================================================================
// DEVELOPER OVERVIEW & ROLE PERMISSIONS MODELS
// =========================================================================

data class UpdateEmployeePermissionsRequest(
    val permissions: String
)

data class CompanyPlatformStatsDto(
    val companyId: Long? = null,
    val companyCode: String = "",
    val companyName: String = "",
    val email: String = "",
    val location: String = "",
    val userCount: Long = 0L,
    val invoiceCount: Long = 0L,
    val expenseCount: Long = 0L,
    val totalRevenue: Double = 0.0,
    val totalExpenses: Double = 0.0
)

data class DeveloperOverviewDto(
    val totalCompanies: Long = 0L,
    val totalUsers: Long = 0L,
    val totalInvoices: Long = 0L,
    val totalExpenses: Long = 0L,
    val totalPlatformRevenue: Double = 0.0,
    val totalPlatformExpenses: Double = 0.0,
    val companies: List<CompanyPlatformStatsDto> = emptyList()
)
