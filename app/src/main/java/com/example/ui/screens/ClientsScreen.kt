package com.example.ui.screens

import android.widget.Toast
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
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
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import com.example.ui.components.AdaptiveContainer
import com.example.ui.components.rememberWindowAdaptiveInfo
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Business
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.ExpandLess
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.People
import androidx.compose.material.icons.filled.Phone
import androidx.compose.material.icons.filled.PostAdd
import androidx.compose.material.icons.filled.Receipt
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Sync
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.data.model.ClientEntity
import com.example.data.model.InvoiceUtils
import com.example.ui.components.InvoiceStatusBadge
import com.example.ui.theme.PrimaryNavy
import com.example.ui.theme.StatusOverdueRose
import com.example.ui.theme.StatusPaidGreen
import com.example.ui.viewmodel.InvoiceViewModel
import androidx.compose.foundation.isSystemInDarkTheme
import com.example.ui.components.AmbientGlassBackdrop
import com.example.ui.components.GlassCard
import com.example.ui.components.glassTextFieldColors

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ClientsScreen(
    viewModel: InvoiceViewModel,
    onBack: () -> Unit,
    onCreateInvoiceForClient: (ClientEntity) -> Unit,
    onOpenInvoice: (Long) -> Unit,
    onOpenMenu: () -> Unit = {},
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val clients by viewModel.filteredClients.collectAsStateWithLifecycle()
    val searchQuery by viewModel.clientSearchQuery.collectAsStateWithLifecycle()
    val allInvoices by viewModel.allInvoices.collectAsStateWithLifecycle()
    val profile by viewModel.businessProfile.collectAsStateWithLifecycle()

    var clientToEdit by remember { mutableStateOf<ClientEntity?>(null) }
    var showAddDialog by remember { mutableStateOf(false) }
    var clientToDelete by remember { mutableStateOf<ClientEntity?>(null) }
    var expandedClientId by remember { mutableStateOf<Long?>(null) }

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
                            text = "Clients & Accounts",
                            fontWeight = FontWeight.Bold,
                            color = if (isDark) Color.White else PrimaryNavy,
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
                        IconButton(
                            onClick = {
                                viewModel.refreshClientsFromBackend()
                                Toast.makeText(context, "Refreshing clients from server...", Toast.LENGTH_SHORT).show()
                            },
                            modifier = Modifier.testTag("clients_sync_btn")
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
                                    contentDescription = "Sync Clients",
                                    tint = if (isDark) Color.White else Color(0xFF1D4ED8),
                                    modifier = Modifier.size(18.dp)
                                )
                            }
                        }
                        IconButton(
                            onClick = onOpenMenu,
                            modifier = Modifier.testTag("clients_menu_btn")
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
            },
            floatingActionButton = {
                FloatingActionButton(
                    onClick = {
                        clientToEdit = null
                        showAddDialog = true
                    },
                    containerColor = Color(0xFF1D4ED8),
                    contentColor = Color.White,
                    shape = RoundedCornerShape(16.dp),
                    modifier = Modifier.testTag("add_client_fab")
                ) {
                    Icon(imageVector = Icons.Default.Add, contentDescription = "Add Client")
                }
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
                    onValueChange = { viewModel.setClientSearchQuery(it) },
                    placeholder = { Text("Search client name, company, email...", color = if (isDark) Color(0xFF94A3B8) else Color(0xFF64748B)) },
                    leadingIcon = { Icon(Icons.Default.Search, contentDescription = null, tint = Color(0xFF2563EB)) },
                    trailingIcon = {
                        if (searchQuery.isNotEmpty()) {
                            IconButton(onClick = { viewModel.setClientSearchQuery("") }) {
                                Icon(Icons.Default.Clear, contentDescription = "Clear")
                            }
                        }
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 8.dp)
                        .testTag("client_search_field"),
                    shape = RoundedCornerShape(14.dp),
                    colors = glassTextFieldColors(),
                    singleLine = true
                )

            if (clients.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(32.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            imageVector = Icons.Default.People,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.size(54.dp)
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        Text(
                            text = "No Clients Found",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold
                        )
                        Text(
                            text = "Add client profiles to track billing, invoices and automate reminders",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            } else {
                LazyVerticalGrid(
                    columns = GridCells.Adaptive(minSize = 340.dp),
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(start = adaptiveInfo.horizontalPadding, end = adaptiveInfo.horizontalPadding, top = 8.dp, bottom = 80.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(clients, key = { it.id }) { client ->
                        // Calculate stats for this client
                        val clientInvoices = allInvoices.filter {
                            it.clientId == client.id || it.clientName.equals(client.name, ignoreCase = true)
                        }

                        var clientTotalBilled = 0.0
                        var clientTotalPaid = 0.0
                        var clientBalanceDue = 0.0

                        clientInvoices.forEach { inv ->
                            val items = InvoiceUtils.deserializeInvoiceItems(inv.itemsJson)
                            val calcs = InvoiceUtils.calculateInvoice(
                                items = items,
                                taxRate = inv.taxRate,
                                discountPercent = inv.discountPercent,
                                discountAmount = inv.discountAmount,
                                shippingFee = inv.shippingFee,
                                amountPaid = inv.amountPaid
                            )
                            clientTotalBilled += calcs.grandTotal
                            clientTotalPaid += calcs.amountPaid
                            clientBalanceDue += calcs.balanceDue
                        }

                        val isExpanded = expandedClientId == client.id

                        GlassCard(
                            modifier = Modifier
                                .fillMaxWidth()
                                .testTag("client_card_${client.id}"),
                            shape = RoundedCornerShape(18.dp),
                            elevation = 3.dp
                        ) {
                            Column(modifier = Modifier.padding(16.dp)) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.Top
                                ) {
                                    Row(modifier = Modifier.weight(1f), verticalAlignment = Alignment.CenterVertically) {
                                        Box(
                                            modifier = Modifier
                                                .size(42.dp)
                                                .clip(CircleShape)
                                                .background(Color(0xFFEFF6FF)),
                                            contentAlignment = Alignment.Center
                                        ) {
                                            Text(
                                                text = client.name.take(1).uppercase(),
                                                fontWeight = FontWeight.Bold,
                                                color = PrimaryNavy,
                                                fontSize = 18.sp
                                            )
                                        }

                                        Spacer(modifier = Modifier.width(12.dp))

                                        Column {
                                            Text(
                                                text = client.name,
                                                style = MaterialTheme.typography.titleMedium,
                                                fontWeight = FontWeight.Bold,
                                                color = MaterialTheme.colorScheme.onSurface
                                            )
                                            if (client.companyName.isNotBlank()) {
                                                Text(
                                                    text = client.companyName,
                                                    style = MaterialTheme.typography.bodySmall,
                                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                                )
                                            }
                                        }
                                    }

                                    Row {
                                        IconButton(
                                            onClick = {
                                                clientToEdit = client
                                                showAddDialog = true
                                            }
                                        ) {
                                            Icon(imageVector = Icons.Default.Edit, contentDescription = "Edit Client", tint = PrimaryNavy)
                                        }
                                        IconButton(onClick = { clientToDelete = client }) {
                                            Icon(imageVector = Icons.Default.Delete, contentDescription = "Delete Client", tint = MaterialTheme.colorScheme.error)
                                        }
                                    }
                                }

                                Spacer(modifier = Modifier.height(10.dp))

                                // Contact Info Badges
                                if (client.email.isNotBlank() || client.phone.isNotBlank()) {
                                    Row(
                                        verticalAlignment = Alignment.CenterVertically,
                                        modifier = Modifier.padding(bottom = 6.dp)
                                    ) {
                                        if (client.email.isNotBlank()) {
                                            Icon(imageVector = Icons.Default.Email, contentDescription = null, modifier = Modifier.size(14.dp), tint = Color(0xFF64748B))
                                            Spacer(modifier = Modifier.width(4.dp))
                                            Text(text = client.email, fontSize = 11.sp, color = Color(0xFF64748B))
                                            Spacer(modifier = Modifier.width(10.dp))
                                        }
                                        if (client.phone.isNotBlank()) {
                                            Icon(imageVector = Icons.Default.Phone, contentDescription = null, modifier = Modifier.size(14.dp), tint = Color(0xFF64748B))
                                            Spacer(modifier = Modifier.width(4.dp))
                                            Text(text = client.phone, fontSize = 11.sp, color = Color(0xFF64748B))
                                        }
                                    }
                                }

                                // Financial KPI Summary Row for this Client
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .clip(RoundedCornerShape(8.dp))
                                        .background(Color(0xFFF8FAFC))
                                        .padding(10.dp),
                                    horizontalArrangement = Arrangement.SpaceBetween
                                ) {
                                    Column {
                                        Text("Total Billed", fontSize = 10.sp, color = Color(0xFF64748B))
                                        Text(
                                            InvoiceUtils.formatMoney(clientTotalBilled, profile.defaultCurrencySymbol),
                                            fontSize = 12.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = Color(0xFF0F172A)
                                        )
                                    }
                                    Column {
                                        Text("Total Paid", fontSize = 10.sp, color = Color(0xFF64748B))
                                        Text(
                                            InvoiceUtils.formatMoney(clientTotalPaid, profile.defaultCurrencySymbol),
                                            fontSize = 12.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = StatusPaidGreen
                                        )
                                    }
                                    Column(horizontalAlignment = Alignment.End) {
                                        Text("Balance Due", fontSize = 10.sp, color = Color(0xFF64748B))
                                        Text(
                                            InvoiceUtils.formatMoney(clientBalanceDue, profile.defaultCurrencySymbol),
                                            fontSize = 12.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = if (clientBalanceDue > 0) StatusOverdueRose else Color(0xFF0F172A)
                                        )
                                    }
                                }

                                Spacer(modifier = Modifier.height(10.dp))

                                // Action Buttons
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    TextButton(
                                        onClick = { expandedClientId = if (isExpanded) null else client.id },
                                        contentPadding = PaddingValues(horizontal = 4.dp, vertical = 2.dp)
                                    ) {
                                        Text(
                                            text = "${clientInvoices.size} Invoices",
                                            fontSize = 12.sp,
                                            fontWeight = FontWeight.SemiBold
                                        )
                                        Spacer(modifier = Modifier.width(4.dp))
                                        Icon(
                                            imageVector = if (isExpanded) Icons.Default.ExpandLess else Icons.Default.ExpandMore,
                                            contentDescription = null,
                                            modifier = Modifier.size(16.dp)
                                        )
                                    }

                                    Button(
                                        onClick = { onCreateInvoiceForClient(client) },
                                        colors = ButtonDefaults.buttonColors(containerColor = PrimaryNavy),
                                        shape = RoundedCornerShape(8.dp),
                                        contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp),
                                        modifier = Modifier.testTag("create_inv_for_client_${client.id}")
                                    ) {
                                        Icon(imageVector = Icons.Default.PostAdd, contentDescription = null, modifier = Modifier.size(14.dp))
                                        Spacer(modifier = Modifier.width(4.dp))
                                        Text("Create Invoice", fontSize = 11.sp)
                                    }
                                }

                                // Expanded Invoices for this Client
                                AnimatedVisibility(visible = isExpanded) {
                                    Column(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(top = 8.dp),
                                        verticalArrangement = Arrangement.spacedBy(6.dp)
                                    ) {
                                        HorizontalDivider()
                                        if (clientInvoices.isEmpty()) {
                                            Text(
                                                text = "No invoices issued for this client yet",
                                                fontSize = 11.sp,
                                                color = Color(0xFF64748B),
                                                modifier = Modifier.padding(vertical = 4.dp)
                                            )
                                        } else {
                                            clientInvoices.forEach { inv ->
                                                val invItems = InvoiceUtils.deserializeInvoiceItems(inv.itemsJson)
                                                val invCalcs = InvoiceUtils.calculateInvoice(
                                                    items = invItems,
                                                    taxRate = inv.taxRate,
                                                    discountPercent = inv.discountPercent,
                                                    discountAmount = inv.discountAmount,
                                                    shippingFee = inv.shippingFee,
                                                    amountPaid = inv.amountPaid
                                                )

                                                Row(
                                                    modifier = Modifier
                                                        .fillMaxWidth()
                                                        .clip(RoundedCornerShape(6.dp))
                                                        .background(Color(0xFFF1F5F9))
                                                        .clickable { onOpenInvoice(inv.id) }
                                                        .padding(horizontal = 10.dp, vertical = 6.dp),
                                                    horizontalArrangement = Arrangement.SpaceBetween,
                                                    verticalAlignment = Alignment.CenterVertically
                                                ) {
                                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                                        Text(inv.invoiceNumber, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                                                        Spacer(modifier = Modifier.width(6.dp))
                                                        InvoiceStatusBadge(status = inv.status)
                                                    }
                                                    Text(
                                                        InvoiceUtils.formatMoney(invCalcs.grandTotal, inv.currencySymbol),
                                                        fontSize = 12.sp,
                                                        fontWeight = FontWeight.Bold,
                                                        color = PrimaryNavy
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
}
}

    // Add / Edit Client Dialog
    if (showAddDialog) {
        val client = clientToEdit
        var name by remember { mutableStateOf(client?.name ?: "") }
        var company by remember { mutableStateOf(client?.companyName ?: "") }
        var email by remember { mutableStateOf(client?.email ?: "") }
        var phone by remember { mutableStateOf(client?.phone ?: "") }
        var address by remember { mutableStateOf(client?.address ?: "") }
        var taxId by remember { mutableStateOf(client?.taxId ?: "") }
        var terms by remember { mutableStateOf(client?.defaultPaymentTerms ?: "Net 30") }

        AlertDialog(
            onDismissRequest = { showAddDialog = false },
            title = { Text(if (client == null) "New Client Profile" else "Edit Client Profile") },
            text = {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .verticalScroll(rememberScrollState()),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedTextField(
                        value = name,
                        onValueChange = { name = it },
                        label = { Text("Client Name *") },
                        modifier = Modifier.fillMaxWidth().testTag("edit_client_name"),
                        shape = RoundedCornerShape(12.dp),
                        colors = glassTextFieldColors()
                    )
                    OutlinedTextField(
                        value = company,
                        onValueChange = { company = it },
                        label = { Text("Company Name") },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp),
                        colors = glassTextFieldColors()
                    )
                    OutlinedTextField(
                        value = email,
                        onValueChange = { email = it },
                        label = { Text("Email") },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp),
                        colors = glassTextFieldColors(),
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email)
                    )
                    OutlinedTextField(
                        value = phone,
                        onValueChange = { phone = it },
                        label = { Text("Phone") },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp),
                        colors = glassTextFieldColors(),
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone)
                    )
                    OutlinedTextField(
                        value = address,
                        onValueChange = { address = it },
                        label = { Text("Address") },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp),
                        colors = glassTextFieldColors(),
                        maxLines = 3
                    )
                    OutlinedTextField(
                        value = taxId,
                        onValueChange = { taxId = it },
                        label = { Text("Tax / VAT ID") },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp),
                        colors = glassTextFieldColors()
                    )
                    OutlinedTextField(
                        value = terms,
                        onValueChange = { terms = it },
                        label = { Text("Payment Terms (e.g. Net 30)") },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp),
                        colors = glassTextFieldColors()
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        if (name.isBlank()) {
                            Toast.makeText(context, "Client name cannot be blank", Toast.LENGTH_SHORT).show()
                            return@Button
                        }
                        val toSave = ClientEntity(
                            id = client?.id ?: 0L,
                            name = name.trim(),
                            companyName = company.trim(),
                            email = email.trim(),
                            phone = phone.trim(),
                            address = address.trim(),
                            taxId = taxId.trim(),
                            defaultPaymentTerms = terms.trim()
                        )
                        viewModel.saveClient(toSave)
                        showAddDialog = false
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = PrimaryNavy)
                ) {
                    Text("Save Client")
                }
            },
            dismissButton = {
                TextButton(onClick = { showAddDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }

    // Delete Client Confirmation
    clientToDelete?.let { c ->
        AlertDialog(
            onDismissRequest = { clientToDelete = null },
            title = { Text("Delete Client?") },
            text = { Text("Are you sure you want to remove ${c.name}? Existing invoices won't be deleted.") },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.deleteClient(c)
                        clientToDelete = null
                    }
                ) {
                    Text("Delete", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { clientToDelete = null }) {
                    Text("Cancel")
                }
            }
        )
    }
}
