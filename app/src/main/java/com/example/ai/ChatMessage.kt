package com.example.ai

import com.example.data.model.ClientEntity
import com.example.data.model.ExpenseEntity
import com.example.data.model.InvoiceEntity
import java.util.UUID

/**
 * Financial metrics snapshot for data summary messages.
 */
data class FinancialSummaryData(
    val totalRevenue: Double,
    val pendingAmount: Double,
    val paidAmount: Double,
    val totalExpenses: Double,
    val netProfit: Double,
    val invoiceCount: Int,
    val paidCount: Int,
    val pendingCount: Int,
    val overdueCount: Int,
    val clientCount: Int,
    val currencySymbol: String
)

/**
 * Message data model for conversational interactions with Gemini AI.
 */
data class ChatMessage(
    val id: String = UUID.randomUUID().toString(),
    val text: String,
    val isUser: Boolean,
    val timestamp: Long = System.currentTimeMillis(),
    val generatedInvoiceId: Long? = null,
    val generatedInvoice: InvoiceEntity? = null,
    val generatedClient: ClientEntity? = null,
    val generatedExpense: ExpenseEntity? = null,
    val financialSummary: FinancialSummaryData? = null,
    val matchedInvoices: List<InvoiceEntity>? = null,
    val isError: Boolean = false
)

/**
 * Types of actions detected by the AI Assistant.
 */
enum class AiActionType {
    GENERAL_CHAT,
    SAVE_CLIENT,
    GENERATE_INVOICE,
    SAVE_EXPENSE,
    INVOICE_ENQUIRY,
    DATA_SUMMARY,
    FINANCIAL_INSIGHT
}

/**
 * Parsed payload resulting from Gemini or local NLP reasoning.
 */
data class AiActionResult(
    val actionType: AiActionType,
    val conversationalReply: String,
    val clientToSave: ClientEntity? = null,
    val invoiceToGenerate: InvoiceEntity? = null,
    val expenseToSave: ExpenseEntity? = null,
    val financialSummary: FinancialSummaryData? = null,
    val matchedInvoices: List<InvoiceEntity>? = null
)
