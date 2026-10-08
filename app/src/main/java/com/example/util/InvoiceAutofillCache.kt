package com.example.util

import android.content.Context
import android.content.SharedPreferences
import com.example.data.model.ClientEntity
import com.example.data.model.InvoiceEntity
import com.example.data.model.InvoiceItem
import com.example.data.model.InvoiceUtils
import org.json.JSONArray
import org.json.JSONObject

data class AutofillItemSuggestion(
    val description: String,
    val unit: String,
    val unitPrice: Double,
    val taxRate: Double = 0.0,
    val hsnOrSac: String = "",
    val sourceLabel: String = "",
    val isCompanySpecific: Boolean = false,
    val customFields: Map<String, String> = emptyMap()
)

object InvoiceAutofillCache {

    private const val PREFS_NAME = "invoicely_browser_cache"
    private const val KEY_RECENT_ITEMS = "cache_recent_items"
    private const val KEY_RECENT_UNITS = "cache_recent_units"
    private const val KEY_RECENT_COMPANIES = "cache_recent_companies"

    val standardUnits = listOf(
        "days", "hrs", "month", "shift", "person", "duty", "candidate",
        "pcs", "units", "sqft", "trip", "kg", "box"
    )

    private fun getPrefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    /**
     * Cache an item entry when an invoice is created/saved.
     */
    fun recordInvoiceSaved(context: Context, invoice: InvoiceEntity, items: List<InvoiceItem>) {
        try {
            val prefs = getPrefs(context)
            val existingJson = prefs.getString(KEY_RECENT_ITEMS, "[]") ?: "[]"
            val array = JSONArray(existingJson)

            val companyName = invoice.clientCompany.trim()
            val clientId = invoice.clientId

            for (item in items) {
                if (item.description.isBlank()) continue
                val obj = JSONObject().apply {
                    put("desc", item.description.trim())
                    put("unit", item.unit.trim())
                    put("rate", item.unitPrice)
                    put("tax", item.taxRate)
                    put("hsn", item.customFields["hsn"] ?: item.customFields["sac"] ?: "")
                    put("company", companyName)
                    put("clientId", clientId ?: -1L)
                    put("ts", System.currentTimeMillis())
                }
                array.put(obj)
            }

            // Keep most recent 100 items
            val trimmedArray = JSONArray()
            val startIdx = maxOf(0, array.length() - 100)
            for (i in startIdx until array.length()) {
                trimmedArray.put(array.get(i))
            }
            prefs.edit().putString(KEY_RECENT_ITEMS, trimmedArray.toString()).apply()

            // Record units
            recordUnits(prefs, items.map { it.unit.trim() })

            // Record company
            if (companyName.isNotBlank()) {
                recordCompany(prefs, companyName)
            }
        } catch (_: Exception) {}
    }

    private fun recordUnits(prefs: SharedPreferences, newUnits: List<String>) {
        val existing = prefs.getStringSet(KEY_RECENT_UNITS, emptySet())?.toMutableSet() ?: mutableSetOf()
        existing.addAll(newUnits.filter { it.isNotBlank() })
        prefs.edit().putStringSet(KEY_RECENT_UNITS, existing).apply()
    }

    private fun recordCompany(prefs: SharedPreferences, company: String) {
        val existing = prefs.getStringSet(KEY_RECENT_COMPANIES, emptySet())?.toMutableSet() ?: mutableSetOf()
        existing.add(company)
        prefs.edit().putStringSet(KEY_RECENT_COMPANIES, existing).apply()
    }

