package com.example.ai

import android.util.Log
import com.example.BuildConfig
import com.example.data.model.BusinessProfile
import com.example.data.model.ClientEntity
import com.example.data.model.ExpenseEntity
import com.example.data.model.InvoiceEntity
import com.example.data.model.InvoiceItem
import com.example.data.model.InvoiceUtils
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.TimeUnit
import java.util.regex.Pattern

/**
 * Service for interacting with the Google Gemini API (model: gemini-2.0-flash)
 * with graceful fallback to local semantic extraction.
 */
class GeminiAiService(
    private val client: OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(25, TimeUnit.SECONDS)
        .readTimeout(25, TimeUnit.SECONDS)
        .build()
) {

    companion object {
        private const val TAG = "GeminiAiService"
        // Target model according to guidelines: Basic Text & Q&A Tasks
        private const val MODEL_NAME = "gemini-2.0-flash"
        private const val API_BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models"

        private val CLIENT_TAG_PATTERN = Pattern.compile("<<<CLIENT_DATA:(.*?)>>>", Pattern.DOTALL)
        private val INVOICE_TAG_PATTERN = Pattern.compile("<<<INVOICE_DATA:(.*?)>>>", Pattern.DOTALL)
        private val EXPENSE_TAG_PATTERN = Pattern.compile("<<<EXPENSE_DATA:(.*?)>>>", Pattern.DOTALL)
        private val FINANCIAL_TAG_PATTERN = Pattern.compile("<<<FINANCIAL_SUMMARY>>>")
        private val MATCHED_INVOICE_PATTERN = Pattern.compile("<<<MATCHED_INVOICE:(.*?)>>>")
    }

    suspend fun processUserPrompt(
        prompt: String,
        profile: BusinessProfile,
        existingClients: List<ClientEntity>,
        invoices: List<InvoiceEntity> = emptyList(),
        expenses: List<ExpenseEntity> = emptyList(),
        nextInvoiceNumber: String,
        conversationHistory: List<ChatMessage> = emptyList(),
        businessMemory: AiBusinessMemory? = null
    ): AiActionResult = withContext(Dispatchers.IO) {
        val apiKey = try {
            BuildConfig.GEMINI_API_KEY
        } catch (_: Exception) {
            ""
        }

        val hasValidKey = apiKey.isNotBlank() && apiKey != "MY_GEMINI_API_KEY"

        if (hasValidKey) {
            try {
                val apiResponse = callGeminiApi(
                    prompt = prompt,
                    apiKey = apiKey,
                    profile = profile,
                    existingClients = existingClients,
                    invoices = invoices,
                    expenses = expenses,
                    nextInvoiceNumber = nextInvoiceNumber,
                    conversationHistory = conversationHistory,
                    businessMemory = businessMemory
                )
                if (apiResponse != null) {
                    val parsed = parseAiOutput(apiResponse, profile, invoices, expenses, existingClients, nextInvoiceNumber)
                    if (parsed != null) {
                        return@withContext parsed
                    }
                }
            } catch (e: Exception) {
                Log.w(TAG, "Gemini API call failed, falling back to local extractor: ${e.message}")
            }
        }

        // Local Smart NLP Fallback
        return@withContext processLocally(
            prompt = prompt,
            profile = profile,
            existingClients = existingClients,
            invoices = invoices,
            expenses = expenses,
            nextInvoiceNumber = nextInvoiceNumber,
            conversationHistory = conversationHistory,
            businessMemory = businessMemory
        )
    }

    /**
     * Executes REST call to Gemini 2.0 Flash endpoint with customer's full real-time database context,
     * learned user habits, and multi-turn conversation memory.
     */
    private fun callGeminiApi(
        prompt: String,
        apiKey: String,
        profile: BusinessProfile,
        existingClients: List<ClientEntity>,
        invoices: List<InvoiceEntity>,
        expenses: List<ExpenseEntity>,
        nextInvoiceNumber: String,
        conversationHistory: List<ChatMessage> = emptyList(),
        businessMemory: AiBusinessMemory? = null
    ): String? {
        val url = "$API_BASE_URL/$MODEL_NAME:generateContent?key=$apiKey"

        val currSym = profile.defaultCurrencySymbol.ifBlank { "$" }

        // Compute live financial metrics
        var totalInvoiced = 0.0
        var totalPaid = 0.0
        var totalPending = 0.0
        var totalOverdue = 0.0

        invoices.forEach { inv ->
            val items = InvoiceUtils.deserializeInvoiceItems(inv.itemsJson)
            val calcs = InvoiceUtils.calculateInvoice(items, inv.taxRate, inv.discountPercent, inv.discountAmount, inv.shippingFee, inv.amountPaid)
            totalInvoiced += calcs.grandTotal
            when (inv.status.lowercase(Locale.US)) {
                "paid" -> totalPaid += calcs.grandTotal
                "overdue" -> {
                    totalOverdue += calcs.balanceDue
                    totalPending += calcs.balanceDue
                }
                else -> totalPending += calcs.balanceDue
            }
        }

        val totalExpenses = expenses.sumOf { it.amount }
        val netProfit = totalPaid - totalExpenses

        val invoicesSummary = if (invoices.isEmpty()) {
            "No invoices recorded yet."
        } else {
            invoices.take(12).joinToString("\n") { inv ->
                val items = InvoiceUtils.deserializeInvoiceItems(inv.itemsJson)
                val calcs = InvoiceUtils.calculateInvoice(items, inv.taxRate, inv.discountPercent, inv.discountAmount, inv.shippingFee, inv.amountPaid)
                "• #${inv.invoiceNumber} | Client: ${inv.clientName} | Status: ${inv.status} | Total: $currSym${String.format(Locale.US, "%,.2f", calcs.grandTotal)} | Balance Due: $currSym${String.format(Locale.US, "%,.2f", calcs.balanceDue)} | Due: ${inv.dueDate}"
            }
        }

        val clientsSummary = if (existingClients.isEmpty()) {
            "No clients recorded yet."
        } else {
            existingClients.take(10).joinToString("\n") { c ->
                "• ${c.name} (${c.companyName.ifBlank { "Individual" }}) | Email: ${c.email} | Phone: ${c.phone}"
            }
        }

        val expensesSummary = if (expenses.isEmpty()) {
            "No expenses recorded yet."
        } else {
            expenses.take(8).joinToString("\n") { e ->
                "• ${e.title} | Category: ${e.category} | Amount: $currSym${String.format(Locale.US, "%,.2f", e.amount)} | Vendor: ${e.vendor} | Date: ${e.date}"
            }
        }

        val systemInstruction = """
            You are the user's dedicated, smart, and highly competent Business Employee Agent & CFO for "${profile.businessName.ifBlank { "My Business" }}" (${profile.defaultCurrency} $currSym), powered by Google Gemini.
            You behave like a trustworthy, proactive, respectful senior employee / business operations manager. You are ready to assist with invoices, financial tracking, client management, business decisions, or answer any question under the sun!

            === REAL-TIME CUSTOMER DATA FROM DATABASE ===
            Financial Overview:
            • Total Invoiced: $currSym${String.format(Locale.US, "%,.2f", totalInvoiced)} (${invoices.size} invoices total)
            • Total Paid / Collected: $currSym${String.format(Locale.US, "%,.2f", totalPaid)} (${invoices.count { it.status.equals("paid", true) }} paid)
            • Pending / Outstanding Balance: $currSym${String.format(Locale.US, "%,.2f", totalPending)} (${invoices.count { !it.status.equals("paid", true) }} unpaid)
            • Overdue Balance: $currSym${String.format(Locale.US, "%,.2f", totalOverdue)} (${invoices.count { it.status.equals("overdue", true) }} overdue)
            • Total Tracked Expenses: $currSym${String.format(Locale.US, "%,.2f", totalExpenses)} (${expenses.size} expenses)
            • Estimated Net Profit: $currSym${String.format(Locale.US, "%,.2f", netProfit)}

            Invoices in Database:
            $invoicesSummary

            Clients in Database:
            $clientsSummary

            Recent Expenses:
            $expensesSummary

            === EMPLOYEE PERSONA & LANGUAGE RULES ===
            1. MULTILINGUAL & NATIVE INDIAN HINDI SUPPORT:
               - You can understand and respond in ANY language fluently based on the user's input.
               - When the user speaks or writes in Hindi or Hinglish (e.g. "bhai kitna pending hai?", "Acme ka invoice bana do", "namaste kaise ho", "mere business ka hisaab batao"):
                 Respond warmly, politely, and natively in Indian Hindi / Hinglish like a smart, respectful Indian office employee/manager ("जी सर! आपके बिज़नेस का पूरा हिसाब यहाँ है...", "हाँजी सर, Acme Corp का इनवॉइस मैंने तैयार कर दिया है!").
               - When the user writes in English, reply in crisp, professional executive English ("Certainly, Sir! Here is the breakdown of your revenue and pending dues:").
               - When the user speaks in any other language (Tamil, Telugu, Bengali, Marathi, Spanish, etc.), reply naturally in that language.

            2. ANSWER ANYTHING (EXECUTIVE EMPLOYEE AGENT):
               - You are an expert employee agent who can answer ANYTHING: invoices, business taxes, GST regulations, overdue collection strategies, marketing advice, pricing calculation, or general everyday questions.
               - Always be polite, respectful (e.g. using "Sir / Ma'am" or "जी सर"), proactive, and solution-oriented.

            3. STRUCTURED PARAGRAPHS & DATA POINTS (CHATGPT FLOW):
               - Format your responses with short, readable paragraphs and clean bullet data points (•).
               - Highlight key metrics, currency amounts, dates, and client names in bold.
               - Avoid huge unbroken blocks of text. Make it effortless to skim on mobile screens and natural when read aloud by voice speech.

            4. DATABASE ACTIONS & SPECIAL TAGS:
               - When discussing financial totals or summarizing revenue, ALWAYS append the exact tag: <<<FINANCIAL_SUMMARY>>>
               - When discussing a specific invoice, mention it clearly and append: <<<MATCHED_INVOICE:INV_NUMBER>>>
               - If user asks to SAVE or ADD A CLIENT:
                 Include: <<<CLIENT_DATA:{"name":"...","company":"...","email":"...","phone":"...","address":"...","taxId":"..."}>>>
               - If user asks to GENERATE or CREATE AN INVOICE:
                 Include: <<<INVOICE_DATA:{"invoiceNumber":"$nextInvoiceNumber","clientName":"...","clientCompany":"...","clientEmail":"...","currencyCode":"${profile.defaultCurrency}","currencySymbol":"$currSym","taxRate":${profile.defaultTaxRate},"taxLabel":"${profile.defaultTaxLabel}","discountPercent":0.0,"items":[{"description":"...","quantity":1.0,"unitPrice":100.0,"unit":"hrs"}],"notes":"..."}>>>
               - If user asks to RECORD or SAVE AN EXPENSE:
                 Include: <<<EXPENSE_DATA:{"title":"...","category":"...","amount":0.0,"vendor":"...","paymentMethod":"Credit Card","taxDeductible":true}>>>
        """.trimIndent()

        val memorySection = if (businessMemory != null) {
            """
            === LEARNED BUSINESS MEMORY & HABITS ===
            • Preferred Language: ${businessMemory.preferredLanguage}
            • User Voice Usage: ${businessMemory.voiceSpeakingCount} voice interactions (User regularly speaks by voice)
            • Frequently Mentioned Clients: ${businessMemory.frequentClients.joinToString(", ").ifBlank { "None recorded yet" }}
            • Recent Chat Topics & Follow-ups: ${businessMemory.recentDiscussionTopics.joinToString("; ").ifBlank { "None" }}
            • Persona: You behave like a seasoned, respectful executive employee who knows every detail of the business records, remembers past conversations, and helps anticipate the user's needs.
            """.trimIndent()
        } else ""

        val historySection = if (conversationHistory.isNotEmpty()) {
            val formatted = conversationHistory.takeLast(8).joinToString("\n") { msg ->
                val speaker = if (msg.isUser) "Boss (User)" else "Invoicely AI"
                val voiceNotice = if (msg.isVoiceInput) " [Voice]" else ""
                "$speaker$voiceNotice: ${msg.text.take(250)}"
            }
            "=== RECENT CONVERSATION CONTEXT ===\n$formatted\n"
        } else ""

        val jsonBody = JSONObject().apply {
            val contentsArray = JSONArray()
            val contentObj = JSONObject().apply {
                val partsArray = JSONArray()
                partsArray.put(JSONObject().apply {
                    put("text", "$systemInstruction\n\n$memorySection\n\n$historySection\nUser request: $prompt")
                })
                put("parts", partsArray)
            }
            contentsArray.put(contentObj)
            put("contents", contentsArray)
        }

        val request = Request.Builder()
            .url(url)
            .post(jsonBody.toString().toRequestBody("application/json".toMediaType()))
            .build()

        client.newCall(request).execute().use { response ->
            if (!response.isSuccessful) {
                Log.e(TAG, "Gemini API error code: ${response.code}")
                return null
            }
            val bodyString = response.body?.string() ?: return null
            val responseJson = JSONObject(bodyString)
            val candidates = responseJson.optJSONArray("candidates")
            if (candidates != null && candidates.length() > 0) {
                val firstCandidate = candidates.getJSONObject(0)
                val content = firstCandidate.optJSONObject("content")
                val parts = content?.optJSONArray("parts")
                if (parts != null && parts.length() > 0) {
                    return parts.getJSONObject(0).optString("text")
                }
            }
        }
        return null
    }

    /**
     * Parses structured tags from AI text output
     */
    private fun parseAiOutput(
        text: String,
        profile: BusinessProfile,
        invoices: List<InvoiceEntity>,
        expenses: List<ExpenseEntity>,
        existingClients: List<ClientEntity>,
        nextInvoiceNumber: String
    ): AiActionResult? {
        // Check for CLIENT tag
        val clientMatcher = CLIENT_TAG_PATTERN.matcher(text)
        if (clientMatcher.find()) {
            val jsonStr = clientMatcher.group(1)?.trim() ?: ""
            val cleanReply = text.replace(clientMatcher.group(0) ?: "", "").trim()
            try {
                val json = JSONObject(jsonStr)
                val client = ClientEntity(
                    name = json.optString("name", "New Client").trim(),
                    companyName = json.optString("company", "").trim(),
                    email = json.optString("email", "").trim(),
                    phone = json.optString("phone", "").trim(),
                    address = json.optString("address", "").trim(),
                    taxId = json.optString("taxId", "").trim(),
                    preferredCurrency = profile.defaultCurrency,
                    defaultPaymentTerms = profile.defaultPaymentTerms
                )
                return AiActionResult(
                    actionType = AiActionType.SAVE_CLIENT,
                    conversationalReply = cleanReply.ifBlank { "Client ${client.name} has been added to your client list." },
                    clientToSave = client
                )
            } catch (e: Exception) {
                Log.e(TAG, "Failed parsing client json: ${e.message}")
            }
        }

        // Check for INVOICE tag
        val invoiceMatcher = INVOICE_TAG_PATTERN.matcher(text)
        if (invoiceMatcher.find()) {
            val jsonStr = invoiceMatcher.group(1)?.trim() ?: ""
            val cleanReply = text.replace(invoiceMatcher.group(0) ?: "", "").trim()
            try {
                val json = JSONObject(jsonStr)
                val items = mutableListOf<InvoiceItem>()
                val itemsArray = json.optJSONArray("items")
                if (itemsArray != null && itemsArray.length() > 0) {
                    for (i in 0 until itemsArray.length()) {
                        val itemObj = itemsArray.getJSONObject(i)
                        items.add(
                            InvoiceItem(
                                description = itemObj.optString("description", "Service").trim(),
                                quantity = itemObj.optDouble("quantity", 1.0),
                                unitPrice = itemObj.optDouble("unitPrice", 0.0),
                                unit = itemObj.optString("unit", "hrs").trim()
                            )
                        )
                    }
                }
                if (items.isEmpty()) {
                    items.add(InvoiceItem(description = "Professional Services", quantity = 1.0, unitPrice = 100.0, unit = "hrs"))
                }

                val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
                val dueDate = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date(System.currentTimeMillis() + 30L * 86400000L))

                val invoice = InvoiceEntity(
                    invoiceNumber = json.optString("invoiceNumber", nextInvoiceNumber).ifBlank { nextInvoiceNumber },
                    clientName = json.optString("clientName", "Client").ifBlank { "Client" },
                    clientCompany = json.optString("clientCompany", ""),
                    clientEmail = json.optString("clientEmail", ""),
                    issueDate = today,
                    dueDate = dueDate,
                    paymentTerms = json.optString("paymentTerms", profile.defaultPaymentTerms.ifBlank { "Net 30" }),
                    currencyCode = json.optString("currencyCode", profile.defaultCurrency.ifBlank { "USD" }),
                    currencySymbol = json.optString("currencySymbol", profile.defaultCurrencySymbol.ifBlank { "$" }),
                    itemsJson = InvoiceUtils.serializeInvoiceItems(items),
                    taxRate = json.optDouble("taxRate", profile.defaultTaxRate),
                    taxLabel = json.optString("taxLabel", profile.defaultTaxLabel.ifBlank { "Tax" }),
                    discountPercent = json.optDouble("discountPercent", 0.0),
                    notes = json.optString("notes", profile.defaultNotes),
                    terms = profile.defaultTerms,
                    paymentInstructions = "Bank: ${profile.bankName}\nAccount: ${profile.accountNumber}\nRouting: ${profile.routingNumber}\nUPI: ${profile.upiId}",
                    status = "Draft",
                    templateId = profile.defaultTemplateId.ifBlank { "gst_tax" }
                )

                return AiActionResult(
                    actionType = AiActionType.GENERATE_INVOICE,
                    conversationalReply = cleanReply.ifBlank { "I've generated invoice #${invoice.invoiceNumber} for ${invoice.clientName}." },
                    invoiceToGenerate = invoice
                )
            } catch (e: Exception) {
                Log.e(TAG, "Failed parsing invoice json: ${e.message}")
            }
        }

        // Check for EXPENSE tag
        val expenseMatcher = EXPENSE_TAG_PATTERN.matcher(text)
        if (expenseMatcher.find()) {
            val jsonStr = expenseMatcher.group(1)?.trim() ?: ""
            val cleanReply = text.replace(expenseMatcher.group(0) ?: "", "").trim()
            try {
                val json = JSONObject(jsonStr)
                val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
                val expense = ExpenseEntity(
                    title = json.optString("title", "Business Expense"),
                    category = json.optString("category", "General"),
                    amount = json.optDouble("amount", 0.0),
                    currency = profile.defaultCurrency,
                    currencySymbol = profile.defaultCurrencySymbol,
                    date = today,
                    vendor = json.optString("vendor", ""),
                    paymentMethod = json.optString("paymentMethod", "Credit Card"),
                    taxDeductible = json.optBoolean("taxDeductible", true)
                )
                return AiActionResult(
                    actionType = AiActionType.SAVE_EXPENSE,
                    conversationalReply = cleanReply.ifBlank { "I've recorded expense of ${profile.defaultCurrencySymbol}${expense.amount} for ${expense.title}." },
                    expenseToSave = expense
                )
            } catch (e: Exception) {
                Log.e(TAG, "Failed parsing expense json: ${e.message}")
            }
        }

        // Check for FINANCIAL_SUMMARY tag or MATCHED_INVOICE tag
        val hasFinancialTag = FINANCIAL_TAG_PATTERN.matcher(text).find()
        var matchedInvoice: InvoiceEntity? = null
        val matchedInvoiceMatcher = MATCHED_INVOICE_PATTERN.matcher(text)
        if (matchedInvoiceMatcher.find()) {
            val invoiceNoOrId = matchedInvoiceMatcher.group(1)?.trim() ?: ""
            matchedInvoice = invoices.firstOrNull {
                it.invoiceNumber.equals(invoiceNoOrId, true) || it.id.toString() == invoiceNoOrId
            }
        }

        val cleanedReply = text
            .replace(CLIENT_TAG_PATTERN.toRegex(), "")
            .replace(INVOICE_TAG_PATTERN.toRegex(), "")
            .replace(EXPENSE_TAG_PATTERN.toRegex(), "")
            .replace(FINANCIAL_TAG_PATTERN.toRegex(), "")
            .replace(MATCHED_INVOICE_PATTERN.toRegex(), "")
            .trim()

        val finSummary = if (hasFinancialTag || text.contains("total revenue", true) || text.contains("financial overview", true)) {
            computeFinancialSummary(profile, invoices, expenses, existingClients)
        } else null

        return AiActionResult(
            actionType = if (hasFinancialTag) AiActionType.DATA_SUMMARY else AiActionType.GENERAL_CHAT,
            conversationalReply = cleanedReply,
            financialSummary = finSummary,
            matchedInvoices = if (matchedInvoice != null) listOf(matchedInvoice) else null
        )
    }

    private fun computeFinancialSummary(
        profile: BusinessProfile,
        invoices: List<InvoiceEntity>,
        expenses: List<ExpenseEntity>,
        existingClients: List<ClientEntity>
    ): FinancialSummaryData {
        var totalInvoiced = 0.0
        var totalPaid = 0.0
        var totalPending = 0.0
        var totalOverdue = 0.0
        var paidCount = 0
        var pendingCount = 0
        var overdueCount = 0

        invoices.forEach { inv ->
            val items = InvoiceUtils.deserializeInvoiceItems(inv.itemsJson)
            val calcs = InvoiceUtils.calculateInvoice(items, inv.taxRate, inv.discountPercent, inv.discountAmount, inv.shippingFee, inv.amountPaid)
            totalInvoiced += calcs.grandTotal
            when (inv.status.lowercase(Locale.US)) {
                "paid" -> {
                    totalPaid += calcs.grandTotal
                    paidCount++
                }
                "overdue" -> {
                    totalOverdue += calcs.balanceDue
                    totalPending += calcs.balanceDue
                    overdueCount++
                    pendingCount++
                }
                else -> {
                    totalPending += calcs.balanceDue
                    pendingCount++
                }
            }
        }
        val totalExpenses = expenses.sumOf { it.amount }
        return FinancialSummaryData(
            totalRevenue = totalInvoiced,
            pendingAmount = totalPending,
            paidAmount = totalPaid,
            totalExpenses = totalExpenses,
            netProfit = totalPaid - totalExpenses,
            invoiceCount = invoices.size,
            paidCount = paidCount,
            pendingCount = pendingCount,
            overdueCount = overdueCount,
            clientCount = existingClients.size,
            currencySymbol = profile.defaultCurrencySymbol.ifBlank { "$" }
        )
    }

    /**
     * Highly responsive, robust local parser for when offline or no API key is set
     */
    private fun processLocally(
        prompt: String,
        profile: BusinessProfile,
        existingClients: List<ClientEntity>,
        invoices: List<InvoiceEntity>,
        expenses: List<ExpenseEntity>,
        nextInvoiceNumber: String,
        conversationHistory: List<ChatMessage> = emptyList(),
        businessMemory: AiBusinessMemory? = null
    ): AiActionResult {
        val lower = prompt.lowercase(Locale.ROOT)
        val isHindi = lower.contains("namaste") || lower.contains("kaise") || lower.contains("baki") ||
                lower.contains("kitna") || lower.contains("hisaab") || lower.contains("banao") ||
                lower.contains("kharcha") || lower.contains("paisa") || lower.contains("kisko") ||
                lower.contains("bhejo") || lower.contains("kripya") || lower.contains("dhanyawad") ||
                prompt.any { it in '\u0900'..'\u097F' }
        val currSym = profile.defaultCurrencySymbol.ifBlank { "$" }

        // 0. DATA QUERY: PENDING / OVERDUE / UNPAID INVOICES
        val isPendingQuery = (lower.contains("pending") || lower.contains("unpaid") ||
                lower.contains("who owes") || lower.contains("money owed") ||
                lower.contains("due") || lower.contains("outstanding") || lower.contains("overdue") ||
                lower.contains("baki") || lower.contains("kitna baki") || lower.contains("kiska baki")) &&
                !lower.contains("create") && !lower.contains("save") && !lower.contains("record")
        if (isPendingQuery) {
            val pendingList = invoices.filter { !it.status.equals("paid", true) }
            val overdueList = invoices.filter { it.status.equals("overdue", true) }

            var pendingSum = 0.0
            var overdueSum = 0.0

            pendingList.forEach { inv ->
                val items = InvoiceUtils.deserializeInvoiceItems(inv.itemsJson)
                val calcs = InvoiceUtils.calculateInvoice(items, inv.taxRate, inv.discountPercent, inv.discountAmount, inv.shippingFee, inv.amountPaid)
                pendingSum += calcs.balanceDue
                if (inv.status.equals("overdue", true)) {
                    overdueSum += calcs.balanceDue
                }
            }

            val reply = if (isHindi) {
                if (pendingList.isEmpty()) {
                    "बधाई हो सर! 🎉 अभी आपके पास **कोई भी पेंडिंग या ओवरड्यू इनवॉइस नहीं है**। आपके सभी क्लाइंट्स का पेमेंट पूरी तरह क्लियर है।"
                } else {
                    val topPending = pendingList.take(3).joinToString("\n") { inv ->
                        val items = InvoiceUtils.deserializeInvoiceItems(inv.itemsJson)
                        val calcs = InvoiceUtils.calculateInvoice(items, inv.taxRate, inv.discountPercent, inv.discountAmount, inv.shippingFee, inv.amountPaid)
                        "• **#${inv.invoiceNumber}** (${inv.clientName}): $currSym${String.format(Locale.US, "%,.2f", calcs.balanceDue)} (स्टेटस: ${inv.status}, ड्यू डेट: ${inv.dueDate})"
                    }
                    "जी सर! वर्तमान में आपके **${pendingList.size} इनवॉइस पेंडिंग हैं**, कुल बकाया राशि **$currSym${String.format(Locale.US, "%,.2f", pendingSum)}** है" +
                            (if (overdueList.isNotEmpty()) " (जिसमें से **$currSym${String.format(Locale.US, "%,.2f", overdueSum)}** ओवरड्यू हो चुका है)।" else "।") +
                            "\n\n$topPending\n\nआप नीचे दिए गए कार्ड्स पर टैप करके तुरंत इनवॉइस देख या शेयर कर सकते हैं!"
                }
            } else {
                if (pendingList.isEmpty()) {
                    "Great news, Sir! 🎉 You currently have **no pending or overdue invoices**. All your billed invoices are fully settled."
                } else {
                    val topPending = pendingList.take(3).joinToString("\n") { inv ->
                        val items = InvoiceUtils.deserializeInvoiceItems(inv.itemsJson)
                        val calcs = InvoiceUtils.calculateInvoice(items, inv.taxRate, inv.discountPercent, inv.discountAmount, inv.shippingFee, inv.amountPaid)
                        "• **#${inv.invoiceNumber}** for **${inv.clientName}**: $currSym${String.format(Locale.US, "%,.2f", calcs.balanceDue)} (${inv.status}, due ${inv.dueDate})"
                    }
                    "Certainly, Sir! You have **${pendingList.size} pending invoices** totaling **$currSym${String.format(Locale.US, "%,.2f", pendingSum)}**" +
                            (if (overdueList.isNotEmpty()) " (including **$currSym${String.format(Locale.US, "%,.2f", overdueSum)}** overdue)." else ".") +
                            "\n\n$topPending\n\nTap any card below to inspect the full invoice details or send reminders!"
                }
            }

            return AiActionResult(
                actionType = AiActionType.DATA_SUMMARY,
                conversationalReply = reply,
                financialSummary = computeFinancialSummary(profile, invoices, expenses, existingClients),
                matchedInvoices = pendingList.take(4)
            )
        }

        // 1. DATA QUERY: REVENUE / FINANCIAL SUMMARY / PROFIT
        val isFinanceSummary = (lower.contains("summary") || lower.contains("revenue") ||
                lower.contains("how much did i make") || lower.contains("turnover") ||
                lower.contains("profit") || lower.contains("financials") || lower.contains("finances") ||
                lower.contains("my data") || lower.contains("business health") ||
                lower.contains("hisaab") || lower.contains("kamai") || lower.contains("munafa")) &&
                !lower.contains("save") && !lower.contains("create")
        if (isFinanceSummary) {
            val fin = computeFinancialSummary(profile, invoices, expenses, existingClients)
            val reply = if (isHindi) {
                "जी सर, यह रहा आपके बिज़नेस का ताज़ा वित्तीय विवरण:\n\n" +
                        "• **कुल इनवॉइस राशि**: $currSym${String.format(Locale.US, "%,.2f", fin.totalRevenue)} (${fin.invoiceCount} इनवॉइस)\n" +
                        "• **वसूल हुई राशि (Paid)**: $currSym${String.format(Locale.US, "%,.2f", fin.paidAmount)} (${fin.paidCount} पेड)\n" +
                        "• **बकाया राशि (Pending)**: $currSym${String.format(Locale.US, "%,.2f", fin.pendingAmount)} (${fin.pendingCount} बाकी)\n" +
                        "• **कुल खर्चे (Expenses)**: $currSym${String.format(Locale.US, "%,.2f", fin.totalExpenses)}\n" +
                        "• **अनुमानित शुद्ध लाभ (Net Profit)**: **$currSym${String.format(Locale.US, "%,.2f", fin.netProfit)}**\n\n" +
                        "वर्तमान में आपके पास कुल **${fin.clientCount} एक्टिव क्लाइंट्स** दर्ज हैं।"
            } else {
                "Here is the complete financial breakdown for your business, Sir:\n\n" +
                        "• **Total Invoiced**: $currSym${String.format(Locale.US, "%,.2f", fin.totalRevenue)} across **${fin.invoiceCount} invoices**\n" +
                        "• **Total Collected**: $currSym${String.format(Locale.US, "%,.2f", fin.paidAmount)} (${fin.paidCount} paid)\n" +
                        "• **Pending Balance**: $currSym${String.format(Locale.US, "%,.2f", fin.pendingAmount)} (${fin.pendingCount} unpaid)\n" +
                        "• **Total Tracked Expenses**: $currSym${String.format(Locale.US, "%,.2f", fin.totalExpenses)}\n" +
                        "• **Estimated Net Profit**: **$currSym${String.format(Locale.US, "%,.2f", fin.netProfit)}**\n\n" +
                        "Your company currently maintains **${fin.clientCount} registered clients**."
            }

            return AiActionResult(
                actionType = AiActionType.DATA_SUMMARY,
                conversationalReply = reply,
                financialSummary = fin
            )
        }

        // 2. DATA QUERY: EXPENSES SUMMARY
        val isExpenseListQuery = (lower.contains("my expenses") || lower.contains("expense breakdown") ||
                lower.contains("how much did i spend") || lower.contains("list expenses") ||
                lower.contains("kharcha dikhao") || lower.contains("kharch")) && !lower.contains("save") && !lower.contains("record")
        if (isExpenseListQuery) {
            val totalSpent = expenses.sumOf { it.amount }
            val reply = if (expenses.isEmpty()) {
                if (isHindi) "सर, अभी तक कोई भी बिज़नेस खर्चा रिकॉर्ड नहीं हुआ है। आप कभी भी *\"खर्चा रिकॉर्ड करो ₹500 क्लाइंट मीटिंग\"* बोल या लिख सकते हैं!"
                else "You haven't recorded any business expenses yet, Sir. You can speak or type *\"Record expense $50 for client lunch\"* anytime!"
            } else {
                val categoryMap = expenses.groupBy { it.category }.mapValues { it.value.sumOf { exp -> exp.amount } }
                val breakdown = categoryMap.entries.joinToString("\n") { (cat, sum) ->
                    "• **$cat**: $currSym${String.format(Locale.US, "%,.2f", sum)}"
                }
                if (isHindi) {
                    "जी सर, आपने कुल **${expenses.size} खर्चे** दर्ज किए हैं, कुल खर्च राशि **$currSym${String.format(Locale.US, "%,.2f", totalSpent)}** है:\n\n$breakdown"
                } else {
                    "Here is your tracked expense breakdown, Sir (**${expenses.size} expenses**, totaling **$currSym${String.format(Locale.US, "%,.2f", totalSpent)}**):\n\n$breakdown"
                }
            }
            return AiActionResult(
                actionType = AiActionType.DATA_SUMMARY,
                conversationalReply = reply
            )
        }

        // 3. DATA QUERY: CLIENTS
        val isClientsQuery = (lower.contains("my clients") || lower.contains("list clients") ||
                lower.contains("who are my clients") || lower.contains("grahak") || lower.contains("clients")) &&
                !lower.contains("save") && !lower.contains("add")
        if (isClientsQuery) {
            val reply = if (existingClients.isEmpty()) {
                if (isHindi) "सर, अभी कोई क्लाइंट सेव नहीं है। आप कह सकते हैं: *\"क्लाइंट जोड़ो रमेश कुमार, ईमेल ramesh@email.com\"*।"
                else "You have no clients saved yet, Sir. Say *\"Save client John Doe from Stellar Tech, email john@stellar.com\"* to add one!"
            } else {
                val list = existingClients.take(5).joinToString("\n") { c ->
                    "• **${c.name}** (${c.companyName.ifBlank { "Individual" }}) — ${c.email.ifBlank { c.phone }}"
                }
                if (isHindi) {
                    "सर, आपके डेटाबेस में कुल **${existingClients.size} क्लाइंट्स** दर्ज हैं:\n\n$list"
                } else {
                    "You have **${existingClients.size} clients** in your database, Sir:\n\n$list"
                }
            }
            return AiActionResult(
                actionType = AiActionType.GENERAL_CHAT,
                conversationalReply = reply
            )
        }

        // 0. RECORD / SAVE EXPENSE INTENT
        val isExpense = lower.contains("expense") || lower.contains("spent") ||
                lower.contains("record expense") || lower.contains("save expense") ||
                lower.contains("bought") || (lower.contains("paid") && !lower.contains("paid count") && !lower.contains("invoice")) ||
                lower.contains("bill for") || lower.contains("receipt")

        if (isExpense) {
            var amount = 50.0
            val amtMatcher = Pattern.compile("[$₹€£]?\\s*(\\d+(?:\\.\\d+)?)\\s*(?:usd|dollars|inr|eur|bucks)?", Pattern.CASE_INSENSITIVE).matcher(prompt)
            if (amtMatcher.find()) {
                amount = amtMatcher.group(1)?.toDoubleOrNull() ?: 50.0
            }

            val category = when {
                lower.contains("uber") || lower.contains("taxi") || lower.contains("flight") || lower.contains("travel") || lower.contains("hotel") || lower.contains("fuel") -> "Travel & Transport"
                lower.contains("aws") || lower.contains("hosting") || lower.contains("server") || lower.contains("domain") || lower.contains("software") || lower.contains("saas") || lower.contains("github") || lower.contains("google") -> "Software & IT"
                lower.contains("lunch") || lower.contains("dinner") || lower.contains("meal") || lower.contains("coffee") || lower.contains("food") || lower.contains("restaurant") -> "Meals & Entertainment"
                lower.contains("desk") || lower.contains("rent") || lower.contains("wework") || lower.contains("office") || lower.contains("paper") -> "Office & Rent"
                lower.contains("ad") || lower.contains("marketing") || lower.contains("facebook") || lower.contains("seo") -> "Marketing & Ads"
                else -> "General Business"
            }

            var vendor = ""
            val forMatcher = Pattern.compile("(?:for|at|to)\\s+([A-Za-z0-9\\s&.,]+?)(?:,|\\s+on|\\s+using|\\s+via|$)", Pattern.CASE_INSENSITIVE).matcher(prompt)
            if (forMatcher.find()) {
                vendor = forMatcher.group(1)?.trim() ?: ""
            }
            val title = if (vendor.isNotBlank()) vendor else "Expense ($category)"

            val paymentMethod = when {
                lower.contains("upi") || lower.contains("gpay") || lower.contains("phonepe") -> "UPI"
                lower.contains("cash") -> "Cash"
                lower.contains("bank") || lower.contains("wire") || lower.contains("transfer") -> "Bank Transfer"
                lower.contains("debit") -> "Debit Card"
                else -> "Credit Card"
            }

            val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
            val expense = ExpenseEntity(
                title = title,
                category = category,
                amount = amount,
                currency = profile.defaultCurrency,
                currencySymbol = profile.defaultCurrencySymbol,
                date = today,
                vendor = vendor,
                paymentMethod = paymentMethod,
                taxDeductible = true,
                taxAmount = amount * 0.18,
                notes = "Recorded via AI voice/chat assistant"
            )

            val formatted = String.format(Locale.US, "%.2f", amount)
            return AiActionResult(
                actionType = AiActionType.SAVE_EXPENSE,
                conversationalReply = "I have recorded an expense of **${profile.defaultCurrencySymbol}$formatted** for **$title** under **$category** using **$paymentMethod**.",
                expenseToSave = expense
            )
        }

        // 1. SAVE CLIENT INTENT
        val isSaveClient = lower.contains("save client") || lower.contains("add client") ||
                lower.contains("create client") || lower.contains("new client") ||
                (lower.contains("client") && (lower.contains("email") || lower.contains("phone")))

        if (isSaveClient) {
            val emailMatcher = Pattern.compile("[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}").matcher(prompt)
            val email = if (emailMatcher.find()) emailMatcher.group(0) else ""

            val phoneMatcher = Pattern.compile("(\\+?[0-9]{1,4}[\\s-]?)?(\\(?[0-9]{3}\\)?[\\s-]?)?[0-9]{3}[\\s-]?[0-9]{4}").matcher(prompt)
            val phone = if (phoneMatcher.find()) phoneMatcher.group(0) else ""

            // Extract name
            var name = "Valued Client"
            val namePatterns = listOf(
                Pattern.compile("(?:save|add|create|new)\\s+client\\s+([A-Za-z0-9\\s&]+?)(?:,|\\s+with|\\s+email|\\s+phone|\\s+from|$)", Pattern.CASE_INSENSITIVE),
                Pattern.compile("(?:client|customer)\\s+named?\\s+([A-Za-z0-9\\s&]+?)(?:,|\\s+with|\\s+email|\\s+phone|$)", Pattern.CASE_INSENSITIVE)
            )
            for (p in namePatterns) {
                val m = p.matcher(prompt)
                if (m.find()) {
                    val candidate = m.group(1)?.trim() ?: ""
                    if (candidate.isNotBlank() && candidate.length > 2) {
                        name = candidate
                        break
                    }
                }
            }

            // Extract company
            var company = ""
            val compMatcher = Pattern.compile("(?:company|from|at)\\s+([A-Za-z0-9\\s&.,]+?)(?:,|\\s+with|\\s+email|\\s+phone|$)", Pattern.CASE_INSENSITIVE).matcher(prompt)
            if (compMatcher.find()) {
                val cand = compMatcher.group(1)?.trim() ?: ""
                if (cand.lowercase() != name.lowercase()) {
                    company = cand
                }
            }

            val client = ClientEntity(
                name = name,
                companyName = company,
                email = email ?: "",
                phone = phone ?: "",
                preferredCurrency = profile.defaultCurrency,
                defaultPaymentTerms = profile.defaultPaymentTerms
            )

            return AiActionResult(
                actionType = AiActionType.SAVE_CLIENT,
                conversationalReply = "I have saved **$name** ${if (company.isNotBlank()) "($company) " else ""}to your clients database with email `${email.ifBlank { "N/A" }}` and phone `${phone.ifBlank { "N/A" }}`.",
                clientToSave = client
            )
        }

        // 2. GENERATE INVOICE INTENT
        val isGenerateInvoice = lower.contains("invoice") || lower.contains("bill") ||
                lower.contains("create invoice") || lower.contains("generate invoice") ||
                lower.contains("charge")

        if (isGenerateInvoice) {
            // Find client match or extract name
            var targetClientName = existingClients.firstOrNull { lower.contains(it.name.lowercase()) }?.name
            if (targetClientName == null) {
                val clientMatcher = Pattern.compile("(?:for|to)\\s+([A-Za-z0-9\\s&]+?)(?:,|\\s+for|\\s+with|\\s+at|\\s+amount|$)", Pattern.CASE_INSENSITIVE).matcher(prompt)
                if (clientMatcher.find()) {
                    targetClientName = clientMatcher.group(1)?.trim() ?: "Acme Corp"
                } else {
                    targetClientName = "Acme Corp"
                }
            }

            // Extract quantity and rate/amount
            var quantity = 1.0
            var unitPrice = 100.0
            var description = "Professional Services"

            // Look for patterns like "10 hours at $50" or "5 days design at 200" or "$500 for consulting"
            val qtyRateMatcher = Pattern.compile("(\\d+(?:\\.\\d+)?)\\s*(hrs|hours|days|pcs|units)?\\s*(?:of|at)?\\s*([a-zA-Z\\s]+?)?\\s*(?:at|@|for)?\\s*[$₹€£]?\\s*(\\d+(?:\\.\\d+)?)", Pattern.CASE_INSENSITIVE).matcher(prompt)
            if (qtyRateMatcher.find()) {
                val q = qtyRateMatcher.group(1)?.toDoubleOrNull() ?: 1.0
                val unitWord = qtyRateMatcher.group(2) ?: "hrs"
                val descWord = qtyRateMatcher.group(3)?.trim() ?: ""
                val p = qtyRateMatcher.group(4)?.toDoubleOrNull() ?: 100.0

                quantity = q
                unitPrice = p
                if (descWord.isNotBlank() && descWord.length > 2) {
                    description = descWord.replaceFirstChar { it.uppercase() }
                }
            } else {
                // Check simple amount e.g. "$500" or "500 USD"
                val amountMatcher = Pattern.compile("[$₹€£]?\\s*(\\d+(?:\\.\\d+)?)\\s*(?:usd|inr|eur|dollars)?", Pattern.CASE_INSENSITIVE).matcher(prompt)
                if (amountMatcher.find()) {
                    unitPrice = amountMatcher.group(1)?.toDoubleOrNull() ?: 100.0
                }
            }

            // Tax rate check e.g. "18% tax" or "GST 18%"
            var taxRate = profile.defaultTaxRate
            val taxMatcher = Pattern.compile("(\\d+(?:\\.\\d+)?)\\s*%(?:\\s*(?:tax|gst|vat))?", Pattern.CASE_INSENSITIVE).matcher(prompt)
            if (taxMatcher.find()) {
                taxRate = taxMatcher.group(1)?.toDoubleOrNull() ?: profile.defaultTaxRate
            }

            val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
            val dueDate = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date(System.currentTimeMillis() + 30L * 86400000L))

            val items = listOf(
                InvoiceItem(
                    description = description,
                    quantity = quantity,
                    unitPrice = unitPrice,
                    unit = "hrs"
                )
            )

            val invoice = InvoiceEntity(
                invoiceNumber = nextInvoiceNumber,
                clientName = targetClientName,
                issueDate = today,
                dueDate = dueDate,
                paymentTerms = profile.defaultPaymentTerms.ifBlank { "Net 30" },
                currencyCode = profile.defaultCurrency.ifBlank { "USD" },
                currencySymbol = profile.defaultCurrencySymbol.ifBlank { "$" },
                itemsJson = InvoiceUtils.serializeInvoiceItems(items),
                taxRate = taxRate,
                taxLabel = profile.defaultTaxLabel.ifBlank { "Tax" },
                notes = "Thank you for your business!",
                terms = profile.defaultTerms,
                paymentInstructions = "Bank: ${profile.bankName}\nAccount: ${profile.accountNumber}\nUPI: ${profile.upiId}",
                status = "Draft",
                templateId = profile.defaultTemplateId.ifBlank { "gst_tax" }
            )

            val totalAmount = quantity * unitPrice * (1.0 + taxRate / 100.0)
            val formatted = String.format(Locale.US, "%.2f", totalAmount)

            return AiActionResult(
                actionType = AiActionType.GENERATE_INVOICE,
                conversationalReply = "I have drafted invoice **#$nextInvoiceNumber** for **$targetClientName**.\n\n" +
                        "• **Item**: $description ($quantity hrs × ${profile.defaultCurrencySymbol}$unitPrice)\n" +
                        "• **Tax**: $taxRate% ${profile.defaultTaxLabel}\n" +
                        "• **Grand Total**: **${profile.defaultCurrencySymbol}$formatted**\n\n" +
                        "You can review the interactive card below and tap **Open Full Preview & DOCX** to inspect, customize, or export!",
                invoiceToGenerate = invoice
            )
        }

        // 3. ENQUIRIES & FAQ
        val reply = when {
            lower.contains("gst") || lower.contains("tax rate") -> {
                "**Standard GST / Tax Rates Breakdown:**\n\n" +
                        "• **5%**: Essential goods, transport, basic food items\n" +
                        "• **12%**: Business processing, standard items\n" +
                        "• **18%**: Most software services, IT consulting, professional agency work (Standard Service Slab)\n" +
                        "• **28%**: Luxury goods, automotive, high-end electronics\n\n" +
                        "💡 *Tip:* For inter-state supplies in India, charge **IGST**; for intra-state supplies, split evenly between **CGST** and **SGST**."
            }
            lower.contains("payment term") || lower.contains("net 30") || lower.contains("due on receipt") -> {
                "**Standard Invoice Payment Terms:**\n\n" +
                        "• **Due on Receipt**: Payment is required immediately upon delivery of the invoice.\n" +
                        "• **Net 15**: Full payment within 15 calendar days.\n" +
                        "• **Net 30**: Standard commercial standard (30 days from invoice date).\n" +
                        "• **Net 60**: Common for large enterprise or corporate clients.\n\n" +
                        "💡 *Pro-Tip:* Add a 2% early payment discount (e.g. *2/10 Net 30*) to incentivize clients to pay within 10 days!"
            }
            lower.contains("overdue") || lower.contains("late payment") || lower.contains("reminder") -> {
                "**How to Handle Overdue Invoices:**\n\n" +
                        "1. **Send polite reminder 3 days prior** to the due date.\n" +
                        "2. **On Due Date**: Send a direct statement with payment links/bank details.\n" +
                        "3. **7 Days Overdue**: Send a formal notice referencing the invoice number and terms.\n" +
                        "4. **14+ Days Overdue**: Follow up via phone call.\n\n" +
                        "In Invoicely, you can tap **Send Reminder** on any unpaid invoice to automatically generate a friendly reminder notice!"
            }
            lower.contains("template") || lower.contains("docx") -> {
                "Invoicely features **10 built-in DOCX templates** including:\n\n" +
                        "1. **GST Standard Tax Invoice** (Compliant for Indian Businesses)\n" +
                        "2. **Zoho Elegance Clean**\n" +
                        "3. **Stripe Modern Minimal**\n" +
                        "4. **QuickBooks Corporate Blue**\n" +
                        "5. **Tech Startup Slate & Emerald**\n" +
                        "6. **FreshBooks Vibrant Accent**\n" +
                        "7. **Nordic Monochrome High-Contrast**\n" +
                        "8. **Creative Studio Purple Gradient**\n" +
                        "9. **Executive Navy Double Border**\n" +
                        "10. **Compact Thermal / Retail Slip**\n\n" +
                        "Head over to the **Templates** tab to preview and set your default style!"
            }
            else -> {
                if (isHindi) {
                    "नमस्ते सर! 🙏 मैं आपका बिज़नेस असिस्टेंट (Invoicely AI) हूँ।\n\nबताइए आज आपके बिज़नेस के लिए क्या करना है? मैं ये सभी कार्य तुरंत कर सकता हूँ:\n\n" +
                            "• ⚡ **इनवॉइस बनाना**: *\"Acme Corp के लिए ₹5,000 का इनवॉइस बना दो 18% GST के साथ\"*\n" +
                            "• 💰 **पेमेंट स्टेटस**: *\"कितना पेमेंट अभी पेंडिंग है?\"*\n" +
                            "• 📊 **फाइनेंशियल समरी**: *\"मेरा पूरा रेवेन्यू और मुनाफ़ा दिखाओ\"*\n" +
                            "• 💸 **खर्चा जोड़ना**: *\"खर्चा लिखो ₹500 क्लाइंट लंच\"*\n" +
                            "• 💡 **बिज़नेस सलाह**: *\"पेंडिंग पेमेंट जल्दी रिकवर कैसे करें?\"*\n\n" +
                            "आप नीचे माइक दबाकर हिंदी या अंग्रेज़ी में सीधे बात भी कर सकते हैं!"
                } else {
                    "Hello Sir! 👋 I am your dedicated **Business Employee Agent & Operations Assistant** for ${profile.businessName.ifBlank { "your business" }}.\n\nHere are some tasks I can handle for you right now:\n\n" +
                            "• ⚡ **Create Invoices**: *\"Generate invoice for Acme Corp, 15 hours of design at $80/hr with 10% tax\"*\n" +
                            "• 💰 **Check Pending Balance**: *\"How much money is pending or overdue?\"*\n" +
                            "• 📊 **Financial Overview**: *\"Summarize my total revenue, paid, and net profit\"*\n" +
                            "• 👤 **Save Clients**: *\"Save client John Doe from Stellar Tech, email john@stellar.com\"*\n" +
                            "• 💸 **Record Expenses**: *\"Record expense $65 for team dinner\"*\n\n" +
                            "Tap the mic to talk with me directly in English, Hindi, or any language!"
                }
            }
        }

        return AiActionResult(
            actionType = AiActionType.INVOICE_ENQUIRY,
            conversationalReply = reply
        )
    }
}
