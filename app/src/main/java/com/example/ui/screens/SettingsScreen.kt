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
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.AccountBalance
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Business
import androidx.compose.material.icons.filled.Calculate
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.CurrencyExchange
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.ExpandLess
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material.icons.filled.Fullscreen
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.Palette
import androidx.compose.material.icons.filled.QrCode
import androidx.compose.material.icons.filled.Receipt
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Storage
import androidx.compose.material.icons.filled.TableChart
import androidx.compose.material.icons.filled.Tune
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import kotlinx.coroutines.launch
import com.example.data.api.ApiConfig
import com.example.data.api.InvoicelyApiManager
import com.example.data.repository.AuthSessionManager
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
import com.example.data.model.BusinessProfile
import com.example.data.model.IndustryTemplates
import com.example.data.model.InvoiceUtils
import com.example.docx.DocxTemplatePreset
import com.example.ui.components.AdaptiveContainer
import com.example.ui.components.rememberWindowAdaptiveInfo
import com.example.ui.components.BusinessCustomIcon
import com.example.ui.components.IndustryTemplateSelectorDialog
import com.example.ui.components.ItemizationBuilderDialog
import com.example.ui.theme.PrimaryNavy
import com.example.ui.theme.StatusPaidGreen
import com.example.ui.viewmodel.InvoiceViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    viewModel: InvoiceViewModel,
    onBack: () -> Unit,
    onCreateInvoice: () -> Unit = {},
    onViewFullPageInvoice: (Long) -> Unit = {},
    onViewTaxCalculator: () -> Unit = {},
    onViewClients: () -> Unit = {},
    onViewTemplates: () -> Unit = {},
    onViewExpenses: () -> Unit = {},
    onViewAiChat: () -> Unit = {},
    onOpenMenu: () -> Unit = {},
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val currentProfile by viewModel.businessProfile.collectAsStateWithLifecycle()
    val allInvoices by viewModel.allInvoices.collectAsStateWithLifecycle()
    val allClients by viewModel.allClients.collectAsStateWithLifecycle()
    val activeTemplate by viewModel.activeTemplateConfig.collectAsStateWithLifecycle()
    val adaptiveInfo = rememberWindowAdaptiveInfo()

    // State holders for all settings
    var profileState by remember(currentProfile) { mutableStateOf(currentProfile) }

    // Card Expand/Collapse States for Zoho-style card navigation
    var expandedCard by remember { mutableStateOf<String?>("columns") }

    val isBackendOnline by viewModel.isBackendOnline.collectAsStateWithLifecycle()
    val isSyncing by viewModel.isSyncing.collectAsStateWithLifecycle()
    val lastSyncTime by viewModel.lastSyncTime.collectAsStateWithLifecycle()
    val syncErrorMessage by viewModel.syncErrorMessage.collectAsStateWithLifecycle()
    val coroutineScope = rememberCoroutineScope()
    var serverUrlInput by remember { mutableStateOf(ApiConfig.baseUrl.value) }

    var showResetDialog by remember { mutableStateOf(false) }
    var showClearInvoicesDialog by remember { mutableStateOf(false) }
    var showSettingsItemBuilder by remember { mutableStateOf(false) }
    var showSettingsIndustrySelector by remember { mutableStateOf(false) }

    val presetColors = listOf(
        "#1E3A8A" to "Navy",
        "#0284C7" to "Sky Blue",
        "#0F766E" to "Teal",
        "#2563EB" to "Sapphire",
        "#4F46E5" to "Indigo",
        "#059669" to "Emerald",
        "#DC2626" to "Crimson",
        "#0F172A" to "Slate",
        "#78350F" to "Amber",
        "#D97706" to "Gold"
    )

    val iconSymbols = listOf(
        "receipt" to "Receipt",
        "business" to "Corporate",
        "store" to "Storefront",
        "star" to "Star",
        "diamond" to "Diamond",
        "verified" to "Verified",
        "trending" to "Growth",
        "account_balance" to "Finance"
    )

    val currencies = listOf(
        Pair("INR", "₹"),
        Pair("USD", "$"),
        Pair("EUR", "€"),
        Pair("GBP", "£"),
        Pair("AED", "AED"),
        Pair("CAD", "C$"),
        Pair("AUD", "A$"),
        Pair("JPY", "¥"),
        Pair("SGD", "S$"),
        Pair("SAR", "SAR")
    )

    fun saveChanges() {
        val currentUser = com.example.data.repository.AuthSessionManager.currentUser.value
        if (currentUser?.role == com.example.data.model.UserRole.EMPLOYEE) {
            Toast.makeText(context, "Permission Denied: Organization settings can only be modified by an Admin.", Toast.LENGTH_LONG).show()
            return
        }
        viewModel.saveBusinessProfile(profileState)
        Toast.makeText(context, "Settings & Preferences saved successfully", Toast.LENGTH_SHORT).show()
    }

    val currentUser by com.example.data.repository.AuthSessionManager.currentUser.collectAsStateWithLifecycle()
    val userRole = currentUser?.role ?: com.example.data.model.UserRole.ADMIN

    Scaffold(
        modifier = modifier.fillMaxSize(),
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                            Text("Invoice Settings", fontWeight = FontWeight.Bold)
                            Surface(shape = RoundedCornerShape(8.dp), color = userRole.badgeBgColor) {
                                Text(
                                    text = if (userRole == com.example.data.model.UserRole.EMPLOYEE) "🔒 EMPLOYEE (READ-ONLY)" else userRole.shortBadge,
                                    color = userRole.badgeFgColor,
                                    fontSize = 10.sp,
                                    fontWeight = FontWeight.ExtraBold,
                                    modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                )
                            }
                        }
                        Text(
                            text = if (userRole == com.example.data.model.UserRole.EMPLOYEE) "Admin credentials required to edit organization data" else "Card-based access to features, tools & custom preferences",
                            fontSize = 11.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(imageVector = Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    IconButton(onClick = { saveChanges() }, modifier = Modifier.testTag("save_all_settings_btn")) {
                        Icon(imageVector = Icons.Default.Check, contentDescription = "Save", tint = PrimaryNavy)
                    }
                    IconButton(onClick = onOpenMenu, modifier = Modifier.testTag("settings_menu_btn")) {
                        Icon(imageVector = Icons.Default.Menu, contentDescription = "Menu", tint = PrimaryNavy)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = MaterialTheme.colorScheme.surface)
            )
        }
    ) { padding ->
        AdaptiveContainer(maxWidth = adaptiveInfo.formMaxWidth) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = adaptiveInfo.horizontalPadding, vertical = 14.dp),
                verticalArrangement = Arrangement.spacedBy(14.dp)
            ) {

            if (userRole == com.example.data.model.UserRole.EMPLOYEE) {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(containerColor = Color(0xFFFEF3C7)),
                    shape = RoundedCornerShape(14.dp),
                    border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFFDE68A))
                ) {
                    Row(
                        modifier = Modifier.padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        Icon(Icons.Default.Lock, contentDescription = null, tint = Color(0xFFD97706), modifier = Modifier.size(20.dp))
                        Text(
                            text = "Staff Notice: Organization profile, banking credentials, and tax settings can only be altered by an Organization Admin.",
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Medium,
                            color = Color(0xFF92400E)
                        )
                    }
                }
            }

            // =========================================================================
            // CARD-BASED ACCESS TO ALL FEATURES AND TOOLS (USER REQUEST)
            // =========================================================================
            Text(
                text = "Invoice Tools & Features Hub",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = PrimaryNavy
            )

            // Primary Tools Grid (Card-based Access)
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                // Tool Card 1: New Invoice Generator
                Card(
                    modifier = Modifier
                        .weight(1f)
                        .clickable { onCreateInvoice() }
                        .testTag("tool_card_create_invoice"),
                    colors = CardDefaults.cardColors(containerColor = PrimaryNavy),
                    shape = RoundedCornerShape(14.dp),
                    elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
                ) {
                    Column(modifier = Modifier.padding(14.dp)) {
                        Box(
                            modifier = Modifier
                                .size(34.dp)
                                .clip(RoundedCornerShape(8.dp))
                                .background(Color.White.copy(alpha = 0.2f)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(Icons.Default.Add, contentDescription = null, tint = Color.White, modifier = Modifier.size(20.dp))
                        }
                        Spacer(modifier = Modifier.height(10.dp))
                        Text("New Invoice", fontWeight = FontWeight.Bold, color = Color.White, fontSize = 14.sp)
                        Text("Client, date & line items", fontSize = 10.sp, color = Color.White.copy(alpha = 0.8f))
                    }
                }

                // Tool Card 2: Full Page Mobile Document Viewer
                Card(
                    modifier = Modifier
                        .weight(1f)
                        .clickable {
                            val targetId = allInvoices.firstOrNull()?.id ?: 0L
                            onViewFullPageInvoice(targetId)
                        }
                        .testTag("tool_card_full_page_viewer"),
                    colors = CardDefaults.cardColors(containerColor = Color(0xFF0F766E)),
                    shape = RoundedCornerShape(14.dp),
                    elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
                ) {
                    Column(modifier = Modifier.padding(14.dp)) {
                        Box(
                            modifier = Modifier
                                .size(34.dp)
                                .clip(RoundedCornerShape(8.dp))
                                .background(Color.White.copy(alpha = 0.2f)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(Icons.Default.Fullscreen, contentDescription = null, tint = Color.White, modifier = Modifier.size(20.dp))
                        }
                        Spacer(modifier = Modifier.height(10.dp))
                        Text("Full Page View", fontWeight = FontWeight.Bold, color = Color.White, fontSize = 14.sp)
                        Text("A4 mobile reader & DOCX", fontSize = 10.sp, color = Color.White.copy(alpha = 0.8f))
                    }
                }
            }

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                // Tool Card 3: 10 Templates Studio
                Card(
                    modifier = Modifier
                        .weight(1f)
                        .clickable { onViewTemplates() }
                        .testTag("tool_card_templates_studio"),
                    colors = CardDefaults.cardColors(containerColor = Color(0xFF4F46E5)),
                    shape = RoundedCornerShape(14.dp),
                    elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
                ) {
                    Column(modifier = Modifier.padding(14.dp)) {
                        Box(
                            modifier = Modifier
                                .size(34.dp)
                                .clip(RoundedCornerShape(8.dp))
                                .background(Color.White.copy(alpha = 0.2f)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(Icons.Default.Description, contentDescription = null, tint = Color.White, modifier = Modifier.size(18.dp))
                        }
                        Spacer(modifier = Modifier.height(8.dp))
                        Text("10 Templates", fontWeight = FontWeight.Bold, color = Color.White, fontSize = 13.sp)
                        Text("Indian Biz, GST, Zoho", fontSize = 10.sp, color = Color.White.copy(alpha = 0.8f))
                    }
                }

                // Tool Card 4: Tax & GST Calculator
                Card(
                    modifier = Modifier
                        .weight(1f)
                        .clickable { onViewTaxCalculator() }
                        .testTag("tool_card_tax_calculator"),
                    colors = CardDefaults.cardColors(containerColor = Color(0xFF0369A1)),
                    shape = RoundedCornerShape(14.dp),
                    elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
                ) {
                    Column(modifier = Modifier.padding(14.dp)) {
                        Box(
                            modifier = Modifier
                                .size(34.dp)
                                .clip(RoundedCornerShape(8.dp))
                                .background(Color.White.copy(alpha = 0.2f)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(Icons.Default.Calculate, contentDescription = null, tint = Color.White, modifier = Modifier.size(18.dp))
                        }
                        Spacer(modifier = Modifier.height(8.dp))
                        Text("Tax Calculator", fontWeight = FontWeight.Bold, color = Color.White, fontSize = 13.sp)
                        Text("GST & Multi-currency", fontSize = 10.sp, color = Color.White.copy(alpha = 0.8f))
                    }
                }

                // Tool Card 5: Clients Directory
                Card(
                    modifier = Modifier
                        .weight(1f)
                        .clickable { onViewClients() }
                        .testTag("tool_card_clients"),
                    colors = CardDefaults.cardColors(containerColor = Color(0xFF334155)),
                    shape = RoundedCornerShape(14.dp),
                    elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
                ) {
                    Column(modifier = Modifier.padding(14.dp)) {
                        Box(
                            modifier = Modifier
                                .size(34.dp)
                                .clip(RoundedCornerShape(8.dp))
                                .background(Color.White.copy(alpha = 0.2f)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(Icons.Default.Business, contentDescription = null, tint = Color.White, modifier = Modifier.size(18.dp))
                        }
                        Spacer(modifier = Modifier.height(8.dp))
                        Text("Clients", fontWeight = FontWeight.Bold, color = Color.White, fontSize = 13.sp)
                        Text("${allClients.size} contacts", fontSize = 10.sp, color = Color.White.copy(alpha = 0.8f))
                    }
                }
            }

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                // Tool Card 6: Expense Platform
                Card(
                    modifier = Modifier
                        .weight(1f)
                        .clickable { onViewExpenses() }
                        .testTag("tool_card_expenses"),
                    colors = CardDefaults.cardColors(containerColor = Color(0xFF059669)),
                    shape = RoundedCornerShape(14.dp),
                    elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
                ) {
                    Column(modifier = Modifier.padding(14.dp)) {
                        Box(
                            modifier = Modifier
                                .size(34.dp)
                                .clip(RoundedCornerShape(8.dp))
                                .background(Color.White.copy(alpha = 0.2f)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(Icons.Default.Receipt, contentDescription = null, tint = Color.White, modifier = Modifier.size(18.dp))
                        }
                        Spacer(modifier = Modifier.height(8.dp))
                        Text("Expenses", fontWeight = FontWeight.Bold, color = Color.White, fontSize = 13.sp)
                        Text("Track & scan bills", fontSize = 10.sp, color = Color.White.copy(alpha = 0.8f))
                    }
                }

                // Tool Card 7: Gemini AI Assistant
                Card(
                    modifier = Modifier
                        .weight(1f)
                        .clickable { onViewAiChat() }
                        .testTag("tool_card_ai_chat"),
                    colors = CardDefaults.cardColors(containerColor = Color(0xFF7C3AED)),
                    shape = RoundedCornerShape(14.dp),
                    elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
                ) {
                    Column(modifier = Modifier.padding(14.dp)) {
                        Box(
                            modifier = Modifier
                                .size(34.dp)
                                .clip(RoundedCornerShape(8.dp))
                                .background(Color.White.copy(alpha = 0.2f)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(Icons.Default.AutoAwesome, contentDescription = null, tint = Color.White, modifier = Modifier.size(18.dp))
                        }
                        Spacer(modifier = Modifier.height(8.dp))
                        Text("AI Assistant", fontWeight = FontWeight.Bold, color = Color.White, fontSize = 13.sp)
                        Text("Voice chat & create", fontSize = 10.sp, color = Color.White.copy(alpha = 0.8f))
                    }
                }
            }

            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = "Preferences & Configurations",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = PrimaryNavy
            )

            // =========================================================================
            // CARD 1: EDITABLE ITEM COLUMN NAMES & COLUMN VISIBILITY (USER REQUEST #4)
            // =========================================================================
            SettingAccordionCard(
                title = "Item Table Columns & Field Names",
                subtitle = "Rename columns (e.g. Price to Salary, Qty to Hours) & toggle Unit/Rate",
                icon = Icons.Default.TableChart,
                isExpanded = expandedCard == "columns",
                onToggle = { expandedCard = if (expandedCard == "columns") null else "columns" },
                badge = "Custom Columns"
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(8.dp))
                            .background(Color(0xFFEFF6FF))
                            .padding(10.dp)
                    ) {
                        Text(
                            text = "💡 Change any column name to match your industry (e.g. 'Salary' for payroll, 'Hours' for freelancing, 'Sessions' for clinic, or remove Unit). Changes apply to invoice forms, preview, and DOCX exports!",
                            fontSize = 11.sp,
                            color = PrimaryNavy
                        )
                    }

                    // Column Names Inputs
                    OutlinedTextField(
                        value = profileState.colHeaderItem,
                        onValueChange = { profileState = profileState.copy(colHeaderItem = it) },
                        label = { Text("Item / Description Column Title") },
                        placeholder = { Text("e.g. Description / Service, Employee Name, Task") },
                        modifier = Modifier.fillMaxWidth().testTag("col_header_item_input"),
                        shape = RoundedCornerShape(10.dp)
                    )

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        OutlinedTextField(
                            value = profileState.colHeaderQty,
                            onValueChange = { profileState = profileState.copy(colHeaderQty = it) },
                            label = { Text("Qty Column Title") },
                            placeholder = { Text("e.g. Qty, Hours, Days") },
                            modifier = Modifier.weight(1f).testTag("col_header_qty_input"),
                            shape = RoundedCornerShape(10.dp)
                        )

                        OutlinedTextField(
                            value = profileState.colHeaderUnit,
                            onValueChange = { profileState = profileState.copy(colHeaderUnit = it) },
                            label = { Text("Unit Column Title") },
                            placeholder = { Text("e.g. Unit, UOM, Type") },
                            modifier = Modifier.weight(1f).testTag("col_header_unit_input"),
                            shape = RoundedCornerShape(10.dp)
                        )
                    }

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        OutlinedTextField(
                            value = profileState.colHeaderRate,
                            onValueChange = { profileState = profileState.copy(colHeaderRate = it) },
                            label = { Text("Price / Rate Column Title") },
                            placeholder = { Text("e.g. Salary, Rate, Price, Wage, Fee") },
                            modifier = Modifier.weight(1f).testTag("col_header_rate_input"),
                            shape = RoundedCornerShape(10.dp)
                        )

                        OutlinedTextField(
                            value = profileState.colHeaderAmount,
                            onValueChange = { profileState = profileState.copy(colHeaderAmount = it) },
                            label = { Text("Total Column Title") },
                            placeholder = { Text("e.g. Amount, Total, Net Payout") },
                            modifier = Modifier.weight(1f).testTag("col_header_amount_input"),
                            shape = RoundedCornerShape(10.dp)
                        )
                    }

                    // Column Visibility Toggles
                    Text("Column Visibility Toggles:", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = PrimaryNavy)

                    FieldToggleRow(
                        title = "Show Unit Column",
                        description = "Display Unit of measurement (hrs, pcs, days). Turn off if not needed.",
                        checked = profileState.showItemUnit,
                        onCheckedChange = { profileState = profileState.copy(showItemUnit = it) }
                    )

                    FieldToggleRow(
                        title = "Show Quantity Column",
                        description = "Display quantity / hours field. Turn off for flat fee services.",
                        checked = profileState.showItemQty,
                        onCheckedChange = { profileState = profileState.copy(showItemQty = it) }
                    )

                    FieldToggleRow(
                        title = "Show Rate / Unit Price Column",
                        description = "Display per-unit rate/price column.",
                        checked = profileState.showItemRate,
                        onCheckedChange = { profileState = profileState.copy(showItemRate = it) }
                    )

                    // Quick Column Preset Buttons
                    Text("Quick Industry Column Presets:", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = PrimaryNavy)
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        FilterChip(
                            selected = false,
                            onClick = {
                                profileState = profileState.copy(
                                    colHeaderItem = "Description / Item",
                                    colHeaderQty = "Qty",
                                    colHeaderUnit = "Unit",
                                    colHeaderRate = "Rate",
                                    colHeaderAmount = "Amount",
                                    showItemUnit = true,
                                    showItemQty = true,
                                    showItemRate = true
                                )
                                Toast.makeText(context, "Standard Retail columns applied", Toast.LENGTH_SHORT).show()
                            },
                            label = { Text("Standard Goods", fontSize = 11.sp) }
                        )

                        FilterChip(
                            selected = false,
                            onClick = {
                                profileState = profileState.copy(
                                    colHeaderItem = "Employee Name / Role",
                                    colHeaderQty = "Days / Month",
                                    colHeaderUnit = "Period",
                                    colHeaderRate = "Salary",
                                    colHeaderAmount = "Net Pay",
                                    showItemUnit = false,
                                    showItemQty = true,
                                    showItemRate = true
                                )
                                Toast.makeText(context, "Payroll / Salary columns applied (Price -> Salary)", Toast.LENGTH_SHORT).show()
                            },
                            label = { Text("Salary / Payroll", fontSize = 11.sp) }
                        )

                        FilterChip(
                            selected = false,
                            onClick = {
                                profileState = profileState.copy(
                                    colHeaderItem = "Scope of Work / Deliverable",
                                    colHeaderQty = "Hours",
                                    colHeaderUnit = "Hrs",
                                    colHeaderRate = "Hourly Rate",
                                    colHeaderAmount = "Line Total",
                                    showItemUnit = false,
                                    showItemQty = true,
                                    showItemRate = true
                                )
                                Toast.makeText(context, "Freelance & Consulting columns applied", Toast.LENGTH_SHORT).show()
                            },
                            label = { Text("Consulting", fontSize = 11.sp) }
                        )
                    }

                    // Live Table Header Preview Box
                    Text("Live Table Header Preview:", fontSize = 11.sp, fontWeight = FontWeight.SemiBold, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(8.dp))
                            .background(Color(android.graphics.Color.parseColor(profileState.brandColorHex)))
                            .padding(horizontal = 10.dp, vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = profileState.colHeaderItem.ifBlank { "Description" },
                            color = Color.White,
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier.weight(if (profileState.showItemUnit) 1.6f else 2.0f)
                        )
                        if (profileState.showItemQty) {
                            Text(
                                text = profileState.colHeaderQty.ifBlank { "Qty" },
                                color = Color.White,
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold,
                                modifier = Modifier.weight(0.7f)
                            )
                        }
                        if (profileState.showItemUnit) {
                            Text(
                                text = profileState.colHeaderUnit.ifBlank { "Unit" },
                                color = Color.White,
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold,
                                modifier = Modifier.weight(0.7f)
                            )
                        }
                        if (profileState.showItemRate) {
                            Text(
                                text = profileState.colHeaderRate.ifBlank { "Rate" },
                                color = Color.White,
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold,
                                modifier = Modifier.weight(1.0f)
                            )
                        }
                        Text(
                            text = profileState.colHeaderAmount.ifBlank { "Amount" },
                            color = Color.White,
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier.weight(1.0f)
                        )
                    }

                    Spacer(modifier = Modifier.height(4.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Button(
                            onClick = { showSettingsItemBuilder = true },
                            colors = ButtonDefaults.buttonColors(containerColor = PrimaryNavy),
                            shape = RoundedCornerShape(8.dp),
                            modifier = Modifier.weight(1.1f).testTag("settings_open_item_builder_btn")
                        ) {
                            Text("Universal Itemization ⚙️", fontSize = 11.sp, fontWeight = FontWeight.Bold)
                        }

                        OutlinedButton(
                            onClick = { showSettingsIndustrySelector = true },
                            shape = RoundedCornerShape(8.dp),
                            modifier = Modifier.weight(0.9f).testTag("settings_browse_industries_btn")
                        ) {
                            Text("12 Industries", fontSize = 11.sp, fontWeight = FontWeight.Bold)
                        }
                    }
                }
            }

            // =========================================================================
            // CARD 2: INVOICE TEMPLATES & DEFAULT DESIGN (10 TEMPLATES IN SETTINGS MENU)
            // =========================================================================
            SettingAccordionCard(
                title = "Invoice Templates & Default Design",
                subtitle = "Select from 10 distinct templates (GST Indian Biz, Zoho Style, etc.) & set default",
                icon = Icons.Default.Description,
                isExpanded = expandedCard == "templates",
                onToggle = { expandedCard = if (expandedCard == "templates") null else "templates" },
                badge = "${DocxTemplatePreset.getById(profileState.defaultTemplateId).templateName} (Default)"
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Text(
                        text = "Choose your organization's default template. All new invoices and exports will automatically use this layout:",
                        fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )

                    // 10 Templates Cards
                    DocxTemplatePreset.allTemplates.forEach { template ->
                        val isDefault = profileState.defaultTemplateId == template.templateId
                        Card(
                            colors = CardDefaults.cardColors(
                                containerColor = if (isDefault) Color(0xFFEFF6FF) else Color(0xFFF8FAFC)
                            ),
                            shape = RoundedCornerShape(12.dp),
                            border = if (isDefault) androidx.compose.foundation.BorderStroke(2.dp, PrimaryNavy) else androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFE2E8F0)),
                            modifier = Modifier
                                .fillMaxWidth()
                                .testTag("template_card_${template.templateId}")
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(12.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Row(modifier = Modifier.weight(1f), verticalAlignment = Alignment.CenterVertically) {
                                    Box(
                                        modifier = Modifier
                                            .size(36.dp)
                                            .clip(RoundedCornerShape(8.dp))
                                            .background(Color(android.graphics.Color.parseColor(template.primaryColorHex))),
                                        contentAlignment = Alignment.Center
                                    ) {
                                        Text(
                                            text = template.docxTitle.take(3),
                                            color = Color.White,
                                            fontWeight = FontWeight.Bold,
                                            fontSize = 9.sp
                                        )
                                    }

                                    Spacer(modifier = Modifier.width(10.dp))

                                    Column {
                                        Row(verticalAlignment = Alignment.CenterVertically) {
                                            Text(
                                                text = template.templateName,
                                                fontWeight = FontWeight.Bold,
                                                fontSize = 13.sp,
                                                color = Color(0xFF0F172A)
                                            )
                                            Spacer(modifier = Modifier.width(6.dp))
                                            Box(
                                                modifier = Modifier
                                                    .clip(RoundedCornerShape(4.dp))
                                                    .background(Color(0xFFE0E7FF))
                                                    .padding(horizontal = 5.dp, vertical = 2.dp)
                                            ) {
                                                Text(template.categoryBadge, fontSize = 9.sp, fontWeight = FontWeight.Bold, color = Color(0xFF3730A3))
                                            }
                                        }
                                        Text(
                                            text = "Title: ${template.docxTitle} • Font: ${template.fontStyle}",
                                            fontSize = 10.sp,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant
                                        )
                                    }
                                }

                                if (isDefault) {
                                    Row(
                                        verticalAlignment = Alignment.CenterVertically,
                                        modifier = Modifier
                                            .clip(RoundedCornerShape(20.dp))
                                            .background(Color(0xFFDCFCE7))
                                            .padding(horizontal = 8.dp, vertical = 4.dp)
                                    ) {
                                        Icon(Icons.Default.Check, contentDescription = null, tint = StatusPaidGreen, modifier = Modifier.size(14.dp))
                                        Spacer(modifier = Modifier.width(4.dp))
                                        Text("Default", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = StatusPaidGreen)
                                    }
                                } else {
                                    OutlinedButton(
                                        onClick = {
                                            profileState = profileState.copy(
                                                defaultTemplateId = template.templateId,
                                                brandColorHex = template.primaryColorHex
                                            )
                                            viewModel.setDefaultTemplate(template.templateId)
                                            Toast.makeText(context, "${template.templateName} set as Default", Toast.LENGTH_SHORT).show()
                                        },
                                        shape = RoundedCornerShape(8.dp),
                                        contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = 10.dp, vertical = 4.dp),
                                        modifier = Modifier.testTag("set_default_${template.templateId}")
                                    ) {
                                        Text("Set Default", fontSize = 11.sp)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =========================================================================
            // CARD 3: GST & INDIAN BUSINESS INVOICING (ZOHO STYLE)
            // =========================================================================
            SettingAccordionCard(
                title = "GST & Indian Business Details",
                subtitle = "GSTIN, PAN, Place of Supply, UPI ID (GPay / PhonePe), IFSC & words",
                icon = Icons.Default.QrCode,
                isExpanded = expandedCard == "gst",
                onToggle = { expandedCard = if (expandedCard == "gst") null else "gst" },
                badge = if (profileState.gstin.isNotBlank()) "GSTIN Active" else "Setup"
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text(
                        text = "Indian tax & digital payment details compliant with GST & Zoho Invoice formats:",
                        fontSize = 11.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        OutlinedTextField(
                            value = profileState.gstin,
                            onValueChange = { profileState = profileState.copy(gstin = it.uppercase(), taxId = it.uppercase()) },
                            label = { Text("GSTIN *") },
                            placeholder = { Text("27AABCU9603R1ZN") },
                            modifier = Modifier.weight(1.2f).testTag("gstin_input"),
                            shape = RoundedCornerShape(10.dp)
                        )
                        OutlinedTextField(
                            value = profileState.panNumber,
                            onValueChange = { profileState = profileState.copy(panNumber = it.uppercase()) },
                            label = { Text("PAN Number") },
                            placeholder = { Text("AABCU9603R") },
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(10.dp)
                        )
                    }

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        OutlinedTextField(
                            value = profileState.placeOfSupply,
                            onValueChange = { profileState = profileState.copy(placeOfSupply = it) },
                            label = { Text("Place of Supply (State)") },
                            placeholder = { Text("27-Maharashtra") },
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(10.dp)
                        )
                        OutlinedTextField(
                            value = profileState.upiId,
                            onValueChange = { profileState = profileState.copy(upiId = it) },
                            label = { Text("UPI ID (GPay/PhonePe)") },
                            placeholder = { Text("company@icici") },
                            modifier = Modifier.weight(1.2f).testTag("upi_input"),
                            shape = RoundedCornerShape(10.dp)
                        )
                    }

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        OutlinedTextField(
                            value = profileState.ifscCode,
                            onValueChange = { profileState = profileState.copy(ifscCode = it.uppercase()) },
                            label = { Text("Bank IFSC Code") },
                            placeholder = { Text("HDFC0000240") },
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(10.dp)
                        )
                        OutlinedTextField(
                            value = profileState.branchName,
                            onValueChange = { profileState = profileState.copy(branchName = it) },
                            label = { Text("Bank Branch") },
                            placeholder = { Text("BKC, Mumbai") },
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(10.dp)
                        )
                    }

                    HorizontalDivider()

                    FieldToggleRow(
                        title = "Show Amount in Words",
                        description = "e.g. 'Rupees Forty-Eight Thousand Two Hundred Only'",
                        checked = profileState.showAmountInWords,
                        onCheckedChange = { profileState = profileState.copy(showAmountInWords = it) }
                    )

                    FieldToggleRow(
                        title = "Show CGST / SGST Breakdown",
                        description = "Split 18% GST into CGST 9% and SGST 9% on invoices",
                        checked = profileState.showGstBreakdown,
                        onCheckedChange = { profileState = profileState.copy(showGstBreakdown = it) }
                    )
                }
            }

            // =========================================================================
            // CARD 4: INVOICE FIELD VISIBILITY CUSTOMIZER (ZOHO STYLE)
            // =========================================================================
            SettingAccordionCard(
                title = "Invoice Field Customization",
                subtitle = "Remove or enable fields (Due Date, Issue Date, Status, PO #, etc.)",
                icon = Icons.Default.Tune,
                isExpanded = expandedCard == "fields",
                onToggle = { expandedCard = if (expandedCard == "fields") null else "fields" },
                badge = "Field Toggles"
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text(
                        text = "Fields turned OFF will be omitted from invoice forms and output documents:",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )

                    HorizontalDivider()

                    FieldToggleRow(
                        title = "Invoice Status",
                        description = "Display Draft, Sent, Paid, Overdue badge",
                        checked = profileState.showStatus,
                        onCheckedChange = { profileState = profileState.copy(showStatus = it) }
                    )

                    FieldToggleRow(
                        title = "Due Date",
                        description = "Show payment deadline and due date alerts",
                        checked = profileState.showDueDate,
                        onCheckedChange = { profileState = profileState.copy(showDueDate = it) }
                    )

                    FieldToggleRow(
                        title = "Issue Date",
                        description = "Show invoice issuance date",
                        checked = profileState.showIssueDate,
                        onCheckedChange = { profileState = profileState.copy(showIssueDate = it) }
                    )

                    FieldToggleRow(
                        title = "Purchase Order (PO #)",
                        description = "Track client's purchase order reference number",
                        checked = profileState.showPoNumber,
                        onCheckedChange = { profileState = profileState.copy(showPoNumber = it) }
                    )

                    FieldToggleRow(
                        title = "Payment Terms",
                        description = "Display terms such as Net 15, Net 30, Due on Receipt",
                        checked = profileState.showPaymentTerms,
                        onCheckedChange = { profileState = profileState.copy(showPaymentTerms = it) }
                    )

                    FieldToggleRow(
                        title = "Client Company Name",
                        description = "Show organization/company under client name",
                        checked = profileState.showClientCompany,
                        onCheckedChange = { profileState = profileState.copy(showClientCompany = it) }
                    )

                    FieldToggleRow(
                        title = "Client Billing Address",
                        description = "Display client's physical/mailing address",
                        checked = profileState.showClientAddress,
                        onCheckedChange = { profileState = profileState.copy(showClientAddress = it) }
                    )

                    FieldToggleRow(
                        title = "Client Tax / GSTIN ID",
                        description = "Show client's tax registration number",
                        checked = profileState.showClientTaxId,
                        onCheckedChange = { profileState = profileState.copy(showClientTaxId = it) }
                    )

                    FieldToggleRow(
                        title = "Line Item Discount",
                        description = "Allow per-item discount percentages",
                        checked = profileState.showItemDiscount,
                        onCheckedChange = { profileState = profileState.copy(showItemDiscount = it) }
                    )

                    FieldToggleRow(
                        title = "Tax Rate & Calculation",
                        description = "Include tax computation (GST, VAT, Sales Tax)",
                        checked = profileState.showItemTax,
                        onCheckedChange = { profileState = profileState.copy(showItemTax = it) }
                    )

                    FieldToggleRow(
                        title = "Shipping & Handling Fee",
                        description = "Include shipping and freight charges",
                        checked = profileState.showShippingFee,
                        onCheckedChange = { profileState = profileState.copy(showShippingFee = it) }
                    )

                    FieldToggleRow(
                        title = "Bank Payment Instructions",
                        description = "Display bank account, routing, and payment link",
                        checked = profileState.showPaymentInstructions,
                        onCheckedChange = { profileState = profileState.copy(showPaymentInstructions = it) }
                    )

                    FieldToggleRow(
                        title = "Notes to Client",
                        description = "Show client message and closing greetings",
                        checked = profileState.showNotes,
                        onCheckedChange = { profileState = profileState.copy(showNotes = it) }
                    )

                    FieldToggleRow(
                        title = "Terms & Conditions",
                        description = "Display contractual payment terms and late fee policies",
                        checked = profileState.showTerms,
                        onCheckedChange = { profileState = profileState.copy(showTerms = it) }
                    )

                    FieldToggleRow(
                        title = "Authorized Signature Block",
                        description = "Display signature line with signee name and title",
                        checked = profileState.showSignature,
                        onCheckedChange = { profileState = profileState.copy(showSignature = it) }
                    )
                }
            }

            // =========================================================================
            // CARD 5: DEFAULT CURRENCY & PRICING (SET IN SETTINGS ONLY)
            // =========================================================================
            SettingAccordionCard(
                title = "Currency Settings (Global)",
                subtitle = "Manage global invoice currency, symbol, and display format",
                icon = Icons.Default.CurrencyExchange,
                isExpanded = expandedCard == "currency",
                onToggle = { expandedCard = if (expandedCard == "currency") null else "currency" },
                badge = "${profileState.defaultCurrency} (${profileState.defaultCurrencySymbol})"
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(8.dp))
                            .background(Color(0xFFEFF6FF))
                            .padding(12.dp)
                    ) {
                        Text(
                            text = "ℹ️ Currency is centrally configured here in Settings. All new invoices and calculations automatically apply these preferences.",
                            fontSize = 12.sp,
                            color = PrimaryNavy
                        )
                    }

                    // Currency Selector Dropdown
                    var currExpanded by remember { mutableStateOf(false) }
                    ExposedDropdownMenuBox(
                        expanded = currExpanded,
                        onExpandedChange = { currExpanded = it },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        OutlinedTextField(
                            value = "${profileState.defaultCurrency} (${profileState.defaultCurrencySymbol})",
                            onValueChange = {},
                            readOnly = true,
                            label = { Text("Base Currency") },
                            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = currExpanded) },
                            modifier = Modifier
                                .fillMaxWidth()
                                .menuAnchor(),
                            shape = RoundedCornerShape(10.dp)
                        )
                        ExposedDropdownMenu(
                            expanded = currExpanded,
                            onDismissRequest = { currExpanded = false }
                        ) {
                            currencies.forEach { (code, sym) ->
                                DropdownMenuItem(
                                    text = { Text("$code ($sym)") },
                                    onClick = {
                                        profileState = profileState.copy(
                                            defaultCurrency = code,
                                            defaultCurrencySymbol = sym
                                        )
                                        currExpanded = false
                                    }
                                )
                            }
                        }
                    }

                    OutlinedTextField(
                        value = profileState.defaultCurrencySymbol,
                        onValueChange = { profileState = profileState.copy(defaultCurrencySymbol = it) },
                        label = { Text("Custom Currency Symbol") },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(10.dp)
                    )

                    // Currency Placement Format (Before: ₹100, After: 100 ₹)
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text("Symbol Placement", style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
                            Text(
                                if (profileState.defaultCurrencyFormat == "before") "Prefix (e.g. ${profileState.defaultCurrencySymbol}1,500.00)" else "Suffix (e.g. 1,500.00 ${profileState.defaultCurrencySymbol})",
                                fontSize = 11.sp,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }

                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            FilterChip(
                                selected = profileState.defaultCurrencyFormat == "before",
                                onClick = { profileState = profileState.copy(defaultCurrencyFormat = "before") },
                                label = { Text("Prefix") }
                            )
                            FilterChip(
                                selected = profileState.defaultCurrencyFormat == "after",
                                onClick = { profileState = profileState.copy(defaultCurrencyFormat = "after") },
                                label = { Text("Suffix") }
                            )
                        }
                    }
                }
            }

            // =========================================================================
            // CARD 6: BUSINESS PROFILE & CUSTOM ICON CREATOR
            // =========================================================================
            SettingAccordionCard(
                title = "Business Profile & Custom Icon",
                subtitle = "Create custom logos, monogram icons, company identity and colors",
                icon = Icons.Default.Business,
                isExpanded = expandedCard == "profile",
                onToggle = { expandedCard = if (expandedCard == "profile") null else "profile" },
                badge = "Icon Builder"
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
                    // LIVE CUSTOM ICON PREVIEW CARD
                    Card(
                        colors = CardDefaults.cardColors(containerColor = Color(0xFFF8FAFC)),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(16.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            BusinessCustomIcon(
                                profile = profileState,
                                size = 64.dp
                            )

                            Spacer(modifier = Modifier.width(16.dp))

                            Column {
                                Text(
                                    text = "Custom Business Icon Preview",
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 14.sp,
                                    color = MaterialTheme.colorScheme.onSurface
                                )
                                Text(
                                    text = "Renders automatically in invoice headers, documents, and DOCX exports",
                                    fontSize = 11.sp,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }
                    }

                    // Icon Style Mode: Symbol vs Initials
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        FilterChip(
                            selected = profileState.customIconType == "symbol",
                            onClick = { profileState = profileState.copy(customIconType = "symbol") },
                            label = { Text("Vector Symbol") },
                            modifier = Modifier.weight(1f)
                        )
                        FilterChip(
                            selected = profileState.customIconType == "initials",
                            onClick = { profileState = profileState.copy(customIconType = "initials") },
                            label = { Text("Monogram Initials") },
                            modifier = Modifier.weight(1f)
                        )
                    }

                    if (profileState.customIconType == "initials") {
                        OutlinedTextField(
                            value = profileState.customIconText,
                            onValueChange = {
                                if (it.length <= 4) profileState = profileState.copy(customIconText = it.uppercase())
                            },
                            label = { Text("Monogram Text (1-3 letters, e.g. AN)") },
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(10.dp)
                        )
                    } else {
                        // Symbol picker chips
                        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                            Text("Select Symbol:", fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.spacedBy(6.dp)
                            ) {
                                iconSymbols.take(4).forEach { (sym, label) ->
                                    FilterChip(
                                        selected = profileState.customIconSymbol == sym,
                                        onClick = { profileState = profileState.copy(customIconSymbol = sym) },
                                        label = { Text(label, fontSize = 11.sp) },
                                        modifier = Modifier.weight(1f)
                                    )
                                }
                            }
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.spacedBy(6.dp)
                            ) {
                                iconSymbols.drop(4).forEach { (sym, label) ->
                                    FilterChip(
                                        selected = profileState.customIconSymbol == sym,
                                        onClick = { profileState = profileState.copy(customIconSymbol = sym) },
                                        label = { Text(label, fontSize = 11.sp) },
                                        modifier = Modifier.weight(1f)
                                    )
                                }
                            }
                        }
                    }

                    // Icon Shape: Rounded, Circle, Square
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        listOf("rounded" to "Rounded", "circle" to "Circle", "square" to "Square").forEach { (shape, name) ->
                            FilterChip(
                                selected = profileState.customIconShape == shape,
                                onClick = { profileState = profileState.copy(customIconShape = shape) },
                                label = { Text(name, fontSize = 12.sp) },
                                modifier = Modifier.weight(1f)
                            )
                        }
                    }

                    // Icon Background Color Palette
                    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text("Icon Background & Brand Color:", fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            presetColors.take(8).forEach { (hex, _) ->
                                val isSelected = profileState.customIconBgColorHex.equals(hex, ignoreCase = true)
                                Box(
                                    modifier = Modifier
                                        .size(32.dp)
                                        .clip(CircleShape)
                                        .background(Color(android.graphics.Color.parseColor(hex)))
                                        .clickable {
                                            profileState = profileState.copy(
                                                customIconBgColorHex = hex,
                                                brandColorHex = hex
                                            )
                                        }
                                        .then(
                                            if (isSelected) Modifier.border(3.dp, Color.Black, CircleShape)
                                            else Modifier
                                        ),
                                    contentAlignment = Alignment.Center
                                ) {
                                    if (isSelected) {
                                        Icon(imageVector = Icons.Default.Check, contentDescription = null, tint = Color.White, modifier = Modifier.size(16.dp))
                                    }
                                }
                            }
                        }
                    }

                    HorizontalDivider()

                    // Business Identity Details
                    OutlinedTextField(
                        value = profileState.businessName,
                        onValueChange = { profileState = profileState.copy(businessName = it) },
                        label = { Text("Display Business Name *") },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(10.dp)
                    )

                    OutlinedTextField(
                        value = profileState.legalName,
                        onValueChange = { profileState = profileState.copy(legalName = it) },
                        label = { Text("Legal Trading Name") },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(10.dp)
                    )

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        OutlinedTextField(
                            value = profileState.email,
                            onValueChange = { profileState = profileState.copy(email = it) },
                            label = { Text("Billing Email") },
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(10.dp),
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email)
                        )
                        OutlinedTextField(
                            value = profileState.phone,
                            onValueChange = { profileState = profileState.copy(phone = it) },
                            label = { Text("Phone") },
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(10.dp),
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone)
                        )
                    }

                    OutlinedTextField(
                        value = profileState.address,
                        onValueChange = { profileState = profileState.copy(address = it) },
                        label = { Text("Physical Address") },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(10.dp),
                        maxLines = 3
                    )

                    OutlinedTextField(
                        value = profileState.website,
                        onValueChange = { profileState = profileState.copy(website = it) },
                        label = { Text("Website") },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(10.dp)
                    )
                }
            }

            // =========================================================================
            // CARD 7: PAYMENT GATEWAYS & BANK INFO
            // =========================================================================
            SettingAccordionCard(
                title = "Payment Gateways & Wire Info",
                subtitle = "Bank account numbers, IFSC/SWIFT, and online payment links",
                icon = Icons.Default.AccountBalance,
                isExpanded = expandedCard == "banking",
                onToggle = { expandedCard = if (expandedCard == "banking") null else "banking" }
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    OutlinedTextField(
                        value = profileState.bankName,
                        onValueChange = { profileState = profileState.copy(bankName = it) },
                        label = { Text("Bank Name") },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(10.dp)
                    )

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        OutlinedTextField(
                            value = profileState.accountHolder,
                            onValueChange = { profileState = profileState.copy(accountHolder = it) },
                            label = { Text("Account Holder") },
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(10.dp)
                        )
                        OutlinedTextField(
                            value = profileState.accountNumber,
                            onValueChange = { profileState = profileState.copy(accountNumber = it) },
                            label = { Text("Account / IBAN") },
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(10.dp)
                        )
                    }

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        OutlinedTextField(
                            value = profileState.routingNumber,
                            onValueChange = { profileState = profileState.copy(routingNumber = it) },
                            label = { Text("Routing / Sort / MICR Code") },
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(10.dp)
                        )
                        OutlinedTextField(
                            value = profileState.swiftBic,
                            onValueChange = { profileState = profileState.copy(swiftBic = it) },
                            label = { Text("SWIFT / BIC") },
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(10.dp)
                        )
                    }

                    OutlinedTextField(
                        value = profileState.paymentLink,
                        onValueChange = { profileState = profileState.copy(paymentLink = it) },
                        label = { Text("Direct Payment Link (PayPal, Stripe, Razorpay)") },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(10.dp)
                    )
                }
            }

            // =========================================================================
            // CARD 8: TAXES, NOTES & SIGNATURE
            // =========================================================================
            SettingAccordionCard(
                title = "Taxes, Notes & Signature",
                subtitle = "Default tax rates, client notes, terms and authorized signee",
                icon = Icons.Default.Receipt,
                isExpanded = expandedCard == "taxes",
                onToggle = { expandedCard = if (expandedCard == "taxes") null else "taxes" }
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        OutlinedTextField(
                            value = profileState.defaultTaxLabel,
                            onValueChange = { profileState = profileState.copy(defaultTaxLabel = it) },
                            label = { Text("Tax Label") },
                            modifier = Modifier.weight(1.2f),
                            shape = RoundedCornerShape(10.dp)
                        )
                        OutlinedTextField(
                            value = if (profileState.defaultTaxRate == 0.0) "" else profileState.defaultTaxRate.toString(),
                            onValueChange = { profileState = profileState.copy(defaultTaxRate = it.toDoubleOrNull() ?: 0.0) },
                            label = { Text("Tax Rate (%)") },
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(10.dp),
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal)
                        )
                    }

                    OutlinedTextField(
                        value = profileState.defaultPaymentTerms,
                        onValueChange = { profileState = profileState.copy(defaultPaymentTerms = it) },
                        label = { Text("Default Payment Terms (e.g. Net 30)") },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(10.dp)
                    )

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        OutlinedTextField(
                            value = profileState.signeeName,
                            onValueChange = { profileState = profileState.copy(signeeName = it) },
                            label = { Text("Signee Name") },
                            modifier = Modifier.weight(1.2f),
                            shape = RoundedCornerShape(10.dp)
                        )
                        OutlinedTextField(
                            value = profileState.signeeTitle,
                            onValueChange = { profileState = profileState.copy(signeeTitle = it) },
                            label = { Text("Signee Title") },
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(10.dp)
                        )
                    }

                    OutlinedTextField(
                        value = profileState.defaultNotes,
                        onValueChange = { profileState = profileState.copy(defaultNotes = it) },
                        label = { Text("Default Notes") },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(10.dp),
                        maxLines = 3
                    )

                    OutlinedTextField(
                        value = profileState.defaultTerms,
                        onValueChange = { profileState = profileState.copy(defaultTerms = it) },
                        label = { Text("Default Terms & Conditions") },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(10.dp),
                        maxLines = 3
                    )
                }
            }

            // =========================================================================
            // CARD 9: OFFLINE ROOM DATABASE & LOCAL STORAGE
            // =========================================================================
            SettingAccordionCard(
                title = "Offline Room Database & Storage",
                subtitle = "Local persistence status, record counts, and database management",
                icon = Icons.Default.Storage,
                isExpanded = expandedCard == "database",
                onToggle = { expandedCard = if (expandedCard == "database") null else "database" },
                badge = "Room DB Active"
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    // Status row
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(8.dp))
                            .background(Color(0xFFD1FAE5))
                            .padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.CheckCircle,
                            contentDescription = null,
                            tint = StatusPaidGreen,
                            modifier = Modifier.size(20.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Column {
                            Text(
                                text = "Local Room Database Active (v3)",
                                fontWeight = FontWeight.Bold,
                                fontSize = 12.sp,
                                color = StatusPaidGreen
                            )
                            Text(
                                text = "100% Offline Capable. Invoices, clients, and custom settings persist securely on-device.",
                                fontSize = 11.sp,
                                color = Color(0xFF065F46)
                            )
                        }
                    }

                    // Metrics
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        Card(
                            colors = CardDefaults.cardColors(containerColor = Color(0xFFF8FAFC)),
                            shape = RoundedCornerShape(10.dp),
                            modifier = Modifier.weight(1f)
                        ) {
                            Column(modifier = Modifier.padding(12.dp)) {
                                Text("Invoices in Room", fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                Text("${allInvoices.size} stored", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = PrimaryNavy)
                            }
                        }

                        Card(
                            colors = CardDefaults.cardColors(containerColor = Color(0xFFF8FAFC)),
                            shape = RoundedCornerShape(10.dp),
                            modifier = Modifier.weight(1f)
                        ) {
                            Column(modifier = Modifier.padding(12.dp)) {
                                Text("Clients in Room", fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                Text("${allClients.size} stored", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = PrimaryNavy)
                            }
                        }
                    }

                    // Reset & Clear Actions
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        OutlinedButton(
                            onClick = { showResetDialog = true },
                            shape = RoundedCornerShape(10.dp),
                            modifier = Modifier.weight(1f)
                        ) {
                            Icon(Icons.Default.Refresh, contentDescription = null, modifier = Modifier.size(16.dp))
                            Spacer(modifier = Modifier.width(6.dp))
                            Text("Reset Demo Data", fontSize = 11.sp)
                        }

                        OutlinedButton(
                            onClick = { showClearInvoicesDialog = true },
                            shape = RoundedCornerShape(10.dp),
                            colors = ButtonDefaults.outlinedButtonColors(contentColor = MaterialTheme.colorScheme.error),
                            modifier = Modifier.weight(1f)
                        ) {
                            Icon(Icons.Default.Delete, contentDescription = null, modifier = Modifier.size(16.dp))
                            Spacer(modifier = Modifier.width(6.dp))
                            Text("Clear Invoices", fontSize = 11.sp)
                        }
                    }
                }
            }

            // =========================================================================
            // CARD 10: GEMINI AI & VOICE ASSISTANT SETTINGS
            // =========================================================================
            SettingAccordionCard(
                title = "Gemini AI & Voice Assistant",
                subtitle = "Google Gemini 3.5 Flash setup, voice chat commands, and invoice prompts",
                icon = Icons.Default.AutoAwesome,
                isExpanded = expandedCard == "gemini_ai",
                onToggle = { expandedCard = if (expandedCard == "gemini_ai") null else "gemini_ai" },
                badge = "Gemini 3.5 Flash"
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(8.dp))
                            .background(Color(0xFFEDE9FE))
                            .padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.AutoAwesome,
                            contentDescription = null,
                            tint = Color(0xFF7C3AED),
                            modifier = Modifier.size(22.dp)
                        )
                        Spacer(modifier = Modifier.width(10.dp))
                        Column {
                            Text(
                                text = "Gemini AI Conversational Core Active",
                                fontWeight = FontWeight.Bold,
                                fontSize = 12.sp,
                                color = Color(0xFF6D28D9)
                            )
                            Text(
                                text = "Speak or text to create complete invoices, save clients, or log expenses in seconds.",
                                fontSize = 11.sp,
                                color = Color(0xFF5B21B6)
                            )
                        }
                    }

                    Text("Example Voice & Chat Commands:", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = PrimaryNavy)

                    val voiceCommands = listOf(
                        "\"Generate invoice for Microsoft 20 hours web dev at $120/hr and 1 design package at $800\"",
                        "\"Save client Tesla Inc with email billing@tesla.com and Austin TX address\"",
                        "\"Save expense $85 for Client Lunch under Meals at Starbucks\"",
                        "\"What is the standard GST rate in India for IT consulting?\""
                    )
                    for (cmd in voiceCommands) {
                        Surface(
                            color = Color(0xFFF8FAFC),
                            shape = RoundedCornerShape(8.dp),
                            border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFE2E8F0)),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text(
                                text = cmd,
                                fontSize = 11.sp,
                                fontStyle = androidx.compose.ui.text.font.FontStyle.Italic,
                                color = Color(0xFF334155),
                                modifier = Modifier.padding(10.dp)
                            )
                        }
                    }

                    Button(
                        onClick = { onViewAiChat() },
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF7C3AED)),
                        shape = RoundedCornerShape(10.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(Icons.Default.AutoAwesome, contentDescription = null, modifier = Modifier.size(16.dp))
                        Spacer(modifier = Modifier.width(6.dp))
                        Text("Open Gemini Voice & Chat Assistant", fontSize = 12.sp, fontWeight = FontWeight.Bold)
                    }
                }
            }

            // =========================================================================
            // BACKEND CLOUD & API SERVER SETTINGS (SPRING BOOT + POSTGRESQL)
            // =========================================================================
            SettingAccordionCard(
                title = "Backend Cloud & API Server",
                subtitle = "Spring Boot + PostgreSQL connection, URL & live synchronization",
                icon = Icons.Default.Storage,
                isExpanded = expandedCard == "backend_sync",
                onToggle = { expandedCard = if (expandedCard == "backend_sync") null else "backend_sync" },
                badge = if (isBackendOnline) "ONLINE" else "OFFLINE"
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    // Status banner
                    Surface(
                        color = if (isBackendOnline) Color(0xFFF0FDF4) else Color(0xFFFFFBEB),
                        shape = RoundedCornerShape(10.dp),
                        border = androidx.compose.foundation.BorderStroke(1.dp, if (isBackendOnline) Color(0xFFBBF7D0) else Color(0xFFFDE68A)),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Row(
                            modifier = Modifier.padding(12.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(10.dp)
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(10.dp)
                                    .clip(CircleShape)
                                    .background(if (isBackendOnline) StatusPaidGreen else Color(0xFFF59E0B))
                            )
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = if (isBackendOnline) "Backend API Online & Connected" else "Backend Server Offline / Unreachable",
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 12.sp,
                                    color = if (isBackendOnline) Color(0xFF166534) else Color(0xFF92400E)
                                )
                                Text(
                                    text = if (lastSyncTime != null) "Last synchronized: $lastSyncTime" else "Offline-first fallback active (Room DB snappiness preserved)",
                                    fontSize = 11.sp,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                                if (syncErrorMessage != null) {
                                    Text(
                                        text = "Sync status: $syncErrorMessage",
                                        fontSize = 10.sp,
                                        color = MaterialTheme.colorScheme.error
                                    )
                                }
                            }
                        }
                    }

                    // Server Base URL field
                    OutlinedTextField(
                        value = serverUrlInput,
                        onValueChange = { serverUrlInput = it },
                        label = { Text("Backend Server Base URL") },
                        supportingText = { Text("E.g. http://10.0.2.2:8080/ for Android emulator, or LAN IP for physical device") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                        shape = RoundedCornerShape(10.dp)
                    )

                    // URL quick preset chips
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        OutlinedButton(
                            onClick = {
                                serverUrlInput = "http://10.0.2.2:8080/"
                                ApiConfig.updateBaseUrl(serverUrlInput)
                                Toast.makeText(context, "Set to Emulator URL", Toast.LENGTH_SHORT).show()
                            },
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(8.dp)
                        ) {
                            Text("Emulator", fontSize = 11.sp)
                        }
                        OutlinedButton(
                            onClick = {
                                serverUrlInput = "http://localhost:8080/"
                                ApiConfig.updateBaseUrl(serverUrlInput)
                                Toast.makeText(context, "Set to Localhost", Toast.LENGTH_SHORT).show()
                            },
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(8.dp)
                        ) {
                            Text("Localhost", fontSize = 11.sp)
                        }
                        Button(
                            onClick = {
                                ApiConfig.updateBaseUrl(serverUrlInput)
                                Toast.makeText(context, "Base URL saved", Toast.LENGTH_SHORT).show()
                            },
                            shape = RoundedCornerShape(8.dp),
                            colors = ButtonDefaults.buttonColors(containerColor = PrimaryNavy)
                        ) {
                            Text("Save URL", fontSize = 11.sp)
                        }
                    }

                    // Test connection & Sync Now actions
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        OutlinedButton(
                            onClick = {
                                coroutineScope.launch {
                                    val ok = InvoicelyApiManager.checkConnection().getOrDefault(false)
                                    if (ok) {
                                        Toast.makeText(context, "✓ Connected to Spring Boot backend!", Toast.LENGTH_SHORT).show()
                                    } else {
                                        Toast.makeText(context, "✗ Backend unreachable. Verify Spring Boot is running on 8080.", Toast.LENGTH_LONG).show()
                                    }
                                }
                            },
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(10.dp)
                        ) {
                            Icon(Icons.Default.Refresh, contentDescription = null, modifier = Modifier.size(16.dp))
                            Spacer(modifier = Modifier.width(6.dp))
                            Text("Test Link", fontSize = 12.sp)
                        }

                        Button(
                            onClick = {
                                viewModel.syncAllDataWithBackend()
                                Toast.makeText(context, "Synchronizing all data with backend...", Toast.LENGTH_SHORT).show()
                            },
                            enabled = !isSyncing,
                            modifier = Modifier.weight(1.2f),
                            shape = RoundedCornerShape(10.dp),
                            colors = ButtonDefaults.buttonColors(containerColor = PrimaryNavy)
                        ) {
                            if (isSyncing) {
                                CircularProgressIndicator(modifier = Modifier.size(16.dp), color = Color.White, strokeWidth = 2.dp)
                                Spacer(modifier = Modifier.width(6.dp))
                                Text("Syncing...", fontSize = 12.sp)
                            } else {
                                Icon(Icons.Default.Refresh, contentDescription = null, modifier = Modifier.size(16.dp))
                                Spacer(modifier = Modifier.width(6.dp))
                                Text("Sync All Now", fontSize = 12.sp)
                            }
                        }
                    }

                    // Active session info
                    val currentToken: String? = com.example.data.api.client.ApiClient.getAuthToken()
                    Surface(
                        color = Color(0xFFF8FAFC),
                        shape = RoundedCornerShape(8.dp),
                        border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFE2E8F0)),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(modifier = Modifier.padding(10.dp)) {
                            Text("API Authentication & Session:", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = PrimaryNavy)
                            Text(
                                text = if (currentToken != null) "JWT Bearer Token Active (${currentToken.take(12)}...)" else "No active JWT token (offline / guest mode)",
                                fontSize = 10.sp,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
            }

            // Save All Button
            Button(
                onClick = { saveChanges() },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp)
                    .testTag("save_settings_bottom_btn"),
                colors = ButtonDefaults.buttonColors(containerColor = PrimaryNavy),
                shape = RoundedCornerShape(12.dp)
            ) {
                Icon(imageVector = Icons.Default.Check, contentDescription = null)
                Spacer(modifier = Modifier.width(8.dp))
                Text("Save All Settings & Preferences", fontWeight = FontWeight.Bold)
            }

            Spacer(modifier = Modifier.height(24.dp))
        }
    }
}

    // Reset Demo Confirmation Dialog
    if (showResetDialog) {
        AlertDialog(
            onDismissRequest = { showResetDialog = false },
            title = { Text("Reset Sample Invoices & Clients?") },
            text = { Text("This will reload sample invoices, clients, and default configuration into your local Room database.") },
            confirmButton = {
                Button(
                    onClick = {
                        viewModel.resetSampleData()
                        showResetDialog = false
                        Toast.makeText(context, "Sample data reset in Room database", Toast.LENGTH_SHORT).show()
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = PrimaryNavy)
                ) {
                    Text("Reset")
                }
            },
            dismissButton = {
                TextButton(onClick = { showResetDialog = false }) { Text("Cancel") }
            }
        )
    }

    // Clear Invoices Confirmation Dialog
    if (showClearInvoicesDialog) {
        AlertDialog(
            onDismissRequest = { showClearInvoicesDialog = false },
            title = { Text("Clear All Invoices?") },
            text = { Text("Are you sure you want to delete all invoices from local storage? Your clients and business profile will be kept.") },
            confirmButton = {
                Button(
                    onClick = {
                        viewModel.clearAllInvoices()
                        showClearInvoicesDialog = false
                        Toast.makeText(context, "Invoices cleared", Toast.LENGTH_SHORT).show()
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error)
                ) {
                    Text("Clear All")
                }
            },
            dismissButton = {
                TextButton(onClick = { showClearInvoicesDialog = false }) { Text("Cancel") }
            }
        )
    }

    if (showSettingsItemBuilder) {
        val currentCols = InvoiceUtils.deserializeColumns(profileState.customColumnsJson, profileState)
        ItemizationBuilderDialog(
            initialColumns = currentCols,
            onSaveColumns = { updatedCols ->
                profileState = profileState.copy(
                    customColumnsJson = InvoiceUtils.serializeColumns(updatedCols)
                )
                viewModel.saveBusinessProfile(profileState)
                Toast.makeText(context, "Global itemization columns saved!", Toast.LENGTH_SHORT).show()
                showSettingsItemBuilder = false
            },
            onDismiss = { showSettingsItemBuilder = false }
        )
    }

    if (showSettingsIndustrySelector) {
        IndustryTemplateSelectorDialog(
            selectedPresetId = "general",
            onSelectPreset = { preset ->
                profileState = profileState.copy(
                    customColumnsJson = InvoiceUtils.serializeColumns(preset.defaultColumns),
                    colHeaderItem = preset.defaultColumns.find { it.key == "description" }?.label ?: profileState.colHeaderItem,
                    defaultNotes = if (preset.defaultNotes.isNotBlank()) preset.defaultNotes else profileState.defaultNotes,
                    defaultTerms = if (preset.defaultTerms.isNotBlank()) preset.defaultTerms else profileState.defaultTerms
                )
                viewModel.saveBusinessProfile(profileState)
                Toast.makeText(context, "Loaded ${preset.name} itemization preset!", Toast.LENGTH_SHORT).show()
                showSettingsIndustrySelector = false
            },
            onDismiss = { showSettingsIndustrySelector = false }
        )
    }
}

