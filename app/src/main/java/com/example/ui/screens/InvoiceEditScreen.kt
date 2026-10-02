package com.example.ui.screens

import android.widget.Toast
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Calculate
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.CurrencyExchange
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Draw
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Event
import androidx.compose.material.icons.filled.ExpandLess
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material.icons.filled.FactCheck
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.LocalShipping
import androidx.compose.material.icons.filled.Payments
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Receipt
import androidx.compose.material.icons.filled.ShoppingBag
import androidx.compose.material.icons.filled.Tune
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.data.model.ClientEntity
import com.example.data.model.CustomClientField
import com.example.data.model.IndustryTemplatePreset
import com.example.data.model.IndustryTemplates
import com.example.data.model.InvoiceEntity
import com.example.data.model.InvoiceItem
import com.example.data.model.InvoiceUtils
import com.example.data.model.ItemColumnDef
import com.example.data.model.ShippingDetails
import com.example.ui.components.IndustryTemplateSelectorDialog
import com.example.ui.components.InvoiceAccordionSection
import com.example.ui.components.ItemizationBuilderDialog
import com.example.ui.components.LiveInvoicePreviewModal
import com.example.ui.theme.PrimaryNavy
import com.example.ui.theme.StatusPaidGreen
import com.example.ui.viewmodel.InvoiceViewModel
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * Modern, enterprise-grade, highly usable Universal Invoice Creation & Customization System.
 * Supports any industry, department, or business model via:
 * 1. Section-based Accordion UI (Client, Shipping, Items, Totals & Taxes, Notes & Signatures)
 * 2. Dynamic Universal Itemization Engine with column customization & formula builder
 * 3. 12 Predefined Industry Templates (General, E-commerce, Retail, Manufacturing, IT, Consulting, etc.)
 * 4. Rich live preview modal with zoom & DOCX export
 * 5. Mobile-first item cards with progressive disclosure
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InvoiceEditScreen(
    invoiceId: Long,
    viewModel: InvoiceViewModel,
    onBack: () -> Unit,
    onSavedAndPreview: (Long) -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val allInvoices by viewModel.allInvoices.collectAsStateWithLifecycle()
    val allClients by viewModel.allClients.collectAsStateWithLifecycle()
    val profile by viewModel.businessProfile.collectAsStateWithLifecycle()

    val existingInvoice = remember(invoiceId, allInvoices) {
        allInvoices.find { it.id == invoiceId }
    }
    val isNew = invoiceId == 0L

    val dateFormat = remember { SimpleDateFormat("yyyy-MM-dd", Locale.US) }
    val today = remember { dateFormat.format(Date()) }
    val defaultDue = remember {
        val cal = Calendar.getInstance().apply { add(Calendar.DAY_OF_YEAR, 30) }
        dateFormat.format(cal.time)
    }

    // -------------------------------------------------------------------------
    // Accordion Expansion States (Allow multiple expanded)
    // -------------------------------------------------------------------------
    var isClientExpanded by remember { mutableStateOf(true) }
    var isShippingExpanded by remember { mutableStateOf(false) }
    var isItemsExpanded by remember { mutableStateOf(true) }
    var isTotalsExpanded by remember { mutableStateOf(true) }
    var isNotesExpanded by remember { mutableStateOf(false) }

    // -------------------------------------------------------------------------
    // Dialog States
    // -------------------------------------------------------------------------
    var showIndustrySelectorDialog by remember { mutableStateOf(isNew) }
    var showItemizationBuilderDialog by remember { mutableStateOf(false) }
    var showLivePreviewModal by remember { mutableStateOf(false) }
    var selectedIndustryId by remember { mutableStateOf("general") }

    // -------------------------------------------------------------------------
    // Section 1: Client Details
    // -------------------------------------------------------------------------
    var selectedClientId by remember { mutableStateOf(existingInvoice?.clientId) }
    var clientName by remember { mutableStateOf(existingInvoice?.clientName ?: "") }
    var clientCompany by remember { mutableStateOf(existingInvoice?.clientCompany ?: "") }
    var clientEmail by remember { mutableStateOf(existingInvoice?.clientEmail ?: "") }
    var clientPhone by remember { mutableStateOf(existingInvoice?.clientPhone ?: "") }
    var clientAddress by remember { mutableStateOf(existingInvoice?.clientAddress ?: "") }
    var clientTaxId by remember { mutableStateOf(existingInvoice?.clientTaxId ?: "") }
    var customerId by remember { mutableStateOf("") }
    var contactPerson by remember { mutableStateOf("") }
    var paymentTerms by remember { mutableStateOf(existingInvoice?.paymentTerms ?: profile.defaultPaymentTerms.ifBlank { "Net 30" }) }
    var issueDate by remember { mutableStateOf(existingInvoice?.issueDate ?: today) }
    var dueDate by remember { mutableStateOf(existingInvoice?.dueDate ?: defaultDue) }
    var poNumber by remember { mutableStateOf(existingInvoice?.poNumber ?: "") }
    var invoiceNumber by remember { mutableStateOf(existingInvoice?.invoiceNumber ?: viewModel.generateNextInvoiceNumber()) }

    // Client Custom Fields
    val customClientFields = remember {
        mutableStateListOf<CustomClientField>().apply {
            if (existingInvoice != null && existingInvoice.customFieldsJson.isNotBlank()) {
                addAll(InvoiceUtils.deserializeCustomFields(existingInvoice.customFieldsJson))
            }
        }
    }

    // Client Display Label Customization
    var clientLabelTitle by remember { mutableStateOf("Client / Customer Name") }
    var clientDropdownExpanded by remember { mutableStateOf(false) }

    // -------------------------------------------------------------------------
    // Section 2: Shipping / Delivery Details
    // -------------------------------------------------------------------------
    var shippingDetails by remember {
        mutableStateOf(
            if (existingInvoice != null && existingInvoice.shippingDetailsJson.isNotBlank()) {
                InvoiceUtils.deserializeShippingDetails(existingInvoice.shippingDetailsJson)
            } else {
                ShippingDetails(
                    isEnabled = false,
                    sameAsBilling = false,
                    sectionTitle = "Shipping Details"
                )
            }
        )
    }

    // -------------------------------------------------------------------------
    // Section 3: Universal Itemization Columns
    // -------------------------------------------------------------------------
    val itemColumns = remember {
        mutableStateListOf<ItemColumnDef>().apply {
            if (existingInvoice != null && existingInvoice.itemColumnsJson.isNotBlank()) {
                addAll(InvoiceUtils.deserializeColumns(existingInvoice.itemColumnsJson, profile))
            } else if (profile.customColumnsJson.isNotBlank()) {
                addAll(InvoiceUtils.deserializeColumns(profile.customColumnsJson, profile))
            } else {
                addAll(IndustryTemplates.getPresetById("general").defaultColumns)
            }
        }
    }

    // Line Items State
    val items = remember {
        mutableStateListOf<InvoiceItem>().apply {
            if (existingInvoice != null) {
                addAll(InvoiceUtils.deserializeInvoiceItems(existingInvoice.itemsJson))
            } else {
                add(
                    InvoiceItem(
                        description = "Professional Consulting Services",
                        quantity = 10.0,
                        unitPrice = 120.0,
                        unit = "hrs"
                    )
                )
            }
        }
    }

    // Per-item expand state for "More fields"
    val expandedItemIndexSet = remember { mutableStateListOf<Int>() }

    // -------------------------------------------------------------------------
    // Section 4: Totals & Taxes
    // -------------------------------------------------------------------------
    val currencyCode = profile.defaultCurrency
    val currencySymbol = profile.defaultCurrencySymbol
    var taxRate by remember { mutableDoubleStateOf(existingInvoice?.taxRate ?: profile.defaultTaxRate) }
    var taxLabel by remember { mutableStateOf(existingInvoice?.taxLabel ?: profile.defaultTaxLabel) }
    var taxType by remember { mutableStateOf(existingInvoice?.taxType ?: "GST") }
    var isTaxInclusive by remember { mutableStateOf(existingInvoice?.isTaxInclusive ?: false) }
    var discountPercent by remember { mutableDoubleStateOf(existingInvoice?.discountPercent ?: 0.0) }
    var discountAmount by remember { mutableDoubleStateOf(existingInvoice?.discountAmount ?: 0.0) }
    var shippingFee by remember { mutableDoubleStateOf(existingInvoice?.shippingFee ?: 0.0) }
    var additionalCharges by remember { mutableDoubleStateOf(existingInvoice?.additionalCharges ?: 0.0) }
    var roundOff by remember { mutableDoubleStateOf(existingInvoice?.roundOff ?: 0.0) }
    var amountPaid by remember { mutableDoubleStateOf(existingInvoice?.amountPaid ?: 0.0) }
    var isDiscountPercentageMode by remember { mutableStateOf(discountPercent > 0.0 || discountAmount == 0.0) }

    // -------------------------------------------------------------------------
    // Section 5: Notes / Terms / Signatures
    // -------------------------------------------------------------------------
    var notes by remember { mutableStateOf(existingInvoice?.notes ?: profile.defaultNotes) }
    var terms by remember { mutableStateOf(existingInvoice?.terms ?: profile.defaultTerms) }
    var notesLabel by remember { mutableStateOf("Notes & Remarks") }
    var termsLabel by remember { mutableStateOf("Terms & Conditions") }
    var paymentInstructions by remember {
        mutableStateOf(
            existingInvoice?.paymentInstructions ?: "Bank: ${profile.bankName}\nAccount: ${profile.accountNumber}\nRouting: ${profile.routingNumber}\nUPI: ${profile.upiId}\nPayment Link: ${profile.paymentLink}"
        )
    }
    var status by remember { mutableStateOf(existingInvoice?.status ?: "Draft") }
    var templateId by remember { mutableStateOf(existingInvoice?.templateId ?: profile.defaultTemplateId) }
    var customerSignatureRequired by remember { mutableStateOf(false) }

    // -------------------------------------------------------------------------
    // Calculations
    // -------------------------------------------------------------------------
    val calculations = remember(
        items.toList(),
        taxRate,
        discountPercent,
        discountAmount,
        shippingFee,
        additionalCharges,
        roundOff,
        amountPaid,
        isTaxInclusive
    ) {
        InvoiceUtils.calculateInvoice(
            items = items,
            taxRate = taxRate,
            discountPercent = if (isDiscountPercentageMode) discountPercent else 0.0,
            discountAmount = if (!isDiscountPercentageMode) discountAmount else 0.0,
            shippingFee = if (shippingDetails.isEnabled) shippingFee else 0.0,
            amountPaid = amountPaid,
            additionalCharges = additionalCharges,
            roundOff = roundOff,
            isTaxInclusive = isTaxInclusive
        )
    }

    // Helper: apply payment terms offset to due date
    fun applyTerms(termName: String, daysOffset: Int) {
        paymentTerms = termName
        val cal = Calendar.getInstance()
        if (daysOffset > 0) cal.add(Calendar.DAY_OF_YEAR, daysOffset)
        dueDate = dateFormat.format(cal.time)
        Toast.makeText(context, "Applied $termName (Due: $dueDate)", Toast.LENGTH_SHORT).show()
    }

    // Helper: Save Invoice
    fun validateAndSave(previewAfter: Boolean) {
        if (clientName.isBlank()) {
            Toast.makeText(context, "Please enter client name in Section 1", Toast.LENGTH_SHORT).show()
            isClientExpanded = true
            return
        }
        if (items.isEmpty()) {
            Toast.makeText(context, "Please add at least one item in Section 3", Toast.LENGTH_SHORT).show()
            isItemsExpanded = true
            return
        }

        val invoiceToSave = InvoiceEntity(
            id = if (isNew) 0L else invoiceId,
            invoiceNumber = invoiceNumber.trim(),
            clientId = selectedClientId,
            clientName = clientName.trim(),
            clientCompany = clientCompany.trim(),
            clientEmail = clientEmail.trim(),
            clientPhone = clientPhone.trim(),
            clientAddress = clientAddress.trim(),
            clientTaxId = clientTaxId.trim(),
            issueDate = issueDate.trim(),
            dueDate = dueDate.trim(),
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
            discountPercent = if (isDiscountPercentageMode) discountPercent else 0.0,
            discountAmount = if (!isDiscountPercentageMode) discountAmount else 0.0,
            shippingFee = if (shippingDetails.isEnabled) shippingFee else 0.0,
            amountPaid = amountPaid,
            status = status,
            templateId = templateId,
            docxTemplateTitle = "TAX INVOICE",
            createdAt = existingInvoice?.createdAt ?: System.currentTimeMillis(),
            paidDate = if (status.equals("paid", ignoreCase = true)) System.currentTimeMillis() else null,
            reminderLastSent = existingInvoice?.reminderLastSent,
            shippingDetailsJson = InvoiceUtils.serializeShippingDetails(shippingDetails),
            customFieldsJson = InvoiceUtils.serializeCustomFields(customClientFields),
            itemColumnsJson = InvoiceUtils.serializeColumns(itemColumns),
            additionalCharges = additionalCharges,
            roundOff = roundOff,
            isTaxInclusive = isTaxInclusive,
            taxType = taxType
        )

        viewModel.saveInvoice(invoiceToSave) { savedId ->
            Toast.makeText(context, "Invoice #${invoiceToSave.invoiceNumber} saved!", Toast.LENGTH_SHORT).show()
            if (previewAfter) {
                onSavedAndPreview(savedId)
            } else {
                onBack()
            }
        }
    }

    Scaffold(
        modifier = Modifier.fillMaxSize(),
        contentWindowInsets = WindowInsets(0, 0, 0, 0),
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(
                                text = if (isNew) "Universal Invoice Creator" else "Edit Invoice",
                                fontWeight = FontWeight.Bold,
                                fontSize = 16.sp,
                                color = PrimaryNavy
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Surface(
                                color = Color(0xFFEFF6FF),
                                shape = RoundedCornerShape(6.dp),
                                border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFBFDBFE))
                            ) {
                                Text(
                                    text = "Adaptive",
                                    fontSize = 9.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = Color(0xFF1D4ED8),
                                    modifier = Modifier.padding(horizontal = 4.dp, vertical = 1.dp)
                                )
                            }
                        }
                        Text(
                            text = "Itemization & form customizable for any business",
                            fontSize = 11.sp,
                            color = Color(0xFF64748B)
                        )
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(imageVector = Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    // Choose Industry button
                    IconButton(
                        onClick = { showIndustrySelectorDialog = true },
                        modifier = Modifier.testTag("choose_industry_top_btn")
                    ) {
                        Icon(Icons.Default.ShoppingBag, contentDescription = "Choose Industry", tint = Color(0xFF2563EB))
                    }

                    // Live Preview Dialog Action
                    IconButton(
                        onClick = { showLivePreviewModal = true },
                        modifier = Modifier.testTag("open_live_preview_top_btn")
                    ) {
                        Icon(Icons.Default.Visibility, contentDescription = "Live Preview", tint = PrimaryNavy)
                    }
                },
                windowInsets = WindowInsets.statusBars,
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.White,
                    scrolledContainerColor = Color.White
                )
            )
        },
        bottomBar = {
            // Enterprise Bottom Sticky Action Bar
            Surface(
                color = Color.White,
                shadowElevation = 14.dp,
                border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFE2E8F0))
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 14.dp, vertical = 10.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = "Grand Total: ${currencySymbol}${String.format(Locale.US, "%,.2f", calculations.grandTotal)}",
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Black,
                            color = PrimaryNavy
                        )
                        Text(
                            text = "${items.size} item(s) • $paymentTerms",
                            fontSize = 10.sp,
                            color = Color(0xFF64748B)
                        )
                    }

                    OutlinedButton(
                        onClick = { validateAndSave(previewAfter = false) },
                        shape = RoundedCornerShape(8.dp),
                        contentPadding = PaddingValues(horizontal = 10.dp, vertical = 8.dp),
                        modifier = Modifier.testTag("save_draft_bottom_btn")
                    ) {
                        Icon(Icons.Default.Check, contentDescription = null, modifier = Modifier.size(14.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Save Draft", fontSize = 11.sp, fontWeight = FontWeight.SemiBold)
                    }

                    OutlinedButton(
                        onClick = { showLivePreviewModal = true },
                        shape = RoundedCornerShape(8.dp),
                        colors = ButtonDefaults.outlinedButtonColors(contentColor = Color(0xFF2563EB)),
                        contentPadding = PaddingValues(horizontal = 10.dp, vertical = 8.dp),
                        modifier = Modifier.testTag("live_preview_bottom_btn")
                    ) {
                        Icon(Icons.Default.Visibility, contentDescription = null, modifier = Modifier.size(14.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Live Preview", fontSize = 11.sp, fontWeight = FontWeight.Bold)
                    }

                    Button(
                        onClick = { validateAndSave(previewAfter = true) },
                        colors = ButtonDefaults.buttonColors(containerColor = PrimaryNavy),
                        shape = RoundedCornerShape(8.dp),
                        contentPadding = PaddingValues(horizontal = 12.dp, vertical = 8.dp),
                        modifier = Modifier.testTag("generate_invoice_bottom_btn")
                    ) {
                        Icon(Icons.Default.Receipt, contentDescription = null, modifier = Modifier.size(14.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Generate", fontSize = 11.sp, fontWeight = FontWeight.Bold)
                    }
                }
            }
        }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .background(Color(0xFFF1F5F9))
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {

            // Top Industry Quick Selector Banner (Edge-to-edge)
            Surface(
                modifier = Modifier.fillMaxWidth(),
                color = Color.White,
                border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFE2E8F0))
            ) {
                Column(modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(6.dp)
                        ) {
                            Icon(Icons.Default.AutoAwesome, contentDescription = null, tint = Color(0xFF2563EB), modifier = Modifier.size(18.dp))
                            Text(
                                text = "Business Type & Preset",
                                fontSize = 13.sp,
                                fontWeight = FontWeight.Bold,
                                color = PrimaryNavy
                            )
                        }

                        Surface(
                            color = Color(0xFFEFF6FF),
                            shape = RoundedCornerShape(6.dp),
                            border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFF93C5FD)),
                            modifier = Modifier.clickable { showIndustrySelectorDialog = true }
                        ) {
                            Text(
                                text = "Browse 12 Industries →",
                                fontSize = 10.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color(0xFF2563EB),
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(8.dp))

                    // Quick Chips row for most common presets
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .horizontalScroll(rememberScrollState()),
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        IndustryTemplates.allPresets.take(6).forEach { preset ->
                            val isSelected = selectedIndustryId == preset.id
                            Surface(
                                color = if (isSelected) Color(0xFF2563EB) else Color(0xFFF1F5F9),
                                shape = RoundedCornerShape(16.dp),
                                border = androidx.compose.foundation.BorderStroke(
                                    1.dp,
                                    if (isSelected) Color(0xFF1D4ED8) else Color(0xFFCBD5E1)
                                ),
                                modifier = Modifier.clickable {
                                    selectedIndustryId = preset.id
                                    templateId = preset.recommendedTemplateId
                                    itemColumns.clear()
                                    itemColumns.addAll(preset.defaultColumns)
                                    if (preset.defaultNotes.isNotBlank()) notes = preset.defaultNotes
                                    if (preset.defaultTerms.isNotBlank()) terms = preset.defaultTerms
                                    shippingDetails = shippingDetails.copy(sectionTitle = preset.recommendedSectionTitle)
                                    if (items.isEmpty() || (items.size == 1 && items.first().description.isBlank())) {
                                        preset.sampleItem?.let { sample ->
                                            items.clear()
                                            items.add(sample)
                                        }
                                    }
                                    Toast.makeText(context, "Loaded ${preset.name} template", Toast.LENGTH_SHORT).show()
                                }
                            ) {
                                Text(
                                    text = preset.name,
                                    fontSize = 11.sp,
                                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                                    color = if (isSelected) Color.White else PrimaryNavy,
                                    modifier = Modifier.padding(horizontal = 10.dp, vertical = 5.dp)
                                )
                            }
                        }
                    }
                }
            }

            // =================================================================
            // INVOICE DOCUMENT HEADER CARD (OUTSIDE ACCORDION)
            // =================================================================
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 0.dp)
                    .testTag("invoice_header_outside_card"),
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White),
                border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFE2E8F0)),
                elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
            ) {
                Column(
                    modifier = Modifier.padding(14.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    // Top Row: Title + Status Dropdown
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            Box(
                                modifier = Modifier
                                    .size(32.dp)
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(Color(0xFFEFF6FF)),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(Icons.Default.Receipt, contentDescription = null, tint = Color(0xFF2563EB), modifier = Modifier.size(18.dp))
                            }
                            Column {
                                Text(
                                    text = "Invoice Details",
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 14.sp,
                                    color = PrimaryNavy
                                )
                                Text(
                                    text = "Document number & status",
                                    fontSize = 10.5.sp,
                                    color = Color(0xFF64748B)
                                )
                            }
                        }

                        // Status Selector Dropdown
                        var statusMenuExpanded by remember { mutableStateOf(false) }
                        val (statusBg, statusFg) = when (status.lowercase()) {
                            "paid" -> Pair(Color(0xFFDCFCE7), Color(0xFF15803D))
                            "overdue" -> Pair(Color(0xFFFFE4E6), Color(0xFFBE123C))
                            "sent" -> Pair(Color(0xFFDBEAFE), Color(0xFF1D4ED8))
                            else -> Pair(Color(0xFFF1F5F9), Color(0xFF475569))
                        }

                        Box {
                            Surface(
                                color = statusBg,
                                shape = RoundedCornerShape(20.dp),
                                border = androidx.compose.foundation.BorderStroke(1.dp, statusFg.copy(alpha = 0.3f)),
                                modifier = Modifier
                                    .clickable { statusMenuExpanded = true }
                                    .testTag("invoice_status_pill_btn")
                            ) {
                                Row(
                                    modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                                ) {
                                    Box(
                                        modifier = Modifier
                                            .size(8.dp)
                                            .clip(CircleShape)
                                            .background(statusFg)
                                    )
                                    Text(
                                        text = status,
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 12.sp,
                                        color = statusFg
                                    )
                                    Icon(Icons.Default.KeyboardArrowDown, contentDescription = "Change Status", tint = statusFg, modifier = Modifier.size(16.dp))
                                }
                            }

                            DropdownMenu(
                                expanded = statusMenuExpanded,
                                onDismissRequest = { statusMenuExpanded = false }
                            ) {
                                listOf("Draft", "Sent", "Paid", "Overdue").forEach { st ->
                                    DropdownMenuItem(
                                        text = {
                                            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                                val dotColor = when (st.lowercase()) {
                                                    "paid" -> Color(0xFF16A34A)
                                                    "overdue" -> Color(0xFFE11D48)
                                                    "sent" -> Color(0xFF2563EB)
                                                    else -> Color(0xFF64748B)
                                                }
                                                Box(modifier = Modifier.size(10.dp).clip(CircleShape).background(dotColor))
                                                Text(st, fontWeight = if (status == st) FontWeight.Bold else FontWeight.Normal)
                                            }
                                        },
                                        onClick = {
                                            status = st
                                            statusMenuExpanded = false
                                        }
                                    )
                                }
                            }
                        }
                    }

                    HorizontalDivider(color = Color(0xFFF1F5F9))

                    // Row 1: Invoice # and PO / Ref #
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        OutlinedTextField(
                            value = invoiceNumber,
                            onValueChange = { invoiceNumber = it },
                            label = { Text("Invoice #") },
                            leadingIcon = {
                                Text("#", fontWeight = FontWeight.Bold, color = Color(0xFF2563EB), fontSize = 16.sp, modifier = Modifier.padding(start = 12.dp, end = 4.dp))
                            },
                            singleLine = true,
                            modifier = Modifier.weight(1.2f).testTag("field_invoice_number")
                        )

                        OutlinedTextField(
                            value = poNumber,
                            onValueChange = { poNumber = it },
                            label = { Text("PO / Ref # (Optional)") },
                            singleLine = true,
                            modifier = Modifier.weight(1f).testTag("field_po_number")
                        )
                    }

                    // Row 2: Issue Date & Due Date
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        OutlinedTextField(
                            value = issueDate,
                            onValueChange = { issueDate = it },
                            label = { Text("Issue Date") },
                            leadingIcon = { Icon(Icons.Default.CalendarToday, contentDescription = null, modifier = Modifier.size(16.dp)) },
                            singleLine = true,
                            modifier = Modifier.weight(1f).testTag("field_issue_date")
                        )

                        OutlinedTextField(
                            value = dueDate,
                            onValueChange = { dueDate = it },
                            label = { Text("Due Date") },
                            leadingIcon = { Icon(Icons.Default.Event, contentDescription = null, modifier = Modifier.size(16.dp)) },
                            singleLine = true,
                            modifier = Modifier.weight(1f).testTag("field_due_date")
                        )
                    }

                    // Quick Terms Shortcut Chips
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .horizontalScroll(rememberScrollState()),
                        horizontalArrangement = Arrangement.spacedBy(6.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text("Terms:", fontSize = 11.sp, color = Color(0xFF64748B), fontWeight = FontWeight.SemiBold)
                        listOf(
                            "Due on Receipt" to 0,
                            "Net 15" to 15,
                            "Net 30" to 30,
                            "Net 60" to 60
                        ).forEach { (tName, offset) ->
                            val isCurrentTerm = paymentTerms == tName
                            Surface(
                                color = if (isCurrentTerm) Color(0xFFEFF6FF) else Color(0xFFF8FAFC),
                                shape = RoundedCornerShape(12.dp),
                                border = androidx.compose.foundation.BorderStroke(
                                    1.dp,
                                    if (isCurrentTerm) Color(0xFF93C5FD) else Color(0xFFCBD5E1)
                                ),
                                modifier = Modifier.clickable { applyTerms(tName, offset) }
                            ) {
                                Text(
                                    text = tName,
                                    fontSize = 10.sp,
                                    fontWeight = if (isCurrentTerm) FontWeight.Bold else FontWeight.Normal,
                                    color = if (isCurrentTerm) Color(0xFF1D4ED8) else Color(0xFF475569),
                                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                                )
                            }
                        }
                    }
                }
            }

            // =================================================================
            // ACCORDION 1: CLIENT DETAILS
            // =================================================================
            InvoiceAccordionSection(
                sectionNumber = 1,
                icon = Icons.Default.Person,
                title = "Client Details",
                collapsedSummary = if (clientName.isNotBlank()) {
                    "Billed to: $clientName ${if (clientCompany.isNotBlank()) "($clientCompany)" else ""} • ${clientEmail.ifBlank { clientPhone.ifBlank { "Contact details added" } }}"
                } else {
                    "No client specified • Tap to enter details"
                },
                isExpanded = isClientExpanded,
                onToggleExpand = { isClientExpanded = !isClientExpanded },
                badgeText = if (clientName.isNotBlank()) "Configured" else "Required",
                testTag = "accordion_client_details"
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    // Client Name with Dropdown Autocomplete
                    val matchingClients = remember(clientName, allClients) {
                        if (clientName.isBlank()) emptyList()
                        else allClients.filter {
                            it.name.contains(clientName, ignoreCase = true) ||
                                it.companyName.contains(clientName, ignoreCase = true)
                        }
                    }

                    Box(modifier = Modifier.fillMaxWidth()) {
                        OutlinedTextField(
                            value = clientName,
                            onValueChange = {
                                clientName = it
                                clientDropdownExpanded = it.isNotBlank()
                            },
                            label = { Text(clientLabelTitle) },
                            singleLine = true,
                            modifier = Modifier
                                .fillMaxWidth()
                                .testTag("field_client_name"),
                            trailingIcon = {
                                if (allClients.isNotEmpty()) {
                                    IconButton(onClick = { clientDropdownExpanded = !clientDropdownExpanded }) {
                                        Icon(Icons.Default.KeyboardArrowDown, contentDescription = "Pick Client")
                                    }
                                }
                            }
                        )

                        DropdownMenu(
                            expanded = clientDropdownExpanded && matchingClients.isNotEmpty(),
                            onDismissRequest = { clientDropdownExpanded = false }
                        ) {
                            matchingClients.forEach { c ->
                                DropdownMenuItem(
                                    text = {
                                        Column {
                                            Text(text = c.name, fontWeight = FontWeight.Bold, fontSize = 13.sp)
                                            if (c.companyName.isNotBlank()) Text(text = c.companyName, fontSize = 11.sp, color = Color.Gray)
                                            if (c.email.isNotBlank()) Text(text = c.email, fontSize = 10.sp, color = Color.Gray)
                                        }
                                    },
                                    onClick = {
                                        selectedClientId = c.id
                                        clientName = c.name
                                        clientCompany = c.companyName
                                        clientEmail = c.email
                                        clientPhone = c.phone
                                        clientAddress = c.address
                                        clientTaxId = c.taxId
                                        clientDropdownExpanded = false
                                        Toast.makeText(context, "Filled details for ${c.name}", Toast.LENGTH_SHORT).show()
                                    }
                                )
                            }
                        }
                    }

                    // Company Name & GST / Tax ID
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        OutlinedTextField(
                            value = clientCompany,
                            onValueChange = { clientCompany = it },
                            label = { Text("Company Name") },
                            singleLine = true,
                            modifier = Modifier.weight(1f).testTag("field_client_company")
                        )

                        OutlinedTextField(
                            value = clientTaxId,
                            onValueChange = { clientTaxId = it },
                            label = { Text("GSTIN / Tax ID") },
                            singleLine = true,
                            modifier = Modifier.weight(1f).testTag("field_client_tax_id")
                        )
                    }

                    // Billing Address
                    OutlinedTextField(
                        value = clientAddress,
                        onValueChange = { clientAddress = it },
                        label = { Text("Billing Address") },
                        maxLines = 3,
                        modifier = Modifier.fillMaxWidth().testTag("field_client_address")
                    )

                    // Email & Phone
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        OutlinedTextField(
                            value = clientEmail,
                            onValueChange = { clientEmail = it },
                            label = { Text("Email Address") },
                            singleLine = true,
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email),
                            modifier = Modifier.weight(1f).testTag("field_client_email")
                        )

                        OutlinedTextField(
                            value = clientPhone,
                            onValueChange = { clientPhone = it },
                            label = { Text("Phone Number") },
                            singleLine = true,
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
                            modifier = Modifier.weight(1f).testTag("field_client_phone")
                        )
                    }

                    // Custom Client Fields List
                    customClientFields.forEachIndexed { cfIndex, cf ->
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            OutlinedTextField(
                                value = cf.label,
                                onValueChange = { customClientFields[cfIndex] = cf.copy(label = it) },
                                label = { Text("Field Label") },
                                modifier = Modifier.weight(0.9f)
                            )
                            OutlinedTextField(
                                value = cf.value,
                                onValueChange = { customClientFields[cfIndex] = cf.copy(value = it) },
                                label = { Text("Value") },
                                modifier = Modifier.weight(1.1f)
                            )
                            IconButton(onClick = { customClientFields.removeAt(cfIndex) }) {
                                Icon(Icons.Default.Delete, contentDescription = "Delete Field", tint = Color.Gray)
                            }
                        }
                    }

                    // Bottom Row: Add Custom Field & Save to Clients DB
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        OutlinedButton(
                            onClick = {
                                customClientFields.add(CustomClientField(label = "Custom Field ${customClientFields.size + 1}"))
                            },
                            shape = RoundedCornerShape(8.dp),
                            contentPadding = PaddingValues(horizontal = 8.dp, vertical = 4.dp)
                        ) {
                            Icon(Icons.Default.Add, contentDescription = null, modifier = Modifier.size(14.dp))
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("+ Add Custom Field", fontSize = 11.sp)
                        }

                        if (clientName.isNotBlank() && allClients.none { it.name.equals(clientName, ignoreCase = true) }) {
                            Button(
                                onClick = {
                                    val newClient = ClientEntity(
                                        name = clientName.trim(),
                                        companyName = clientCompany.trim(),
                                        email = clientEmail.trim(),
                                        phone = clientPhone.trim(),
                                        address = clientAddress.trim(),
                                        taxId = clientTaxId.trim()
                                    )
                                    viewModel.saveClient(newClient) { newId ->
                                        selectedClientId = newId
                                        Toast.makeText(context, "Saved $clientName to client directory", Toast.LENGTH_SHORT).show()
                                    }
                                },
                                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF16A34A)),
                                shape = RoundedCornerShape(8.dp),
                                contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp)
                            ) {
                                Text("Save Client to DB", fontSize = 11.sp, fontWeight = FontWeight.Bold)
                            }
                        }
                    }
                }
            }

            // =================================================================
            // ACCORDION 2: SHIPPING / DELIVERY DETAILS (OPTIONAL)
            // =================================================================
            val isShippingSectionVisible = profile.showShippingSection || shippingDetails.isEnabled
            if (isShippingSectionVisible) {
                InvoiceAccordionSection(
                    sectionNumber = 2,
                icon = Icons.Default.LocalShipping,
                title = shippingDetails.sectionTitle,
                collapsedSummary = if (!shippingDetails.isEnabled) {
                    "Disabled (Completely optional) • Tap to configure"
                } else if (shippingDetails.sameAsBilling) {
                    "Same as Billing Address • ${shippingDetails.shippingMethod.ifBlank { "Standard Delivery" }}"
                } else {
                    "${shippingDetails.shippingAddress.ifBlank { "No address specified" }} • ${shippingDetails.courier.ifBlank { "Carrier" }}"
                },
                isExpanded = isShippingExpanded,
                onToggleExpand = { isShippingExpanded = !isShippingExpanded },
                badgeText = if (shippingDetails.isEnabled) "Active" else "Optional",
                testTag = "accordion_shipping_details"
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    // Enable Toggle Switch
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text("Enable Shipping / Delivery Section", fontSize = 13.sp, fontWeight = FontWeight.Bold, color = PrimaryNavy)
                            Text("Include delivery notes, tracking, and carrier on invoice", fontSize = 11.sp, color = Color.Gray)
                        }

                        Switch(
                            checked = shippingDetails.isEnabled,
                            onCheckedChange = {
                                shippingDetails = shippingDetails.copy(isEnabled = it)
                            },
                            colors = SwitchDefaults.colors(
                                checkedThumbColor = Color.White,
                                checkedTrackColor = Color(0xFF2563EB)
                            )
                        )
                    }

                    if (shippingDetails.isEnabled) {
                        HorizontalDivider(color = Color(0xFFF1F5F9))

                        // Customizable Section Title Chips
                        Text("Section Name on Invoice:", fontSize = 11.sp, fontWeight = FontWeight.SemiBold, color = Color(0xFF475569))
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .horizontalScroll(rememberScrollState()),
                            horizontalArrangement = Arrangement.spacedBy(6.dp)
                        ) {
                            listOf("Shipping Details", "Delivery Details", "Dispatch Details", "Logistics Details").forEach { titleOption ->
                                val isSelected = shippingDetails.sectionTitle == titleOption
                                Surface(
                                    color = if (isSelected) Color(0xFF2563EB) else Color(0xFFF1F5F9),
                                    shape = RoundedCornerShape(12.dp),
                                    modifier = Modifier.clickable {
                                        shippingDetails = shippingDetails.copy(sectionTitle = titleOption)
                                    }
                                ) {
                                    Text(
                                        text = titleOption,
                                        fontSize = 11.sp,
                                        fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
                                        color = if (isSelected) Color.White else PrimaryNavy,
                                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                                    )
                                }
                            }
                        }

                        // Same as Billing Address Toggle
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text("Same as Billing Address", fontSize = 13.sp, fontWeight = FontWeight.Medium)
                            Switch(
                                checked = shippingDetails.sameAsBilling,
                                onCheckedChange = { same ->
                                    shippingDetails = shippingDetails.copy(
                                        sameAsBilling = same,
                                        shippingAddress = if (same) clientAddress else shippingDetails.shippingAddress
                                    )
                                }
                            )
                        }

                        // Shipping Address
                        if (!shippingDetails.sameAsBilling) {
                            OutlinedTextField(
                                value = shippingDetails.shippingAddress,
                                onValueChange = { shippingDetails = shippingDetails.copy(shippingAddress = it) },
                                label = { Text("Delivery / Destination Address") },
                                modifier = Modifier.fillMaxWidth()
                            )
                        }

                        // Carrier & Tracking Number
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(10.dp)
                        ) {
                            OutlinedTextField(
                                value = shippingDetails.courier,
                                onValueChange = { shippingDetails = shippingDetails.copy(courier = it) },
                                label = { Text("Courier / Carrier (e.g. FedEx)") },
                                singleLine = true,
                                modifier = Modifier.weight(1f)
                            )

                            OutlinedTextField(
                                value = shippingDetails.trackingNumber,
                                onValueChange = { shippingDetails = shippingDetails.copy(trackingNumber = it) },
                                label = { Text("Tracking #") },
                                singleLine = true,
                                modifier = Modifier.weight(1f)
                            )
                        }

                        // Shipping Method & Dispatch Date
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(10.dp)
                        ) {
                            OutlinedTextField(
                                value = shippingDetails.shippingMethod,
                                onValueChange = { shippingDetails = shippingDetails.copy(shippingMethod = it) },
                                label = { Text("Method (Air / Road)") },
                                singleLine = true,
                                modifier = Modifier.weight(1f)
                            )

                            OutlinedTextField(
                                value = shippingDetails.dispatchDate,
                                onValueChange = { shippingDetails = shippingDetails.copy(dispatchDate = it) },
                                label = { Text("Dispatch Date") },
                                singleLine = true,
                                modifier = Modifier.weight(1f)
                            )
                        }

                        // Warehouse & Vehicle Number
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(10.dp)
                        ) {
                            OutlinedTextField(
                                value = shippingDetails.warehouse,
                                onValueChange = { shippingDetails = shippingDetails.copy(warehouse = it) },
                                label = { Text("Warehouse / Origin") },
                                singleLine = true,
                                modifier = Modifier.weight(1f)
                            )

                            OutlinedTextField(
                                value = shippingDetails.vehicleNumber,
                                onValueChange = { shippingDetails = shippingDetails.copy(vehicleNumber = it) },
                                label = { Text("Vehicle # (Optional)") },
                                singleLine = true,
                                modifier = Modifier.weight(1f)
                            )
                        }
                    }
                }
            } else {
                Surface(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable {
                            shippingDetails = shippingDetails.copy(isEnabled = true)
                            isShippingExpanded = true
                        }
                        .testTag("enable_shipping_prompt_card"),
                    color = Color.White,
                    shape = RoundedCornerShape(10.dp),
                    border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFE2E8F0))
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 14.dp, vertical = 12.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                            Box(
                                modifier = Modifier
                                    .size(32.dp)
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(Color(0xFFF1F5F9)),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(Icons.Default.LocalShipping, contentDescription = null, tint = Color(0xFF64748B), modifier = Modifier.size(18.dp))
                            }
                            Column {
                                Text(text = "Shipping Details (Hidden by Settings)", fontSize = 13.sp, fontWeight = FontWeight.SemiBold, color = Color(0xFF334155))
                                Text(text = "Keep hidden for services, or tap to enable for physical goods", fontSize = 10.5.sp, color = Color(0xFF94A3B8))
                            }
                        }
                        Text(text = "+ Add Shipping", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = Color(0xFF2563EB))
                    }
                }
            }

            // =================================================================
            // ACCORDION 3: ITEMS / PRODUCTS / SERVICES (UNIVERSAL ENGINE)
            // =================================================================
            InvoiceAccordionSection(
                sectionNumber = 3,
                icon = Icons.Default.Receipt,
                title = "Items & Services",
                collapsedSummary = "${items.size} line item(s) • Subtotal: ${currencySymbol}${String.format(Locale.US, "%,.2f", calculations.subtotal)}",
                isExpanded = isItemsExpanded,
                onToggleExpand = { isItemsExpanded = !isItemsExpanded },
                badgeText = "${items.size} Items",
                testTag = "accordion_items_section"
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    // Sleek Sub-header Toolbar
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(6.dp)
                        ) {
                            Text(
                                text = "Item List & Rates",
                                fontSize = 13.sp,
                                fontWeight = FontWeight.Bold,
                                color = PrimaryNavy
                            )
                            Surface(
                                color = Color(0xFFEFF6FF),
                                shape = RoundedCornerShape(6.dp),
                                border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFBFDBFE))
                            ) {
                                Text(
                                    text = "${itemColumns.count { it.isVisible }} Columns",
                                    fontSize = 10.sp,
                                    fontWeight = FontWeight.SemiBold,
                                    color = Color(0xFF1D4ED8),
                                    modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                )
                            }
                        }

                        Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                            OutlinedButton(
                                onClick = { showItemizationBuilderDialog = true },
                                shape = RoundedCornerShape(8.dp),
                                contentPadding = PaddingValues(horizontal = 8.dp, vertical = 4.dp),
                                modifier = Modifier.testTag("open_item_builder_btn")
                            ) {
                                Icon(Icons.Default.Tune, contentDescription = null, tint = Color(0xFF2563EB), modifier = Modifier.size(13.dp))
                                Spacer(modifier = Modifier.width(4.dp))
                                Text("Item Settings", fontSize = 11.sp, color = Color(0xFF2563EB), fontWeight = FontWeight.Bold)
                            }

                            Button(
                                onClick = {
                                    items.add(InvoiceItem(description = "", quantity = 1.0, unitPrice = 0.0, unit = "hrs"))
                                },
                                colors = ButtonDefaults.buttonColors(containerColor = PrimaryNavy),
                                shape = RoundedCornerShape(8.dp),
                                contentPadding = PaddingValues(horizontal = 8.dp, vertical = 4.dp)
                            ) {
                                Icon(Icons.Default.Add, contentDescription = null, modifier = Modifier.size(13.dp))
                                Spacer(modifier = Modifier.width(3.dp))
                                Text("+ Add", fontSize = 11.sp, fontWeight = FontWeight.Bold)
                            }
                        }
                    }

                    // Mobile-first Item Cards (Sleek, matching Client accordion elegance)
                    items.forEachIndexed { itemIndex, item ->
                        val isItemDetailsExpanded = expandedItemIndexSet.contains(itemIndex)

                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .testTag("item_card_$itemIndex"),
                            shape = RoundedCornerShape(12.dp),
                            colors = CardDefaults.cardColors(containerColor = Color.White),
                            border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFE2E8F0))
                        ) {
                            Column(modifier = Modifier.padding(10.dp)) {
                                // Row 1: Index + Description + Actions
                                val descCol = itemColumns.find { it.key == "description" }
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                                ) {
                                    Box(
                                        modifier = Modifier
                                            .size(24.dp)
                                            .clip(CircleShape)
                                            .background(Color(0xFFEFF6FF)),
                                        contentAlignment = Alignment.Center
                                    ) {
                                        Text(
                                            text = "${itemIndex + 1}",
                                            fontSize = 10.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = Color(0xFF1D4ED8)
                                        )
                                    }

                                    OutlinedTextField(
                                        value = item.description,
                                        onValueChange = { items[itemIndex] = item.copy(description = it) },
                                        label = { Text(descCol?.label ?: "Description / Service / Product") },
                                        singleLine = true,
                                        modifier = Modifier
                                            .weight(1f)
                                            .testTag("item_desc_$itemIndex")
                                    )

                                    IconButton(
                                        onClick = {
                                            val duplicated = item.copy(id = java.util.UUID.randomUUID().toString())
                                            items.add(itemIndex + 1, duplicated)
                                            Toast.makeText(context, "Duplicated item", Toast.LENGTH_SHORT).show()
                                        },
                                        modifier = Modifier.size(28.dp)
                                    ) {
                                        Icon(Icons.Default.ContentCopy, contentDescription = "Duplicate", modifier = Modifier.size(15.dp), tint = Color(0xFF64748B))
                                    }

                                    if (items.size > 1) {
                                        IconButton(
                                            onClick = {
                                                items.removeAt(itemIndex)
                                                expandedItemIndexSet.remove(itemIndex)
                                            },
                                            modifier = Modifier.size(28.dp)
                                        ) {
                                            Icon(Icons.Default.Delete, contentDescription = "Delete", modifier = Modifier.size(15.dp), tint = Color(0xFFDC2626))
                                        }
                                    }
                                }

                                Spacer(modifier = Modifier.height(6.dp))

                                // Row 2: Quantity, Unit, Rate, Amount
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    val qtyCol = itemColumns.find { it.key == "quantity" }
                                    OutlinedTextField(
                                        value = if (item.quantity % 1.0 == 0.0) item.quantity.toInt().toString() else item.quantity.toString(),
                                        onValueChange = { str ->
                                            val q = str.toDoubleOrNull() ?: 1.0
                                            items[itemIndex] = item.copy(quantity = q)
                                        },
                                        label = { Text(qtyCol?.label ?: "Qty", fontSize = 10.sp) },
                                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                                        singleLine = true,
                                        modifier = Modifier.weight(0.9f).testTag("item_qty_$itemIndex")
                                    )

                                    val unitCol = itemColumns.find { it.key == "unit" }
                                    OutlinedTextField(
                                        value = item.unit,
                                        onValueChange = { items[itemIndex] = item.copy(unit = it) },
                                        label = { Text(unitCol?.label ?: "Unit", fontSize = 10.sp) },
                                        singleLine = true,
                                        modifier = Modifier.weight(0.8f).testTag("item_unit_$itemIndex")
                                    )

                                    val rateCol = itemColumns.find { it.key == "unitPrice" }
                                    OutlinedTextField(
                                        value = if (item.unitPrice > 0) item.unitPrice.toString() else "",
                                        onValueChange = { str ->
                                            val r = str.toDoubleOrNull() ?: 0.0
                                            items[itemIndex] = item.copy(unitPrice = r)
                                        },
                                        label = { Text(rateCol?.label ?: "Rate", fontSize = 10.sp) },
                                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                                        singleLine = true,
                                        modifier = Modifier.weight(1.1f).testTag("item_rate_$itemIndex")
                                    )

                                    // Line Total Badge
                                    Surface(
                                        color = Color(0xFFF8FAFC),
                                        shape = RoundedCornerShape(8.dp),
                                        border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFE2E8F0)),
                                        modifier = Modifier.weight(1.1f)
                                    ) {
                                        Column(
                                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 6.dp),
                                            horizontalAlignment = Alignment.End
                                        ) {
                                            Text("Amount", fontSize = 9.sp, color = Color(0xFF64748B), fontWeight = FontWeight.SemiBold)
                                            Text(
                                                text = "${currencySymbol}${String.format(Locale.US, "%,.2f", item.total)}",
                                                fontSize = 12.sp,
                                                fontWeight = FontWeight.Bold,
                                                color = PrimaryNavy
                                            )
                                        }
                                    }
                                }

                                // Row 3: Extra columns
                                val extraCustomCols = itemColumns.filter {
                                    it.key != "description" && it.key != "quantity" && it.key != "unit" && it.key != "unitPrice" && it.key != "total"
                                }

                                if (extraCustomCols.isNotEmpty()) {
                                    Spacer(modifier = Modifier.height(4.dp))
                                    Row(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .clickable {
                                                if (isItemDetailsExpanded) expandedItemIndexSet.remove(itemIndex)
                                                else expandedItemIndexSet.add(itemIndex)
                                            }
                                            .padding(vertical = 4.dp),
                                        horizontalArrangement = Arrangement.SpaceBetween,
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Text(
                                            text = if (isItemDetailsExpanded) "Hide extra fields (${extraCustomCols.size}) ▲" else "More column fields (${extraCustomCols.size}) ▼",
                                            fontSize = 11.sp,
                                            fontWeight = FontWeight.SemiBold,
                                            color = Color(0xFF2563EB)
                                        )
                                    }

                                    AnimatedVisibility(visible = isItemDetailsExpanded) {
                                        Column(
                                            modifier = Modifier
                                                .fillMaxWidth()
                                                .padding(top = 4.dp),
                                            verticalArrangement = Arrangement.spacedBy(6.dp)
                                        ) {
                                            extraCustomCols.chunked(2).forEach { pair ->
                                                Row(
                                                    modifier = Modifier.fillMaxWidth(),
                                                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                                                ) {
                                                    pair.forEach { col ->
                                                        val currVal = item.customFields[col.key] ?: ""
                                                        OutlinedTextField(
                                                            value = currVal,
                                                            onValueChange = { newVal ->
                                                                val updatedMap = item.customFields.toMutableMap()
                                                                updatedMap[col.key] = newVal
                                                                items[itemIndex] = item.copy(customFields = updatedMap)
                                                            },
                                                            label = { Text("${col.label} (${col.dataType})", fontSize = 10.sp) },
                                                            singleLine = true,
                                                            modifier = Modifier.weight(1f)
                                                        )
                                                    }
                                                    if (pair.size == 1) {
                                                        Spacer(modifier = Modifier.weight(1f))
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Bottom "+ Add Another Item" Button
                    OutlinedButton(
                        onClick = {
                            items.add(InvoiceItem(description = "", quantity = 1.0, unitPrice = 0.0, unit = "hrs"))
                        },
                        shape = RoundedCornerShape(10.dp),
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("add_item_btn")
                    ) {
                        Icon(Icons.Default.Add, contentDescription = null, modifier = Modifier.size(16.dp))
                        Spacer(modifier = Modifier.width(6.dp))
                        Text("+ Add Another Line Item", fontWeight = FontWeight.Bold, fontSize = 13.sp)
                    }
                }
            }

            // =================================================================
            // ACCORDION 4: TOTALS & TAXES
            // =================================================================
            InvoiceAccordionSection(
                sectionNumber = 4,
                icon = Icons.Default.Payments,
                title = "Totals & Taxes",
                collapsedSummary = "Subtotal: ${currencySymbol}${String.format(Locale.US, "%,.2f", calculations.subtotal)} • Tax: ${currencySymbol}${String.format(Locale.US, "%,.2f", calculations.taxTotal)} • Grand Total: ${currencySymbol}${String.format(Locale.US, "%,.2f", calculations.grandTotal)}",
                isExpanded = isTotalsExpanded,
                onToggleExpand = { isTotalsExpanded = !isTotalsExpanded },
                badgeText = "${currencySymbol}${String.format(Locale.US, "%,.0f", calculations.grandTotal)}",
                testTag = "accordion_totals_taxes"
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    // Subtotal Display Row
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text("Subtotal", fontSize = 13.sp, color = Color(0xFF64748B))
                        Text(
                            text = "${currencySymbol}${String.format(Locale.US, "%,.2f", calculations.subtotal)}",
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Bold,
                            color = PrimaryNavy
                        )
                    }

                    // Discount row (Percentage vs Flat amount)
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        OutlinedTextField(
                            value = if (isDiscountPercentageMode) (if (discountPercent > 0) discountPercent.toString() else "") else (if (discountAmount > 0) discountAmount.toString() else ""),
                            onValueChange = { str ->
                                val v = str.toDoubleOrNull() ?: 0.0
                                if (isDiscountPercentageMode) discountPercent = v else discountAmount = v
                            },
                            label = { Text(if (isDiscountPercentageMode) "Discount (%)" else "Discount ($currencySymbol)") },
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                            singleLine = true,
                            modifier = Modifier.weight(1.2f).testTag("field_discount")
                        )

                        // Mode Switch
                        Surface(
                            color = Color(0xFFF1F5F9),
                            shape = RoundedCornerShape(8.dp),
                            modifier = Modifier
                                .weight(0.8f)
                                .clickable { isDiscountPercentageMode = !isDiscountPercentageMode }
                        ) {
                            Box(modifier = Modifier.padding(vertical = 12.dp), contentAlignment = Alignment.Center) {
                                Text(
                                    text = if (isDiscountPercentageMode) "% (Percent)" else "$ (Flat)",
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = Color(0xFF2563EB)
                                )
                            }
                        }
                    }

                    // Tax Setup Row (GST / VAT / Sales Tax / Custom)
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        OutlinedTextField(
                            value = taxLabel,
                            onValueChange = { taxLabel = it },
                            label = { Text("Tax Label (e.g. GST)") },
                            singleLine = true,
                            modifier = Modifier.weight(1f)
                        )

                        OutlinedTextField(
                            value = if (taxRate > 0) taxRate.toString() else "",
                            onValueChange = { taxRate = it.toDoubleOrNull() ?: 0.0 },
                            label = { Text("Tax Rate (%)") },
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                            singleLine = true,
                            modifier = Modifier.weight(1f).testTag("field_tax_rate")
                        )
                    }

                    // Tax-inclusive pricing toggle
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text("Tax-Inclusive Pricing", fontSize = 12.sp, fontWeight = FontWeight.Medium)
                            Text("Item rates already include taxes", fontSize = 10.sp, color = Color.Gray)
                        }
                        Switch(
                            checked = isTaxInclusive,
                            onCheckedChange = { isTaxInclusive = it },
                            colors = SwitchDefaults.colors(
                                checkedThumbColor = Color.White,
                                checkedTrackColor = Color(0xFF2563EB)
                            )
                        )
                    }

                    // Shipping & Additional Charges
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        OutlinedTextField(
                            value = if (shippingFee > 0) shippingFee.toString() else "",
                            onValueChange = { shippingFee = it.toDoubleOrNull() ?: 0.0 },
                            label = { Text("Shipping Fee ($currencySymbol)") },
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                            singleLine = true,
                            modifier = Modifier.weight(1f).testTag("field_shipping_fee")
                        )

                        OutlinedTextField(
                            value = if (additionalCharges > 0) additionalCharges.toString() else "",
                            onValueChange = { additionalCharges = it.toDoubleOrNull() ?: 0.0 },
                            label = { Text("Additional Charges") },
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                            singleLine = true,
                            modifier = Modifier.weight(1f)
                        )
                    }

                    // Prominent Grand Total SaaS Card
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(14.dp),
                        colors = CardDefaults.cardColors(containerColor = PrimaryNavy)
                    ) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column {
                                    Text("GRAND TOTAL DUE", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = Color(0xFF94A3B8))
                                    Text(
                                        text = "${currencySymbol}${String.format(Locale.US, "%,.2f", calculations.grandTotal)}",
                                        fontSize = 24.sp,
                                        fontWeight = FontWeight.Black,
                                        color = Color.White
                                    )
                                }

                                Surface(
                                    color = Color(0xFF16A34A).copy(alpha = 0.2f),
                                    shape = RoundedCornerShape(8.dp),
                                    border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFF22C55E))
                                ) {
                                    Text(
                                        text = status.uppercase(),
                                        fontSize = 10.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = Color(0xFF4ADE80),
                                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                                    )
                                }
                            }

                            Spacer(modifier = Modifier.height(8.dp))

                            // Amount in Words Pill
                            Surface(
                                color = Color(0xFF0F172A),
                                shape = RoundedCornerShape(6.dp),
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Text(
                                    text = InvoiceUtils.amountInWords(calculations.grandTotal, currencyCode),
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.Medium,
                                    color = Color(0xFF38BDF8),
                                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 6.dp)
                                )
                            }
                        }
                    }
                }
            }

            // =================================================================
            // ACCORDION 5: NOTES / TERMS / SIGNATURES
            // =================================================================
            InvoiceAccordionSection(
                sectionNumber = 5,
                icon = Icons.Default.FactCheck,
                title = "Notes, Terms & Signatures",
                collapsedSummary = "Signatory: ${profile.signeeName} • Stamp: ${if (profile.showStamp) "Active" else "Hidden"} • Payment Wire included",
                isExpanded = isNotesExpanded,
                onToggleExpand = { isNotesExpanded = !isNotesExpanded },
                badgeText = "Branding",
                testTag = "accordion_notes_signatures"
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    if (profile.showNotesSection) {
                        OutlinedTextField(
                            value = notes,
                            onValueChange = { notes = it },
                            label = { Text(notesLabel) },
                            maxLines = 3,
                            modifier = Modifier.fillMaxWidth().testTag("field_notes")
                        )
                    }

                    if (profile.showTermsSection) {
                        OutlinedTextField(
                            value = terms,
                            onValueChange = { terms = it },
                            label = { Text(termsLabel) },
                            maxLines = 3,
                            modifier = Modifier.fillMaxWidth().testTag("field_terms")
                        )
                    }

                    if (profile.showBankingSection) {
                        OutlinedTextField(
                            value = paymentInstructions,
                            onValueChange = { paymentInstructions = it },
                            label = { Text("Payment Instructions & Bank Account") },
                            maxLines = 3,
                            modifier = Modifier.fillMaxWidth().testTag("field_payment_instructions")
                        )
                    }

                    if (profile.showSignatureSection) {
                        // Authorized Signatory Card Preview
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(10.dp),
                            colors = CardDefaults.cardColors(containerColor = Color(0xFFF1F5F9))
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(12.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column {
                                    Text("Authorized Signatory (Default)", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = PrimaryNavy)
                                    Text(profile.signeeName, fontSize = 13.sp, fontStyle = androidx.compose.ui.text.font.FontStyle.Italic, color = Color(0xFF1E3A8A))
                                    Text(profile.signeeTitle, fontSize = 10.sp, color = Color.Gray)
                                }

                                if (profile.showStamp) {
                                    Surface(
                                        color = Color(0xFFEFF6FF),
                                        shape = RoundedCornerShape(6.dp),
                                        border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFF2563EB))
                                    ) {
                                        Text(
                                            text = "SEAL ACTIVE",
                                            fontSize = 9.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = Color(0xFF1D4ED8),
                                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))
        }
    }

    // -------------------------------------------------------------------------
    // DIALOGS & OVERLAYS
    // -------------------------------------------------------------------------

    // 1. Dynamic Itemization Customizer Dialog
    if (showItemizationBuilderDialog) {
        ItemizationBuilderDialog(
            initialColumns = itemColumns,
            onSaveColumns = { updatedCols ->
                itemColumns.clear()
                itemColumns.addAll(updatedCols)
                Toast.makeText(context, "Itemization structure applied!", Toast.LENGTH_SHORT).show()
            },
            onDismiss = { showItemizationBuilderDialog = false }
        )
    }

    // 2. 12 Industry Preset Selector Dialog
    if (showIndustrySelectorDialog) {
        IndustryTemplateSelectorDialog(
            selectedPresetId = selectedIndustryId,
            onSelectPreset = { preset ->
                selectedIndustryId = preset.id
                templateId = preset.recommendedTemplateId
                itemColumns.clear()
                itemColumns.addAll(preset.defaultColumns)
                if (preset.defaultNotes.isNotBlank()) notes = preset.defaultNotes
                if (preset.defaultTerms.isNotBlank()) terms = preset.defaultTerms
                shippingDetails = shippingDetails.copy(sectionTitle = preset.recommendedSectionTitle)
                if (items.isEmpty() || (items.size == 1 && items.first().description.isBlank())) {
                    preset.sampleItem?.let { sample ->
                        items.clear()
                        items.add(sample)
                    }
                }
                Toast.makeText(context, "Loaded ${preset.name} template", Toast.LENGTH_SHORT).show()
                showIndustrySelectorDialog = false
            },
            onDismiss = { showIndustrySelectorDialog = false }
        )
    }

    // 3. Live Full Invoice Preview Modal
    if (showLivePreviewModal) {
        LiveInvoicePreviewModal(
            invoiceNumber = invoiceNumber,
            issueDate = issueDate,
            dueDate = dueDate,
            poNumber = poNumber,
            paymentTerms = paymentTerms,
            currencySymbol = currencySymbol,
            currencyCode = currencyCode,
            clientName = clientName,
            clientCompany = clientCompany,
            clientEmail = clientEmail,
            clientPhone = clientPhone,
            clientAddress = clientAddress,
            clientTaxId = clientTaxId,
            customClientFields = customClientFields,
            shippingDetails = shippingDetails,
            activeColumns = itemColumns,
            items = items,
            taxRate = taxRate,
            taxLabel = taxLabel,
            taxType = taxType,
            isTaxInclusive = isTaxInclusive,
            calculations = calculations,
            notes = notes,
            terms = terms,
            paymentInstructions = paymentInstructions,
            notesLabel = notesLabel,
            termsLabel = termsLabel,
            profile = profile,
            templateId = templateId,
            onDismiss = { showLivePreviewModal = false }
        )
    }
}
