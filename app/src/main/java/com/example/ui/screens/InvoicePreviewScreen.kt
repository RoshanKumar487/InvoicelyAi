package com.example.ui.screens

import android.content.Context
import android.content.Intent
import android.print.PrintAttributes
import android.print.PrintManager
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.Toast
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTransformGestures
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ReceiptLong
import androidx.compose.material.icons.filled.Download
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.Print
import androidx.compose.material.icons.filled.RestartAlt
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Tune
import androidx.compose.material.icons.filled.ZoomIn
import androidx.compose.material.icons.filled.ZoomOut
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.FileProvider
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.data.model.BusinessProfile
import com.example.data.model.InvoiceCalculations
import com.example.data.model.InvoiceEntity
import com.example.data.model.InvoiceItem
import com.example.data.model.InvoiceUtils
import com.example.data.model.TemplateConfig
import com.example.docx.DocxTemplatePreset
import com.example.ui.components.BusinessCustomIcon
import com.example.ui.components.InvoiceStatusBadge
import com.example.ui.components.InvoiceTemplateRenderer
import com.example.ui.components.PaymentReminderBottomSheet
import com.example.ui.theme.PrimaryNavy
import com.example.ui.theme.StatusPaidGreen
import com.example.ui.viewmodel.InvoiceViewModel
import java.io.File
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InvoicePreviewScreen(
    invoiceId: Long,
    viewModel: InvoiceViewModel,
    onBack: () -> Unit,
    onEditInvoice: (Long) -> Unit,
    initialFullPage: Boolean = true,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val allInvoices by viewModel.allInvoices.collectAsStateWithLifecycle()
    val profile by viewModel.businessProfile.collectAsStateWithLifecycle()

    val sampleInvoice = remember(profile) {
        InvoiceEntity(
            id = 0L,
            invoiceNumber = "INV-2026-001",
            clientId = null,
            clientName = "Horizon Enterprise Corp",
            clientCompany = "Horizon Global Media Ltd",
            clientEmail = "billing@horizonglobal.com",
            clientPhone = "+1 (555) 349-8120",
            clientAddress = "500 Madison Avenue, 18th Floor\nNew York, NY 10022",
            clientTaxId = if (profile.gstin.isNotBlank()) "27AABCU9603R1ZM" else "TAX-NY-984210",
            issueDate = "2026-10-01",
            dueDate = "2026-10-31",
            poNumber = "PO-9942",
            paymentTerms = profile.defaultPaymentTerms.ifBlank { "Net 30" },
            currencyCode = profile.defaultCurrency,
            currencySymbol = profile.defaultCurrencySymbol,
            taxRate = profile.defaultTaxRate,
            taxLabel = profile.defaultTaxLabel,
            itemsJson = InvoiceUtils.serializeInvoiceItems(
                listOf(
                    InvoiceItem(description = "Enterprise Cloud Architecture & API Setup", quantity = 35.0, unitPrice = 140.0, unit = "hrs"),
                    InvoiceItem(description = "Full Stack System Modernization & Security", quantity = 1.0, unitPrice = 2800.0, unit = "pkg"),
                    InvoiceItem(description = "Ongoing Monthly SLA Maintenance & Support", quantity = 1.0, unitPrice = 950.0, unit = "mo")
                )
            ),
            notes = profile.defaultNotes,
            terms = profile.defaultTerms,
            paymentInstructions = "Bank: ${profile.bankName}\nAccount: ${profile.accountNumber}\nRouting: ${profile.routingNumber}\nUPI: ${profile.upiId}",
            status = "Sent",
            templateId = profile.defaultTemplateId
        )
    }

    val invoice = allInvoices.find { it.id == invoiceId }
        ?: allInvoices.firstOrNull()
        ?: sampleInvoice

    val items = remember(invoice.itemsJson) {
        val list = InvoiceUtils.deserializeInvoiceItems(invoice.itemsJson)
        if (list.isEmpty()) {
            listOf(InvoiceItem(description = "Professional Consulting Services", quantity = 1.0, unitPrice = 150.0, unit = "hrs"))
        } else {
            list
        }
    }

    val calculations = remember(invoice, profile, items) {
        InvoiceUtils.calculateInvoice(
            items = items,
            taxRate = if (profile.showItemTax) invoice.taxRate else 0.0,
            discountPercent = if (profile.showItemDiscount) invoice.discountPercent else 0.0,
            discountAmount = if (profile.showItemDiscount) invoice.discountAmount else 0.0,
            shippingFee = if (profile.showShippingFee) invoice.shippingFee else 0.0,
            amountPaid = invoice.amountPaid
        )
    }

    // Active Template Config for this preview
    var templateConfig by remember(invoice.id, invoice.templateId, profile.brandColorHex) {
        mutableStateOf(
            DocxTemplatePreset.getById(invoice.templateId).copy(
                primaryColorHex = profile.brandColorHex
            )
        )
    }

    var templateDropdownExpanded by remember { mutableStateOf(false) }

    // Zoomable Document States
    var zoomScale by remember { mutableFloatStateOf(1.0f) }

    var generatedDocxFile by remember { mutableStateOf<File?>(null) }
    var reminderInvoice by remember { mutableStateOf<InvoiceEntity?>(null) }
    val reminderSheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    val brandColor = remember(templateConfig.primaryColorHex) {
        try {
            Color(android.graphics.Color.parseColor(templateConfig.primaryColorHex))
        } catch (_: Exception) {
            PrimaryNavy
        }
    }

    fun exportAndShareDocx() {
        try {
            val file = viewModel.generateDocx(context, invoice, templateConfig)
            generatedDocxFile = file
            val uri = FileProvider.getUriForFile(
                context,
                "${context.packageName}.fileprovider",
                file
            )
            val shareIntent = Intent(Intent.ACTION_SEND).apply {
                type = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
                putExtra(Intent.EXTRA_STREAM, uri)
                putExtra(Intent.EXTRA_SUBJECT, "Invoice ${invoice.invoiceNumber} from ${profile.businessName}")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            context.startActivity(Intent.createChooser(shareIntent, "Share DOCX Invoice"))
        } catch (e: Exception) {
            Toast.makeText(context, "Error sharing DOCX: ${e.message}", Toast.LENGTH_SHORT).show()
        }
    }

    fun downloadDocx() {
        try {
            val file = viewModel.generateDocx(context, invoice, templateConfig)
            generatedDocxFile = file
            Toast.makeText(
                context,
                "DOCX exported successfully: ${file.name}",
                Toast.LENGTH_LONG
            ).show()
        } catch (e: Exception) {
            Toast.makeText(context, "Error exporting DOCX: ${e.message}", Toast.LENGTH_SHORT).show()
        }
    }

    fun printInvoice() {
        try {
            val printManager = context.getSystemService(Context.PRINT_SERVICE) as PrintManager
            val webView = WebView(context)
            webView.webViewClient = object : WebViewClient() {
                override fun onPageFinished(view: WebView?, url: String?) {
                    val printAdapter = webView.createPrintDocumentAdapter("Invoice_${invoice.invoiceNumber}")
                    printManager.print("Invoice_${invoice.invoiceNumber}", printAdapter, PrintAttributes.Builder().build())
                }
            }

            val colItem = profile.colHeaderItem.ifBlank { templateConfig.colHeaderItem }
            val colQty = profile.colHeaderQty.ifBlank { templateConfig.colHeaderQty }
            val colRate = profile.colHeaderRate.ifBlank { templateConfig.colHeaderRate }
            val colAmount = profile.colHeaderAmount.ifBlank { templateConfig.colHeaderAmount }

            val html = """
                <html>
                <head>
                    <style>
                        body { font-family: sans-serif; margin: 30px; color: #1e293b; }
                        .header { display: flex; justify-content: space-between; border-bottom: 2px solid ${templateConfig.primaryColorHex}; padding-bottom: 15px; }
                        .title { font-size: 28px; font-weight: bold; color: ${templateConfig.primaryColorHex}; }
                        .table { width: 100%; border-collapse: collapse; margin-top: 25px; }
                        .table th { background: ${templateConfig.primaryColorHex}; color: white; padding: 10px; text-align: left; }
                        .table td { padding: 10px; border-bottom: 1px solid #e2e8f0; }
                        .totals { margin-top: 20px; float: right; width: 300px; }
                        .total-row { display: flex; justify-content: space-between; padding: 5px 0; }
                        .grand-total { font-size: 20px; font-weight: bold; color: ${templateConfig.primaryColorHex}; border-top: 2px solid #e2e8f0; padding-top: 10px; }
                    </style>
                </head>
                <body>
                    <div class="header">
                        <div>
                            <h2>${profile.businessName}</h2>
                            <p>${profile.legalName}<br>${profile.address.replace("\n", "<br>")}<br>GSTIN/Tax ID: ${profile.gstin.ifBlank { profile.taxId }}</p>
                        </div>
                        <div style="text-align: right;">
                            <div class="title">${templateConfig.docxTitle}</div>
                            <p><strong>${invoice.invoiceNumber}</strong><br>Date: ${invoice.issueDate}<br>Due: ${invoice.dueDate}</p>
                        </div>
                    </div>
                    <div style="margin-top: 20px;">
                        <h3>Billed To:</h3>
                        <p><strong>${invoice.clientName}</strong><br>${invoice.clientCompany}<br>${invoice.clientAddress.replace("\n", "<br>")}<br>${invoice.clientEmail}</p>
                    </div>
                    <table class="table">
                        <tr>
                            <th>${colItem}</th>
                            <th style="text-align: right;">${colQty}</th>
                            <th style="text-align: right;">${colRate}</th>
                            <th style="text-align: right;">${colAmount}</th>
                        </tr>
                        ${items.joinToString("") { item ->
                            "<tr><td>${item.description}</td><td style='text-align: right;'>${item.quantity} ${item.unit}</td><td style='text-align: right;'>${InvoiceUtils.formatMoney(item.unitPrice, invoice.currencySymbol)}</td><td style='text-align: right;'>${InvoiceUtils.formatMoney(item.total, invoice.currencySymbol)}</td></tr>"
                        }}
                    </table>
                    <div class="totals">
                        <div class="total-row"><span>Subtotal:</span><span>${InvoiceUtils.formatMoney(calculations.subtotal, invoice.currencySymbol)}</span></div>
                        ${if (calculations.discountTotal > 0) "<div class='total-row'><span>Discount:</span><span>-${InvoiceUtils.formatMoney(calculations.discountTotal, invoice.currencySymbol)}</span></div>" else ""}
                        ${if (calculations.taxTotal > 0) "<div class='total-row'><span>${invoice.taxLabel}:</span><span>${InvoiceUtils.formatMoney(calculations.taxTotal, invoice.currencySymbol)}</span></div>" else ""}
                        <div class="total-row grand-total"><span>Total:</span><span>${InvoiceUtils.formatMoney(calculations.grandTotal, invoice.currencySymbol)}</span></div>
                        <div class="total-row" style="color: #dc2626; font-weight: bold;"><span>Balance Due:</span><span>${InvoiceUtils.formatMoney(calculations.balanceDue, invoice.currencySymbol)}</span></div>
                    </div>
                </body>
                </html>
            """.trimIndent()

            webView.loadDataWithBaseURL(null, html, "text/html", "UTF-8", null)
        } catch (e: Exception) {
            Toast.makeText(context, "Print error: ${e.message}", Toast.LENGTH_SHORT).show()
        }
    }

    // =========================================================================
    // FULL PREVIEW PAGE (Always in Full Page View with Smooth Zoom)
    // =========================================================================
    Scaffold(
        modifier = modifier.fillMaxSize(),
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(invoice.invoiceNumber, fontWeight = FontWeight.Bold, fontSize = 16.sp)
                            Spacer(modifier = Modifier.width(6.dp))
                            Surface(
                                color = Color(0xFFEFF6FF),
                                shape = RoundedCornerShape(6.dp),
                                border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFBFDBFE))
                            ) {
                                Text(
                                    text = templateConfig.templateName,
                                    fontSize = 10.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = Color(0xFF1D4ED8),
                                    modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                )
                            }
                        }
                        Text("A4 Print-Ready Document Layout", fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onBack, modifier = Modifier.testTag("full_page_back_btn")) {
                        Icon(imageVector = Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    // Zoom Out Button
                    IconButton(
                        onClick = { zoomScale = (zoomScale - 0.15f).coerceAtLeast(0.6f) },
                        modifier = Modifier.testTag("zoom_out_btn")
                    ) {
                        Icon(imageVector = Icons.Default.ZoomOut, contentDescription = "Zoom Out", tint = PrimaryNavy)
                    }

                    // Zoom Percentage Pill (tap to reset to 100%)
                    Surface(
                        color = Color(0xFFF1F5F9),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.clickable { zoomScale = 1.0f }
                    ) {
                        Text(
                            text = "${(zoomScale * 100).toInt()}%",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold,
                            color = PrimaryNavy,
                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 3.dp)
                        )
                    }

                    // Zoom In Button
                    IconButton(
                        onClick = { zoomScale = (zoomScale + 0.15f).coerceAtMost(2.5f) },
                        modifier = Modifier.testTag("zoom_in_btn")
                    ) {
                        Icon(imageVector = Icons.Default.ZoomIn, contentDescription = "Zoom In", tint = PrimaryNavy)
                    }

                    // Switch Template Dropdown
                    Box {
                        IconButton(onClick = { templateDropdownExpanded = true }) {
                            Icon(imageVector = Icons.Default.Tune, contentDescription = "Switch Template", tint = PrimaryNavy)
                        }
                        DropdownMenu(
                            expanded = templateDropdownExpanded,
                            onDismissRequest = { templateDropdownExpanded = false }
                        ) {
                            DocxTemplatePreset.allTemplates.forEach { preset ->
                                DropdownMenuItem(
                                    text = {
                                        Row(verticalAlignment = Alignment.CenterVertically) {
                                            Box(
                                                modifier = Modifier
                                                    .size(12.dp)
                                                    .clip(CircleShape)
                                                    .background(Color(android.graphics.Color.parseColor(preset.primaryColorHex)))
                                            )
                                            Spacer(modifier = Modifier.width(8.dp))
                                            Text(preset.templateName, fontSize = 12.sp)
                                        }
                                    },
                                    onClick = {
                                        templateConfig = preset.copy(primaryColorHex = templateConfig.primaryColorHex)
                                        templateDropdownExpanded = false
                                    }
                                )
                            }
                        }
                    }

                    // Print / PDF
                    IconButton(onClick = { printInvoice() }, modifier = Modifier.testTag("print_invoice_btn")) {
                        Icon(imageVector = Icons.Default.Print, contentDescription = "Print / PDF")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = MaterialTheme.colorScheme.surface)
            )
        },
        bottomBar = {
            Surface(
                color = MaterialTheme.colorScheme.surface,
                shadowElevation = 10.dp
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 14.dp, vertical = 10.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedButton(
                        onClick = { downloadDocx() },
                        modifier = Modifier
                            .weight(1f)
                            .height(46.dp)
                            .testTag("download_docx_btn"),
                        shape = RoundedCornerShape(10.dp)
                    ) {
                        Icon(Icons.Default.Download, contentDescription = null, modifier = Modifier.size(16.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("DOCX", fontSize = 11.sp)
                    }

                    Button(
                        onClick = { exportAndShareDocx() },
                        modifier = Modifier
                            .weight(1.3f)
                            .height(46.dp)
                            .testTag("share_docx_btn"),
                        colors = ButtonDefaults.buttonColors(containerColor = PrimaryNavy),
                        shape = RoundedCornerShape(10.dp)
                    ) {
                        Icon(Icons.Default.Share, contentDescription = null, modifier = Modifier.size(16.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Share DOCX", fontSize = 12.sp, fontWeight = FontWeight.Bold)
                    }

                    OutlinedButton(
                        onClick = { onEditInvoice(invoice.id) },
                        modifier = Modifier
                            .weight(1f)
                            .height(46.dp)
                            .testTag("edit_invoice_btn"),
                        shape = RoundedCornerShape(10.dp)
                    ) {
                        Icon(Icons.Default.Edit, contentDescription = null, modifier = Modifier.size(16.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Edit", fontSize = 11.sp)
                    }

                    if (invoice.status != "Paid") {
                        IconButton(
                            onClick = { reminderInvoice = invoice },
                            modifier = Modifier
                                .size(46.dp)
                                .clip(RoundedCornerShape(10.dp))
                                .background(Color(0xFFFEF3C7))
                                .testTag("reminder_btn")
                        ) {
                            Icon(
                                imageVector = Icons.Default.NotificationsActive,
                                contentDescription = "Send Reminder",
                                tint = Color(0xFFD97706)
                            )
                        }
                    }
                }
            }
        }
    ) { padding ->
        // Interactive Zoomable Canvas
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .background(Color(0xFF0F172A)) // High-contrast sleek dark background makes paper pop
        ) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .pointerInput(Unit) {
                        detectTransformGestures { _, _, zoom, _ ->
                            zoomScale = (zoomScale * zoom).coerceIn(0.6f, 2.5f)
                        }
                    }
                    .verticalScroll(rememberScrollState())
                    .horizontalScroll(rememberScrollState())
                    .padding(horizontal = 8.dp, vertical = 14.dp),
                contentAlignment = Alignment.TopCenter
            ) {
                Box(
                    modifier = Modifier
                        .graphicsLayer(
                            scaleX = zoomScale,
                            scaleY = zoomScale,
                            transformOrigin = TransformOrigin(0.5f, 0f)
                        )
                        .widthIn(max = 680.dp)
                ) {
                    InvoiceDocumentPaper(
                        invoice = invoice,
                        items = items,
                        profile = profile,
                        templateConfig = templateConfig,
                        calculations = calculations,
                        brandColor = brandColor,
                        isFullPage = true,
                        modifier = Modifier.testTag("full_page_invoice_document")
                    )
                }
            }

            // Floating Quick Zoom Thumb Controller
            Surface(
                color = Color.White.copy(alpha = 0.95f),
                shape = RoundedCornerShape(24.dp),
                shadowElevation = 6.dp,
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .padding(end = 16.dp, bottom = 16.dp)
            ) {
                Row(
                    modifier = Modifier.padding(horizontal = 6.dp, vertical = 4.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    IconButton(
                        onClick = { zoomScale = (zoomScale - 0.2f).coerceAtLeast(0.6f) },
                        modifier = Modifier.size(32.dp)
                    ) {
                        Icon(imageVector = Icons.Default.ZoomOut, contentDescription = "Zoom Out", modifier = Modifier.size(16.dp))
                    }
                    Text(
                        text = "${(zoomScale * 100).toInt()}%",
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold,
                        color = PrimaryNavy,
                        modifier = Modifier
                            .clickable { zoomScale = 1.0f }
                            .padding(horizontal = 6.dp)
                    )
                    IconButton(
                        onClick = { zoomScale = (zoomScale + 0.2f).coerceAtMost(2.5f) },
                        modifier = Modifier.size(32.dp)
                    ) {
                        Icon(imageVector = Icons.Default.ZoomIn, contentDescription = "Zoom In", modifier = Modifier.size(16.dp))
                    }
                    IconButton(
                        onClick = { zoomScale = 1.0f },
                        modifier = Modifier.size(32.dp)
                    ) {
                        Icon(imageVector = Icons.Default.RestartAlt, contentDescription = "Reset Zoom", modifier = Modifier.size(16.dp))
                    }
                }
            }
        }
    }

    // Payment reminder bottom sheet
    reminderInvoice?.let { inv ->
        PaymentReminderBottomSheet(
            invoice = inv,
            profile = profile,
            onDismiss = { reminderInvoice = null },
            onReminderSent = { id -> viewModel.markReminderSent(id) },
            sheetState = reminderSheetState
        )
    }
}

/**
 * Reusable A4-style Invoice Document Paper.
 * Renders the chosen template letterhead and layout dynamically with all data filled by user.
 */
@Composable
fun InvoiceDocumentPaper(
    invoice: InvoiceEntity,
    items: List<InvoiceItem>,
    profile: BusinessProfile,
    templateConfig: TemplateConfig,
    calculations: InvoiceCalculations,
    brandColor: Color,
    modifier: Modifier = Modifier,
    isFullPage: Boolean = true
) {
    val activeColumns = remember(invoice.itemColumnsJson, profile.customColumnsJson, profile) {
        val jsonToUse = invoice.itemColumnsJson.ifBlank { profile.customColumnsJson }
        InvoiceUtils.deserializeColumns(jsonToUse, profile).filter { it.isVisible }
    }
    val shippingDetails = remember(invoice.shippingDetailsJson) {
        InvoiceUtils.deserializeShippingDetails(invoice.shippingDetailsJson)
    }
    val customClientFields = remember(invoice.customFieldsJson) {
        InvoiceUtils.deserializeCustomFields(invoice.customFieldsJson)
    }

    Card(
        modifier = modifier
            .fillMaxWidth()
            .shadow(10.dp, RoundedCornerShape(12.dp)),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        shape = RoundedCornerShape(12.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 8.dp)
    ) {
        InvoiceTemplateRenderer(
            templateId = templateConfig.templateId,
            invoiceNumber = invoice.invoiceNumber,
            issueDate = invoice.issueDate,
            dueDate = invoice.dueDate,
            poNumber = invoice.poNumber,
            paymentTerms = invoice.paymentTerms,
            currencySymbol = invoice.currencySymbol,
            currencyCode = invoice.currencyCode,
            clientName = invoice.clientName,
            clientCompany = invoice.clientCompany,
            clientEmail = invoice.clientEmail,
            clientPhone = invoice.clientPhone,
            clientAddress = invoice.clientAddress,
            clientTaxId = invoice.clientTaxId,
            customClientFields = customClientFields,
            shippingDetails = shippingDetails,
            activeColumns = activeColumns,
            items = items,
            taxRate = invoice.taxRate,
            taxLabel = invoice.taxLabel,
            taxType = invoice.taxType,
            isTaxInclusive = invoice.isTaxInclusive,
            calculations = calculations,
            notes = invoice.notes,
            terms = invoice.terms,
            paymentInstructions = invoice.paymentInstructions,
            notesLabel = "Notes",
            termsLabel = "Terms & Conditions",
            profile = profile,
            status = invoice.status
        )
    }
}
