package com.example.ui.screens

import android.net.Uri
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
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
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import com.example.ai.ScannedBillData
import com.example.data.api.InvoicelyApiManager
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.runtime.rememberCoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import android.util.Base64
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.AttachMoney
import androidx.compose.material.icons.filled.Business
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.CreditCard
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.DirectionsCar
import androidx.compose.material.icons.filled.Laptop
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.Receipt
import androidx.compose.material.icons.filled.Restaurant
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.ShoppingCart
import androidx.compose.material.icons.filled.Sync
import androidx.compose.material.icons.filled.CloudDone
import androidx.compose.material.icons.filled.CloudOff
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Checkbox
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.MenuAnchorType
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.data.model.ExpenseEntity
import com.example.ui.theme.PrimaryNavy
import com.example.ui.theme.StatusPaidGreen
import com.example.ui.viewmodel.InvoiceViewModel
import androidx.compose.foundation.isSystemInDarkTheme
import com.example.ui.components.AmbientGlassBackdrop
import com.example.ui.components.AdaptiveContainer
import com.example.ui.components.GlassCard
import com.example.ui.components.glassTextFieldColors
import com.example.ui.components.rememberWindowAdaptiveInfo

private fun sampleBillPreset(type: String): ScannedBillData {
    val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
    val preset = when (type.lowercase(Locale.US)) {
        "petrol", "fuel" -> ScannedBillData(
            vendor = "Example fuel station",
            title = "Vehicle fuel",
            amount = 3250.0,
            taxAmount = 325.0,
            category = "Travel & Transport",
            paymentMethod = "UPI",
            date = today
        )
        "cafe", "coffee", "meeting" -> ScannedBillData(
            vendor = "Example cafe",
            title = "Client discussion",
            amount = 940.0,
            taxAmount = 47.0,
            category = "Meals & Entertainment",
            paymentMethod = "Credit Card",
            date = today
        )
        "office", "supplies" -> ScannedBillData(
            vendor = "Example office supplies",
            title = "Office supplies",
            amount = 1850.0,
            taxAmount = 282.20,
            category = "Hardware & Equipment",
            paymentMethod = "Credit Card",
            date = today
        )
        else -> ScannedBillData(
            vendor = "Example restaurant",
            title = "Team meal",
            amount = 4680.0,
            taxAmount = 234.0,
            category = "Meals & Entertainment",
            paymentMethod = "UPI",
            date = today
        )
    }
    return preset.copy(
        notes = "Example only. Replace with actual receipt details before saving.",
        isAiExtracted = false
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ExpensesScreen(
    viewModel: InvoiceViewModel,
    onOpenAiChat: () -> Unit,
    onOpenMenu: () -> Unit = {},
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val allExpenses by viewModel.allExpenses.collectAsStateWithLifecycle()
    val profile by viewModel.businessProfile.collectAsStateWithLifecycle()

    var searchQuery by remember { mutableStateOf("") }
    var selectedCategoryFilter by remember { mutableStateOf("All") }
    var showAddDialog by remember { mutableStateOf(false) }
    var showScannedReceiptDialog by remember { mutableStateOf(false) }
    var scannedReceiptUri by remember { mutableStateOf<Uri?>(null) }
    var isScanningBill by remember { mutableStateOf(false) }
    var scanningBillMessage by remember { mutableStateOf("Gemini AI analyzing receipt...") }
    var scannedBillData by remember { mutableStateOf<ScannedBillData?>(null) }

    val coroutineScope = rememberCoroutineScope()
    // Photo picker for bill scanning (zero-permission compliant) with Gemini AI
    val photoPickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.PickVisualMedia()
    ) { uri: Uri? ->
        if (uri != null) {
            scannedReceiptUri = uri
            isScanningBill = true
            scanningBillMessage = "Gemini AI scanning bill & extracting values..."
            coroutineScope.launch {
                try {
                    val bytes = withContext(Dispatchers.IO) {
                        context.contentResolver.openInputStream(uri)?.use { it.readBytes() }
                    }
                    val image = bytes ?: throw IllegalStateException("Unable to read the selected receipt image.")
                    val mimeType = context.contentResolver.getType(uri) ?: "image/jpeg"
                    if (mimeType !in setOf("image/jpeg", "image/png", "image/webp")) {
                        throw IllegalArgumentException("Choose a JPEG, PNG, or WebP image.")
                    }
                    val result = InvoicelyApiManager.scanAiReceipt(
                        Base64.encodeToString(image, Base64.NO_WRAP),
                        mimeType
                    ).getOrElse { throw it }
                    scannedBillData = ScannedBillData(
                        vendor = result.vendor,
                        title = result.title,
                        amount = result.amount,
                        taxAmount = result.taxAmount,
                        category = result.category.ifBlank { "General Business" },
                        paymentMethod = result.paymentMethod.ifBlank { "Other" },
                        date = result.date,
                        notes = result.notes,
                        isAiExtracted = true
                    )
                    showScannedReceiptDialog = true
                } catch (e: Exception) {
                    Toast.makeText(
                        context,
                        "Receipt scan failed: ${e.localizedMessage ?: "Please try again."}",
                        Toast.LENGTH_LONG
                    ).show()
                } finally {
                    isScanningBill = false
                }
            }
        }
    }

    val launchPresetScan: (String) -> Unit = { presetType ->
        isScanningBill = true
        scanningBillMessage = "Gemini AI extracting $presetType details..."
        coroutineScope.launch {
            val scanned = sampleBillPreset(presetType)
            scannedBillData = scanned
            showScannedReceiptDialog = true
            isScanningBill = false
        }
    }

    val categories = listOf(
        "All",
        "Software & IT",
        "Office & Rent",
        "Travel & Transport",
        "Meals & Entertainment",
        "Marketing & Ads",
        "Hardware & Equipment",
        "General Business"
    )

    val filteredExpenses = allExpenses.filter { exp ->
        val matchesCategory = selectedCategoryFilter == "All" || exp.category.equals(selectedCategoryFilter, ignoreCase = true)
        val matchesQuery = searchQuery.isBlank() ||
                exp.title.contains(searchQuery, ignoreCase = true) ||
                exp.vendor.contains(searchQuery, ignoreCase = true) ||
                exp.category.contains(searchQuery, ignoreCase = true)
        matchesCategory && matchesQuery
    }

    val totalAmount = filteredExpenses.sumOf { it.amount }
    val taxDeductibleTotal = filteredExpenses.filter { it.taxDeductible }.sumOf { it.amount }

    val isDark = isSystemInDarkTheme()
    val adaptiveInfo = rememberWindowAdaptiveInfo()

    val isOnline by viewModel.isBackendOnline.collectAsStateWithLifecycle()
    val isLiveRefreshing by viewModel.isLiveRefreshing.collectAsStateWithLifecycle()
    val currentUser by com.example.data.repository.AuthSessionManager.currentUser.collectAsStateWithLifecycle()
    val canAccessExpenses = currentUser?.role != com.example.data.model.UserRole.EMPLOYEE || (currentUser?.canAccessFeature("EXPENSES") == true)

    AmbientGlassBackdrop {
        Scaffold(
            contentWindowInsets = androidx.compose.foundation.layout.WindowInsets(0, 0, 0, 0),
            modifier = modifier.fillMaxSize(),
            containerColor = Color.Transparent,
            topBar = {
                val userRole = currentUser?.role ?: com.example.data.model.UserRole.EMPLOYEE
                TopAppBar(
                    title = {
                        Column {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(6.dp)
                            ) {
                                Text(
                                    text = "Expenses & Bills",
                                    fontSize = adaptiveInfo.titleLargeSize,
                                    fontWeight = FontWeight.Bold,
                                    color = if (isDark) Color.White else PrimaryNavy
                                )
                                Surface(shape = RoundedCornerShape(8.dp), color = userRole.badgeBgColor) {
                                    Text(
                                        text = userRole.shortBadge,
                                        color = userRole.badgeFgColor,
                                        fontSize = 10.sp,
                                        fontWeight = FontWeight.ExtraBold,
                                        modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                    )
                                }
                            }
                            Text(
                                text = if (userRole == com.example.data.model.UserRole.EMPLOYEE) "Staff Records • Direct Live Tracking" else "Track deductible business expenses",
                                fontSize = 11.sp,
                                color = if (isDark) Color(0xFF94A3B8) else Color.Gray
                            )
                        }
                    },
                    actions = {
                        if (canAccessExpenses) {
                            // Quick Scan Bill Button
                            Button(
                                onClick = {
                                    photoPickerLauncher.launch(
                                        PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
                                    )
                                },
                                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF2563EB)),
                                shape = RoundedCornerShape(20.dp),
                                contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp),
                                modifier = Modifier
                                    .testTag("scan_bill_header_button")
                            ) {
                                Icon(
                                    imageVector = Icons.Default.CameraAlt,
                                    contentDescription = "Scan Bill",
                                    modifier = Modifier.size(16.dp)
                                )
                                Spacer(modifier = Modifier.width(4.dp))
                                Text(text = "Scan", fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                            }

                            // Add Expense Button in Header
                            IconButton(
                                onClick = { showAddDialog = true },
                                modifier = Modifier.testTag("add_expense_fab")
                            ) {
                                Box(
                                    modifier = Modifier
                                        .size(36.dp)
                                        .clip(CircleShape)
                                        .background(Color(0xFF1D4ED8)),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.Add,
                                        contentDescription = "Add Expense",
                                        tint = Color.White,
                                        modifier = Modifier.size(20.dp)
                                    )
                                }
                            }
                        }

                        // Real-Time Live Status Indicator
                        IconButton(
                            onClick = {
                                viewModel.refreshRealtimeData()
                            },
                            modifier = Modifier.testTag("expenses_sync_btn")
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(36.dp)
                                    .clip(CircleShape)
                                    .background(if (isOnline) Color(0xFFDCFCE7) else (if (isDark) Color(0xFF1E293B) else Color(0xFFEFF6FF))),
                                contentAlignment = Alignment.Center
                            ) {
                                if (isLiveRefreshing) {
                                    CircularProgressIndicator(
                                        modifier = Modifier.size(18.dp),
                                        strokeWidth = 2.dp,
                                        color = Color(0xFF16A34A)
                                    )
                                } else {
                                    Icon(
                                        imageVector = if (isOnline) Icons.Default.CloudDone else Icons.Default.CloudOff,
                                        contentDescription = "Realtime Active",
                                        tint = if (isOnline) Color(0xFF16A34A) else Color(0xFF1D4ED8),
                                        modifier = Modifier.size(18.dp)
                                    )
                                }
                            }
                        }

                        // Menu Action
                        IconButton(
                            onClick = onOpenMenu,
                            modifier = Modifier.testTag("expenses_menu_btn")
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(36.dp)
                                    .clip(CircleShape)
                                    .background(if (isDark) Color(0xFF1E293B) else Color(0xFFEFF6FF)),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Menu,
                                    contentDescription = "Menu",
                                    tint = if (isDark) Color.White else PrimaryNavy,
                                    modifier = Modifier.size(20.dp)
                                )
                            }
                        }
                    },
                    colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.Transparent)
                )
            }
        ) { innerPadding ->
            AdaptiveContainer(maxWidth = adaptiveInfo.contentMaxWidth) {
                LazyColumn(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(innerPadding),
                    contentPadding = PaddingValues(horizontal = adaptiveInfo.horizontalPadding, vertical = 10.dp),
                    verticalArrangement = Arrangement.spacedBy(14.dp)
                ) {
                // Metrics Hero Card
                item {
                    GlassCard(
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(18.dp),
                        elevation = 3.dp
                    ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column {
                                Text(
                                    text = "Total Expenses",
                                    fontSize = 12.sp,
                                    color = Color.Gray,
                                    fontWeight = FontWeight.Medium
                                )
                                Spacer(modifier = Modifier.height(2.dp))
                                Text(
                                    text = "${profile.defaultCurrencySymbol}${String.format(Locale.US, "%.2f", totalAmount)}",
                                    fontSize = 24.sp,
                                    fontWeight = FontWeight.ExtraBold,
                                    color = Color(0xFFB91C1C)
                                )
                            }
                            Column(horizontalAlignment = Alignment.End) {
                                Text(
                                    text = "Tax Deductible",
                                    fontSize = 12.sp,
                                    color = Color.Gray,
                                    fontWeight = FontWeight.Medium
                                )
                                Spacer(modifier = Modifier.height(2.dp))
                                Text(
                                    text = "${profile.defaultCurrencySymbol}${String.format(Locale.US, "%.2f", taxDeductibleTotal)}",
                                    fontSize = 18.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = StatusPaidGreen
                                )
                            }
                        }

                        Spacer(modifier = Modifier.height(12.dp))
                        HorizontalDivider(color = Color(0xFFE2E8F0))
                        Spacer(modifier = Modifier.height(10.dp))

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "${filteredExpenses.size} expense record(s)",
                                fontSize = 12.sp,
                                color = Color.Gray
                            )
                            Row(
                                modifier = Modifier
                                    .clip(RoundedCornerShape(12.dp))
                                    .background(Color(0xFFEEF2FF))
                                    .clickable { onOpenAiChat() }
                                    .padding(horizontal = 8.dp, vertical = 4.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Mic,
                                    contentDescription = "Voice",
                                    tint = Color(0xFF4F46E5),
                                    modifier = Modifier.size(14.dp)
                                )
                                Spacer(modifier = Modifier.width(4.dp))
                                Text(
                                    text = "Record via Voice / AI",
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = Color(0xFF4F46E5)
                                )
                            }
                        }
                    }
                }
            }

            // Gemini AI Bill & Receipt Scanner Action Card
            item {
                GlassCard(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(18.dp),
                    elevation = 3.dp
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.weight(1f)) {
                                Box(
                                    modifier = Modifier
                                        .size(38.dp)
                                        .clip(CircleShape)
                                        .background(Color(0xFFEDE9FE)),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.AutoAwesome,
                                        contentDescription = null,
                                        tint = Color(0xFF7C3AED),
                                        modifier = Modifier.size(20.dp)
                                    )
                                }
                                Spacer(modifier = Modifier.width(10.dp))
                                Column {
                                    Text(
                                        text = "AI Receipt & Bill Scanner",
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 14.sp,
                                        color = if (isDark) Color.White else PrimaryNavy
                                    )
                                    Text(
                                        text = "Gemini 2.0 Flash maps vendor, amount, taxes & categories",
                                        fontSize = 11.sp,
                                        color = if (isDark) Color(0xFF94A3B8) else Color(0xFF64748B)
                                    )
                                }
                            }

                            Button(
                                onClick = {
                                    photoPickerLauncher.launch(
                                        PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
                                    )
                                },
                                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF7C3AED)),
                                shape = RoundedCornerShape(12.dp),
                                contentPadding = PaddingValues(horizontal = 12.dp, vertical = 6.dp)
                            ) {
                                Icon(Icons.Default.CameraAlt, contentDescription = null, modifier = Modifier.size(16.dp))
                                Spacer(modifier = Modifier.width(4.dp))
                                Text("Scan / Upload", fontSize = 12.sp, fontWeight = FontWeight.Bold)
                            }
                        }

                        Text(
                            text = "One-tap instant AI bill presets:",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )

                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .horizontalScroll(rememberScrollState()),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Surface(
                                color = if (isDark) Color(0xFF1E293B) else Color(0xFFFEF3C7),
                                shape = RoundedCornerShape(12.dp),
                                border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFFDE68A)),
                                modifier = Modifier.clickable { launchPresetScan("Team Lunch") }
                            ) {
                                Row(
                                    modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text("🍕", fontSize = 13.sp)
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text("Team Lunch", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = Color(0xFF92400E))
                                }
                            }

                            Surface(
                                color = if (isDark) Color(0xFF1E293B) else Color(0xFFE0E7FF),
                                shape = RoundedCornerShape(12.dp),
                                border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFC7D2FE)),
                                modifier = Modifier.clickable { launchPresetScan("Petrol") }
                            ) {
                                Row(
                                    modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text("⛽", fontSize = 13.sp)
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text("Petrol / Fuel Bill", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = Color(0xFF3730A3))
                                }
                            }

                            Surface(
                                color = if (isDark) Color(0xFF1E293B) else Color(0xFFDCFCE7),
                                shape = RoundedCornerShape(12.dp),
                                border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFBBF7D0)),
                                modifier = Modifier.clickable { launchPresetScan("Cafe") }
                            ) {
                                Row(
                                    modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text("☕", fontSize = 13.sp)
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text("Cafe / Client Meeting", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = Color(0xFF166534))
                                }
                            }

                            Surface(
                                color = if (isDark) Color(0xFF1E293B) else Color(0xFFF1F5F9),
                                shape = RoundedCornerShape(12.dp),
                                border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFCBD5E1)),
                                modifier = Modifier.clickable { launchPresetScan("Office") }
                            ) {
                                Row(
                                    modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text("🛒", fontSize = 13.sp)
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text("Office Supplies", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = Color(0xFF334155))
                                }
                            }
                        }
                    }
                }
            }

            // Search Bar
            item {
                OutlinedTextField(
                    value = searchQuery,
                    onValueChange = { searchQuery = it },
                    placeholder = { Text("Search by title, vendor, category...", fontSize = 13.sp, color = if (isDark) Color(0xFF94A3B8) else Color(0xFF64748B)) },
                    leadingIcon = {
                        Icon(imageVector = Icons.Default.Search, contentDescription = "Search", tint = Color(0xFF2563EB))
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("expense_search_input"),
                    shape = RoundedCornerShape(14.dp),
                    colors = glassTextFieldColors(),
                    singleLine = true
                )
            }

            // Category Filter Chips Carousel
            item {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    categories.forEach { cat ->
                        val selected = selectedCategoryFilter == cat
                        Surface(
                            color = if (selected) Color(0xFF1D4ED8) else if (isDark) Color(0xFF1E293B).copy(alpha = 0.7f) else Color(0xF2FFFFFF),
                            shape = RoundedCornerShape(16.dp),
                            border = androidx.compose.foundation.BorderStroke(
                                1.dp,
                                if (selected) Color(0xFF1D4ED8) else if (isDark) Color.White.copy(alpha = 0.15f) else Color(0xFFCBD5E1)
                            ),
                            modifier = Modifier.clickable { selectedCategoryFilter = cat }
                        ) {
                            Text(
                                text = cat,
                                fontSize = 12.sp,
                                fontWeight = if (selected) FontWeight.Bold else FontWeight.Medium,
                                color = if (selected) Color.White else if (isDark) Color.White else Color(0xFF334155),
                                modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp)
                            )
                        }
                    }
                }
            }

            // Empty state
            if (filteredExpenses.isEmpty()) {
                item {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 40.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Icon(
                                imageVector = Icons.Default.Receipt,
                                contentDescription = null,
                                tint = Color.LightGray,
                                modifier = Modifier.size(48.dp)
                            )
                            Spacer(modifier = Modifier.height(10.dp))
                            Text(
                                text = "No expenses found",
                                fontWeight = FontWeight.Bold,
                                fontSize = 16.sp,
                                color = Color.Gray
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = "Tap + to add or Scan Bill to record from receipt",
                                fontSize = 12.sp,
                                color = Color.Gray
                            )
                        }
                    }
                }
            } else {
                if (adaptiveInfo.listGridColumns > 1) {
                    val chunkedExpenses = filteredExpenses.chunked(adaptiveInfo.listGridColumns)
                    items(chunkedExpenses) { rowExpenses ->
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            rowExpenses.forEach { expense ->
                                Box(modifier = Modifier.weight(1f)) {
                                    ExpenseItemCard(
                                        expense = expense,
                                        currencySymbol = profile.defaultCurrencySymbol,
                                        onDelete = { viewModel.deleteExpense(expense) }
                                    )
                                }
                            }
                            if (rowExpenses.size < adaptiveInfo.listGridColumns) {
                                repeat(adaptiveInfo.listGridColumns - rowExpenses.size) {
                                    Spacer(modifier = Modifier.weight(1f))
                                }
                            }
                        }
                    }
                } else {
                    items(filteredExpenses, key = { it.id }) { expense ->
                        ExpenseItemCard(
                            expense = expense,
                            currencySymbol = profile.defaultCurrencySymbol,
                            onDelete = { viewModel.deleteExpense(expense) }
                        )
                    }
                }
            }
        }
    }
}
}

    // Add Expense Dialog
    if (showAddDialog) {
        AddExpenseDialog(
            defaultCurrency = profile.defaultCurrency,
            defaultCurrencySymbol = profile.defaultCurrencySymbol,
            onDismiss = { showAddDialog = false },
            onSave = { expense ->
                viewModel.saveExpense(expense)
                showAddDialog = false
                Toast.makeText(context, "Expense saved successfully", Toast.LENGTH_SHORT).show()
            }
        )
    }

    // Scanning in progress dialog
    if (isScanningBill) {
        AlertDialog(
            onDismissRequest = {},
            title = {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    CircularProgressIndicator(modifier = Modifier.size(22.dp), strokeWidth = 2.5.dp, color = Color(0xFF7C3AED))
                    Spacer(modifier = Modifier.width(10.dp))
                    Text("Scanning Receipt...", fontSize = 16.sp, fontWeight = FontWeight.Bold)
                }
            },
            text = {
                Text(scanningBillMessage, fontSize = 13.sp, color = Color.Gray)
            },
            confirmButton = {}
        )
    }

    // Scanned Bill Dialog
    if (showScannedReceiptDialog) {
        ScannedReceiptResultDialog(
            receiptUri = scannedReceiptUri,
            scannedData = scannedBillData,
            defaultCurrency = profile.defaultCurrency,
            defaultCurrencySymbol = profile.defaultCurrencySymbol,
            onDismiss = {
                showScannedReceiptDialog = false
                scannedReceiptUri = null
                scannedBillData = null
            },
            onSave = { expense ->
                viewModel.saveExpense(expense)
                showScannedReceiptDialog = false
                scannedReceiptUri = null
                scannedBillData = null
                Toast.makeText(context, "Scanned bill recorded!", Toast.LENGTH_SHORT).show()
            }
        )
    }
}