@Composable
fun SettingAccordionCard(
    title: String,
    subtitle: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    isExpanded: Boolean,
    onToggle: () -> Unit,
    badge: String? = null,
    content: @Composable () -> Unit
) {
    Card(
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        shape = RoundedCornerShape(16.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable(onClick = onToggle),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(modifier = Modifier.weight(1f), verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        modifier = Modifier
                            .size(38.dp)
                            .clip(CircleShape)
                            .background(Color(0xFFEFF6FF)),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(imageVector = icon, contentDescription = null, tint = PrimaryNavy, modifier = Modifier.size(20.dp))
                    }

                    Spacer(modifier = Modifier.width(12.dp))

                    Column {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(text = title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                            if (badge != null) {
                                Spacer(modifier = Modifier.width(6.dp))
                                Box(
                                    modifier = Modifier
                                        .clip(RoundedCornerShape(8.dp))
                                        .background(Color(0xFFEFF6FF))
                                        .padding(horizontal = 6.dp, vertical = 2.dp)
                                ) {
                                    Text(badge, fontSize = 10.sp, fontWeight = FontWeight.Bold, color = PrimaryNavy)
                                }
                            }
                        }
                        Text(text = subtitle, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }

                Icon(
                    imageVector = if (isExpanded) Icons.Default.ExpandLess else Icons.Default.ExpandMore,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            AnimatedVisibility(visible = isExpanded) {
                Column(modifier = Modifier.padding(top = 16.dp)) {
                    content()
                }
            }
        }
    }
}

@Composable
private fun FieldToggleRow(
    title: String,
    description: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onCheckedChange(!checked) }
            .padding(vertical = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(title, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
            Text(description, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 11.sp)
        }
        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange
        )
    }
}
