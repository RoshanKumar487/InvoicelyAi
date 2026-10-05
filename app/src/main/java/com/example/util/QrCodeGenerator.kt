package com.example.util

import android.graphics.Bitmap
import android.graphics.Color
import com.google.zxing.BarcodeFormat
import com.google.zxing.EncodeHintType
import com.google.zxing.qrcode.QRCodeWriter
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel
import java.net.URLEncoder
import java.util.EnumMap
import java.util.Locale

/**
 * Utility for generating high-resolution QR codes and creating interoperable Indian UPI payment URIs
 * for instant customer scan-to-pay via Google Pay, PhonePe, Paytm, BHIM, Cred, and mobile banking apps.
 */
object QrCodeGenerator {

    /**
     * Builds an NPCI standard UPI Payment URI.
     * Format: upi://pay?pa=...&pn=...&am=...&cu=INR&tn=...
     */
    fun buildUpiPaymentUri(
        upiId: String,
        payeeName: String,
        amount: Double,
        invoiceNumber: String,
        currency: String = "INR"
    ): String {
        val cleanUpi = upiId.trim()
        if (cleanUpi.isBlank()) return ""

        val encodedName = URLEncoder.encode(payeeName.ifBlank { "Merchant" }, "UTF-8")
        val encodedNote = URLEncoder.encode("Inv $invoiceNumber", "UTF-8")
        val amountStr = String.format(Locale.US, "%.2f", maxOf(0.0, amount))

        return "upi://pay?pa=$cleanUpi&pn=$encodedName&am=$amountStr&cu=$currency&tn=$encodedNote"
    }

    /**
     * Generates a square QR Code [Bitmap] from given content string.
     */
    fun generateQrBitmap(
        content: String,
        sizePx: Int = 300,
        darkColor: Int = Color.BLACK,
        lightColor: Int = Color.WHITE
    ): Bitmap? {
        if (content.isBlank()) return null
        return try {
            val hints = EnumMap<EncodeHintType, Any>(EncodeHintType::class.java).apply {
                put(EncodeHintType.CHARACTER_SET, "UTF-8")
                put(EncodeHintType.MARGIN, 1)
                put(EncodeHintType.ERROR_CORRECTION, ErrorCorrectionLevel.M)
            }

            val writer = QRCodeWriter()
            val bitMatrix = writer.encode(content, BarcodeFormat.QR_CODE, sizePx, sizePx, hints)
            val width = bitMatrix.width
            val height = bitMatrix.height
            val pixels = IntArray(width * height)

            for (y in 0 until height) {
                val offset = y * width
                for (x in 0 until width) {
                    pixels[offset + x] = if (bitMatrix.get(x, y)) darkColor else lightColor
                }
            }

            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            bitmap.setPixels(pixels, 0, width, 0, 0, width, height)
            bitmap
        } catch (_: Exception) {
            null
        }
    }
}
