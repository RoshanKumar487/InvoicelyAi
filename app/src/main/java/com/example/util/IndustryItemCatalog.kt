package com.example.util

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountBalance
import androidx.compose.material.icons.filled.Business
import androidx.compose.material.icons.filled.Code
import androidx.compose.material.icons.filled.LocalShipping
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Security
import androidx.compose.material.icons.filled.ShoppingBag
import androidx.compose.ui.graphics.vector.ImageVector
import com.example.data.model.InvoiceItem

data class DomainPresetCategory(
    val id: String,
    val name: String,
    val shortLabel: String,
    val description: String,
    val icon: ImageVector,
    val colorHex: Long,
    val items: List<CatalogItemDef>
)

data class CatalogItemDef(
    val description: String,
    val quantity: Double,
    val unitPrice: Double,
    val unit: String,
    val taxRate: Double = 18.0,
    val hsnOrSac: String = "",
    val subtitle: String = "",
    val customFields: Map<String, String> = emptyMap()
) {
    fun toInvoiceItem(): InvoiceItem {
        val fields = customFields.toMutableMap()
        if (hsnOrSac.isNotBlank()) {
            fields["hsn"] = hsnOrSac
            fields["sac"] = hsnOrSac
        }
        return InvoiceItem(
            description = description,
            quantity = quantity,
            unitPrice = unitPrice,
            unit = unit,
            taxRate = taxRate,
            customFields = fields
        )
    }
}

object IndustryItemCatalog {

