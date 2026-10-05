package com.example.ui.components

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
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.filled.Business
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Work
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
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
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.example.data.model.InvoiceEntity
import com.example.data.model.InvoiceItem
import com.example.util.AutofillItemSuggestion
import com.example.util.CatalogItemDef
import com.example.util.DomainPresetCategory
import com.example.util.IndustryItemCatalog
import com.example.util.InvoiceAutofillCache
import java.util.Locale

/**
 * Autocomplete item description input field with browser-like popup suggestions.
 */
@Composable
fun AutofillItemDescriptionField(
    value: String,
    onValueChange: (String) -> Unit,
    onSuggestionSelected: (AutofillItemSuggestion) -> Unit,
    clientCompany: String,
    clientId: Long?,
    allInvoices: List<InvoiceEntity>,
    label: String = "Description / Service / Product",
    modifier: Modifier = Modifier,
    testTag: String = ""
) {
    val context = LocalContext.current
    var isDropdownExpanded by remember { mutableStateOf(false) }

    val suggestions = remember(value, clientCompany, clientId, allInvoices.size) {
        if (value.length >= 1 || isDropdownExpanded) {
            InvoiceAutofillCache.getItemSuggestions(
                context = context,
                query = value,
                clientCompany = clientCompany,
                clientId = clientId,
                allInvoices = allInvoices
            )
        } else {
            emptyList()
        }
    }

    Box(modifier = modifier) {
        OutlinedTextField(
            value = value,
            onValueChange = { newVal ->
                onValueChange(newVal)
                isDropdownExpanded = true
            },
            label = { Text(label, fontSize = 11.sp) },
            singleLine = true,
            trailingIcon = {
                if (suggestions.isNotEmpty()) {
                    IconButton(onClick = { isDropdownExpanded = !isDropdownExpanded }) {
                        Icon(
                            imageVector = Icons.Default.ArrowDropDown,
                            contentDescription = "Show suggestions",
                            tint = Color(0xFF2563EB),
                            modifier = Modifier.size(20.dp)
                        )
                    }
                }
            },
            modifier = Modifier
                .fillMaxWidth()
                .testTag(testTag)
        )

        DropdownMenu(
            expanded = isDropdownExpanded && suggestions.isNotEmpty(),
            onDismissRequest = { isDropdownExpanded = false },
            modifier = Modifier
                .fillMaxWidth(0.92f)
                .background(Color.White)
        ) {
            // Header
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 12.dp, vertical = 6.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    Icon(Icons.Default.History, contentDescription = null, tint = Color(0xFF2563EB), modifier = Modifier.size(13.dp))
                    Text(
                        text = if (clientCompany.isNotBlank()) "Suggested for $clientCompany" else "Recent & Domain Suggestions",
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color(0xFF2563EB)
                    )
                }
                Text(
                    text = "${suggestions.size} matches",
                    fontSize = 10.sp,
                    color = Color(0xFF94A3B8)
                )
            }
            HorizontalDivider(color = Color(0xFFF1F5F9))

            suggestions.forEach { sug ->
                DropdownMenuItem(
                    text = {
                        Column(modifier = Modifier.padding(vertical = 2.dp)) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = sug.description,
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.SemiBold,
                                    color = Color(0xFF0F172A),
                                    modifier = Modifier.weight(1f)
                                )
                                Spacer(modifier = Modifier.width(6.dp))
                                Surface(
                                    color = if (sug.isCompanySpecific) Color(0xFFFEF3C7) else Color(0xFFEFF6FF),
                                    shape = RoundedCornerShape(4.dp)
                                ) {
                                    Text(
                                        text = "₹${String.format(Locale.US, "%,.0f", sug.unitPrice)} / ${sug.unit.ifBlank { "unit" }}",
                                        fontSize = 10.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = if (sug.isCompanySpecific) Color(0xFFB45309) else Color(0xFF1D4ED8),
                                        modifier = Modifier.padding(horizontal = 5.dp, vertical = 2.dp)
                                    )
                                }
                            }
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.spacedBy(8.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                if (sug.hsnOrSac.isNotBlank()) {
                                    Text(
                                        text = "SAC/HSN: ${sug.hsnOrSac}",
                                        fontSize = 10.sp,
                                        color = Color(0xFF64748B)
                                    )
                                }
                                Text(
                                    text = sug.sourceLabel,
                                    fontSize = 10.sp,
                                    color = if (sug.isCompanySpecific) Color(0xFFD97706) else Color(0xFF64748B),
                                    fontWeight = if (sug.isCompanySpecific) FontWeight.Bold else FontWeight.Normal
                                )
                            }
                        }
                    },
                    leadingIcon = {
                        Icon(
                            imageVector = if (sug.isCompanySpecific) Icons.Default.Star else Icons.Default.History,
                            contentDescription = null,
                            tint = if (sug.isCompanySpecific) Color(0xFFF59E0B) else Color(0xFF64748B),
                            modifier = Modifier.size(16.dp)
                        )
                    },
                    onClick = {
                        onSuggestionSelected(sug)
                        isDropdownExpanded = false
                    }
                )
            }
        }
    }
}

