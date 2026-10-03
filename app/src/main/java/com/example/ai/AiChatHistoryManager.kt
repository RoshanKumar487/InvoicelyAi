package com.example.ai

import android.content.Context
import android.util.Log
import com.example.data.model.BusinessProfile
import com.example.data.model.ClientEntity
import com.example.data.model.ExpenseEntity
import com.example.data.model.InvoiceEntity
import com.example.data.model.InvoiceUtils
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.util.Locale

/**
 * Learned business memory & user communication habits.
 * Keeps track of how the user talks, frequent clients, and past discussion contexts.
 */
data class AiBusinessMemory(
    val preferredLanguage: String = "English / Hindi",
    val voiceSpeakingCount: Int = 0,
    val textMessageCount: Int = 0,
    val lastVisitTime: Long = System.currentTimeMillis(),
    val frequentClients: List<String> = emptyList(),
    val frequentServices: List<String> = emptyList(),
    val recentDiscussionTopics: List<String> = emptyList(),
    val learnedNotes: List<String> = emptyList()
)

/**
 * Manages persistent local storage for AI chat history, conversation memory,
 * and contextual business intelligence predictions.
 */
class AiChatHistoryManager(private val context: Context) {

    companion object {
        private const val TAG = "AiChatHistoryManager"
        private const val CHAT_FILE = "ai_chat_history.json"
        private const val MEMORY_FILE = "ai_business_memory.json"
        private const val MAX_SAVED_MESSAGES = 80
    }

