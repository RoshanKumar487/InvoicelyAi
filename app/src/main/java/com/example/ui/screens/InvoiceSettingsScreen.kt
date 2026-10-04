package com.example.ui.screens

import android.widget.Toast
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.AccountBalance
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Draw
import androidx.compose.material.icons.filled.FactCheck
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.LocalShipping
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.Notes
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Receipt
import androidx.compose.material.icons.filled.TableChart
import androidx.compose.material.icons.filled.Tune
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
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
import androidx.compose.material3.Scaffold
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.foundation.horizontalScroll
import com.example.data.model.BusinessProfile
import com.example.data.model.IndustryTemplates
import com.example.data.model.InvoiceUtils
import com.example.ui.components.AdaptiveContainer
import com.example.ui.components.IndustryTemplateSelectorDialog
import com.example.ui.components.rememberWindowAdaptiveInfo
import com.example.ui.theme.PrimaryNavy
import com.example.ui.viewmodel.InvoiceViewModel

/**
 * Invoice Settings & Section Controls Screen.
 * Allows users to customize which sections, blocks and fields appear on the Invoice Edit screen.
 * Each section is modeled as a distinct, dedicated card block.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InvoiceSettingsScreen(
    viewModel: InvoiceViewModel,
    onBack: () -> Unit,
    onOpenMenu: () -> Unit = {},
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val profile by viewModel.businessProfile.collectAsStateWithLifecycle()
    val adaptiveInfo = rememberWindowAdaptiveInfo()

    // Business Category & Industry Presets
    var selectedIndustryPresetId by remember(profile.industryPresetId) { mutableStateOf(profile.industryPresetId.ifBlank { "general" }) }
    var showIndustryDialog by remember { mutableStateOf(false) }

    // Local mutable state initialized from business profile
    var showShippingSection by remember(profile.showShippingSection) { mutableStateOf(profile.showShippingSection) }
    var showNotesSection by remember(profile.showNotesSection) { mutableStateOf(profile.showNotesSection) }
    var showPaymentInstructions by remember(profile.showPaymentInstructions) { mutableStateOf(profile.showPaymentInstructions) }
    var showTerms by remember(profile.showTerms) { mutableStateOf(profile.showTerms) }
    var showNotes by remember(profile.showNotes) { mutableStateOf(profile.showNotes) }
    var showSignature by remember(profile.showSignature) { mutableStateOf(profile.showSignature) }
    var showStamp by remember(profile.showStamp) { mutableStateOf(profile.showStamp) }

    // Tax & Totals Settings
    var isTaxApplicable by remember(profile.isTaxApplicable) { mutableStateOf(profile.isTaxApplicable) }
    var defaultTaxRate by remember(profile.defaultTaxRate) { mutableStateOf(profile.defaultTaxRate) }
    var defaultTaxLabel by remember(profile.defaultTaxLabel) { mutableStateOf(profile.defaultTaxLabel) }
    var defaultDiscountType by remember(profile.defaultDiscountType) { mutableStateOf(profile.defaultDiscountType) }
    var defaultDiscountValue by remember(profile.defaultDiscountValue) { mutableStateOf(profile.defaultDiscountValue) }
    var additionalChargeLabel by remember(profile.additionalChargeLabel) { mutableStateOf(profile.additionalChargeLabel) }
    var defaultAdditionalCharge by remember(profile.defaultAdditionalCharge) { mutableStateOf(profile.defaultAdditionalCharge) }

    // Client fields
    var showClientCompany by remember(profile.showClientCompany) { mutableStateOf(profile.showClientCompany) }
    var showClientEmail by remember(profile.showClientEmail) { mutableStateOf(profile.showClientEmail) }
    var showClientPhone by remember(profile.showClientPhone) { mutableStateOf(profile.showClientPhone) }
    var showClientAddress by remember(profile.showClientAddress) { mutableStateOf(profile.showClientAddress) }
    var showClientTaxId by remember(profile.showClientTaxId) { mutableStateOf(profile.showClientTaxId) }

    // Item fields
    var showItemUnit by remember(profile.showItemUnit) { mutableStateOf(profile.showItemUnit) }
    var showItemQty by remember(profile.showItemQty) { mutableStateOf(profile.showItemQty) }
    var showItemRate by remember(profile.showItemRate) { mutableStateOf(profile.showItemRate) }
    var showItemDiscount by remember(profile.showItemDiscount) { mutableStateOf(profile.showItemDiscount) }
    var showItemTax by remember(profile.showItemTax) { mutableStateOf(profile.showItemTax) }

    // Meta fields
    var showPoNumber by remember(profile.showPoNumber) { mutableStateOf(profile.showPoNumber) }
    var showPaymentTerms by remember(profile.showPaymentTerms) { mutableStateOf(profile.showPaymentTerms) }
    var defaultPaymentTerms by remember(profile.defaultPaymentTerms) { mutableStateOf(profile.defaultPaymentTerms) }

    // Banking details
    var bankName by remember(profile.bankName) { mutableStateOf(profile.bankName) }
    var accountNumber by remember(profile.accountNumber) { mutableStateOf(profile.accountNumber) }
    var routingNumber by remember(profile.routingNumber) { mutableStateOf(profile.routingNumber) }
    var upiId by remember(profile.upiId) { mutableStateOf(profile.upiId) }
    var paymentLink by remember(profile.paymentLink) { mutableStateOf(profile.paymentLink) }

    // Terms & Notes text
    var defaultTerms by remember(profile.defaultTerms) { mutableStateOf(profile.defaultTerms) }
    var defaultNotes by remember(profile.defaultNotes) { mutableStateOf(profile.defaultNotes) }

    // Signee
    var signeeName by remember(profile.signeeName) { mutableStateOf(profile.signeeName) }
    var signeeTitle by remember(profile.signeeTitle) { mutableStateOf(profile.signeeTitle) }

    fun saveAll(notify: Boolean = true) {
        val activePreset = IndustryTemplates.getPresetById(selectedIndustryPresetId)
        val updated = profile.copy(
            industryPresetId = selectedIndustryPresetId,
            businessCategory = activePreset.name,
            showShippingSection = showShippingSection,
            showNotesSection = showNotesSection,
            isTaxApplicable = isTaxApplicable,
            defaultTaxRate = defaultTaxRate,
            defaultTaxLabel = defaultTaxLabel,
            defaultDiscountType = defaultDiscountType,
            defaultDiscountValue = defaultDiscountValue,
            additionalChargeLabel = additionalChargeLabel,
            defaultAdditionalCharge = defaultAdditionalCharge,
            showPaymentInstructions = showPaymentInstructions,
            showTerms = showTerms,
            showNotes = showNotes,
            showSignature = showSignature,
            showStamp = showStamp,
            showClientCompany = showClientCompany,
            showClientEmail = showClientEmail,
            showClientPhone = showClientPhone,
            showClientAddress = showClientAddress,
            showClientTaxId = showClientTaxId,
            showItemUnit = showItemUnit,
            showItemQty = showItemQty,
            showItemRate = showItemRate,
            showItemDiscount = showItemDiscount,
            showItemTax = showItemTax,
            showPoNumber = showPoNumber,
            showPaymentTerms = showPaymentTerms,
            defaultPaymentTerms = defaultPaymentTerms,
            bankName = bankName,
            accountNumber = accountNumber,
            routingNumber = routingNumber,
            upiId = upiId,
            paymentLink = paymentLink,
            defaultTerms = defaultTerms,
            defaultNotes = defaultNotes,
            signeeName = signeeName,
            signeeTitle = signeeTitle
        )
        viewModel.saveBusinessProfile(updated)
        if (notify) {
            Toast.makeText(context, "Invoice section controls saved!", Toast.LENGTH_SHORT).show()
        }
    }

    Scaffold(
        modifier = modifier.fillMaxSize(),
        contentWindowInsets = WindowInsets(0, 0, 0, 0),
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(
                            text = "Invoice Settings",
                            fontSize = 17.sp,
                            fontWeight = FontWeight.Bold,
                            color = PrimaryNavy
                        )
                        Text(
                            text = "Section Controls & Field Visibility",
                            fontSize = 11.sp,
                            color = Color(0xFF64748B)
                        )
                    }
                },
                navigationIcon = {
                    IconButton(
                        onClick = onBack,
                        modifier = Modifier.testTag("invoice_settings_back_btn")
                    ) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back",
                            tint = PrimaryNavy
                        )
                    }
                },
                actions = {
                    Button(
                        onClick = { saveAll(notify = true) },
                        colors = ButtonDefaults.buttonColors(containerColor = PrimaryNavy),
                        shape = RoundedCornerShape(8.dp),
                        modifier = Modifier
                            .testTag("invoice_settings_save_btn")
                    ) {
                        Text("Save", fontSize = 12.sp, fontWeight = FontWeight.Bold)
                    }
                    IconButton(
                        onClick = onOpenMenu,
                        modifier = Modifier.testTag("invoice_settings_menu_btn")
                    ) {
                        Icon(imageVector = Icons.Default.Menu, contentDescription = "Menu", tint = PrimaryNavy)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.White)
            )
        }
    ) { innerPadding ->
        AdaptiveContainer(maxWidth = adaptiveInfo.formMaxWidth) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding)
                    .background(Color(0xFFF8FAFC))
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = adaptiveInfo.horizontalPadding, vertical = 16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
            // Intro Information Card
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(14.dp),
                colors = CardDefaults.cardColors(containerColor = Color(0xFFEFF6FF)),
                border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFBFDBFE))
            ) {
                Row(
                    modifier = Modifier.padding(14.dp),
                    verticalAlignment = Alignment.Top,
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Tune,
                        contentDescription = null,
                        tint = Color(0xFF2563EB),
                        modifier = Modifier.size(24.dp)
                    )
                    Column {
                        Text(
                            text = "Customized Invoicing Workflow",
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Bold,
                            color = PrimaryNavy
                        )
                        Spacer(modifier = Modifier.height(3.dp))
                        Text(
                            text = "Choose which sections appear when creating or editing an invoice. Sections turned OFF will be hidden completely on the invoice edit screen, keeping your workflow lean and uncluttered.",
                            fontSize = 12.sp,
                            color = Color(0xFF334155),
                            lineHeight = 17.sp
                        )
                    }
                }
            }

            // =================================================================
            // BLOCK 0: BUSINESS CATEGORY & INDUSTRY WORKFLOW (Configured here only)
            // =================================================================
            val activePreset = remember(selectedIndustryPresetId) {
                IndustryTemplates.getPresetById(selectedIndustryPresetId)
            }

            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White),
                border = androidx.compose.foundation.BorderStroke(1.5.dp, Color(0xFFBFDBFE))
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                            Box(
                                modifier = Modifier
                                    .size(42.dp)
                                    .clip(RoundedCornerShape(10.dp))
                                    .background(Color(0xFFEFF6FF)),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(activePreset.icon, contentDescription = null, tint = Color(0xFF2563EB), modifier = Modifier.size(24.dp))
                            }
                            Column {
                                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                    Text(activePreset.name, fontSize = 16.sp, fontWeight = FontWeight.Bold, color = PrimaryNavy)
                                    Surface(
                                        color = Color(0xFFDBEAFE),
                                        shape = RoundedCornerShape(6.dp)
                                    ) {
                                        Text(
                                            text = activePreset.industryCategory,
                                            fontSize = 10.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = Color(0xFF1D4ED8),
                                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                        )
                                    }
                                }
                                Text(
                                    text = "Primary Business Category (Inlined across all invoices)",
                                    fontSize = 11.sp,
                                    color = Color(0xFF64748B)
                                )
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(10.dp))
                    Text(
                        text = activePreset.description,
                        fontSize = 12.sp,
                        color = Color(0xFF334155),
                        lineHeight = 16.sp
                    )

                    Spacer(modifier = Modifier.height(12.dp))

                    Text("Quick Select Business Category:", fontSize = 11.sp, fontWeight = FontWeight.SemiBold, color = Color(0xFF64748B))
                    Spacer(modifier = Modifier.height(6.dp))

                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .horizontalScroll(rememberScrollState()),
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        IndustryTemplates.allPresets.forEach { preset ->
                            val isSel = selectedIndustryPresetId == preset.id
                            Surface(
                                color = if (isSel) Color(0xFF2563EB) else Color(0xFFF1F5F9),
                                shape = RoundedCornerShape(12.dp),
                                border = androidx.compose.foundation.BorderStroke(
                                    1.dp,
                                    if (isSel) Color(0xFF1D4ED8) else Color(0xFFCBD5E1)
                                ),
                                modifier = Modifier.clickable {
                                    selectedIndustryPresetId = preset.id
                                    val serializedCols = InvoiceUtils.serializeColumns(preset.defaultColumns)
                                    val updated = profile.copy(
                                        industryPresetId = preset.id,
                                        businessCategory = preset.name,
                                        customColumnsJson = serializedCols,
                                        defaultTemplateId = preset.recommendedTemplateId,
                                        defaultTerms = preset.defaultTerms.ifBlank { defaultTerms },
                                        defaultNotes = preset.defaultNotes.ifBlank { defaultNotes }
                                    )
                                    if (preset.defaultTerms.isNotBlank()) defaultTerms = preset.defaultTerms
                                    if (preset.defaultNotes.isNotBlank()) defaultNotes = preset.defaultNotes
                                    viewModel.saveBusinessProfile(updated)
                                    Toast.makeText(context, "Switched business category to ${preset.name}", Toast.LENGTH_SHORT).show()
                                }
                            ) {
                                Row(
                                    modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                                ) {
                                    Icon(preset.icon, contentDescription = null, tint = if (isSel) Color.White else PrimaryNavy, modifier = Modifier.size(14.dp))
                                    Text(
                                        text = preset.name,
                                        fontSize = 11.sp,
                                        fontWeight = if (isSel) FontWeight.Bold else FontWeight.Medium,
                                        color = if (isSel) Color.White else PrimaryNavy
                                    )
                                }
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(10.dp))

                    OutlinedButton(
                        onClick = { showIndustryDialog = true },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(10.dp),
                        border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFF93C5FD))
                    ) {
                        Icon(Icons.Default.Tune, contentDescription = null, modifier = Modifier.size(16.dp), tint = Color(0xFF2563EB))
                        Spacer(modifier = Modifier.width(6.dp))
                        Text("Browse All 12 Business Categories & Details", fontSize = 12.sp, color = Color(0xFF2563EB), fontWeight = FontWeight.Bold)
                    }
                }
            }

            // =================================================================
            // 4-SECTION DEFAULT WORKFLOW INFO
            // =================================================================
            Surface(
                color = Color(0xFFEFF6FF),
                shape = RoundedCornerShape(12.dp),
                border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFBFDBFE)),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(14.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.FactCheck, contentDescription = null, tint = Color(0xFF1D4ED8), modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "4 Core Sections Displayed by Default",
                            fontWeight = FontWeight.Bold,
                            fontSize = 13.sp,
                            color = Color(0xFF1E3A8A)
                        )
                    }
                    Spacer(modifier = Modifier.height(6.dp))
                    Text(
                        text = "1. Invoice Details (Number, Status, Issue & Due Dates)\n" +
                            "2. Client Information (Name, Company, Address, Tax ID)\n" +
                            "3. Items & Services (Descriptions, Quantities, Rates, Totals)\n" +
                            "4. Totals & Summary (Subtotal, Discount, Tax, Grand Total)\n\n" +
                            "Optional sections (Delivery Details, Notes & Signatures) only appear on the edit screen when toggled ON below or added manually.",
                        fontSize = 11.5.sp,
                        color = Color(0xFF1E293B),
                        lineHeight = 17.sp
                    )
                }
            }

            // =================================================================
            // BLOCK 1: SHIPPING & LOGISTICS SECTION (OPTIONAL)
            // =================================================================
            SectionControlBlock(
                title = "Shipping & Delivery Details Section",
                description = "Enable delivery addresses, carrier/courier, tracking numbers, and dispatch details on the invoice edit page.",
                icon = Icons.Default.LocalShipping,
                iconColor = Color(0xFF0284C7),
                iconBg = Color(0xFFE0F2FE),
                isEnabled = showShippingSection,
                onToggle = {
                    showShippingSection = it
                    saveAll(notify = false)
                },
                badgeText = if (showShippingSection) "Visible on Edit Page" else "Hidden by Default",
                badgeActive = showShippingSection,
                testTag = "toggle_shipping_section"
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Surface(
                        color = Color(0xFFF1F5F9),
                        shape = RoundedCornerShape(8.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Row(
                            modifier = Modifier.padding(10.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(Icons.Default.Info, contentDescription = null, tint = Color(0xFF0284C7), modifier = Modifier.size(16.dp))
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = if (showShippingSection) "Enabled: Delivery Details accordion will appear in the invoice editor." else "Disabled: Delivery Details section is hidden from the edit page.",
                                fontSize = 11.sp,
                                color = Color(0xFF475569)
                            )
                        }
                    }
                }
            }

            // =================================================================
            // BLOCK 2: NOTES, TERMS & SIGNATURES SECTION (OPTIONAL)
            // =================================================================
            SectionControlBlock(
                title = "Notes, Terms & Signatures Section",
                description = "Include customer remarks, terms & conditions, bank account wire instructions, and signature block on invoice edit page.",
                icon = Icons.Default.FactCheck,
                iconColor = Color(0xFF7C3AED),
                iconBg = Color(0xFFEDE9FE),
                isEnabled = showNotesSection,
                onToggle = {
                    showNotesSection = it
                    saveAll(notify = false)
                },
                badgeText = if (showNotesSection) "Visible on Edit Page" else "Hidden by Default",
                badgeActive = showNotesSection,
                testTag = "toggle_notes_section"
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    OutlinedTextField(
                        value = defaultTerms,
                        onValueChange = { defaultTerms = it; saveAll(notify = false) },
                        label = { Text("Default Terms & Conditions Text") },
                        maxLines = 3,
                        modifier = Modifier.fillMaxWidth()
                    )

                    OutlinedTextField(
                        value = defaultNotes,
                        onValueChange = { defaultNotes = it; saveAll(notify = false) },
                        label = { Text("Default Notes & Remarks") },
                        maxLines = 3,
                        modifier = Modifier.fillMaxWidth()
                    )

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        OutlinedTextField(
                            value = bankName,
                            onValueChange = { bankName = it; saveAll(notify = false) },
                            label = { Text("Bank Name") },
                            singleLine = true,
                            modifier = Modifier.weight(1f)
                        )
                        OutlinedTextField(
                            value = accountNumber,
                            onValueChange = { accountNumber = it; saveAll(notify = false) },
                            label = { Text("Account #") },
                            singleLine = true,
                            modifier = Modifier.weight(1f)
                        )
                    }

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        OutlinedTextField(
                            value = signeeName,
                            onValueChange = { signeeName = it; saveAll(notify = false) },
                            label = { Text("Signee Name") },
                            singleLine = true,
                            modifier = Modifier.weight(1f)
                        )
                        OutlinedTextField(
                            value = signeeTitle,
                            onValueChange = { signeeTitle = it; saveAll(notify = false) },
                            label = { Text("Signee Title") },
                            singleLine = true,
                            modifier = Modifier.weight(1f)
                        )
                    }
                }
            }

            // =================================================================
            // BLOCK 3: TOTALS, TAXES & DISCOUNT CONFIGURATION
            // =================================================================
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(14.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White),
                border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFE2E8F0))
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        Box(
                            modifier = Modifier
                                .size(38.dp)
                                .clip(RoundedCornerShape(8.dp))
                                .background(Color(0xFFFEF3C7)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(Icons.Default.Receipt, contentDescription = null, tint = Color(0xFFD97706), modifier = Modifier.size(20.dp))
                        }
                        Column {
                            Text("Totals, Taxes & Discount Defaults", fontSize = 15.sp, fontWeight = FontWeight.Bold, color = PrimaryNavy)
                            Text("Configure tax applicability, default discounts & charges", fontSize = 11.sp, color = Color.Gray)
                        }
                    }

                    Spacer(modifier = Modifier.height(14.dp))
                    HorizontalDivider(color = Color(0xFFF1F5F9))
                    Spacer(modifier = Modifier.height(10.dp))

                    // Tax Applicable Toggle
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text("Tax Applicable", fontSize = 13.sp, fontWeight = FontWeight.SemiBold, color = PrimaryNavy)
                            Text(
                                "Disable if your invoices are tax-exempt, zero-rated, or you do not charge taxes. When disabled, tax is completely hidden from the totals section on the edit page.",
                                fontSize = 11.sp,
                                color = Color.Gray,
                                lineHeight = 15.sp
                            )
                        }
                        Spacer(modifier = Modifier.width(12.dp))
                        Switch(
                            checked = isTaxApplicable,
                            onCheckedChange = {
                                isTaxApplicable = it
                                saveAll(notify = false)
                            },
                            colors = SwitchDefaults.colors(checkedThumbColor = Color.White, checkedTrackColor = Color(0xFF2563EB))
                        )
                    }

                    if (isTaxApplicable) {
                        Spacer(modifier = Modifier.height(10.dp))
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(10.dp)
                        ) {
                            OutlinedTextField(
                                value = defaultTaxLabel,
                                onValueChange = { defaultTaxLabel = it; saveAll(notify = false) },
                                label = { Text("Tax Label (e.g. GST, VAT, Sales Tax)") },
                                singleLine = true,
                                modifier = Modifier.weight(1.2f)
                            )
                            OutlinedTextField(
                                value = if (defaultTaxRate > 0) defaultTaxRate.toString() else "",
                                onValueChange = {
                                    defaultTaxRate = it.toDoubleOrNull() ?: 0.0
                                    saveAll(notify = false)
                                },
                                label = { Text("Default Tax Rate (%)") },
                                keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(keyboardType = androidx.compose.ui.text.input.KeyboardType.Decimal),
                                singleLine = true,
                                modifier = Modifier.weight(0.8f)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(14.dp))
                    HorizontalDivider(color = Color(0xFFF1F5F9))
                    Spacer(modifier = Modifier.height(10.dp))

                    // Default Discount Mode & Value
                    Text("Default Discount Settings:", fontSize = 12.sp, fontWeight = FontWeight.SemiBold, color = Color(0xFF475569))
                    Spacer(modifier = Modifier.height(6.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(
                            modifier = Modifier.weight(1.1f),
                            horizontalArrangement = Arrangement.spacedBy(6.dp)
                        ) {
                            val isPercent = defaultDiscountType == "percentage"
                            Surface(
                                color = if (isPercent) Color(0xFF2563EB) else Color(0xFFF1F5F9),
                                shape = RoundedCornerShape(8.dp),
                                modifier = Modifier
                                    .weight(1f)
                                    .clickable {
                                        defaultDiscountType = "percentage"
                                        saveAll(notify = false)
                                    }
                            ) {
                                Box(modifier = Modifier.padding(vertical = 10.dp), contentAlignment = Alignment.Center) {
                                    Text("% Percentage", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = if (isPercent) Color.White else PrimaryNavy)
                                }
                            }
                            Surface(
                                color = if (!isPercent) Color(0xFF2563EB) else Color(0xFFF1F5F9),
                                shape = RoundedCornerShape(8.dp),
                                modifier = Modifier
                                    .weight(1f)
                                    .clickable {
                                        defaultDiscountType = "flat"
                                        saveAll(notify = false)
                                    }
                            ) {
                                Box(modifier = Modifier.padding(vertical = 10.dp), contentAlignment = Alignment.Center) {
                                    Text("$ Flat Amount", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = if (!isPercent) Color.White else PrimaryNavy)
                                }
                            }
                        }

                        OutlinedTextField(
                            value = if (defaultDiscountValue > 0) defaultDiscountValue.toString() else "",
                            onValueChange = {
                                defaultDiscountValue = it.toDoubleOrNull() ?: 0.0
                                saveAll(notify = false)
                            },
                            label = { Text("Default Value") },
                            keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(keyboardType = androidx.compose.ui.text.input.KeyboardType.Decimal),
                            singleLine = true,
                            modifier = Modifier.weight(0.9f)
                        )
                    }

                    Spacer(modifier = Modifier.height(14.dp))
                    HorizontalDivider(color = Color(0xFFF1F5F9))
                    Spacer(modifier = Modifier.height(10.dp))

                    // Additional Charges / Custom Field
                    Text("Additional Charge / Surcharge Field Name:", fontSize = 12.sp, fontWeight = FontWeight.SemiBold, color = Color(0xFF475569))
                    Spacer(modifier = Modifier.height(6.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        OutlinedTextField(
                            value = additionalChargeLabel,
                            onValueChange = { additionalChargeLabel = it; saveAll(notify = false) },
                            label = { Text("Field Label (e.g. Shipping Fee, Service Charge)") },
                            singleLine = true,
                            modifier = Modifier.weight(1.3f)
                        )
                        OutlinedTextField(
                            value = if (defaultAdditionalCharge > 0) defaultAdditionalCharge.toString() else "",
                            onValueChange = {
                                defaultAdditionalCharge = it.toDoubleOrNull() ?: 0.0
                                saveAll(notify = false)
                            },
                            label = { Text("Default ($)") },
                            keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(keyboardType = androidx.compose.ui.text.input.KeyboardType.Decimal),
                            singleLine = true,
                            modifier = Modifier.weight(0.7f)
                        )
                    }
                }
            }

            // =================================================================
            // BLOCK 6: ITEMIZATION & TABLE SECTION CONTROLS
            // =================================================================
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(14.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White),
                border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFE2E8F0))
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                            Box(
                                modifier = Modifier
                                    .size(38.dp)
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(Color(0xFFEDE9FE)),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(Icons.Default.TableChart, contentDescription = null, tint = Color(0xFF7C3AED), modifier = Modifier.size(20.dp))
                            }
                            Column {
                                Text("Item Table Column Defaults", fontSize = 15.sp, fontWeight = FontWeight.Bold, color = PrimaryNavy)
                                Text("Toggle columns visible when adding invoice items", fontSize = 11.sp, color = Color.Gray)
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(14.dp))
                    HorizontalDivider(color = Color(0xFFF1F5F9))
                    Spacer(modifier = Modifier.height(10.dp))

                    FieldToggleRow(
                        label = "Unit of Measurement",
                        description = "Enable pcs, hrs, days, units column",
                        checked = showItemUnit,
                        onCheckedChange = { showItemUnit = it; saveAll(notify = false) }
                    )
                    FieldToggleRow(
                        label = "Quantity Column",
                        description = "Enable quantity number counter",
                        checked = showItemQty,
                        onCheckedChange = { showItemQty = it; saveAll(notify = false) }
                    )
                    FieldToggleRow(
                        label = "Unit Price / Rate Column",
                        description = "Enable per-unit base price",
                        checked = showItemRate,
                        onCheckedChange = { showItemRate = it; saveAll(notify = false) }
                    )
                    FieldToggleRow(
                        label = "Line Item Discount",
                        description = "Enable item-level discount percentage",
                        checked = showItemDiscount,
                        onCheckedChange = { showItemDiscount = it; saveAll(notify = false) }
                    )
                    FieldToggleRow(
                        label = "Line Item Tax Rate",
                        description = "Enable item-level GST / VAT calculation",
                        checked = showItemTax,
                        onCheckedChange = { showItemTax = it; saveAll(notify = false) }
                    )
                }
            }

            // =================================================================
            // BLOCK 7: CLIENT & BILLING FIELDS
            // =================================================================
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(14.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White),
                border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFE2E8F0))
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                            Box(
                                modifier = Modifier
                                    .size(38.dp)
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(Color(0xFFDBEAFE)),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(Icons.Default.Person, contentDescription = null, tint = Color(0xFF2563EB), modifier = Modifier.size(20.dp))
                            }
                            Column {
                                Text("Client Details Fields", fontSize = 15.sp, fontWeight = FontWeight.Bold, color = PrimaryNavy)
                                Text("Control which client inputs show in Section 1", fontSize = 11.sp, color = Color.Gray)
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(14.dp))
                    HorizontalDivider(color = Color(0xFFF1F5F9))
                    Spacer(modifier = Modifier.height(10.dp))

                    FieldToggleRow(
                        label = "Company Name",
                        description = "Client business / corporate name",
                        checked = showClientCompany,
                        onCheckedChange = { showClientCompany = it; saveAll(notify = false) }
                    )
                    FieldToggleRow(
                        label = "Client Email Address",
                        description = "For automated reminders & PDF receipts",
                        checked = showClientEmail,
                        onCheckedChange = { showClientEmail = it; saveAll(notify = false) }
                    )
                    FieldToggleRow(
                        label = "Client Phone Number",
                        description = "WhatsApp & SMS notifications",
                        checked = showClientPhone,
                        onCheckedChange = { showClientPhone = it; saveAll(notify = false) }
                    )
                    FieldToggleRow(
                        label = "Client Billing Address",
                        description = "Street, City, Postal code",
                        checked = showClientAddress,
                        onCheckedChange = { showClientAddress = it; saveAll(notify = false) }
                    )
                    FieldToggleRow(
                        label = "Client Tax ID / GSTIN",
                        description = "For tax invoices and GST compliance",
                        checked = showClientTaxId,
                        onCheckedChange = { showClientTaxId = it; saveAll(notify = false) }
                    )
                }
            }

            // =================================================================
            // BLOCK 8: INVOICE META & GENERAL CONTROLS
            // =================================================================
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(14.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White),
                border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFE2E8F0))
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        Box(
                            modifier = Modifier
                                .size(38.dp)
                                .clip(RoundedCornerShape(8.dp))
                                .background(Color(0xFFFEF3C7)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(Icons.Default.Receipt, contentDescription = null, tint = Color(0xFFD97706), modifier = Modifier.size(20.dp))
                        }
                        Column {
                            Text("Invoice Meta & Terms Defaults", fontSize = 15.sp, fontWeight = FontWeight.Bold, color = PrimaryNavy)
                            Text("Top metadata header options on the edit screen", fontSize = 11.sp, color = Color.Gray)
                        }
                    }

                    Spacer(modifier = Modifier.height(14.dp))
                    HorizontalDivider(color = Color(0xFFF1F5F9))
                    Spacer(modifier = Modifier.height(10.dp))

                    FieldToggleRow(
                        label = "Purchase Order (PO #)",
                        description = "Allow entering client PO reference numbers",
                        checked = showPoNumber,
                        onCheckedChange = { showPoNumber = it; saveAll(notify = false) }
                    )

                    FieldToggleRow(
                        label = "Payment Terms Selector",
                        description = "Quick Net 15, Net 30, Due on Receipt options",
                        checked = showPaymentTerms,
                        onCheckedChange = { showPaymentTerms = it; saveAll(notify = false) }
                    )

                    Spacer(modifier = Modifier.height(6.dp))

                    OutlinedTextField(
                        value = defaultPaymentTerms,
                        onValueChange = { defaultPaymentTerms = it; saveAll(notify = false) },
                        label = { Text("Default Payment Terms") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // Save Button at bottom
            Button(
                onClick = { saveAll(notify = true); onBack() },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp)
                    .testTag("invoice_settings_bottom_save_btn"),
                colors = ButtonDefaults.buttonColors(containerColor = PrimaryNavy),
                shape = RoundedCornerShape(10.dp)
            ) {
                Icon(Icons.Default.CheckCircle, contentDescription = null, modifier = Modifier.size(18.dp))
                Spacer(modifier = Modifier.width(8.dp))
                Text("Save Settings & Apply to Invoices", fontSize = 15.sp, fontWeight = FontWeight.Bold)
            }

            Spacer(modifier = Modifier.height(40.dp))
        }
    }
}

    // Business Category & Industry Template Selector Dialog (Settings page only)
    if (showIndustryDialog) {
        IndustryTemplateSelectorDialog(
            selectedPresetId = selectedIndustryPresetId,
            onSelectPreset = { preset ->
                selectedIndustryPresetId = preset.id
                if (preset.defaultTerms.isNotBlank()) defaultTerms = preset.defaultTerms
                if (preset.defaultNotes.isNotBlank()) defaultNotes = preset.defaultNotes
                val serializedCols = InvoiceUtils.serializeColumns(preset.defaultColumns)
                val updated = profile.copy(
                    industryPresetId = preset.id,
                    businessCategory = preset.name,
                    customColumnsJson = serializedCols,
                    defaultTemplateId = preset.recommendedTemplateId,
                    defaultTerms = defaultTerms,
                    defaultNotes = defaultNotes
                )
                viewModel.saveBusinessProfile(updated)
                showIndustryDialog = false
                Toast.makeText(context, "Applied ${preset.name} category to invoices!", Toast.LENGTH_SHORT).show()
            },
            onDismiss = { showIndustryDialog = false }
        )
    }
}

/**
 * Reusable Card Block for a top-level section toggle & controls.
 */