    /**
     * Find intelligent browser-like autocomplete suggestions for an item description query.
     * Prioritizes:
     * 1. Items previously billed to this specific company/client
     * 2. Items previously billed across any invoice in history / cache
     * 3. Domain templates (Security Agency, Employee/HR, IT, etc.)
     */
    fun getItemSuggestions(
        context: Context,
        query: String,
        clientCompany: String,
        clientId: Long?,
        allInvoices: List<InvoiceEntity>
    ): List<AutofillItemSuggestion> {
        val results = mutableListOf<AutofillItemSuggestion>()
        val seenDescriptions = mutableSetOf<String>()
        val trimmedQuery = query.trim().lowercase()
        val trimmedCompany = clientCompany.trim()

        // 1. Search in historical invoices specifically for THIS company
        if (trimmedCompany.isNotBlank() || clientId != null) {
            val companyInvoices = allInvoices.filter { inv ->
                (clientId != null && inv.clientId == clientId) ||
                (trimmedCompany.isNotBlank() && inv.clientCompany.trim().equals(trimmedCompany, ignoreCase = true))
            }

            for (inv in companyInvoices) {
                val invItems = InvoiceUtils.deserializeInvoiceItems(inv.itemsJson)
                for (item in invItems) {
                    val desc = item.description.trim()
                    if (desc.isNotBlank() && (trimmedQuery.isEmpty() || desc.lowercase().contains(trimmedQuery))) {
                        val key = desc.lowercase()
                        if (seenDescriptions.add(key)) {
                            results.add(
                                AutofillItemSuggestion(
                                    description = desc,
                                    unit = item.unit,
                                    unitPrice = item.unitPrice,
                                    taxRate = item.taxRate,
                                    hsnOrSac = item.customFields["hsn"] ?: item.customFields["sac"] ?: "",
                                    sourceLabel = "★ Billed to $trimmedCompany",
                                    isCompanySpecific = true,
                                    customFields = item.customFields
                                )
                            )
                        }
                    }
                }
            }
        }

        // 2. Search across ALL previous invoices from Room DB
        for (inv in allInvoices) {
            val invItems = InvoiceUtils.deserializeInvoiceItems(inv.itemsJson)
            for (item in invItems) {
                val desc = item.description.trim()
                if (desc.isNotBlank() && (trimmedQuery.isEmpty() || desc.lowercase().contains(trimmedQuery))) {
                    val key = desc.lowercase()
                    if (seenDescriptions.add(key)) {
                        results.add(
                            AutofillItemSuggestion(
                                description = desc,
                                unit = item.unit,
                                unitPrice = item.unitPrice,
                                taxRate = item.taxRate,
                                hsnOrSac = item.customFields["hsn"] ?: item.customFields["sac"] ?: "",
                                sourceLabel = "🕒 Previous Invoice (${inv.invoiceNumber})",
                                isCompanySpecific = false,
                                customFields = item.customFields
                            )
                        )
                    }
                }
            }
        }

        // 3. Search in domain / industry item catalog (Security Agency, Employee/HR Salary, IT, etc.)
        for (catItem in IndustryItemCatalog.getAllItems()) {
            val desc = catItem.description.trim()
            if (trimmedQuery.isEmpty() || desc.lowercase().contains(trimmedQuery) || catItem.subtitle.lowercase().contains(trimmedQuery)) {
                val key = desc.lowercase()
                if (seenDescriptions.add(key)) {
                    results.add(
                        AutofillItemSuggestion(
                            description = desc,
                            unit = catItem.unit,
                            unitPrice = catItem.unitPrice,
                            taxRate = catItem.taxRate,
                            hsnOrSac = catItem.hsnOrSac,
                            sourceLabel = "Catalog • ${catItem.subtitle}",
                            isCompanySpecific = false,
                            customFields = catItem.customFields
                        )
                    )
                }
            }
        }

        return results.take(12)
    }

    /**
     * Retrieve the last invoice for a given company or client to allow 1-tap "Repeat Last Items".
     */
    fun getLastInvoiceForCompany(
        clientCompany: String,
        clientId: Long?,
        allInvoices: List<InvoiceEntity>
    ): InvoiceEntity? {
        val trimmedCompany = clientCompany.trim()
        if (trimmedCompany.isBlank() && clientId == null) return null
        return allInvoices.firstOrNull { inv ->
            (clientId != null && inv.clientId == clientId) ||
            (trimmedCompany.isNotBlank() && inv.clientCompany.trim().equals(trimmedCompany, ignoreCase = true))
        }
    }

    /**
     * Get suggested units based on history + standard units.
     */
    fun getSuggestedUnits(context: Context): List<String> {
        val prefs = getPrefs(context)
        val recent = prefs.getStringSet(KEY_RECENT_UNITS, emptySet()) ?: emptySet()
        val combined = LinkedHashSet<String>()
        combined.addAll(recent)
        combined.addAll(standardUnits)
        return combined.toList()
    }

    /**
     * Search company suggestions for fast autocomplete in client details.
     */
    fun getCompanySuggestions(
        query: String,
        allClients: List<ClientEntity>,
        allInvoices: List<InvoiceEntity>
    ): List<ClientEntity> {
        val trimmed = query.trim().lowercase()
        val matches = mutableListOf<ClientEntity>()
        val seen = mutableSetOf<String>()

        for (c in allClients) {
            val name = c.companyName.ifBlank { c.name }.trim()
            if (trimmed.isEmpty() || name.lowercase().contains(trimmed)) {
                if (seen.add(name.lowercase())) {
                    matches.add(c)
                }
            }
        }

        for (inv in allInvoices) {
            val comp = inv.clientCompany.trim()
            if (comp.isNotBlank() && (trimmed.isEmpty() || comp.lowercase().contains(trimmed))) {
                if (seen.add(comp.lowercase())) {
                    matches.add(
                        ClientEntity(
                            id = inv.clientId ?: 0L,
                            name = inv.clientName.ifBlank { comp },
                            companyName = comp,
                            email = inv.clientEmail,
                            phone = inv.clientPhone,
                            address = inv.clientAddress,
                            taxId = inv.clientTaxId,
                            defaultPaymentTerms = inv.paymentTerms
                        )
                    )
                }
            }
        }

        return matches.take(8)
    }
}