/**
 * Autocomplete Unit field with one-tap dropdown of standard units.
 */
@Composable
fun AutofillUnitField(
    value: String,
    onValueChange: (String) -> Unit,
    label: String = "Unit",
    modifier: Modifier = Modifier,
    testTag: String = ""
) {
    val context = LocalContext.current
    var isExpanded by remember { mutableStateOf(false) }
    val units = remember { InvoiceAutofillCache.getSuggestedUnits(context) }

    Box(modifier = modifier) {
        OutlinedTextField(
            value = value,
            onValueChange = onValueChange,
            label = { Text(label, fontSize = 10.sp) },
            singleLine = true,
            trailingIcon = {
                IconButton(onClick = { isExpanded = !isExpanded }, modifier = Modifier.size(24.dp)) {
                    Icon(Icons.Default.ArrowDropDown, contentDescription = "Units", tint = Color(0xFF64748B), modifier = Modifier.size(16.dp))
                }
            },
            modifier = Modifier
                .fillMaxWidth()
                .testTag(testTag)
        )

        DropdownMenu(
            expanded = isExpanded,
            onDismissRequest = { isExpanded = false },
            modifier = Modifier.background(Color.White)
        ) {
            units.forEach { u ->
                DropdownMenuItem(
                    text = {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(text = u, fontSize = 12.sp, fontWeight = if (u.equals(value, ignoreCase = true)) FontWeight.Bold else FontWeight.Normal)
                            if (u.equals(value, ignoreCase = true)) {
                                Icon(Icons.Default.Check, contentDescription = null, tint = Color(0xFF2563EB), modifier = Modifier.size(14.dp))
                            }
                        }
                    },
                    onClick = {
                        onValueChange(u)
                        isExpanded = false
                    }
                )
            }
        }
    }
}

/**
 * Domain & Industry Item Catalog Dialog.
 * Provides one-tap adding of items for:
 * - Security Agency & Guard Services (Security Guards 12h/8h shifts, Gunman, Supervisor, Days, Shift, Rate/Day, SAC 998525)
 * - Employee Salary & HR Staffing (Monthly salary, Days worked, Hours, OT, Placement, SAC 998519)
 * - IT & Software Services
 * - Transport & Logistics
 * - Construction & Contracting
 * - Retail & Trading
 */