@Composable
fun SectionControlBlock(
    title: String,
    description: String,
    icon: ImageVector,
    iconColor: Color,
    iconBg: Color,
    isEnabled: Boolean,
    onToggle: (Boolean) -> Unit,
    badgeText: String,
    badgeActive: Boolean,
    testTag: String,
    content: @Composable () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(14.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        border = androidx.compose.foundation.BorderStroke(
            1.dp,
            if (isEnabled) Color(0xFFCBD5E1) else Color(0xFFE2E8F0)
        )
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            // Header Row with Switch
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                    modifier = Modifier.weight(1f)
                ) {
                    Box(
                        modifier = Modifier
                            .size(38.dp)
                            .clip(RoundedCornerShape(8.dp))
                            .background(iconBg),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(icon, contentDescription = null, tint = iconColor, modifier = Modifier.size(20.dp))
                    }
                    Column {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                            Text(
                                text = title,
                                fontSize = 15.sp,
                                fontWeight = FontWeight.Bold,
                                color = PrimaryNavy
                            )
                        }
                        Text(
                            text = description,
                            fontSize = 11.sp,
                            color = Color.Gray,
                            lineHeight = 15.sp
                        )
                    }
                }

                Spacer(modifier = Modifier.width(8.dp))

                Switch(
                    checked = isEnabled,
                    onCheckedChange = onToggle,
                    colors = SwitchDefaults.colors(
                        checkedThumbColor = Color.White,
                        checkedTrackColor = Color(0xFF2563EB)
                    ),
                    modifier = Modifier.testTag(testTag)
                )
            }

            Spacer(modifier = Modifier.height(10.dp))

            // Status Badge
            Surface(
                color = if (badgeActive) Color(0xFFEFF6FF) else Color(0xFFF1F5F9),
                shape = RoundedCornerShape(6.dp),
                border = androidx.compose.foundation.BorderStroke(
                    0.5.dp,
                    if (badgeActive) Color(0xFF93C5FD) else Color(0xFFCBD5E1)
                )
            ) {
                Text(
                    text = badgeText,
                    fontSize = 10.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = if (badgeActive) Color(0xFF1D4ED8) else Color(0xFF64748B),
                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
                )
            }

            // Expandable configuration controls
            AnimatedVisibility(visible = isEnabled) {
                Column {
                    Spacer(modifier = Modifier.height(12.dp))
                    HorizontalDivider(color = Color(0xFFF1F5F9))
                    Spacer(modifier = Modifier.height(12.dp))
                    content()
                }
            }
        }
    }
}

@Composable
private fun FieldToggleRow(
    label: String,
    description: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 6.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(text = label, fontSize = 13.sp, fontWeight = FontWeight.Medium, color = PrimaryNavy)
            Text(text = description, fontSize = 11.sp, color = Color.Gray)
        }
        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange,
            colors = SwitchDefaults.colors(
                checkedThumbColor = Color.White,
                checkedTrackColor = Color(0xFF2563EB)
            )
        )
    }
}
