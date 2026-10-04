package com.example.data.model

import androidx.compose.ui.graphics.Color

enum class UserRole(
    val title: String,
    val shortBadge: String,
    val badgeBgColor: Color,
    val badgeFgColor: Color,
    val description: String
) {
    DEVELOPER(
        title = "Platform Developer",
        shortBadge = "⚡ DEVELOPER",
        badgeBgColor = Color(0xFFF3E8FF),
        badgeFgColor = Color(0xFF7E22CE),
        description = "Global platform access across all organizations and system data"
    ),
    ADMIN(
        title = "Organization Admin",
        shortBadge = "👑 ADMIN",
        badgeBgColor = Color(0xFFDBEAFE),
        badgeFgColor = Color(0xFF1D4ED8),
        description = "Full control over organization data, banking, settings, and staff approvals"
    ),
    EMPLOYEE(
        title = "Team Employee",
        shortBadge = "👤 EMPLOYEE",
        badgeBgColor = Color(0xFFD1FAE5),
        badgeFgColor = Color(0xFF047857),
        description = "Operational access to log expenses, create invoices, and use business tools"
    );

    val canManageCompanySettings: Boolean get() = this == ADMIN || this == DEVELOPER
    val canApproveJoinRequests: Boolean get() = this == ADMIN || this == DEVELOPER
    val canViewGlobalOrganizations: Boolean get() = this == DEVELOPER
    val canAddExpenses: Boolean get() = true
    val canCreateInvoices: Boolean get() = true
}

data class UserAccount(
    val id: Long,
    val fullName: String,
    val email: String,
    val mobile: String = "",
    val role: UserRole,
    val status: String = "ACTIVE", // ACTIVE, PENDING_APPROVAL, REJECTED
    val companyId: Long? = null,
    val companyName: String? = null,
    val companyCode: String? = null,
    val permissions: String = "INVOICES,EXPENSES,CLIENTS,REPORTS"
) {
    /** Checks whether this user has access to a specific tool/feature */
    fun canAccessFeature(feature: String): Boolean {
        if (role == UserRole.ADMIN || role == UserRole.DEVELOPER) return true
        val list = permissions.split(",").map { it.trim().uppercase() }
        return list.contains(feature.trim().uppercase())
    }
}

data class CompanyInfo(
    val id: Long,
    val companyCode: String,
    val companyName: String,
    val gstin: String = "",
    val location: String = "",
    val details: String = "",
    val email: String = "",
    val phone: String = ""
)

data class EmployeeJoinRequest(
    val id: Long,
    val userId: Long,
    val userFullName: String,
    val userEmail: String,
    val userMobile: String = "",
    val companyId: Long,
    val companyName: String,
    val companyCode: String,
    val status: String = "PENDING", // PENDING, APPROVED, REJECTED
    val requestMessage: String = "",
    val requestedDate: String = "Just now"
)
