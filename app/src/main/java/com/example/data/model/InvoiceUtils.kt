package com.example.data.model

import org.json.JSONArray
import org.json.JSONObject
import java.util.Locale

object InvoiceUtils {

    fun serializeInvoiceItems(items: List<InvoiceItem>): String {
        val array = JSONArray()
        for (item in items) {
            val obj = JSONObject()
            obj.put("id", item.id)
            obj.put("description", item.description)
            obj.put("quantity", item.quantity)
            obj.put("unitPrice", item.unitPrice)
            obj.put("unit", item.unit)
            obj.put("taxRate", item.taxRate)
            obj.put("discountRate", item.discountRate)

            val customObj = JSONObject()
            item.customFields.forEach { (k, v) -> customObj.put(k, v) }
            obj.put("customFields", customObj)

            array.put(obj)
        }
        return array.toString()
    }

    fun deserializeInvoiceItems(json: String?): List<InvoiceItem> {
        if (json.isNullOrBlank()) return emptyList()
        val list = mutableListOf<InvoiceItem>()
        try {
            val array = JSONArray(json)
            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)
                val customMap = mutableMapOf<String, String>()
                val customObj = obj.optJSONObject("customFields")
                if (customObj != null) {
                    val keys = customObj.keys()
                    while (keys.hasNext()) {
                        val k = keys.next()
                        customMap[k] = customObj.optString(k, "")
                    }
                }

                list.add(
                    InvoiceItem(
                        id = obj.optString("id", java.util.UUID.randomUUID().toString()),
                        description = obj.optString("description", ""),
                        quantity = obj.optDouble("quantity", 1.0),
                        unitPrice = obj.optDouble("unitPrice", 0.0),
                        unit = obj.optString("unit", "hrs"),
                        taxRate = obj.optDouble("taxRate", 0.0),
                        discountRate = obj.optDouble("discountRate", 0.0),
                        customFields = customMap
                    )
                )
            }
        } catch (_: Exception) {
            // Return empty list on parse error
        }
        return list
    }

    fun calculateInvoice(
        items: List<InvoiceItem>,
        taxRate: Double,
        discountPercent: Double,
        discountAmount: Double,
        shippingFee: Double,
        amountPaid: Double,
        additionalCharges: Double = 0.0,
        roundOff: Double = 0.0,
        isTaxInclusive: Boolean = false
    ): InvoiceCalculations {
        val subtotal = items.sumOf { it.quantity * it.unitPrice }
        val itemDiscounts = items.sumOf { (it.quantity * it.unitPrice) * (it.discountRate / 100.0) }
        val percentDiscount = (subtotal - itemDiscounts) * (discountPercent / 100.0)
        val totalDiscount = itemDiscounts + percentDiscount + discountAmount
        val taxableBase = maxOf(0.0, subtotal - totalDiscount)
        val taxTotal = if (isTaxInclusive) {
            taxableBase - (taxableBase / (1.0 + (taxRate / 100.0)))
        } else {
            taxableBase * (taxRate / 100.0)
        }
        val grossBeforeRound = if (isTaxInclusive) {
            taxableBase + shippingFee + additionalCharges
        } else {
            taxableBase + taxTotal + shippingFee + additionalCharges
        }
        val grandTotal = maxOf(0.0, grossBeforeRound + roundOff)
        val balanceDue = maxOf(0.0, grandTotal - amountPaid)

        return InvoiceCalculations(
            subtotal = subtotal,
            discountTotal = totalDiscount,
            taxTotal = taxTotal,
            shipping = shippingFee,
            grandTotal = grandTotal,
            amountPaid = amountPaid,
            balanceDue = balanceDue,
            additionalCharges = additionalCharges,
            roundOff = roundOff
        )
    }

    fun formatMoney(amount: Double, currencySymbol: String = "$"): String {
        return "$currencySymbol${String.format(Locale.US, "%,.2f", amount)}"
    }

    /**
     * Converts a numeric currency amount to English words (e.g. "Rupees Forty-Five Thousand Only")
     * Standard Indian Business / Zoho format.
     */
    fun amountInWords(amount: Double, currencyCode: String = "INR"): String {
        val wholePart = amount.toLong()
        val paise = Math.round((amount - wholePart) * 100).toInt()
        val currencyWord = when (currencyCode.uppercase()) {
            "INR" -> "Rupees"
            "USD" -> "US Dollars"
            "EUR" -> "Euros"
            "GBP" -> "Pounds"
            else -> currencyCode
        }

        if (wholePart == 0L) {
            return if (paise > 0) "Zero $currencyWord and $paise Cents Only" else "Zero $currencyWord Only"
        }

        val words = convertNumberToWords(wholePart)
        val result = StringBuilder(currencyWord).append(" ").append(words)
        if (paise > 0) {
            result.append(" and ").append(convertNumberToWords(paise.toLong())).append(if (currencyCode.equals("INR", true)) " Paise" else " Cents")
        }
        result.append(" Only")
        return result.toString()
    }

    private val units = arrayOf(
        "", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine",
        "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen",
        "Seventeen", "Eighteen", "Nineteen"
    )
    private val tens = arrayOf(
        "", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"
    )

    private fun convertNumberToWords(n: Long): String {
        if (n < 20) return units[n.toInt()]
        if (n < 100) return tens[(n / 10).toInt()] + (if (n % 10 != 0L) "-" + units[(n % 10).toInt()] else "")
        if (n < 1000) return units[(n / 100).toInt()] + " Hundred" + (if (n % 100 != 0L) " and " + convertNumberToWords(n % 100) else "")
        if (n < 100000) return convertNumberToWords(n / 1000) + " Thousand" + (if (n % 1000 != 0L) " " + convertNumberToWords(n % 1000) else "")
        if (n < 10000000) return convertNumberToWords(n / 100000) + " Lakh" + (if (n % 100000 != 0L) " " + convertNumberToWords(n % 100000) else "")
        return convertNumberToWords(n / 10000000) + " Crore" + (if (n % 10000000 != 0L) " " + convertNumberToWords(n % 10000000) else "")
    }

    /**
     * Default list of item columns matching user business profile configurations.
     */
    fun getDefaultColumns(profile: BusinessProfile): List<ItemColumnDef> {
        return listOf(
            ItemColumnDef(id = "col_item", label = profile.colHeaderItem.ifBlank { "Description / Service" }, key = "description", isVisible = true, order = 0, isCustom = false, widthWeight = 2.2f),
            ItemColumnDef(id = "col_hsn", label = "HSN/SAC", key = "hsn", isVisible = false, order = 1, isCustom = true, widthWeight = 0.9f),
            ItemColumnDef(id = "col_qty", label = profile.colHeaderQty.ifBlank { "Qty" }, key = "quantity", isVisible = profile.showItemQty, order = 2, isCustom = false, widthWeight = 0.7f),
            ItemColumnDef(id = "col_unit", label = profile.colHeaderUnit.ifBlank { "Unit" }, key = "unit", isVisible = profile.showItemUnit, order = 3, isCustom = false, widthWeight = 0.7f),
            ItemColumnDef(id = "col_rate", label = profile.colHeaderRate.ifBlank { "Rate" }, key = "unitPrice", isVisible = profile.showItemRate, order = 4, isCustom = false, widthWeight = 1.1f),
            ItemColumnDef(id = "col_discount", label = profile.colHeaderDiscount.ifBlank { "Disc (%)" }, key = "discountRate", isVisible = false, order = 5, isCustom = true, widthWeight = 0.8f),
            ItemColumnDef(id = "col_amount", label = profile.colHeaderAmount.ifBlank { "Amount" }, key = "total", isVisible = true, order = 6, isCustom = false, widthWeight = 1.3f)
        )
    }

    /**
     * Serialize column definitions into JSON.
     */
    fun serializeColumns(columns: List<ItemColumnDef>): String {
        val array = JSONArray()
        columns.sortedBy { it.order }.forEachIndexed { idx, col ->
            val obj = JSONObject()
            obj.put("id", col.id)
            obj.put("label", col.label)
            obj.put("key", col.key)
            obj.put("isVisible", col.isVisible)
            obj.put("order", idx)
            obj.put("isCustom", col.isCustom)
            obj.put("widthWeight", col.widthWeight.toDouble())
            obj.put("dataType", col.dataType)
            obj.put("isRequired", col.isRequired)
            obj.put("calculationType", col.calculationType)
            obj.put("formula", col.formula)
            obj.put("alignment", col.alignment)
            obj.put("dropdownOptions", col.dropdownOptions)
            array.put(obj)
        }
        return array.toString()
    }

    /**
     * Parse column definitions from JSON with fallback to defaults.
     */
    fun deserializeColumns(json: String?, profile: BusinessProfile): List<ItemColumnDef> {
        if (json.isNullOrBlank()) return getDefaultColumns(profile)
        return try {
            val array = JSONArray(json)
            val list = mutableListOf<ItemColumnDef>()
            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)
                list.add(
                    ItemColumnDef(
                        id = obj.optString("id", "col_$i"),
                        label = obj.optString("label", "Column $i"),
                        key = obj.optString("key", "col_$i"),
                        isVisible = obj.optBoolean("isVisible", true),
                        order = obj.optInt("order", i),
                        isCustom = obj.optBoolean("isCustom", false),
                        widthWeight = obj.optDouble("widthWeight", 1.0).toFloat(),
                        dataType = obj.optString("dataType", "text"),
                        isRequired = obj.optBoolean("isRequired", false),
                        calculationType = obj.optString("calculationType", "none"),
                        formula = obj.optString("formula", ""),
                        alignment = obj.optString("alignment", "start"),
                        dropdownOptions = obj.optString("dropdownOptions", "")
                    )
                )
            }
            if (list.isEmpty()) getDefaultColumns(profile) else list.sortedBy { it.order }
        } catch (_: Exception) {
            getDefaultColumns(profile)
        }
    }

    fun serializeShippingDetails(shipping: ShippingDetails): String {
        val obj = JSONObject()
        obj.put("isEnabled", shipping.isEnabled)
        obj.put("sameAsBilling", shipping.sameAsBilling)
        obj.put("sectionTitle", shipping.sectionTitle)
        obj.put("shippingAddress", shipping.shippingAddress)
        obj.put("deliveryAddress", shipping.deliveryAddress)
        obj.put("shippingMethod", shipping.shippingMethod)
        obj.put("courier", shipping.courier)
        obj.put("trackingNumber", shipping.trackingNumber)
        obj.put("expectedDelivery", shipping.expectedDelivery)
        obj.put("warehouse", shipping.warehouse)
        obj.put("deliveryContact", shipping.deliveryContact)
        obj.put("vehicleNumber", shipping.vehicleNumber)
        obj.put("dispatchDate", shipping.dispatchDate)
        return obj.toString()
    }

    fun deserializeShippingDetails(json: String?): ShippingDetails {
        if (json.isNullOrBlank() || json == "{}") return ShippingDetails()
        return try {
            val obj = JSONObject(json)
            ShippingDetails(
                isEnabled = obj.optBoolean("isEnabled", false),
                sameAsBilling = obj.optBoolean("sameAsBilling", false),
                sectionTitle = obj.optString("sectionTitle", "Shipping Details"),
                shippingAddress = obj.optString("shippingAddress", ""),
                deliveryAddress = obj.optString("deliveryAddress", ""),
                shippingMethod = obj.optString("shippingMethod", ""),
                courier = obj.optString("courier", ""),
                trackingNumber = obj.optString("trackingNumber", ""),
                expectedDelivery = obj.optString("expectedDelivery", ""),
                warehouse = obj.optString("warehouse", ""),
                deliveryContact = obj.optString("deliveryContact", ""),
                vehicleNumber = obj.optString("vehicleNumber", ""),
                dispatchDate = obj.optString("dispatchDate", "")
            )
        } catch (_: Exception) {
            ShippingDetails()
        }
    }

    fun serializeCustomFields(fields: List<CustomClientField>): String {
        val array = JSONArray()
        for (f in fields) {
            val obj = JSONObject()
            obj.put("id", f.id)
            obj.put("label", f.label)
            obj.put("value", f.value)
            obj.put("isRequired", f.isRequired)
            array.put(obj)
        }
        return array.toString()
    }

    fun deserializeCustomFields(json: String?): List<CustomClientField> {
        if (json.isNullOrBlank() || json == "{}") return emptyList()
        val list = mutableListOf<CustomClientField>()
        try {
            val array = JSONArray(json)
            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)
                list.add(
                    CustomClientField(
                        id = obj.optString("id", java.util.UUID.randomUUID().toString()),
                        label = obj.optString("label", "Custom Field"),
                        value = obj.optString("value", ""),
                        isRequired = obj.optBoolean("isRequired", false)
                    )
                )
            }
        } catch (_: Exception) {
            // ignore
        }
        return list
    }
}
