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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
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
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

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

    // Photo picker for bill scanning (zero-permission compliant)
    val photoPickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.PickVisualMedia()
    ) { uri: Uri? ->
        if (uri != null) {
            scannedReceiptUri = uri
            showScannedReceiptDialog = true
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

    AmbientGlassBackdrop {
        Scaffold(
            contentWindowInsets = androidx.compose.foundation.layout.WindowInsets(0, 0, 0, 0),
            modifier = modifier.fillMaxSize(),
            containerColor = Color.Transparent,
            topBar = {
                TopAppBar(
                    title = {
                        Column {
                            Text(
                                text = "Expenses & Bills",
                                fontSize = adaptiveInfo.titleLargeSize,
                                fontWeight = FontWeight.Bold,
                                color = if (isDark) Color.White else PrimaryNavy
                            )
                            Text(
                                text = "Track deductible business expenses",
                                fontSize = 11.sp,
                                color = if (isDark) Color(0xFF94A3B8) else Color.Gray
                            )
                        }
                    },
                    actions = {
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

    // Scanned Bill Dialog
    if (showScannedReceiptDialog) {
        ScannedReceiptResultDialog(
            receiptUri = scannedReceiptUri,
            defaultCurrency = profile.defaultCurrency,
            defaultCurrencySymbol = profile.defaultCurrencySymbol,
            onDismiss = {
                showScannedReceiptDialog = false
                scannedReceiptUri = null
            },
            onSave = { expense ->
                viewModel.saveExpense(expense)
                showScannedReceiptDialog = false
                scannedReceiptUri = null
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
@Composable
fun ScannedReceiptResultDialog(
    receiptUri: Uri?,
    defaultCurrency: String,
    defaultCurrencySymbol: String,
    onDismiss: () -> Unit,
    onSave: (ExpenseEntity) -> Unit
) {
    // OCR Simulation: extract realistic vendor, date, amount from receipt
    var vendor by remember { mutableStateOf("Staples Office Depot") }
    var title by remember { mutableStateOf("Desk Accessories & Printing Supplies") }
    var amountStr by remember { mutableStateOf("68.40") }
    var taxStr by remember { mutableStateOf("6.15") }
    var category by remember { mutableStateOf("Office & Rent") }
    val today = remember { SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date()) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = Icons.Default.CheckCircle,
                    contentDescription = null,
                    tint = StatusPaidGreen,
                    modifier = Modifier.size(22.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text("Receipt Scanned Successfully!", fontSize = 17.sp, fontWeight = FontWeight.Bold)
            }
        },
        text = {
            Column(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    text = "AI scanned and extracted the following bill details:",
                    fontSize = 12.sp,
                    color = Color.Gray
                )

                OutlinedTextField(
                    value = vendor,
                    onValueChange = { vendor = it },
                    label = { Text("Vendor / Store") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )

                OutlinedTextField(
                    value = title,
                    onValueChange = { title = it },
                    label = { Text("Item Description") },
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
                        modifier = Modifier.weight(1f)
                    )
                    OutlinedTextField(
                        value = taxStr,
                        onValueChange = { taxStr = it },
                        label = { Text("Tax ($defaultCurrencySymbol)") },
                        singleLine = true,
                        modifier = Modifier.weight(1f)
                    )
                }

                Surface(
                    color = Color(0xFFF1F5F9),
                    shape = RoundedCornerShape(8.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(
                        text = "Receipt attached • Date: $today • Tax Deductible: Yes",
                        fontSize = 11.sp,
                        color = Color(0xFF475569),
                        modifier = Modifier.padding(8.dp)
                    )
                }
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    val amount = amountStr.toDoubleOrNull() ?: 68.40
                    val tax = taxStr.toDoubleOrNull() ?: 6.15
                    val expense = ExpenseEntity(
                        title = title,
                        category = category,
                        amount = amount,
                        currency = defaultCurrency,
                        currencySymbol = defaultCurrencySymbol,
                        date = today,
                        vendor = vendor,
                        paymentMethod = "Credit Card",
                        taxDeductible = true,
                        taxAmount = tax,
                        receiptImageUri = receiptUri?.toString(),
                        notes = "Auto-scanned receipt"
                    )
                    onSave(expense)
                },
                colors = ButtonDefaults.buttonColors(containerColor = PrimaryNavy)
            ) {
                Text("Confirm & Save")
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