    val categories: List<DomainPresetCategory> = listOf(
        DomainPresetCategory(
            id = "security_agency",
            name = "Security Agency & Guard Services",
            shortLabel = "Security Agency",
            description = "Monthly bills for deployed guards, gunmen, supervisors, 8h/12h shifts, and EPF/ESI",
            icon = Icons.Default.Security,
            colorHex = 0xFF4338CA,
            items = listOf(
                CatalogItemDef(
                    description = "Security Guard (12-Hour Shift - Day/Night)",
                    quantity = 26.0,
                    unitPrice = 750.0,
                    unit = "days",
                    taxRate = 18.0,
                    hsnOrSac = "998525",
                    subtitle = "Standard 12h duty • 26 days month",
                    customFields = mapOf("shift" to "12 Hours")
                ),
                CatalogItemDef(
                    description = "Security Guard (8-Hour Shift)",
                    quantity = 26.0,
                    unitPrice = 550.0,
                    unit = "days",
                    taxRate = 18.0,
                    hsnOrSac = "998525",
                    subtitle = "Standard 8h duty • 26 days month",
                    customFields = mapOf("shift" to "8 Hours")
                ),
                CatalogItemDef(
                    description = "Armed Security Guard (Gunman)",
                    quantity = 1.0,
                    unitPrice = 28000.0,
                    unit = "month",
                    taxRate = 18.0,
                    hsnOrSac = "998525",
                    subtitle = "Licensed armed guard deployment",
                    customFields = mapOf("designation" to "Gunman")
                ),
                CatalogItemDef(
                    description = "Security Supervisor / Field Officer",
                    quantity = 1.0,
                    unitPrice = 22000.0,
                    unit = "month",
                    taxRate = 18.0,
                    hsnOrSac = "998525",
                    subtitle = "Site inspection & muster management",
                    customFields = mapOf("designation" to "Supervisor")
                ),
                CatalogItemDef(
                    description = "Housekeeping & Facility Cleaning Staff",
                    quantity = 26.0,
                    unitPrice = 500.0,
                    unit = "days",
                    taxRate = 18.0,
                    hsnOrSac = "998533",
                    subtitle = "Commercial office & campus cleaning",
                    customFields = mapOf("shift" to "8 Hours")
                ),
                CatalogItemDef(
                    description = "Security Guard Overtime (OT Hours)",
                    quantity = 30.0,
                    unitPrice = 85.0,
                    unit = "hrs",
                    taxRate = 18.0,
                    hsnOrSac = "998525",
                    subtitle = "Additional shift & emergency hours",
                    customFields = mapOf("shift" to "Overtime")
                ),
                CatalogItemDef(
                    description = "Reliever Guard Charges (Night Duty)",
                    quantity = 4.0,
                    unitPrice = 750.0,
                    unit = "days",
                    taxRate = 18.0,
                    hsnOrSac = "998525",
                    subtitle = "Weekend / Leave replacement guard",
                    customFields = mapOf("shift" to "Reliever")
                ),
                CatalogItemDef(
                    description = "Agency Supervision & Service Charge (10%)",
                    quantity = 1.0,
                    unitPrice = 3500.0,
                    unit = "month",
                    taxRate = 18.0,
                    hsnOrSac = "998529",
                    subtitle = "Management, uniform & equipment admin fee"
                ),
                CatalogItemDef(
                    description = "Statutory EPF & ESIC Compliance Reimbursement",
                    quantity = 1.0,
                    unitPrice = 2800.0,
                    unit = "month",
                    taxRate = 18.0,
                    hsnOrSac = "998529",
                    subtitle = "Employer statutory contribution at actuals"
                )
            )
        ),

        DomainPresetCategory(
            id = "hr_staffing",
            name = "Employee Salary & HR Staffing",
            shortLabel = "Employee / HR Salary",
            description = "Monthly staff salary reimbursement, attendance days/hours, OT, and placement",
            icon = Icons.Default.Person,
            colorHex = 0xFF0D9488,
            items = listOf(
                CatalogItemDef(
                    description = "Monthly Staff Salary Reimbursement (Contract Team)",
                    quantity = 1.0,
                    unitPrice = 30000.0,
                    unit = "month",
                    taxRate = 18.0,
                    hsnOrSac = "998519",
                    subtitle = "Monthly contractual workforce salary",
                    customFields = mapOf("billing_type" to "Monthly Retainer")
                ),
                CatalogItemDef(
                    description = "Contract Staff Attendance Billing (Days Worked)",
                    quantity = 26.0,
                    unitPrice = 1200.0,
                    unit = "days",
                    taxRate = 18.0,
                    hsnOrSac = "998519",
                    subtitle = "Calculated per muster roll attendance",
                    customFields = mapOf("muster" to "Verified")
                ),
                CatalogItemDef(
                    description = "Consultant / Developer Hourly Billing",
                    quantity = 160.0,
                    unitPrice = 750.0,
                    unit = "hrs",
                    taxRate = 18.0,
                    hsnOrSac = "998314",
                    subtitle = "Approved timesheet billing • 160 hours",
                    customFields = mapOf("timesheet" to "Approved")
                ),
                CatalogItemDef(
                    description = "Employee Overtime (OT) Allowance",
                    quantity = 25.0,
                    unitPrice = 220.0,
                    unit = "hrs",
                    taxRate = 18.0,
                    hsnOrSac = "998519",
                    subtitle = "Approved weekend & late night hours"
                ),
                CatalogItemDef(
                    description = "Statutory Employer EPF (12%) & ESI (3.25%) Contribution",
                    quantity = 1.0,
                    unitPrice = 4800.0,
                    unit = "month",
                    taxRate = 18.0,
                    hsnOrSac = "998519",
                    subtitle = "Mandatory government compliance contribution"
                ),
                CatalogItemDef(
                    description = "HR Recruitment & Placement Success Fee",
                    quantity = 1.0,
                    unitPrice = 45000.0,
                    unit = "candidate",
                    taxRate = 18.0,
                    hsnOrSac = "998512",
                    subtitle = "Permanent hire placement fee (8.33% CTC)"
                ),
                CatalogItemDef(
                    description = "Monthly Payroll Processing & Admin Service Fee",
                    quantity = 10.0,
                    unitPrice = 350.0,
                    unit = "person",
                    taxRate = 18.0,
                    hsnOrSac = "998519",
                    subtitle = "Per-employee payroll software & payslip fee"
                )
            )
        ),

        DomainPresetCategory(
            id = "it_software",
            name = "IT, Software & Freelance Agency",
            shortLabel = "IT & Software",
            description = "Software engineering, UI/UX design, cloud devops, and monthly AMC",
            icon = Icons.Default.Code,
            colorHex = 0xFF2563EB,
            items = listOf(
                CatalogItemDef(
                    description = "Senior Full-Stack Software Engineer (Monthly Retainer)",
                    quantity = 1.0,
                    unitPrice = 65000.0,
                    unit = "month",
                    taxRate = 18.0,
                    hsnOrSac = "998313",
                    subtitle = "Dedicated engineer • 160 hrs monthly"
                ),
                CatalogItemDef(
                    description = "UI/UX Product Design & Interactive Prototyping",
                    quantity = 40.0,
                    unitPrice = 1200.0,
                    unit = "hrs",
                    taxRate = 18.0,
                    hsnOrSac = "998314",
                    subtitle = "Figma design system & user workflows"
                ),
                CatalogItemDef(
                    description = "Annual Application Maintenance & Support (AMC)",
                    quantity = 1.0,
                    unitPrice = 15000.0,
                    unit = "month",
                    taxRate = 18.0,
                    hsnOrSac = "998315",
                    subtitle = "99.9% uptime SLA, bug fixes & updates"
                ),
                CatalogItemDef(
                    description = "Cloud Infrastructure & DevOps Setup",
                    quantity = 1.0,
                    unitPrice = 25000.0,
                    unit = "project",
                    taxRate = 18.0,
                    hsnOrSac = "998315",
                    subtitle = "Kubernetes, CI/CD pipeline, and AWS deployment"
                )
            )
        ),

        DomainPresetCategory(
            id = "transport_logistics",
            name = "Transport & Logistics Services",
            shortLabel = "Transport & Logistics",
            description = "Freight per trip/km, loading/unloading, and fleet transport",
            icon = Icons.Default.LocalShipping,
            colorHex = 0xFFD97706,
            items = listOf(
                CatalogItemDef(
                    description = "Goods Freight & Vehicle Transportation (Full Load)",
                    quantity = 1.0,
                    unitPrice = 18000.0,
                    unit = "trip",
                    taxRate = 5.0,
                    hsnOrSac = "996511",
                    subtitle = "Full truckload dedicated transport"
                ),
                CatalogItemDef(
                    description = "Local Dispatch & Fleet Delivery (Per Km)",
                    quantity = 150.0,
                    unitPrice = 38.0,
                    unit = "km",
                    taxRate = 5.0,
                    hsnOrSac = "996511",
                    subtitle = "Metered GPS trip transit rate"
                ),
                CatalogItemDef(
                    description = "Loading, Unloading & Labour Handling Charges",
                    quantity = 1.0,
                    unitPrice = 2500.0,
                    unit = "trip",
                    taxRate = 18.0,
                    hsnOrSac = "996511",
                    subtitle = "Warehouse dock ground team handling"
                )
            )
        ),

        DomainPresetCategory(
            id = "construction_labour",
            name = "Construction & Contracting Work",
            shortLabel = "Construction & Labour",
            description = "Civil contracting, sq.ft tiling/plastering, and skilled/unskilled man-days",
            icon = Icons.Default.AccountBalance,
            colorHex = 0xFF7C3AED,
            items = listOf(
                CatalogItemDef(
                    description = "Civil Construction / Finishing Work",
                    quantity = 500.0,
                    unitPrice = 350.0,
                    unit = "sqft",
                    taxRate = 18.0,
                    hsnOrSac = "995411",
                    subtitle = "Commercial floor installation & civil finish"
                ),
                CatalogItemDef(
                    description = "Skilled Mason / Carpenter Labour Man-days",
                    quantity = 26.0,
                    unitPrice = 900.0,
                    unit = "days",
                    taxRate = 18.0,
                    hsnOrSac = "995419",
                    subtitle = "Master craftsman daily attendance"
                ),
                CatalogItemDef(
                    description = "Unskilled Helper Labour Man-days",
                    quantity = 26.0,
                    unitPrice = 550.0,
                    unit = "days",
                    taxRate = 18.0,
                    hsnOrSac = "995419",
                    subtitle = "Site assistance & material movement"
                )
            )
        ),

        DomainPresetCategory(
            id = "retail_wholesale",
            name = "Retail & Wholesale Trading",
            shortLabel = "Trading & Retail",
            description = "Standard commercial goods, inventory cartons, and merchandise",
            icon = Icons.Default.ShoppingBag,
            colorHex = 0xFF059669,
            items = listOf(
                CatalogItemDef(
                    description = "Standard Commercial Goods Consignment",
                    quantity = 100.0,
                    unitPrice = 180.0,
                    unit = "pcs",
                    taxRate = 18.0,
                    hsnOrSac = "847130",
                    subtitle = "Packaged unit consignment"
                ),
                CatalogItemDef(
                    description = "Master Packaging Box / Cartons",
                    quantity = 10.0,
                    unitPrice = 1450.0,
                    unit = "box",
                    taxRate = 12.0,
                    hsnOrSac = "481910",
                    subtitle = "Corrugated protective shipping container"
                )
            )
        )
    )

    fun getAllItems(): List<CatalogItemDef> {
        return categories.flatMap { it.items }
    }
}
