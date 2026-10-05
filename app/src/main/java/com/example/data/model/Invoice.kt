package com.example.data.model

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Status of an invoice throughout its lifecycle.
 */
enum class InvoiceStatus(val displayName: String) {
    DRAFT("Draft"),
    SENT("Sent"),
    PAID("Paid"),
    OVERDUE("Overdue"),
    CANCELLED("Cancelled");

    companion object {
        fun fromString(value: String): InvoiceStatus {
            return entries.find { 
                it.name.equals(value, ignoreCase = true) || it.displayName.equals(value, ignoreCase = true) 
            } ?: DRAFT
        }
    }
}

/**
 * Domain model representing a structured Invoice.
 * Encapsulates client details, currency, itemization (InvoiceItem), tax rates, discount,
 * payment instructions, lifecycle status, and calculated financial summaries.
 */
data class Invoice(
    val id: Long = 0,
    val invoiceNumber: String,
    val clientId: Long? = null,
    val clientName: String,
    val clientCompany: String = "",
    val clientEmail: String = "",
    val clientPhone: String = "",
    val clientAddress: String = "",
    val clientTaxId: String = "",
    val issueDate: String = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date()),
    val dueDate: String = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date(System.currentTimeMillis() + 30L * 86400000L)),
    val poNumber: String = "",
    val paymentTerms: String = "Net 30",
    val currency: String = "USD",
    val currencySymbol: String = "$",
    val taxRate: Double = 0.0,
    val taxLabel: String = "Tax",
    val discountPercent: Double = 0.0,
    val discountAmount: Double = 0.0,
    val shippingFee: Double = 0.0,
    val amountPaid: Double = 0.0,
    val status: InvoiceStatus = InvoiceStatus.DRAFT,
    val items: List<InvoiceItem> = emptyList(),
    val notes: String = "",
    val terms: String = "",
    val paymentInstructions: String = "",
    val templateId: String = "gst_tax",
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
    val isRcm: Boolean = false
) {
    // =========================================================================
    // Dynamic Calculation Helpers
    // =========================================================================

    /** Subtotal before taxes and order-level discounts */
    val subtotal: Double
        get() = items.sumOf { it.quantity * it.unitPrice }

    /** Sum of all line-item discounts */
    val itemDiscounts: Double
        get() = items.sumOf { (it.quantity * it.unitPrice) * (it.discountRate / 100.0) }

    /** Percentage-based invoice level discount */
    val percentageDiscountAmount: Double
        get() = (subtotal - itemDiscounts) * (discountPercent / 100.0)

    /** Total discount applied to this invoice */
    val totalDiscount: Double
        get() = itemDiscounts + percentageDiscountAmount + discountAmount

    /** Amount subject to tax */
    val taxableAmount: Double
        get() = maxOf(0.0, subtotal - totalDiscount)

    /** Sum of tax calculated from individual items with distinct tax rates */
    val itemTaxTotal: Double
        get() = items.sumOf { item ->
            val itemTaxable = (item.quantity * item.unitPrice) * (1.0 - (item.discountRate / 100.0))
            itemTaxable * (item.taxRate / 100.0)
        }

    /** Total tax amount (uses item-level tax if present, otherwise invoice-level taxRate) */
    val taxAmount: Double
        get() = if (itemTaxTotal > 0) itemTaxTotal else taxableAmount * (taxRate / 100.0)

    /** Grand total = taxable amount + tax + shipping */
    val grandTotal: Double
        get() = maxOf(0.0, taxableAmount + taxAmount + shippingFee)

    /** Remaining balance owed by client */
    val balanceDue: Double
        get() = maxOf(0.0, grandTotal - amountPaid)

    /** Determines if payment is past the due date */
    val isOverdue: Boolean
        get() = status != InvoiceStatus.PAID && status != InvoiceStatus.CANCELLED && try {
            val format = SimpleDateFormat("yyyy-MM-dd", Locale.US)
            val parsedDue = format.parse(dueDate)
            parsedDue != null && parsedDue.before(Date())
        } catch (_: Exception) {
            false
        }

    /**
     * Converts domain Invoice to persistent InvoiceEntity for Room database.
     */
    fun toEntity(): InvoiceEntity {
        return InvoiceEntity(
            id = id,
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
            currencyCode = currency,
            currencySymbol = currencySymbol,
            itemsJson = InvoiceUtils.serializeInvoiceItems(items),
            notes = notes,
            terms = terms,
            paymentInstructions = paymentInstructions,
            taxRate = taxRate,
            taxLabel = taxLabel,
            discountPercent = discountPercent,
            discountAmount = discountAmount,
            shippingFee = shippingFee,
            amountPaid = amountPaid,
            status = status.displayName,
            templateId = templateId,
            docxTemplateTitle = docxTemplateTitle,
            createdAt = createdAt,
            paidDate = paidDate,
            reminderLastSent = reminderLastSent,
            shippingDetailsJson = shippingDetailsJson,
            customFieldsJson = customFieldsJson,
            itemColumnsJson = itemColumnsJson,
            additionalCharges = additionalCharges,
            roundOff = roundOff,
            isTaxInclusive = isTaxInclusive,
            taxType = taxType,
            isRcm = isRcm
        )
    }

    companion object {
        /**
         * Reconstructs a domain Invoice from a Room InvoiceEntity.
         */
        fun fromEntity(entity: InvoiceEntity): Invoice {
            return Invoice(
                id = entity.id,
                invoiceNumber = entity.invoiceNumber,
                clientId = entity.clientId,
                clientName = entity.clientName,
                clientCompany = entity.clientCompany,
                clientEmail = entity.clientEmail,
                clientPhone = entity.clientPhone,
                clientAddress = entity.clientAddress,
                clientTaxId = entity.clientTaxId,
                issueDate = entity.issueDate,
                dueDate = entity.dueDate,
                poNumber = entity.poNumber,
                paymentTerms = entity.paymentTerms,
                currency = entity.currencyCode,
                currencySymbol = entity.currencySymbol,
                taxRate = entity.taxRate,
                taxLabel = entity.taxLabel,
                discountPercent = entity.discountPercent,
                discountAmount = entity.discountAmount,
                shippingFee = entity.shippingFee,
                amountPaid = entity.amountPaid,
                status = InvoiceStatus.fromString(entity.status),
                items = InvoiceUtils.deserializeInvoiceItems(entity.itemsJson),
                notes = entity.notes,
                terms = entity.terms,
                paymentInstructions = entity.paymentInstructions,
                templateId = entity.templateId,
                docxTemplateTitle = entity.docxTemplateTitle,
                createdAt = entity.createdAt,
                paidDate = entity.paidDate,
                reminderLastSent = entity.reminderLastSent,
                shippingDetailsJson = entity.shippingDetailsJson,
                customFieldsJson = entity.customFieldsJson,
                itemColumnsJson = entity.itemColumnsJson,
                additionalCharges = entity.additionalCharges,
                roundOff = entity.roundOff,
                isTaxInclusive = entity.isTaxInclusive,
                taxType = entity.taxType,
                isRcm = entity.isRcm
            )
        }
    }
}

/**
 * Extension function to map an InvoiceEntity directly to a domain Invoice.
 */
fun InvoiceEntity.toDomain(): Invoice = Invoice.fromEntity(this)