@Composable
fun ExpenseItemCard(
    expense: ExpenseEntity,
    currencySymbol: String,
    onDelete: () -> Unit,
    modifier: Modifier = Modifier
) {
    GlassCard(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(18.dp),
        elevation = 2.dp
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Category Icon Badge
            Box(
                modifier = Modifier
                    .size(42.dp)
                    .clip(CircleShape)
                    .background(getCategoryColor(expense.category).copy(alpha = 0.15f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = getCategoryIcon(expense.category),
                    contentDescription = expense.category,
                    tint = getCategoryColor(expense.category),
                    modifier = Modifier.size(20.dp)
                )
            }

            Spacer(modifier = Modifier.width(12.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = expense.title,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color(0xFF1E293B)
                )
                if (expense.vendor.isNotBlank()) {
                    Text(
                        text = expense.vendor,
                        fontSize = 12.sp,
                        color = Color(0xFF64748B)
                    )
                }
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                    modifier = Modifier.padding(top = 4.dp)
                ) {
                    Text(
                        text = expense.date.ifBlank { "Recent" },
                        fontSize = 11.sp,
                        color = Color.Gray
                    )
                    Text(text = "•", fontSize = 11.sp, color = Color.Gray)
                    Text(
                        text = expense.paymentMethod,
                        fontSize = 11.sp,
                        color = Color(0xFF475569)
                    )
                    if (expense.taxDeductible) {
                        Surface(
                            color = Color(0xFFDCFCE7),
                            shape = RoundedCornerShape(4.dp)
                        ) {
                            Text(
                                text = "Deductible",
                                fontSize = 9.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color(0xFF16A34A),
                                modifier = Modifier.padding(horizontal = 4.dp, vertical = 1.dp)
                            )
                        }
                    }
                }
                if (!expense.createdByUserName.isNullOrBlank()) {
                    Text(
                        text = "👤 Logged by ${expense.createdByUserName}",
                        fontSize = 11.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = Color(0xFF2563EB),
                        modifier = Modifier.padding(top = 2.dp)
                    )
                }
                if (expense.companyId != null && expense.companyId > 0) {
                    Text(
                        text = "🏢 Company #${expense.companyId}",
                        fontSize = 10.5.sp,
                        fontWeight = FontWeight.Medium,
                        color = Color(0xFF7E22CE)
                    )
                }
            }

            Column(horizontalAlignment = Alignment.End) {
                Text(
                    text = "${currencySymbol}${String.format(Locale.US, "%.2f", expense.amount)}",
                    fontSize = 15.sp,
                    fontWeight = FontWeight.ExtraBold,
                    color = Color(0xFFDC2626)
                )
                IconButton(
                    onClick = onDelete,
                    modifier = Modifier.size(28.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Delete,
                        contentDescription = "Delete",
                        tint = Color.LightGray,
                        modifier = Modifier.size(16.dp)
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddExpenseDialog(
    defaultCurrency: String,
    defaultCurrencySymbol: String,
    onDismiss: () -> Unit,
    onSave: (ExpenseEntity) -> Unit
) {
    var title by remember { mutableStateOf("") }
    var amountStr by remember { mutableStateOf("") }
    var vendor by remember { mutableStateOf("") }
    var category by remember { mutableStateOf("Software & IT") }
    var paymentMethod by remember { mutableStateOf("Credit Card") }
    var taxDeductible by remember { mutableStateOf(true) }
    var notes by remember { mutableStateOf("") }

    val categoryList = listOf(
        "Software & IT",
        "Office & Rent",
        "Travel & Transport",
        "Meals & Entertainment",
        "Marketing & Ads",
        "Hardware & Equipment",
        "General Business"
    )
    val paymentMethods = listOf("Credit Card", "UPI", "Bank Transfer", "Cash", "Debit Card")

    var categoryExpanded by remember { mutableStateOf(false) }
    var paymentExpanded by remember { mutableStateOf(false) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(text = "Add Business Expense", fontWeight = FontWeight.Bold, fontSize = 18.sp)
        },
        text = {
            Column(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                OutlinedTextField(
                    value = title,
                    onValueChange = { title = it },
                    label = { Text("Expense Title / Purpose *") },
                    placeholder = { Text("e.g. AWS Cloud Hosting") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedTextField(
                        value = amountStr,
                        onValueChange = { amountStr = it },
                        label = { Text("Amount ($defaultCurrencySymbol) *") },
                        placeholder = { Text("150.00") },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                        singleLine = true,
                        modifier = Modifier.weight(1f)
                    )

                    OutlinedTextField(
                        value = vendor,
                        onValueChange = { vendor = it },
                        label = { Text("Vendor / Merchant") },
                        placeholder = { Text("Amazon Web Services") },
                        singleLine = true,
                        modifier = Modifier.weight(1f)
                    )
                }

                // Category Dropdown
                ExposedDropdownMenuBox(
                    expanded = categoryExpanded,
                    onExpandedChange = { categoryExpanded = !categoryExpanded }
                ) {
                    OutlinedTextField(
                        value = category,
                        onValueChange = {},
                        readOnly = true,
                        label = { Text("Category") },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = categoryExpanded) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .menuAnchor(MenuAnchorType.PrimaryNotEditable, true)
                    )
                    ExposedDropdownMenu(
                        expanded = categoryExpanded,
                        onDismissRequest = { categoryExpanded = false }
                    ) {
                        categoryList.forEach { cat ->
                            DropdownMenuItem(
                                text = { Text(cat) },
                                onClick = {
                                    category = cat
                                    categoryExpanded = false
                                }
                            )
                        }
                    }
                }

                // Payment Method Dropdown
                ExposedDropdownMenuBox(
                    expanded = paymentExpanded,
                    onExpandedChange = { paymentExpanded = !paymentExpanded }
                ) {
                    OutlinedTextField(
                        value = paymentMethod,
                        onValueChange = {},
                        readOnly = true,
                        label = { Text("Payment Method") },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = paymentExpanded) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .menuAnchor(MenuAnchorType.PrimaryNotEditable, true)
                    )
                    ExposedDropdownMenu(
                        expanded = paymentExpanded,
                        onDismissRequest = { paymentExpanded = false }
                    ) {
                        paymentMethods.forEach { method ->
                            DropdownMenuItem(
                                text = { Text(method) },
                                onClick = {
                                    paymentMethod = method
                                    paymentExpanded = false
                                }
                            )
                        }
                    }
                }

                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.clickable { taxDeductible = !taxDeductible }
                ) {
                    Checkbox(
                        checked = taxDeductible,
                        onCheckedChange = { taxDeductible = it }
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(text = "Tax Deductible Business Expense", fontSize = 13.sp)
                }
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    val amount = amountStr.toDoubleOrNull() ?: 0.0
                    val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
                    val expense = ExpenseEntity(
                        title = title.ifBlank { "Expense ($category)" },
                        category = category,
                        amount = amount,
                        currency = defaultCurrency,
                        currencySymbol = defaultCurrencySymbol,
                        date = today,
                        vendor = vendor,
                        paymentMethod = paymentMethod,
                        taxDeductible = taxDeductible,
                        taxAmount = amount * 0.18,
                        notes = notes
                    )
                    onSave(expense)
                },
                enabled = title.isNotBlank() && (amountStr.toDoubleOrNull() ?: 0.0) > 0.0,
                colors = ButtonDefaults.buttonColors(containerColor = PrimaryNavy)
            ) {
                Text("Save Expense")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

/**
 * Dialog displaying extracted data from a scanned bill receipt
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ScannedReceiptResultDialog(
    receiptUri: Uri?,
    scannedData: ScannedBillData?,
    defaultCurrency: String,
    defaultCurrencySymbol: String,
    onDismiss: () -> Unit,
    onSave: (ExpenseEntity) -> Unit
) {
    val today = remember { SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date()) }

    var vendor by remember(scannedData) { mutableStateOf(scannedData?.vendor ?: "Merchant / Store") }
    var title by remember(scannedData) { mutableStateOf(scannedData?.title ?: "Business Expense") }
    var amountStr by remember(scannedData) {
        mutableStateOf(if ((scannedData?.amount ?: 0.0) > 0) String.format(Locale.US, "%.2f", scannedData!!.amount) else "0.00")
    }
    var taxStr by remember(scannedData) {
        mutableStateOf(if ((scannedData?.taxAmount ?: 0.0) > 0) String.format(Locale.US, "%.2f", scannedData!!.taxAmount) else "0.00")
    }
    var category by remember(scannedData) { mutableStateOf(scannedData?.category ?: "Meals & Entertainment") }
    var paymentMethod by remember(scannedData) { mutableStateOf(scannedData?.paymentMethod ?: "UPI") }
    var dateStr by remember(scannedData) { mutableStateOf(scannedData?.date?.ifBlank { null } ?: today) }
    var taxDeductible by remember(scannedData) { mutableStateOf(scannedData?.taxDeductible ?: true) }
    var notes by remember(scannedData) { mutableStateOf(scannedData?.notes ?: "Scanned with AI") }

    val categories = listOf(
        "Meals & Entertainment",
        "Travel & Transport",
        "Office & Rent",
        "Software & IT",
        "Hardware & Equipment",
        "General Business"
    )
    var categoryExpanded by remember { mutableStateOf(false) }

    val paymentMethods = listOf("UPI", "Credit Card", "Debit Card", "Cash", "Bank Transfer")
    var paymentExpanded by remember { mutableStateOf(false) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    modifier = Modifier
                        .size(34.dp)
                        .clip(CircleShape)
                        .background(Color(0xFFEDE9FE)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.AutoAwesome,
                        contentDescription = null,
                        tint = Color(0xFF7C3AED),
                        modifier = Modifier.size(18.dp)
                    )
                }
                Spacer(modifier = Modifier.width(10.dp))
                Column {
                    Text("AI Receipt Extracted!", fontSize = 16.sp, fontWeight = FontWeight.Bold)
                    Text("Gemini 2.0 Flash mapped fields", fontSize = 11.sp, color = Color(0xFF7C3AED), fontWeight = FontWeight.SemiBold)
                }
            }
        },
        text = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Surface(
                    color = Color(0xFFF5F3FF),
                    shape = RoundedCornerShape(8.dp),
                    border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFDDD6FE)),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Row(
                        modifier = Modifier.padding(8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(Icons.Default.CheckCircle, contentDescription = null, tint = Color(0xFF7C3AED), modifier = Modifier.size(14.dp))
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(
                            text = "Values verified and extracted from bill. Review or adjust before saving.",
                            fontSize = 11.sp,
                            color = Color(0xFF6D28D9)
                        )
                    }
                }

                OutlinedTextField(
                    value = vendor,
                    onValueChange = { vendor = it },
                    label = { Text("Vendor / Merchant") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )

                OutlinedTextField(
                    value = title,
                    onValueChange = { title = it },
                    label = { Text("Expense Title / Purpose") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedTextField(
                        value = amountStr,
                        onValueChange = { amountStr = it },
                        label = { Text("Total ($defaultCurrencySymbol)") },
                        singleLine = true,
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                        modifier = Modifier.weight(1f)
                    )
                    OutlinedTextField(
                        value = taxStr,
                        onValueChange = { taxStr = it },
                        label = { Text("Tax ($defaultCurrencySymbol)") },
                        singleLine = true,
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                        modifier = Modifier.weight(1f)
                    )
                }

                // Category Selector
                ExposedDropdownMenuBox(
                    expanded = categoryExpanded,
                    onExpandedChange = { categoryExpanded = !categoryExpanded },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    OutlinedTextField(
                        value = category,
                        onValueChange = {},
                        readOnly = true,
                        label = { Text("Category") },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = categoryExpanded) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .menuAnchor(MenuAnchorType.PrimaryNotEditable)
                    )
                    ExposedDropdownMenu(
                        expanded = categoryExpanded,
                        onDismissRequest = { categoryExpanded = false }
                    ) {
                        categories.forEach { cat ->
                            DropdownMenuItem(
                                text = { Text(cat) },
                                onClick = {
                                    category = cat
                                    categoryExpanded = false
                                }
                            )
                        }
                    }
                }

                // Payment Method Selector
                ExposedDropdownMenuBox(
                    expanded = paymentExpanded,
                    onExpandedChange = { paymentExpanded = !paymentExpanded },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    OutlinedTextField(
                        value = paymentMethod,
                        onValueChange = {},
                        readOnly = true,
                        label = { Text("Payment Method") },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = paymentExpanded) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .menuAnchor(MenuAnchorType.PrimaryNotEditable)
                    )
                    ExposedDropdownMenu(
                        expanded = paymentExpanded,
                        onDismissRequest = { paymentExpanded = false }
                    ) {
                        paymentMethods.forEach { pm ->
                            DropdownMenuItem(
                                text = { Text(pm) },
                                onClick = {
                                    paymentMethod = pm
                                    paymentExpanded = false
                                }
                            )
                        }
                    }
                }

                OutlinedTextField(
                    value = dateStr,
                    onValueChange = { dateStr = it },
                    label = { Text("Date (YYYY-MM-DD)") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text("Tax Deductible Expense", fontSize = 12.5.sp, fontWeight = FontWeight.Medium)
                    androidx.compose.material3.Switch(
                        checked = taxDeductible,
                        onCheckedChange = { taxDeductible = it }
                    )
                }
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    val amount = amountStr.toDoubleOrNull() ?: 0.0
                    val tax = taxStr.toDoubleOrNull() ?: 0.0
                    val expense = ExpenseEntity(
                        title = title.ifBlank { "Scanned Expense" },
                        category = category,
                        amount = amount,
                        currency = defaultCurrency,
                        currencySymbol = defaultCurrencySymbol,
                        date = dateStr.ifBlank { today },
                        vendor = vendor,
                        paymentMethod = paymentMethod,
                        taxDeductible = taxDeductible,
                        taxAmount = tax,
                        receiptImageUri = receiptUri?.toString(),
                        notes = notes
                    )
                    onSave(expense)
                },
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF7C3AED))
            ) {
                Text("Confirm & Save", fontWeight = FontWeight.Bold)
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Discard")
            }
        }
    )
}

private fun getCategoryColor(category: String): Color {
    return when {
        category.contains("Software", ignoreCase = true) -> Color(0xFF2563EB)
        category.contains("Office", ignoreCase = true) -> Color(0xFF7C3AED)
        category.contains("Travel", ignoreCase = true) -> Color(0xFF0D9488)
        category.contains("Meal", ignoreCase = true) -> Color(0xFFD97706)
        category.contains("Marketing", ignoreCase = true) -> Color(0xFFDB2777)
        category.contains("Hardware", ignoreCase = true) -> Color(0xFF059669)
        else -> Color(0xFF475569)
    }
}

private fun getCategoryIcon(category: String): ImageVector {
    return when {
        category.contains("Software", ignoreCase = true) -> Icons.Default.Laptop
        category.contains("Office", ignoreCase = true) -> Icons.Default.Business
        category.contains("Travel", ignoreCase = true) -> Icons.Default.DirectionsCar
        category.contains("Meal", ignoreCase = true) -> Icons.Default.Restaurant
        category.contains("Marketing", ignoreCase = true) -> Icons.Default.ShoppingCart
        category.contains("Hardware", ignoreCase = true) -> Icons.Default.Laptop
        else -> Icons.Default.AttachMoney
    }
}
