package com.example.ui.viewmodel

import com.example.data.model.Invoice
import com.example.data.model.InvoiceEntity
import com.example.data.model.InvoiceItem
import com.example.data.model.InvoiceStatus
import com.example.data.model.InvoiceUtils

/**
 * State representing an active invoice creation or editing form.
 * Encapsulates client details, line items, currency, taxes, status, and calculations.
 */
data class InvoiceFormState(
    val invoiceId: Long = 0L,
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
    val taxRate: Double = 0.0,
    val taxLabel: String = "Tax",
    val discountPercent: Double = 0.0,
    val discountAmount: Double = 0.0,
    val shippingFee: Double = 0.0,
    val amountPaid: Double = 0.0,
    val status: String = "Draft",
    val templateId: String = "gst_tax",
    val notes: String = "",
    val terms: String = "",
    val paymentInstructions: String = "",
    val items: List<InvoiceItem> = emptyList(),
    val validationError: String? = null,
    val isSaving: Boolean = false
) {
    // =========================================================================
    // Financial calculations
    // =========================================================================

    /** Subtotal before taxes and order discounts */
    val subtotal: Double
        get() = items.sumOf { it.quantity * it.unitPrice }

    /** Sum of all line item discounts */
    val itemDiscounts: Double
        get() = items.sumOf { (it.quantity * it.unitPrice) * (it.discountRate / 100.0) }

    /** Percentage-based discount */
    val percentageDiscount: Double
        get() = (subtotal - itemDiscounts) * (discountPercent / 100.0)

    /** Total combined discount */
    val totalDiscount: Double
        get() = itemDiscounts + percentageDiscount + discountAmount

    /** Net taxable base */
    val taxableBase: Double
        get() = maxOf(0.0, subtotal - totalDiscount)

    /** Total tax calculated across items or flat rate */
    val taxTotal: Double
        get() {
            val itemTax = items.sumOf { item ->
                val lineTotal = (item.quantity * item.unitPrice) * (1.0 - item.discountRate / 100.0)
                lineTotal * (item.taxRate / 100.0)
            }
            return if (itemTax > 0) itemTax else taxableBase * (taxRate / 100.0)
        }

    /** Grand Total */
    val grandTotal: Double
        get() = maxOf(0.0, taxableBase + taxTotal + shippingFee)

    /** Balance due remaining */
    val balanceDue: Double
        get() = maxOf(0.0, grandTotal - amountPaid)

    /** Convert form state to Room persistent InvoiceEntity */
    fun toInvoiceEntity(): InvoiceEntity {
        return InvoiceEntity(
            id = invoiceId,
            invoiceNumber = invoiceNumber.trim(),
            clientId = clientId,
            clientName = clientName.trim(),
            clientCompany = clientCompany.trim(),
            clientEmail = clientEmail.trim(),
            clientPhone = clientPhone.trim(),
            clientAddress = clientAddress.trim(),
            clientTaxId = clientTaxId.trim(),
            issueDate = issueDate,
            dueDate = dueDate,
            poNumber = poNumber.trim(),
            paymentTerms = paymentTerms,
            currencyCode = currencyCode,
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
            status = status,
            templateId = templateId,
            docxTemplateTitle = "INVOICE"
        )
    }

    /** Convert form state to domain Invoice */
    fun toDomainInvoice(): Invoice {
        return Invoice(
            id = invoiceId,
            invoiceNumber = invoiceNumber.trim(),
            clientId = clientId,
            clientName = clientName.trim(),
            clientCompany = clientCompany.trim(),
            clientEmail = clientEmail.trim(),
            clientPhone = clientPhone.trim(),
            clientAddress = clientAddress.trim(),
            clientTaxId = clientTaxId.trim(),
            issueDate = issueDate,
            dueDate = dueDate,
            poNumber = poNumber.trim(),
            paymentTerms = paymentTerms,
            currency = currencyCode,
            currencySymbol = currencySymbol,
            taxRate = taxRate,
            taxLabel = taxLabel,
            discountPercent = discountPercent,
            discountAmount = discountAmount,
            shippingFee = shippingFee,
            amountPaid = amountPaid,
            status = InvoiceStatus.fromString(status),
            items = items,
            notes = notes,
            terms = terms,
            paymentInstructions = paymentInstructions,
            templateId = templateId
        )
    }
}
