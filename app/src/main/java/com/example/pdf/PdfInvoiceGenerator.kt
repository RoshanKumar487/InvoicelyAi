package com.example.pdf

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.DashPathEffect
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.Typeface
import android.graphics.pdf.PdfDocument
import android.graphics.Bitmap
import com.example.data.model.BusinessProfile
import com.example.data.model.InvoiceCalculations
import com.example.data.model.InvoiceEntity
import com.example.data.model.InvoiceItem
import com.example.data.model.InvoiceUtils
import com.example.data.model.TemplateConfig
import com.example.util.IndianCurrencyUtils
import com.example.util.QrCodeGenerator
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * High-fidelity, print-ready PDF generator for Android.
 * Renders invoices to standard A4 (595 x 842 pt) conforming to the selected
 * industry template, letterhead design, and business branding.
 */
object PdfInvoiceGenerator {

    private const val PAGE_WIDTH = 595
    private const val PAGE_HEIGHT = 842
    private const val MARGIN_X = 36f
    private const val MARGIN_RIGHT = PAGE_WIDTH - 36f
    private const val CONTENT_WIDTH = MARGIN_RIGHT - MARGIN_X

    fun generateInvoicePdf(
        context: Context,
        invoice: InvoiceEntity,
        items: List<InvoiceItem>,
        calculations: InvoiceCalculations,
        profile: BusinessProfile,
        templateConfig: TemplateConfig
    ): File {
        val pdfDocument = PdfDocument()
        val pageInfo = PdfDocument.PageInfo.Builder(PAGE_WIDTH, PAGE_HEIGHT, 1).create()
        val page = pdfDocument.startPage(pageInfo)
        val canvas = page.canvas

        // Determine Theme Colors
        val primaryColorInt = try {
            Color.parseColor(templateConfig.primaryColorHex)
        } catch (_: Exception) {
            Color.parseColor("#1E3A8A")
        }

        val secondaryColorInt = try {
            Color.parseColor(templateConfig.secondaryColorHex)
        } catch (_: Exception) {
            Color.parseColor("#0D9488")
        }

        // Paints
        val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG)
        val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
        }
        val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.NORMAL)
        }

        // 1. Draw Page Background
        canvas.drawColor(Color.WHITE)

        var currentY = 32f

        // 2. Draw Template Letterhead Header
        val templateId = (invoice.templateId.ifBlank { templateConfig.templateId }).lowercase()

        when {
            templateId.contains("corporate") || templateId.contains("enterprise") -> {
                // Solid Top Banner Band
                fillPaint.color = primaryColorInt
                canvas.drawRect(0f, 0f, PAGE_WIDTH.toFloat(), 70f, fillPaint)

                textPaint.color = Color.WHITE
                textPaint.typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)
                textPaint.textSize = 20f
                canvas.drawText(profile.businessName.ifBlank { "Apex Nova Dynamics" }, MARGIN_X, 42f, textPaint)

                textPaint.textSize = 10f
                textPaint.typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.NORMAL)
                textPaint.color = Color.parseColor("#E2E8F0")
                canvas.drawText(profile.legalName.ifBlank { profile.email }, MARGIN_X, 58f, textPaint)

                // Top right doc title
                textPaint.textSize = 18f
                textPaint.typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)
                textPaint.color = Color.WHITE
                val titleWidth = textPaint.measureText(templateConfig.docxTitle)
                canvas.drawText(templateConfig.docxTitle, MARGIN_RIGHT - titleWidth, 44f, textPaint)

                currentY = 88f
            }
            templateId.contains("ecommerce") -> {
                // E-Commerce Dispatch Top Header
                fillPaint.color = Color.parseColor("#0F172A")
                canvas.drawRect(0f, 0f, PAGE_WIDTH.toFloat(), 56f, fillPaint)

                textPaint.color = Color.WHITE
                textPaint.typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)
                textPaint.textSize = 16f
                canvas.drawText(profile.businessName.ifBlank { "Apex Store Logistics" }, MARGIN_X, 34f, textPaint)

                textPaint.textSize = 10f
                textPaint.color = Color.parseColor("#38BDF8")
                val dispatchTag = "DISPATCH & FULFILLMENT SLIP"
                val tagWidth = textPaint.measureText(dispatchTag)
                canvas.drawText(dispatchTag, MARGIN_RIGHT - tagWidth, 34f, textPaint)

                currentY = 72f
            }
            templateId.contains("classic") -> {
                // Classic Centered Letterhead
                textPaint.color = primaryColorInt
                textPaint.typeface = Typeface.create(Typeface.SERIF, Typeface.BOLD)
                textPaint.textSize = 22f
                val bName = profile.businessName.ifBlank { "Apex Nova Dynamics" }
                val bWidth = textPaint.measureText(bName)
                canvas.drawText(bName, (PAGE_WIDTH - bWidth) / 2f, currentY + 18f, textPaint)

                textPaint.textSize = 9f
                textPaint.typeface = Typeface.create(Typeface.SERIF, Typeface.NORMAL)
                textPaint.color = Color.parseColor("#64748B")
                val subline = "${profile.legalName} • ${profile.address.replace("\n", ", ")}"
                val sublineWidth = textPaint.measureText(subline)
                canvas.drawText(subline, (PAGE_WIDTH - sublineWidth) / 2f, currentY + 34f, textPaint)

                strokePaint.color = primaryColorInt
                strokePaint.strokeWidth = 2f
                canvas.drawLine(MARGIN_X, currentY + 44f, MARGIN_RIGHT, currentY + 44f, strokePaint)
                strokePaint.strokeWidth = 0.5f
                canvas.drawLine(MARGIN_X, currentY + 47f, MARGIN_RIGHT, currentY + 47f, strokePaint)

                currentY += 60f
            }
            templateId.contains("tech") -> {
                // Tech Strip Header
                fillPaint.color = primaryColorInt
                canvas.drawRect(MARGIN_X, currentY, MARGIN_X + 6f, currentY + 44f, fillPaint)

                textPaint.color = primaryColorInt
                textPaint.typeface = Typeface.create(Typeface.MONOSPACE, Typeface.BOLD)
                textPaint.textSize = 18f
                canvas.drawText(profile.businessName.ifBlank { "Apex Tech Labs" }, MARGIN_X + 14f, currentY + 20f, textPaint)

                textPaint.textSize = 9f
                textPaint.typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.NORMAL)
                textPaint.color = Color.parseColor("#64748B")
                canvas.drawText("ENTERPRISE IT & CLOUD SERVICES • ${profile.email}", MARGIN_X + 14f, currentY + 36f, textPaint)

                currentY += 56f
            }
            else -> {
                // Minimalist / Clean Letterhead
                textPaint.color = primaryColorInt
                textPaint.typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)
                textPaint.textSize = 20f
                canvas.drawText(profile.businessName.ifBlank { "Apex Nova Dynamics" }, MARGIN_X, currentY + 18f, textPaint)

                textPaint.textSize = 9f
                textPaint.typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.NORMAL)
                textPaint.color = Color.parseColor("#64748B")
                val addrLine = profile.address.split("\n").firstOrNull() ?: ""
                canvas.drawText("${profile.legalName} • $addrLine • ${profile.phone}", MARGIN_X, currentY + 34f, textPaint)

                strokePaint.color = primaryColorInt
                strokePaint.strokeWidth = 1.5f
                canvas.drawLine(MARGIN_X, currentY + 42f, MARGIN_RIGHT, currentY + 42f, strokePaint)

                currentY += 54f
            }
        }

        // 3. Invoice Metadata & Status Box
        val metaBoxY = currentY
        val metaColRight = MARGIN_RIGHT
        val metaColLeft = MARGIN_X

        // Left: Business contacts / Tax ID
        textPaint.textSize = 9f
        textPaint.color = Color.parseColor("#475569")
        textPaint.typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.NORMAL)

        var bY = metaBoxY + 10f
        if (profile.address.isNotBlank()) {
            profile.address.split("\n").take(2).forEach { line ->
                canvas.drawText(line.trim(), metaColLeft, bY, textPaint)
                bY += 12f
            }
        }
        val taxIdDisplay = profile.gstin.ifBlank { profile.taxId }
        if (taxIdDisplay.isNotBlank()) {
            canvas.drawText("Tax ID / GSTIN: $taxIdDisplay", metaColLeft, bY, textPaint)
            bY += 12f
        }
        if (profile.email.isNotBlank()) {
            canvas.drawText("Email: ${profile.email} • ${profile.phone}", metaColLeft, bY, textPaint)
            bY += 12f
        }

        // Right: Document Type, Watermark, Invoice #, Date, Due Date, Status Badge
        var rY = metaBoxY + 8f
        val docTypeTitle = invoice.docxTemplateTitle.ifBlank { templateConfig.docxTitle }.uppercase()
        textPaint.textSize = 9.5f
        textPaint.typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)
        textPaint.color = primaryColorInt
        val docTypeWidth = textPaint.measureText(docTypeTitle)
        canvas.drawText(docTypeTitle, metaColRight - docTypeWidth, rY, textPaint)

        rY += 10f
        val copyWatermark = if (invoice.notes.contains("DUPLICATE", ignoreCase = true)) {
            "DUPLICATE FOR TRANSPORTER"
        } else if (invoice.notes.contains("TRIPLICATE", ignoreCase = true)) {
            "TRIPLICATE FOR SUPPLIER"
        } else {
            "ORIGINAL FOR RECIPIENT"
        }
        textPaint.textSize = 6f
        textPaint.typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.NORMAL)
        textPaint.color = Color.parseColor("#64748B")
        val copyWidth = textPaint.measureText(copyWatermark)
        canvas.drawText(copyWatermark, metaColRight - copyWidth, rY, textPaint)

        rY += 14f
        textPaint.textSize = 13f
        textPaint.typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)
        textPaint.color = primaryColorInt
        val invNumText = "#${invoice.invoiceNumber}"
        val invNumWidth = textPaint.measureText(invNumText)
        canvas.drawText(invNumText, metaColRight - invNumWidth, rY, textPaint)

        rY += 14f
        textPaint.textSize = 9f
        textPaint.typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.NORMAL)
        textPaint.color = Color.parseColor("#334155")

        val issueDateText = "Date: ${invoice.issueDate.ifBlank { "Today" }}"
        canvas.drawText(issueDateText, metaColRight - textPaint.measureText(issueDateText), rY, textPaint)

        rY += 12f
        val dueDateText = "Due: ${invoice.dueDate.ifBlank { "Net 30" }}"
        canvas.drawText(dueDateText, metaColRight - textPaint.measureText(dueDateText), rY, textPaint)

        if (invoice.poNumber.isNotBlank()) {
            rY += 12f
            val poText = "PO / Ref: ${invoice.poNumber}"
            canvas.drawText(poText, metaColRight - textPaint.measureText(poText), rY, textPaint)
        }

        // Status Badge Pill
        rY += 14f
        val statusText = invoice.status.uppercase(Locale.US)
        textPaint.textSize = 8.5f
        textPaint.typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)
        val statusTextWidth = textPaint.measureText(statusText)
        val badgeW = statusTextWidth + 14f
        val badgeH = 14f
        val badgeLeft = metaColRight - badgeW
        val badgeTop = rY - 10f

        val (statusBg, statusFg) = when (invoice.status.lowercase()) {
            "paid" -> Pair(Color.parseColor("#DCFCE7"), Color.parseColor("#15803D"))
            "overdue" -> Pair(Color.parseColor("#FFE4E6"), Color.parseColor("#BE123C"))
            "sent" -> Pair(Color.parseColor("#DBEAFE"), Color.parseColor("#1D4ED8"))
            else -> Pair(Color.parseColor("#F1F5F9"), Color.parseColor("#475569"))
        }

        fillPaint.color = statusBg
        canvas.drawRoundRect(RectF(badgeLeft, badgeTop, metaColRight, badgeTop + badgeH), 4f, 4f, fillPaint)
        textPaint.color = statusFg
        canvas.drawText(statusText, badgeLeft + 7f, badgeTop + 10.5f, textPaint)

        currentY = maxOf(bY, rY + 8f) + 12f

        // 4. Billed To & Shipping Parties Cards
        val clientCardY = currentY
        val halfW = (CONTENT_WIDTH - 12f) / 2f

        // Client Details Card
        fillPaint.color = Color.parseColor("#F8FAFC")
        strokePaint.color = Color.parseColor("#E2E8F0")
        strokePaint.strokeWidth = 1f

        val clientRect = RectF(MARGIN_X, clientCardY, MARGIN_X + halfW, clientCardY + 68f)
        canvas.drawRoundRect(clientRect, 6f, 6f, fillPaint)
        canvas.drawRoundRect(clientRect, 6f, 6f, strokePaint)

        textPaint.textSize = 8f
        textPaint.typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)
        textPaint.color = primaryColorInt
        canvas.drawText("BILLED TO", MARGIN_X + 10f, clientCardY + 14f, textPaint)

        textPaint.textSize = 10f
        textPaint.typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)
        textPaint.color = Color.parseColor("#0F172A")
        val cName = invoice.clientName.ifBlank { "Client / Customer" }
        canvas.drawText(cName, MARGIN_X + 10f, clientCardY + 28f, textPaint)

        textPaint.textSize = 8.5f
        textPaint.typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.NORMAL)
        textPaint.color = Color.parseColor("#475569")
        var cLineY = clientCardY + 40f
        if (invoice.clientCompany.isNotBlank()) {
            canvas.drawText(invoice.clientCompany, MARGIN_X + 10f, cLineY, textPaint)
            cLineY += 11f
        }
        val firstAddressLine = invoice.clientAddress.split("\n").firstOrNull() ?: ""
        if (firstAddressLine.isNotBlank()) {
            canvas.drawText(firstAddressLine, MARGIN_X + 10f, cLineY, textPaint)
            cLineY += 11f
        }
        if (invoice.clientEmail.isNotBlank()) {
            canvas.drawText(invoice.clientEmail, MARGIN_X + 10f, cLineY, textPaint)
        }

        // Shipping Details Card (if shipping is enabled)
        val shipping = InvoiceUtils.deserializeShippingDetails(invoice.shippingDetailsJson)
        val showShipping = shipping.isEnabled || profile.showShippingSection

        val rightCardLeft = MARGIN_X + halfW + 12f
        val rightCardRect = RectF(rightCardLeft, clientCardY, MARGIN_RIGHT, clientCardY + 68f)
        canvas.drawRoundRect(rightCardRect, 6f, 6f, fillPaint)
        canvas.drawRoundRect(rightCardRect, 6f, 6f, strokePaint)

        textPaint.textSize = 8f
        textPaint.typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)
        textPaint.color = primaryColorInt
        val rightHeaderTitle = if (showShipping) shipping.sectionTitle.ifBlank { "SHIPPING & DELIVERY" } else "PAYMENT TERMS"
        canvas.drawText(rightHeaderTitle.uppercase(Locale.US), rightCardLeft + 10f, clientCardY + 14f, textPaint)

        textPaint.textSize = 9f
        textPaint.color = Color.parseColor("#0F172A")
        textPaint.typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.NORMAL)

        if (showShipping && (shipping.shippingAddress.isNotBlank() || shipping.courier.isNotBlank() || shipping.deliveryAddress.isNotBlank())) {
            var shipY = clientCardY + 28f
            val shipDest = shipping.deliveryAddress.ifBlank { shipping.shippingAddress }.split("\n").firstOrNull() ?: "Standard Ground"
            canvas.drawText("Destination: $shipDest", rightCardLeft + 10f, shipY, textPaint)
            shipY += 12f
            if (shipping.courier.isNotBlank() || shipping.trackingNumber.isNotBlank()) {
                canvas.drawText("Carrier: ${shipping.courier} • #${shipping.trackingNumber}", rightCardLeft + 10f, shipY, textPaint)
                shipY += 12f
            }
            if (shipping.expectedDelivery.isNotBlank()) {
                canvas.drawText("Expected: ${shipping.expectedDelivery}", rightCardLeft + 10f, shipY, textPaint)
            }
        } else {
            var termY = clientCardY + 28f
            canvas.drawText("Terms: ${invoice.paymentTerms}", rightCardLeft + 10f, termY, textPaint)
            termY += 12f
            canvas.drawText("Currency: ${invoice.currencyCode} (${invoice.currencySymbol})", rightCardLeft + 10f, termY, textPaint)
            termY += 12f
            canvas.drawText("Tax Treatment: ${invoice.taxType} (${invoice.taxRate}%)", rightCardLeft + 10f, termY, textPaint)
        }

        currentY = clientCardY + 78f

        // 5. Item Table Header
        val tableTop = currentY
        val headerHeight = 22f

        fillPaint.color = primaryColorInt
        canvas.drawRoundRect(RectF(MARGIN_X, tableTop, MARGIN_RIGHT, tableTop + headerHeight), 4f, 4f, fillPaint)

        textPaint.color = Color.WHITE
        textPaint.textSize = 8.5f
        textPaint.typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)

        val col1X = MARGIN_X + 8f                     // Item
        val col2X = MARGIN_X + CONTENT_WIDTH * 0.52f  // Qty
        val col3X = MARGIN_X + CONTENT_WIDTH * 0.65f  // Rate
        val col4X = MARGIN_X + CONTENT_WIDTH * 0.80f  // Tax/Disc
        val col5X = MARGIN_RIGHT - 8f                 // Total (Right aligned)

        val textBaseline = tableTop + 14.5f
        canvas.drawText(profile.colHeaderItem.ifBlank { "ITEM / DESCRIPTION" }, col1X, textBaseline, textPaint)
        canvas.drawText(profile.colHeaderQty.ifBlank { "QTY" }, col2X, textBaseline, textPaint)
        canvas.drawText(profile.colHeaderRate.ifBlank { "RATE" }, col3X, textBaseline, textPaint)
        canvas.drawText("TAX / DISC", col4X, textBaseline, textPaint)

        val totalHeader = profile.colHeaderAmount.ifBlank { "AMOUNT" }
        canvas.drawText(totalHeader, col5X - textPaint.measureText(totalHeader), textBaseline, textPaint)

        currentY += headerHeight

        // 6. Item Rows
        val rowHeight = 24f
        val maxItemsToShow = items.take(12)

        maxItemsToShow.forEachIndexed { index, item ->
            val rowY = currentY
            if (index % 2 == 1) {
                fillPaint.color = Color.parseColor("#F8FAFC")
                canvas.drawRect(MARGIN_X, rowY, MARGIN_RIGHT, rowY + rowHeight, fillPaint)
            }

            strokePaint.color = Color.parseColor("#E2E8F0")
            strokePaint.strokeWidth = 0.5f
            canvas.drawLine(MARGIN_X, rowY + rowHeight, MARGIN_RIGHT, rowY + rowHeight, strokePaint)

            val rowBaseline = rowY + 15.5f

            // Description
            textPaint.typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.NORMAL)
            textPaint.color = Color.parseColor("#0F172A")
            textPaint.textSize = 8.5f
            val desc = if (item.description.length > 34) item.description.take(32) + "…" else item.description.ifBlank { "Item ${index + 1}" }
            canvas.drawText(desc, col1X, rowBaseline, textPaint)

            // Qty
            val qtyStr = "${String.format(Locale.US, "%.1f", item.quantity)} ${item.unit}"
            canvas.drawText(qtyStr, col2X, rowBaseline, textPaint)

            // Rate
            val rateStr = "${invoice.currencySymbol}${String.format(Locale.US, "%,.2f", item.unitPrice)}"
            canvas.drawText(rateStr, col3X, rowBaseline, textPaint)

            // Tax / Disc
            val taxDiscStr = if (item.discountRate > 0) "-${item.discountRate.toInt()}%" else "${item.taxRate.toInt()}%"
            canvas.drawText(taxDiscStr, col4X, rowBaseline, textPaint)

            // Line Total
            val lineTotalStr = "${invoice.currencySymbol}${String.format(Locale.US, "%,.2f", item.total)}"
            textPaint.typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)
            canvas.drawText(lineTotalStr, col5X - textPaint.measureText(lineTotalStr), rowBaseline, textPaint)

            currentY += rowHeight
        }

        currentY += 8f

        // 7. Totals & Payment Grid
        val totalsWidth = 190f
        val totalsLeft = MARGIN_RIGHT - totalsWidth
        val notesWidth = CONTENT_WIDTH - totalsWidth - 14f

        val totalsStartY = currentY

        // Left Side: Payment instructions & Notes
        var noteY = totalsStartY + 4f
        if (profile.showPaymentInstructions && invoice.paymentInstructions.isNotBlank()) {
            textPaint.textSize = 8f
            textPaint.typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)
            textPaint.color = primaryColorInt
            canvas.drawText("PAYMENT INSTRUCTIONS", MARGIN_X, noteY, textPaint)
            noteY += 11f

            textPaint.textSize = 8f
            textPaint.typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.NORMAL)
            textPaint.color = Color.parseColor("#475569")
            invoice.paymentInstructions.split("\n").take(3).forEach { pLine ->
                if (pLine.isNotBlank()) {
                    canvas.drawText(pLine.trim(), MARGIN_X, noteY, textPaint)
                    noteY += 10f
                }
            }
            noteY += 4f
        }

        if (profile.showNotes && invoice.notes.isNotBlank()) {
            textPaint.textSize = 8f
            textPaint.typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)
            textPaint.color = primaryColorInt
            canvas.drawText("NOTES", MARGIN_X, noteY, textPaint)
            noteY += 11f

            textPaint.textSize = 7.5f
            textPaint.typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.NORMAL)
            textPaint.color = Color.parseColor("#475569")
            invoice.notes.split("\n").take(2).forEach { nLine ->
                if (nLine.isNotBlank()) {
                    canvas.drawText(nLine.trim(), MARGIN_X, noteY, textPaint)
                    noteY += 9.5f
                }
            }
        }

        // Right Side: Structured Totals Table
        var totY = totalsStartY

        fun drawTotalLine(label: String, valueStr: String, isBold: Boolean = false, isHighlight: Boolean = false) {
            val lineH = if (isHighlight) 22f else 15f

            if (isHighlight) {
                fillPaint.color = primaryColorInt
                canvas.drawRoundRect(RectF(totalsLeft, totY, MARGIN_RIGHT, totY + lineH), 4f, 4f, fillPaint)
                textPaint.color = Color.WHITE
            } else {
                textPaint.color = Color.parseColor("#334155")
            }

            textPaint.textSize = if (isHighlight) 10f else 8.5f
            textPaint.typeface = if (isBold || isHighlight) Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD) else Typeface.create(Typeface.SANS_SERIF, Typeface.NORMAL)

            val baseline = totY + if (isHighlight) 14.5f else 11f
            canvas.drawText(label, totalsLeft + 6f, baseline, textPaint)
            canvas.drawText(valueStr, MARGIN_RIGHT - 6f - textPaint.measureText(valueStr), baseline, textPaint)

            totY += lineH
        }

        drawTotalLine("Subtotal", "${invoice.currencySymbol}${String.format(Locale.US, "%,.2f", calculations.subtotal)}")

        if (calculations.discountTotal > 0) {
            drawTotalLine("Discount", "-${invoice.currencySymbol}${String.format(Locale.US, "%,.2f", calculations.discountTotal)}")
        }

        if (calculations.taxTotal > 0) {
            val rcmTag = if (invoice.isRcm) " (RCM)" else ""
            drawTotalLine("${invoice.taxLabel} (${invoice.taxRate}%)$rcmTag", "${invoice.currencySymbol}${String.format(Locale.US, "%,.2f", calculations.taxTotal)}")
        }

        if (calculations.shipping > 0) {
            drawTotalLine("Shipping Fee", "${invoice.currencySymbol}${String.format(Locale.US, "%,.2f", calculations.shipping)}")
        }

        if (calculations.roundOff != 0.0) {
            val sign = if (calculations.roundOff > 0) "+" else ""
            drawTotalLine("Round Off", "$sign${invoice.currencySymbol}${String.format(Locale.US, "%,.2f", calculations.roundOff)}")
        }

        // Grand Total Box
        drawTotalLine(
            label = "Total Amount",
            valueStr = "${invoice.currencySymbol}${String.format(Locale.US, "%,.2f", calculations.grandTotal)}",
            isHighlight = true
        )

        if (calculations.amountPaid > 0) {
            drawTotalLine("Amount Paid", "-${invoice.currencySymbol}${String.format(Locale.US, "%,.2f", calculations.amountPaid)}")
            drawTotalLine("Balance Due", "${invoice.currencySymbol}${String.format(Locale.US, "%,.2f", calculations.balanceDue)}", isBold = true)
        }

        // Dynamic UPI QR Code in Payment Section
        if (profile.upiId.isNotBlank()) {
            val upiUri = QrCodeGenerator.buildUpiPaymentUri(
                upiId = profile.upiId,
                payeeName = profile.businessName.ifBlank { profile.legalName },
                amount = calculations.balanceDue,
                invoiceNumber = invoice.invoiceNumber,
                currency = invoice.currencyCode
            )
            val qrBmp = QrCodeGenerator.generateQrBitmap(upiUri, sizePx = 180)
            if (qrBmp != null) {
                val qrSize = 46f
                val qrX = MARGIN_X
                val qrY = noteY + 2f
                canvas.drawBitmap(Bitmap.createScaledBitmap(qrBmp, qrSize.toInt(), qrSize.toInt(), true), qrX, qrY, null)

                textPaint.textSize = 7f
                textPaint.typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)
                textPaint.color = primaryColorInt
                canvas.drawText("SCAN & PAY VIA UPI", qrX + qrSize + 6f, qrY + 11f, textPaint)

                textPaint.textSize = 6f
                textPaint.typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.NORMAL)
                textPaint.color = Color.parseColor("#64748B")
                canvas.drawText("GPay • PhonePe • Paytm • BHIM", qrX + qrSize + 6f, qrY + 22f, textPaint)
                canvas.drawText("UPI ID: ${profile.upiId}", qrX + qrSize + 6f, qrY + 33f, textPaint)

                noteY = qrY + qrSize + 6f
            }
        }

        // Amount in Words
        if (profile.showAmountInWords) {
            val words = IndianCurrencyUtils.convertToWords(calculations.grandTotal, invoice.currencyCode)
            textPaint.textSize = 7f
            textPaint.typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.ITALIC)
            textPaint.color = Color.parseColor("#334155")
            val wordsY = maxOf(totY + 14f, noteY + 14f)
            canvas.drawText("Total in Words: $words", MARGIN_X, wordsY, textPaint)
        }

        // 8. Footer Section: Signatory & Terms
        val footerY = PAGE_HEIGHT - 60f

        strokePaint.color = Color.parseColor("#E2E8F0")
        strokePaint.strokeWidth = 1f
        canvas.drawLine(MARGIN_X, footerY, MARGIN_RIGHT, footerY, strokePaint)

        textPaint.textSize = 7.5f
        textPaint.typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.NORMAL)
        textPaint.color = Color.parseColor("#64748B")

        val footerText = if (profile.showTerms && invoice.terms.isNotBlank()) {
            "Terms: ${invoice.terms.split("\n").firstOrNull()?.take(65) ?: ""}"
        } else {
            "This is a verified computer generated invoice. Payment is appreciated."
        }
        canvas.drawText(footerText, MARGIN_X, footerY + 16f, textPaint)

        // Signatory Box
        if (profile.showSignature && profile.signeeName.isNotBlank()) {
            val signRight = MARGIN_RIGHT
            val signName = profile.signeeName
            val signTitle = profile.signeeTitle.ifBlank { "Authorized Signatory" }

            textPaint.typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)
            textPaint.textSize = 8.5f
            textPaint.color = Color.parseColor("#0F172A")
            canvas.drawText(signName, signRight - textPaint.measureText(signName), footerY + 16f, textPaint)

            textPaint.typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.NORMAL)
            textPaint.textSize = 7.5f
            textPaint.color = Color.parseColor("#64748B")
            canvas.drawText(signTitle, signRight - textPaint.measureText(signTitle), footerY + 28f, textPaint)
        }

        pdfDocument.finishPage(page)

        // 9. Write PDF Document to App Storage
        val exportDir = File(context.filesDir, "invoices")
        if (!exportDir.exists()) exportDir.mkdirs()

        val sanitizeInvNum = invoice.invoiceNumber.replace("[^a-zA-Z0-9_-]".toRegex(), "_")
        val outputFile = File(exportDir, "Invoice_${sanitizeInvNum}.pdf")

        FileOutputStream(outputFile).use { outStream ->
            pdfDocument.writeTo(outStream)
        }

        pdfDocument.close()
        return outputFile
    }
}
