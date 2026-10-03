package com.example.ui.screens

import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import com.example.ui.components.AdaptiveContainer
import com.example.ui.components.rememberWindowAdaptiveInfo
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.PictureAsPdf
import androidx.compose.material.icons.filled.Receipt
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Sync
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.data.model.InvoiceEntity
import com.example.data.model.InvoiceUtils
import com.example.ui.components.InvoiceStatusBadge
import com.example.ui.components.PaymentReminderBottomSheet
import com.example.ui.theme.PrimaryNavy
import com.example.ui.theme.StatusOverdueRose
import com.example.ui.viewmodel.InvoiceViewModel

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.ui.draw.clip
import com.example.ui.components.AmbientGlassBackdrop
import com.example.ui.components.GlassCard
import com.example.ui.components.glassTextFieldColors

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InvoicesListScreen(
    viewModel: InvoiceViewModel,
    onBack: () -> Unit,
    onCreateInvoice: () -> Unit,
    onOpenInvoice: (Long) -> Unit,
    onEditInvoice: (Long) -> Unit,
    onOpenMenu: () -> Unit = {},
    modifier: Modifier = Modifier
) {
    val invoices by viewModel.filteredInvoices.collectAsStateWithLifecycle()
    val searchQuery by viewModel.invoiceSearchQuery.collectAsStateWithLifecycle()
    val currentFilter by viewModel.invoiceStatusFilter.collectAsStateWithLifecycle()
    val profile by viewModel.businessProfile.collectAsStateWithLifecycle()

    var invoiceToDelete by remember { mutableStateOf<InvoiceEntity?>(null) }
    var reminderInvoice by remember { mutableStateOf<InvoiceEntity?>(null) }
    val reminderSheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    val filterOptions = listOf("All", "Draft", "Sent", "Paid", "Overdue")
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
                        Text(
                            text = "All Invoices",
                            fontWeight = FontWeight.ExtraBold,
                            color = if (isDark) Color.White else Color(0xFF0F172A),
                            fontSize = adaptiveInfo.titleLargeSize
                        )
                    },
                    navigationIcon = {
                        IconButton(onClick = onBack) {
                            Box(
                                modifier = Modifier
                                    .size(36.dp)
                                    .clip(CircleShape)
                                    .background(if (isDark) Color(0xFF1E293B) else Color(0xFFEFF6FF)),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(
                                    imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                                    contentDescription = "Back",
                                    tint = if (isDark) Color.White else Color(0xFF1D4ED8),
                                    modifier = Modifier.size(18.dp)
                                )
                            }
                        }
                    },
                    actions = {
                        // Sync Invoices with Backend
                        IconButton(
                            onClick = {
                                viewModel.refreshInvoicesFromBackend()
                            },
                            modifier = Modifier.testTag("invoices_sync_btn")
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(36.dp)
                                    .clip(CircleShape)
                                    .background(if (isDark) Color(0xFF1E293B) else Color(0xFFEFF6FF)),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Sync,
                                    contentDescription = "Sync Invoices",
                                    tint = if (isDark) Color.White else Color(0xFF1D4ED8),
                                    modifier = Modifier.size(18.dp)
                                )
                            }
                        }

                        // Create Invoice Button in Header
                        IconButton(
                            onClick = onCreateInvoice,
                            modifier = Modifier.testTag("invoices_create_fab")
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
                                    contentDescription = "Create Invoice",
                                    tint = Color.White,
                                    modifier = Modifier.size(20.dp)
                                )
                            }
                        }

                        // Menu Action
                        IconButton(
                            onClick = onOpenMenu,
                            modifier = Modifier.testTag("invoices_menu_btn")
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
        ) { padding ->
            AdaptiveContainer(maxWidth = adaptiveInfo.contentMaxWidth) {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(padding)
                ) {
                // Search Input with 100% Crisp Visibility
                OutlinedTextField(
                    value = searchQuery,
                    onValueChange = { viewModel.setInvoiceSearchQuery(it) },
                    placeholder = { Text("Search by invoice # or client name...") },
                    leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
                    trailingIcon = {
                        if (searchQuery.isNotEmpty()) {
                            IconButton(onClick = { viewModel.setInvoiceSearchQuery("") }) {
                                Icon(Icons.Default.Clear, contentDescription = "Clear")
                            }
                        }
                    },
                    colors = glassTextFieldColors(),
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 6.dp)
                        .testTag("invoice_search_field"),
                    shape = RoundedCornerShape(16.dp),
                    singleLine = true
                )

                // Status Filter Chips
                LazyRow(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 6.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(filterOptions) { filter ->
                        val isSelected = currentFilter.equals(filter, ignoreCase = true)
                        FilterChip(
                            selected = isSelected,
                            onClick = { viewModel.setInvoiceStatusFilter(filter) },
                            label = {
                                Text(
                                    text = filter,
                                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                                    fontSize = 12.5.sp
                                )
                            },
                            colors = androidx.compose.material3.FilterChipDefaults.filterChipColors(
                                selectedContainerColor = Color(0xFF2563EB),
                                selectedLabelColor = Color.White,
                                containerColor = if (isDark) Color(0xFF1E293B).copy(alpha = 0.7f) else Color.White.copy(alpha = 0.85f),
                                labelColor = if (isDark) Color(0xFFCBD5E1) else Color(0xFF334155)
                            ),
                            border = androidx.compose.material3.FilterChipDefaults.filterChipBorder(
                                enabled = true,
                                selected = isSelected,
                                borderColor = if (isSelected) Color(0xFF1D4ED8) else if (isDark) Color(0xFF475569) else Color(0xFFCBD5E1),
                                selectedBorderColor = Color(0xFF1D4ED8)
                            ),
                            shape = RoundedCornerShape(12.dp),
                            modifier = Modifier.testTag("filter_chip_$filter")
                        )
                    }
                }

                Spacer(modifier = Modifier.height(4.dp))

            if (invoices.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(32.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            imageVector = Icons.Default.Receipt,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.size(54.dp)
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        Text(
                            text = "No Invoices Found",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold
                        )
                        Text(
                            text = if (searchQuery.isNotBlank() || currentFilter != "All") "Try adjusting your search or filters" else "Tap + to create your first invoice",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            } else {
                LazyVerticalGrid(
                    columns = GridCells.Adaptive(minSize = 340.dp),
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(start = adaptiveInfo.horizontalPadding, end = adaptiveInfo.horizontalPadding, top = 8.dp, bottom = 16.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    items(invoices, key = { it.id }) { invoice ->
                        val items = InvoiceUtils.deserializeInvoiceItems(invoice.itemsJson)
                        val calcs = InvoiceUtils.calculateInvoice(
                            items = items,
                            taxRate = invoice.taxRate,
                            discountPercent = invoice.discountPercent,
                            discountAmount = invoice.discountAmount,
                            shippingFee = invoice.shippingFee,
                            amountPaid = invoice.amountPaid
                        )

                        var menuExpanded by remember { mutableStateOf(false) }

                        GlassCard(
                            modifier = Modifier
                                .fillMaxWidth()
                                .testTag("invoice_card_${invoice.id}")
                                .clickable { onOpenInvoice(invoice.id) },
                            shape = RoundedCornerShape(18.dp),
                            elevation = 3.dp
                        ) {
                            Column(modifier = Modifier.padding(16.dp)) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        Text(
                                            text = invoice.invoiceNumber,
                                            style = MaterialTheme.typography.titleMedium,
                                            fontWeight = FontWeight.Bold,
                                            color = MaterialTheme.colorScheme.onSurface
                                        )
                                        Spacer(modifier = Modifier.width(8.dp))
                                        InvoiceStatusBadge(status = invoice.status)
                                    }

                                    Box {
                                        IconButton(onClick = { menuExpanded = true }) {
                                            Icon(imageVector = Icons.Default.MoreVert, contentDescription = "Options")
                                        }
                                        DropdownMenu(
                                            expanded = menuExpanded,
                                            onDismissRequest = { menuExpanded = false }
                                        ) {
                                            DropdownMenuItem(
                                                text = { Text("Preview & DOCX") },
                                                leadingIcon = { Icon(Icons.Default.Visibility, contentDescription = null) },
                                                onClick = {
                                                    menuExpanded = false
                                                    onOpenInvoice(invoice.id)
                                                }
                                            )
                                            DropdownMenuItem(
                                                text = { Text("Edit Invoice") },
                                                leadingIcon = { Icon(Icons.Default.Edit, contentDescription = null) },
                                                onClick = {
                                                    menuExpanded = false
                                                    onEditInvoice(invoice.id)
                                                }
                                            )
                                            if (invoice.status != "Paid") {
                                                DropdownMenuItem(
                                                    text = { Text("Mark as Paid") },
                                                    onClick = {
                                                        menuExpanded = false
                                                        viewModel.updateInvoiceStatus(invoice.id, "Paid")
                                                    }
                                                )
                                            }
                                            if (invoice.status != "Sent") {
                                                DropdownMenuItem(
                                                    text = { Text("Mark as Sent") },
                                                    onClick = {
                                                        menuExpanded = false
                                                        viewModel.updateInvoiceStatus(invoice.id, "Sent")
                                                    }
                                                )
                                            }
                                            DropdownMenuItem(
                                                text = { Text("Send Reminder") },
                                                leadingIcon = { Icon(Icons.Default.NotificationsActive, contentDescription = null) },
                                                onClick = {
                                                    menuExpanded = false
                                                    reminderInvoice = invoice
                                                }
                                            )
                                            DropdownMenuItem(
                                                text = { Text("Delete", color = MaterialTheme.colorScheme.error) },
                                                leadingIcon = { Icon(Icons.Default.Delete, contentDescription = null, tint = MaterialTheme.colorScheme.error) },
                                                onClick = {
                                                    menuExpanded = false
                                                    invoiceToDelete = invoice
                                                }
                                            )
                                        }
                                    }
                                }

                                Spacer(modifier = Modifier.height(6.dp))

                                Text(
                                    text = if (invoice.clientCompany.isNotBlank()) "${invoice.clientName} • ${invoice.clientCompany}" else invoice.clientName,
                                    style = MaterialTheme.typography.bodyMedium,
                                    fontWeight = FontWeight.Medium,
                                    color = MaterialTheme.colorScheme.onSurface
                                )

                                Spacer(modifier = Modifier.height(10.dp))

                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.Bottom
                                ) {
                                    Column {
                                        Text(
                                            text = "Issued: ${invoice.issueDate}",
                                            style = MaterialTheme.typography.bodySmall,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant
                                        )
                                        Text(
                                            text = "Due: ${invoice.dueDate}",
                                            style = MaterialTheme.typography.bodySmall,
                                            fontWeight = if (invoice.status == "Overdue") FontWeight.Bold else FontWeight.Normal,
                                            color = if (invoice.status == "Overdue") StatusOverdueRose else MaterialTheme.colorScheme.onSurfaceVariant
                                        )
                                    }

                                    Column(horizontalAlignment = Alignment.End) {
                                        Text(
                                            text = InvoiceUtils.formatMoney(calcs.grandTotal, invoice.currencySymbol),
                                            style = MaterialTheme.typography.titleLarge,
                                            fontWeight = FontWeight.Bold,
                                            color = MaterialTheme.colorScheme.onSurface
                                        )
                                        if (calcs.balanceDue < calcs.grandTotal && calcs.balanceDue > 0) {
                                            Text(
                                                text = "Bal: ${InvoiceUtils.formatMoney(calcs.balanceDue, invoice.currencySymbol)}",
                                                style = MaterialTheme.typography.labelSmall,
                                                color = StatusOverdueRose
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
}

    // Delete Confirmation Dialog
    invoiceToDelete?.let { inv ->
        AlertDialog(
            onDismissRequest = { invoiceToDelete = null },
            title = { Text("Delete Invoice?") },
            text = { Text("Are you sure you want to permanently delete invoice ${inv.invoiceNumber}?") },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.deleteInvoice(inv)
                        invoiceToDelete = null
                    }
                ) {
                    Text("Delete", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { invoiceToDelete = null }) {
                    Text("Cancel")
                }
            }
        )
    }

    // Payment reminder modal bottom sheet
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