    /**
     * Loads saved chat messages from local disk.
     */
    fun loadChatHistory(): List<ChatMessage> {
        val file = File(context.filesDir, CHAT_FILE)
        if (!file.exists()) return emptyList()

        return try {
            val jsonStr = file.readText()
            if (jsonStr.isBlank()) return emptyList()

            val array = JSONArray(jsonStr)
            val list = mutableListOf<ChatMessage>()
            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)
                list.add(
                    ChatMessage(
                        id = obj.optString("id", java.util.UUID.randomUUID().toString()),
                        text = obj.optString("text", ""),
                        isUser = obj.optBoolean("isUser", false),
                        timestamp = obj.optLong("timestamp", System.currentTimeMillis()),
                        generatedInvoiceId = if (obj.has("generatedInvoiceId") && !obj.isNull("generatedInvoiceId")) obj.optLong("generatedInvoiceId") else null,
                        isError = obj.optBoolean("isError", false),
                        isVoiceInput = obj.optBoolean("isVoiceInput", false)
                    )
                )
            }
            list
        } catch (e: Exception) {
            Log.e(TAG, "Error loading chat history: ${e.message}")
            emptyList()
        }
    }

    /**
     * Persists recent chat messages to local disk.
     */
    fun saveChatHistory(messages: List<ChatMessage>) {
        try {
            val toSave = messages.takeLast(MAX_SAVED_MESSAGES)
            val array = JSONArray()
            toSave.forEach { msg ->
                val obj = JSONObject()
                obj.put("id", msg.id)
                obj.put("text", msg.text)
                obj.put("isUser", msg.isUser)
                obj.put("timestamp", msg.timestamp)
                if (msg.generatedInvoiceId != null) {
                    obj.put("generatedInvoiceId", msg.generatedInvoiceId)
                }
                obj.put("isError", msg.isError)
                obj.put("isVoiceInput", msg.isVoiceInput)
                array.put(obj)
            }
            val file = File(context.filesDir, CHAT_FILE)
            file.writeText(array.toString())
        } catch (e: Exception) {
            Log.e(TAG, "Error saving chat history: ${e.message}")
        }
    }

    /**
     * Clears all persisted chat messages from local disk.
     */
    fun clearChatHistory() {
        try {
            val file = File(context.filesDir, CHAT_FILE)
            if (file.exists()) {
                file.delete()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error clearing chat history: ${e.message}")
        }
    }

    /**
     * Loads learned memory facts from disk.
     */
    fun loadMemory(): AiBusinessMemory {
        val file = File(context.filesDir, MEMORY_FILE)
        if (!file.exists()) return AiBusinessMemory()

        return try {
            val json = JSONObject(file.readText())
            val freqClients = mutableListOf<String>()
            val clientsArr = json.optJSONArray("frequentClients")
            if (clientsArr != null) {
                for (i in 0 until clientsArr.length()) freqClients.add(clientsArr.getString(i))
            }

            val freqServices = mutableListOf<String>()
            val servArr = json.optJSONArray("frequentServices")
            if (servArr != null) {
                for (i in 0 until servArr.length()) freqServices.add(servArr.getString(i))
            }

            val recentTopics = mutableListOf<String>()
            val topicsArr = json.optJSONArray("recentDiscussionTopics")
            if (topicsArr != null) {
                for (i in 0 until topicsArr.length()) recentTopics.add(topicsArr.getString(i))
            }

            val notes = mutableListOf<String>()
            val notesArr = json.optJSONArray("learnedNotes")
            if (notesArr != null) {
                for (i in 0 until notesArr.length()) notes.add(notesArr.getString(i))
            }

            AiBusinessMemory(
                preferredLanguage = json.optString("preferredLanguage", "English / Hindi"),
                voiceSpeakingCount = json.optInt("voiceSpeakingCount", 0),
                textMessageCount = json.optInt("textMessageCount", 0),
                lastVisitTime = json.optLong("lastVisitTime", System.currentTimeMillis()),
                frequentClients = freqClients,
                frequentServices = freqServices,
                recentDiscussionTopics = recentTopics,
                learnedNotes = notes
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error loading business memory: ${e.message}")
            AiBusinessMemory()
        }
    }

    /**
     * Analyzes each chat interaction, learns the user's speaking habits,
     * extracts business context, and saves to memory.
     */
    fun learnFromTurn(
        userPrompt: String,
        isVoice: Boolean,
        aiResult: AiActionResult?,
        existingClients: List<ClientEntity>
    ) {
        try {
            val current = loadMemory()
            val lower = userPrompt.lowercase(Locale.ROOT)

            // Detect language & tone
            val isHindiSpoken = lower.contains("namaste") || lower.contains("kaise") || lower.contains("baki") ||
                    lower.contains("kitna") || lower.contains("hisaab") || lower.contains("banao") ||
                    lower.contains("kharcha") || lower.contains("paisa") || lower.contains("kisko") ||
                    lower.contains("kripya") || lower.contains("dhanyawad") || lower.contains("bhai") ||
                    userPrompt.any { it in '\u0900'..'\u097F' }

            val detectedLang = if (isHindiSpoken) "Hindi / Hinglish" else current.preferredLanguage

            // Update voice / text counts
            val newVoiceCount = if (isVoice) current.voiceSpeakingCount + 1 else current.voiceSpeakingCount
            val newTextCount = if (!isVoice) current.textMessageCount + 1 else current.textMessageCount

            // Identify mentioned clients
            val updatedClients = current.frequentClients.toMutableList()
            existingClients.forEach { c ->
                if ((lower.contains(c.name.lowercase(Locale.ROOT)) ||
                            (c.companyName.isNotBlank() && lower.contains(c.companyName.lowercase(Locale.ROOT)))) &&
                    !updatedClients.contains(c.name)
                ) {
                    updatedClients.add(0, c.name)
                }
            }
            if (aiResult?.clientToSave != null && !updatedClients.contains(aiResult.clientToSave.name)) {
                updatedClients.add(0, aiResult.clientToSave.name)
            }

            // Extract topic / context notes
            val updatedTopics = current.recentDiscussionTopics.toMutableList()
            when {
                lower.contains("pending") || lower.contains("baki") || lower.contains("overdue") -> {
                    updatedTopics.removeAll { it.contains("pending", true) || it.contains("due", true) }
                    updatedTopics.add(0, "Pending collections & overdue tracking")
                }
                lower.contains("invoice") || lower.contains("bill") || lower.contains("banao") -> {
                    val clientTarget = aiResult?.invoiceToGenerate?.clientName ?: ""
                    val desc = if (clientTarget.isNotBlank()) "Invoice creation for $clientTarget" else "Invoice generation"
                    updatedTopics.removeAll { it.startsWith("Invoice") }
                    updatedTopics.add(0, desc)
                }
                lower.contains("expense") || lower.contains("kharcha") -> {
                    updatedTopics.removeAll { it.contains("expense", true) }
                    updatedTopics.add(0, "Expense logging & cash tracking")
                }
                lower.contains("tax") || lower.contains("gst") -> {
                    updatedTopics.removeAll { it.contains("tax", true) || it.contains("gst", true) }
                    updatedTopics.add(0, "Tax / GST consultation")
                }
            }

            val updatedMemory = current.copy(
                preferredLanguage = detectedLang,
                voiceSpeakingCount = newVoiceCount,
                textMessageCount = newTextCount,
                lastVisitTime = System.currentTimeMillis(),
                frequentClients = updatedClients.take(10),
                recentDiscussionTopics = updatedTopics.take(6)
            )

            saveMemory(updatedMemory)
        } catch (e: Exception) {
            Log.e(TAG, "Error learning from conversation turn: ${e.message}")
        }
    }

    private fun saveMemory(memory: AiBusinessMemory) {
        try {
            val json = JSONObject()
            json.put("preferredLanguage", memory.preferredLanguage)
            json.put("voiceSpeakingCount", memory.voiceSpeakingCount)
            json.put("textMessageCount", memory.textMessageCount)
            json.put("lastVisitTime", memory.lastVisitTime)

            val clientsArr = JSONArray()
            memory.frequentClients.forEach { clientsArr.put(it) }
            json.put("frequentClients", clientsArr)

            val servArr = JSONArray()
            memory.frequentServices.forEach { servArr.put(it) }
            json.put("frequentServices", servArr)

            val topicsArr = JSONArray()
            memory.recentDiscussionTopics.forEach { topicsArr.put(it) }
            json.put("recentDiscussionTopics", topicsArr)

            val notesArr = JSONArray()
            memory.learnedNotes.forEach { notesArr.put(it) }
            json.put("learnedNotes", notesArr)

            val file = File(context.filesDir, MEMORY_FILE)
            file.writeText(json.toString())
        } catch (e: Exception) {
            Log.e(TAG, "Error saving memory: ${e.message}")
        }
    }

    /**
     * Generates intelligent, dynamic predictions of what the user is going to ask or do next,
     * conditioned on real-time database state (overdue invoices, pending payments, active clients)
     * and past chat conversation patterns.
     */
    fun generateDynamicPredictions(
        invoices: List<InvoiceEntity>,
        clients: List<ClientEntity>,
        expenses: List<ExpenseEntity>,
        currencySymbol: String
    ): List<String> {
        val memory = loadMemory()
        val isHindi = memory.preferredLanguage.contains("Hindi", true)
        val predictions = mutableListOf<String>()

        // 1. Overdue Invoice Prediction (Top Priority)
        val overdueInv = invoices.firstOrNull { it.status.equals("overdue", true) }
        if (overdueInv != null) {
            val items = InvoiceUtils.deserializeInvoiceItems(overdueInv.itemsJson)
            val calcs = InvoiceUtils.calculateInvoice(items, overdueInv.taxRate, overdueInv.discountPercent, overdueInv.discountAmount, overdueInv.shippingFee, overdueInv.amountPaid)
            val amountStr = "$currencySymbol${String.format(Locale.US, "%,.0f", calcs.balanceDue)}"
            if (isHindi) {
                predictions.add("⚠️ ${overdueInv.clientName} का $amountStr ओवरड्यू है - फॉलो-अप रिमाइंडर भेजें?")
            } else {
                predictions.add("⚠️ Follow up on overdue #$overdueInv.invoiceNumber ($amountStr - ${overdueInv.clientName})")
            }
        }

        // 2. Pending Collections Prediction
        val pendingCount = invoices.count { !it.status.equals("paid", true) }
        if (pendingCount > 0) {
            if (isHindi) {
                predictions.add("💰 कुल कितना पेंडिंग पेमेंट बाकी है?")
            } else {
                predictions.add("💰 Check all pending collections & dues")
            }
        }

        // 3. Repeat / Frequent Client Bill Prediction
        val topClientName = memory.frequentClients.firstOrNull() ?: clients.firstOrNull()?.name
        if (!topClientName.isNullOrBlank()) {
            if (isHindi) {
                predictions.add("⚡ $topClientName के लिए नया बिल बना दो")
            } else {
                predictions.add("⚡ Create new invoice for $topClientName")
            }
        }

        // 4. Financial Health & Net Profit Overview
        if (isHindi) {
            predictions.add("📊 इस महीने का पूरा रेवेन्यू और मुनाफा दिखाओ")
        } else {
            predictions.add("📊 Show complete revenue & net profit overview")
        }

        // 5. Expense Recording
        if (isHindi) {
            predictions.add("💸 आज का नया बिज़नेस खर्चा दर्ज करो")
        } else {
            predictions.add("💸 Record a business expense or receipt")
        }

        // 6. Active Clients Directory
        if (clients.isNotEmpty()) {
            if (isHindi) {
                predictions.add("👥 मेरे एक्टिव क्लाइंट्स की लिस्ट दिखाओ")
            } else {
                predictions.add("👥 Who are my active clients?")
            }
        }

        // 7. Contextual follow-up from recent chat topic
        val lastTopic = memory.recentDiscussionTopics.firstOrNull()
        if (lastTopic != null && lastTopic.contains("Tax", true)) {
            predictions.add(if (isHindi) "💡 मेरे बिज़नेस के लिए GST टैक्स बचत टिप्स" else "💡 Best tax saving strategies for my business")
        }

        return predictions
    }

    /**
     * Generates a warm, highly competent Executive Employee Greeting
     * summarizing real-time records and welcoming the user.
     */
    fun createExecutiveGreeting(
        profile: BusinessProfile,
        invoices: List<InvoiceEntity>,
        clients: List<ClientEntity>
    ): ChatMessage {
        val memory = loadMemory()
        val currSym = profile.defaultCurrencySymbol.ifBlank { "$" }

        var totalPending = 0.0
        var totalOverdue = 0.0
        var overdueCount = 0
        var pendingCount = 0

        invoices.forEach { inv ->
            val items = InvoiceUtils.deserializeInvoiceItems(inv.itemsJson)
            val calcs = InvoiceUtils.calculateInvoice(items, inv.taxRate, inv.discountPercent, inv.discountAmount, inv.shippingFee, inv.amountPaid)
            if (!inv.status.equals("paid", true)) {
                totalPending += calcs.balanceDue
                pendingCount++
                if (inv.status.equals("overdue", true)) {
                    totalOverdue += calcs.balanceDue
                    overdueCount++
                }
            }
        }

        val isHindi = memory.preferredLanguage.contains("Hindi", true)
        val text = if (isHindi) {
            "नमस्ते सर! 👋 मैं हूँ **Invoicely AI**, आपका समर्पित स्मार्ट बिज़नेस एम्प्लॉई।\n\n" +
            "मैंने आपके सभी रिकॉर्ड्स का पूरा हिसाब तैयार रखा है:\n" +
            "• 💰 **पेंडिंग पेमेंट**: **$currSym${String.format(Locale.US, "%,.2f", totalPending)}** ($pendingCount इनवॉइस)\n" +
            (if (overdueCount > 0) "• ⚠️ **ओवरड्यू**: **$currSym${String.format(Locale.US, "%,.2f", totalOverdue)}** ($overdueCount इनवॉइस समय से पीछे हैं)\n" else "") +
            "• 👥 **क्लाइंट्स**: ${clients.size} एक्टिव क्लाइंट्स\n\n" +
            "आप नीचे दिए गए **माइक (Mic) आइकॉन** पर टैप करके मुझसे स्वाभाविक रूप से हिंदी या इंग्लिश में बोलकर बात कर सकते हैं, या कोई भी कमांड दे सकते हैं!"
        } else {
            "Hello, Sir! 👋 I am **Invoicely AI**, your dedicated Smart Business Employee & Executive Partner.\n\n" +
            "I've been keeping continuous track of all your records:\n" +
            "• 💰 **Pending Collections**: **$currSym${String.format(Locale.US, "%,.2f", totalPending)}** ($pendingCount invoice${if (pendingCount != 1) "s" else ""})\n" +
            (if (overdueCount > 0) "• ⚠️ **Overdue Dues**: **$currSym${String.format(Locale.US, "%,.2f", totalOverdue)}** ($overdueCount overdue)\n" else "") +
            "• 👥 **Active Clients**: ${clients.size} recorded in your system\n\n" +
            "You can tap the **Mic button** below to talk with me natively by voice, ask for any bill or report, or choose a smart suggestion below!"
        }

        return ChatMessage(
            text = text,
            isUser = false
        )
    }
}
