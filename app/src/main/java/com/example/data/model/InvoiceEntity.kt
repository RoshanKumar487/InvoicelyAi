package com.example.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "invoices")
data class InvoiceEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val invoiceNumber: String,
    val clientId: Long? = null,
    val clientName: String,
    val clientCompany: String = "",
    val clientEmail: String = "",
    val clientPhone: String = "",
    val clientAddress: String = "",
    val clientTaxId: String = "",
    val issueDate: String, // YYYY-MM-DD
    val dueDate: String,   // YYYY-MM-DD
    val poNumber: String = "",
    val paymentTerms: String = "Net 30", // "Due on Receipt", "Net 15", "Net 30", "Net 60", "Custom"
    val currencyCode: String = "USD",
    val currencySymbol: String = "$",
    val itemsJson: String = "[]",
    val notes: String = "",
    val terms: String = "",
    val paymentInstructions: String = "",
    val taxRate: Double = 0.0,
    val taxLabel: String = "Tax",
    val discountPercent: Double = 0.0,
    val discountAmount: Double = 0.0,
    val shippingFee: Double = 0.0,
    val amountPaid: Double = 0.0,
    val status: String = "Draft", // "Draft", "Sent", "Paid", "Overdue", "Cancelled"
    val templateId: String = "modern", // "modern", "corporate", "creative", "compact"
    val docxTemplateTitle: String = "INVOICE",
    val createdAt: Long = System.currentTimeMillis(),
    val paidDate: Long? = null,
    val reminderLastSent: Long? = null,
    val shippingDetailsJson: String = "{}",
    val customFieldsJson: String = "{}",
    val itemColumnsJson: String = "",
    val additionalCharges: Double = 0.0,
    val roundOff: Double = 0.0,
    val isTaxInclusive: Boolean = false,
    val taxType: String = "GST",
    val companyId: Long? = null,
    val createdByUserId: Long? = null,
    val createdByUserName: String? = null
)

data class InvoiceItem(
    val id: String = java.util.UUID.randomUUID().toString(),
    val description: String = "",
    val quantity: Double = 1.0,
    val unitPrice: Double = 0.0,
    val unit: String = "hrs", // "hrs", "pcs", "units", "days", "services"
    val taxRate: Double = 0.0,
    val discountRate: Double = 0.0,
    val customFields: Map<String, String> = emptyMap()
) {
    /** Total line item amount after item-level discount, before taxes */
    val total: Double
        get() = (quantity * unitPrice) * (1.0 - (discountRate / 100.0))

    /** Discount amount applied on this line item */
    val discountAmount: Double
        get() = (quantity * unitPrice) * (discountRate / 100.0)

    /** Tax amount calculated for this specific line item */
    val taxAmount: Double
        get() = total * (taxRate / 100.0)

    /** Gross total including item-level tax */
    val grossTotal: Double
        get() = total + taxAmount
}

data class InvoiceCalculations(
    val subtotal: Double,
    val discountTotal: Double,
    val taxTotal: Double,
    val shipping: Double,
    val grandTotal: Double,
    val amountPaid: Double,
    val balanceDue: Double,
    val additionalCharges: Double = 0.0,
    val roundOff: Double = 0.0
)