@Composable
fun DomainItemCatalogDialog(
    onDismissRequest: () -> Unit,
    onAddItem: (InvoiceItem) -> Unit,
    onAddMultipleItems: (List<InvoiceItem>) -> Unit,
    currencySymbol: String = "₹"
) {
    var selectedCategoryId by remember { mutableStateOf("security_agency") }
    var searchQuery by remember { mutableStateOf("") }
    val categories = IndustryItemCatalog.categories
    val activeCategory = categories.find { it.id == selectedCategoryId } ?: categories.first()

    val filteredItems = remember(searchQuery, selectedCategoryId) {
        if (searchQuery.isBlank()) {
            activeCategory.items
        } else {
            val q = searchQuery.trim().lowercase()
            IndustryItemCatalog.getAllItems().filter {
                it.description.lowercase().contains(q) ||
                it.subtitle.lowercase().contains(q) ||
                it.hsnOrSac.contains(q)
            }
        }
    }

    Dialog(
        onDismissRequest = onDismissRequest,
        properties = DialogProperties(usePlatformDefaultWidth = false)
    ) {
        Surface(
            modifier = Modifier
                .fillMaxWidth(0.95f)
                .padding(vertical = 24.dp),
            shape = RoundedCornerShape(16.dp),
            color = Color.White,
            shadowElevation = 8.dp
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                // Header
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                            Icon(Icons.Default.Work, contentDescription = null, tint = Color(0xFF2563EB), modifier = Modifier.size(20.dp))
                            Text(
                                text = "Industry Item Catalog",
                                fontSize = 16.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color(0xFF0F172A)
                            )
                        }
                        Text(
                            text = "Pre-configured line items with SAC, units & GST",
                            fontSize = 11.sp,
                            color = Color(0xFF64748B)
                        )
                    }

                    IconButton(onClick = onDismissRequest) {
                        Icon(Icons.Default.Close, contentDescription = "Close", tint = Color(0xFF64748B))
                    }
                }

                Spacer(modifier = Modifier.height(8.dp))

                // Search Bar
                OutlinedTextField(
                    value = searchQuery,
                    onValueChange = { searchQuery = it },
                    placeholder = { Text("Search services, items, SAC codes...", fontSize = 11.sp, color = Color(0xFF94A3B8)) },
                    leadingIcon = { Icon(Icons.Default.Search, contentDescription = null, tint = Color(0xFF64748B), modifier = Modifier.size(16.dp)) },
                    trailingIcon = {
                        if (searchQuery.isNotEmpty()) {
                            IconButton(onClick = { searchQuery = "" }) {
                                Icon(Icons.Default.Close, contentDescription = "Clear", tint = Color(0xFF64748B), modifier = Modifier.size(15.dp))
                            }
                        }
                    },
                    singleLine = true,
                    shape = RoundedCornerShape(10.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(48.dp)
                )

                Spacer(modifier = Modifier.height(10.dp))

                // Category Chips Scroll
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    categories.forEach { cat ->
                        val isSelected = cat.id == selectedCategoryId
                        Surface(
                            color = if (isSelected) Color(cat.colorHex) else Color(0xFFF1F5F9),
                            shape = RoundedCornerShape(20.dp),
                            border = androidx.compose.foundation.BorderStroke(
                                1.dp,
                                if (isSelected) Color(cat.colorHex) else Color(0xFFE2E8F0)
                            ),
                            modifier = Modifier.clickable { selectedCategoryId = cat.id }
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(4.dp)
                            ) {
                                Icon(
                                    imageVector = cat.icon,
                                    contentDescription = null,
                                    tint = if (isSelected) Color.White else Color(0xFF475569),
                                    modifier = Modifier.size(14.dp)
                                )
                                Text(
                                    text = cat.shortLabel,
                                    fontSize = 11.sp,
                                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                                    color = if (isSelected) Color.White else Color(0xFF334155)
                                )
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(10.dp))

                // Category Description Banner
                Surface(
                    color = Color(activeCategory.colorHex).copy(alpha = 0.08f),
                    shape = RoundedCornerShape(8.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = activeCategory.name,
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color(activeCategory.colorHex)
                            )
                            Text(
                                text = activeCategory.description,
                                fontSize = 10.sp,
                                color = Color(0xFF475569)
                            )
                        }

                        Button(
                            onClick = {
                                val allCatItems = activeCategory.items.map { it.toInvoiceItem() }
                                onAddMultipleItems(allCatItems)
                                onDismissRequest()
                            },
                            colors = ButtonDefaults.buttonColors(containerColor = Color(activeCategory.colorHex)),
                            shape = RoundedCornerShape(8.dp),
                            contentPadding = PaddingValues(horizontal = 8.dp, vertical = 4.dp)
                        ) {
                            Text("Add All (${activeCategory.items.size})", fontSize = 10.sp, fontWeight = FontWeight.Bold)
                        }
                    }
                }

                Spacer(modifier = Modifier.height(10.dp))

                // Item List
                LazyColumn(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(filteredItems) { catItem ->
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(10.dp),
                            colors = CardDefaults.cardColors(containerColor = Color(0xFFFAFAFA)),
                            border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFE2E8F0))
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(10.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(
                                        text = catItem.description,
                                        fontSize = 12.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = Color(0xFF0F172A)
                                    )
                                    if (catItem.subtitle.isNotBlank()) {
                                        Text(
                                            text = catItem.subtitle,
                                            fontSize = 10.sp,
                                            color = Color(0xFF64748B)
                                        )
                                    }
                                    Spacer(modifier = Modifier.height(4.dp))
                                    Row(
                                        horizontalArrangement = Arrangement.spacedBy(6.dp),
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Surface(
                                            color = Color(0xFFEFF6FF),
                                            shape = RoundedCornerShape(4.dp)
                                        ) {
                                            Text(
                                                text = "${catItem.quantity.toInt()} ${catItem.unit} @ ${currencySymbol}${String.format(Locale.US, "%,.0f", catItem.unitPrice)}",
                                                fontSize = 10.sp,
                                                fontWeight = FontWeight.SemiBold,
                                                color = Color(0xFF1D4ED8),
                                                modifier = Modifier.padding(horizontal = 5.dp, vertical = 2.dp)
                                            )
                                        }

                                        if (catItem.hsnOrSac.isNotBlank()) {
                                            Surface(
                                                color = Color(0xFFF1F5F9),
                                                shape = RoundedCornerShape(4.dp)
                                            ) {
                                                Text(
                                                    text = "SAC: ${catItem.hsnOrSac}",
                                                    fontSize = 10.sp,
                                                    fontWeight = FontWeight.Medium,
                                                    color = Color(0xFF475569),
                                                    modifier = Modifier.padding(horizontal = 5.dp, vertical = 2.dp)
                                                )
                                            }
                                        }

                                        Text(
                                            text = "GST ${catItem.taxRate.toInt()}%",
                                            fontSize = 10.sp,
                                            color = Color(0xFF15803D),
                                            fontWeight = FontWeight.SemiBold
                                        )
                                    }
                                }

                                Spacer(modifier = Modifier.width(8.dp))

                                Button(
                                    onClick = {
                                        onAddItem(catItem.toInvoiceItem())
                                    },
                                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF2563EB)),
                                    shape = RoundedCornerShape(8.dp),
                                    contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp)
                                ) {
                                    Icon(Icons.Default.Add, contentDescription = null, modifier = Modifier.size(13.dp))
                                    Spacer(modifier = Modifier.width(3.dp))
                                    Text("Add", fontSize = 11.sp, fontWeight = FontWeight.Bold)
                                }
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(10.dp))

                // Bottom Action
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.End
                ) {
                    Button(
                        onClick = onDismissRequest,
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF0F172A)),
                        shape = RoundedCornerShape(8.dp)
                    ) {
                        Text("Done", fontSize = 12.sp, fontWeight = FontWeight.Bold)
                    }
                }
            }
        }
    }
}
