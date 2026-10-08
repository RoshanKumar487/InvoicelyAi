package com.example.util

import java.util.Locale
import kotlin.math.roundToLong

/**
 * Utility for formatting currency numbers and converting amounts into formal Indian numbering words
 * (Crores, Lakhs, Thousands, Hundreds, Rupees, and Paise), compliant with Indian GST & accounting rules.
 * Also gracefully handles international currencies (USD, EUR, GBP).
 */
object IndianCurrencyUtils {

    private val units = arrayOf(
        "", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine",
        "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen"
    )

    private val tens = arrayOf(
        "", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"
    )

    /**
     * Converts a financial amount into words with Indian accounting convention (Lakhs & Crores).
     * Example: 185250.50 -> "One Lakh Eighty-Five Thousand Two Hundred Fifty Rupees and Fifty Paise Only"
     */
    fun convertToWords(amount: Double, currencyCode: String = "INR"): String {
        if (amount == 0.0) {
            val unitName = if (currencyCode.equals("INR", ignoreCase = true)) "Rupees" else "Dollars"
            return "Zero $unitName Only"
        }

        val isNegative = amount < 0
        val positiveAmount = kotlin.math.abs(amount)

        val wholePart = positiveAmount.toLong()
        val decimalPart = ((positiveAmount - wholePart) * 100).roundToLong()

        val isInr = currencyCode.equals("INR", ignoreCase = true) || currencyCode.isBlank()

        val words = if (isInr) {
            convertIndianWhole(wholePart)
        } else {
            convertWesternWhole(wholePart)
        }

        val mainCurrency = if (isInr) {
            if (wholePart == 1L) "Rupee" else "Rupees"
        } else {
            if (wholePart == 1L) "Dollar" else "Dollars"
        }

        val subCurrency = if (isInr) "Paise" else "Cents"

        val sb = StringBuilder()
        if (isNegative) sb.append("Minus ")
        sb.append(words).append(" ").append(mainCurrency)

        if (decimalPart > 0) {
            sb.append(" and ")
            sb.append(convertUnderThousand(decimalPart.toInt()))
            sb.append(" ").append(subCurrency)
        }

        sb.append(" Only")
        return sb.toString().replace(Regex("\\s+"), " ").trim()
    }

    private fun convertIndianWhole(n: Long): String {
        if (n == 0L) return "Zero"

        var remaining = n
        val sb = StringBuilder()

        // Crores (10,000,000)
        val crores = remaining / 10_000_000L
        if (crores > 0) {
            sb.append(convertIndianWhole(crores)).append(" Crore ")
            remaining %= 10_000_000L
        }

        // Lakhs (100,000)
        val lakhs = remaining / 100_000L
        if (lakhs > 0) {
            sb.append(convertUnderHundred(lakhs.toInt())).append(" Lakh ")
            remaining %= 100_000L
        }

        // Thousands (1,000)
        val thousands = remaining / 1_000L
        if (thousands > 0) {
            sb.append(convertUnderHundred(thousands.toInt())).append(" Thousand ")
            remaining %= 1_000L
        }

        // Hundreds (100)
        val hundreds = remaining / 100L
        if (hundreds > 0) {
            sb.append(units[hundreds.toInt()]).append(" Hundred ")
            remaining %= 100L
        }

        // Remainder (< 100)
        if (remaining > 0) {
            sb.append(convertUnderHundred(remaining.toInt())).append(" ")
        }

        return sb.toString().trim()
    }

    private fun convertWesternWhole(n: Long): String {
        if (n == 0L) return "Zero"
        var remaining = n
        val sb = StringBuilder()

        val billions = remaining / 1_000_000_000L
        if (billions > 0) {
            sb.append(convertUnderThousand(billions.toInt())).append(" Billion ")
            remaining %= 1_000_000_000L
        }

        val millions = remaining / 1_000_000L
        if (millions > 0) {
            sb.append(convertUnderThousand(millions.toInt())).append(" Million ")
            remaining %= 1_000_000L
        }

        val thousands = remaining / 1_000L
        if (thousands > 0) {
            sb.append(convertUnderThousand(thousands.toInt())).append(" Thousand ")
            remaining %= 1_000L
        }

        if (remaining > 0) {
            sb.append(convertUnderThousand(remaining.toInt())).append(" ")
        }

        return sb.toString().trim()
    }

    private fun convertUnderThousand(n: Int): String {
        val hundreds = n / 100
        val rem = n % 100
        val sb = StringBuilder()
        if (hundreds > 0) {
            sb.append(units[hundreds]).append(" Hundred ")
        }
        if (rem > 0) {
            sb.append(convertUnderHundred(rem))
        }
        return sb.toString().trim()
    }

    private fun convertUnderHundred(n: Int): String {
        return when {
            n < 20 -> units[n]
            n % 10 == 0 -> tens[n / 10]
            else -> "${tens[n / 10]} ${units[n % 10]}"
        }
    }
}
