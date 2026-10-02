package com.example.ui.components

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
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowDownward
import androidx.compose.material.icons.filled.ArrowUpward
import androidx.compose.material.icons.filled.Calculate
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.DragHandle
import androidx.compose.material.icons.filled.Functions
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Tune
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
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
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.example.data.model.IndustryTemplatePreset
import com.example.data.model.IndustryTemplates
import com.example.data.model.ItemColumnDef
import com.example.ui.theme.PrimaryNavy

val AVAILABLE_DATA_TYPES = listOf(
    "text" to "Text (Single line)",
    "number" to "Number",
    "currency" to "Currency (Rate / Price)",
    "percentage" to "Percentage (%)",
    "date" to "Date",
    "dropdown" to "Dropdown Select",
    "checkbox" to "Checkbox (Yes / No)",
    "sku" to "SKU Code",
    "barcode" to "Barcode",
    "hsn" to "HSN / SAC Code",
    "tax" to "Tax Rate (%)",
    "formula" to "Calculated Formula",
    "quantity" to "Quantity (Units)",
    "unit" to "Unit (hrs, pcs, kg)",
    "duration" to "Duration / Hours",
    "serial_number" to "Serial Number",
    "batch_number" to "Batch Number"
)

/**
 * Universal Dynamic Itemization Builder Modal Dialog.
 * Allows users from ANY industry to customize column definitions:
 * - Reorder columns (up/down)
 * - Internal Field Key vs Display Invoice Label
 * - Data Type selection
 * - Calculation Behavior & Formula
 * - Visibility & Required toggles
 * - Duplicate & Delete column
 * - Add New Custom Column
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ItemizationBuilderDialog(
    initialColumns: List<ItemColumnDef>,
    onSaveColumns: (List<ItemColumnDef>) -> Unit,
    onDismiss: () -> Unit
) {
    val columns = remember {
        mutableStateListOf<ItemColumnDef>().apply {
            addAll(initialColumns.sortedBy { it.order })
        }
    }

    var showAddCustomDialog by remember { mutableStateOf(false) }
    var editingFormulaColumnIndex by remember { mutableStateOf<Int?>(null) }

    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false)
    ) {
        Surface(
            modifier = Modifier
                .fillMaxSize()
                .padding(12.dp),
            shape = RoundedCornerShape(20.dp),
            color = Color(0xFFF8FAFC)
        ) {
            Column(modifier = Modifier.fillMaxSize()) {
                // Top Header
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(Color.White)
                        .padding(horizontal = 16.dp, vertical = 14.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .size(36.dp)
                                .clip(RoundedCornerShape(10.dp))
                                .background(Color(0xFFEFF6FF)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Default.Tune,
                                contentDescription = null,
                                tint = Color(0xFF2563EB),
                                modifier = Modifier.size(20.dp)
                            )
                        }
                        Column {
                            Text(
                                text = "Itemization Customizer",
                                fontSize = 17.sp,
                                fontWeight = FontWeight.Bold,
                                color = PrimaryNavy
                            )
                            Text(
                                text = "Customize columns, data types & formulas",
                                fontSize = 11.sp,
                                color = Color(0xFF64748B)
                            )
                        }
                    }

                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.Close, contentDescription = "Close", tint = Color.Gray)
                    }
                }

                HorizontalDivider(color = Color(0xFFE2E8F0))

                // Action Bar: Add Custom Column & Column Counter
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 10.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "${columns.count { it.isVisible }} visible of ${columns.size} total columns",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = Color(0xFF475569)
                    )

                    Button(
                        onClick = { showAddCustomDialog = true },
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF2563EB)),
                        shape = RoundedCornerShape(8.dp),
                        contentPadding = PaddingValues(horizontal = 12.dp, vertical = 6.dp),
                        modifier = Modifier.testTag("add_custom_column_btn")
                    ) {
                        Icon(Icons.Default.Add, contentDescription = null, modifier = Modifier.size(16.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("+ Add Custom Column", fontSize = 12.sp, fontWeight = FontWeight.Bold)
                    }
                }

                // Columns List
                LazyColumn(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    itemsIndexed(columns, key = { _, col -> col.id }) { index, col ->
                        ColumnItemCard(
                            column = col,
                            index = index,
                            totalCount = columns.size,
                            onMoveUp = {
                                if (index > 0) {
                                    val item = columns.removeAt(index)
                                    columns.add(index - 1, item)
                                }
                            },
                            onMoveDown = {
                                if (index < columns.size - 1) {
                                    val item = columns.removeAt(index)
                                    columns.add(index + 1, item)
                                }
                            },
                            onUpdateColumn = { updated ->
                                columns[index] = updated
                            },
                            onDelete = {
                                if (columns.size > 1) {
                                    columns.removeAt(index)
                                }
                            },
                            onDuplicate = {
                                val dup = col.copy(
                                    id = "col_custom_${System.currentTimeMillis() % 100000}",
                                    label = "${col.label} (Copy)",
                                    key = "${col.key}_copy",
                                    isCustom = true
                                )
                                columns.add(index + 1, dup)
                            },
                            onOpenFormulaBuilder = {
                                editingFormulaColumnIndex = index
                            }
                        )
                    }
                }

                // Bottom Action Bar
                Surface(
                    color = Color.White,
                    shadowElevation = 8.dp
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        OutlinedButton(
                            onClick = onDismiss,
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(10.dp)
                        ) {
                            Text("Cancel", fontSize = 13.sp)
                        }

                        Button(
                            onClick = {
                                // Re-index order
                                val reindexed = columns.mapIndexed { idx, item ->
                                    item.copy(order = idx)
                                }
                                onSaveColumns(reindexed)
                                onDismiss()
                            },
                            modifier = Modifier
                                .weight(1f)
                                .testTag("apply_column_customization_btn"),
                            colors = ButtonDefaults.buttonColors(containerColor = PrimaryNavy),
                            shape = RoundedCornerShape(10.dp)
                        ) {
                            Icon(Icons.Default.Check, contentDescription = null, modifier = Modifier.size(16.dp))
                            Spacer(modifier = Modifier.width(6.dp))
                            Text("Apply Itemization", fontSize = 13.sp, fontWeight = FontWeight.Bold)
                        }
                    }
                }
            }
        }
    }

    // Modal to Add Custom Column
    if (showAddCustomDialog) {
        AddCustomColumnDialog(
            existingKeys = columns.map { it.key },
            onAdd = { newCol ->
                columns.add(newCol.copy(order = columns.size))
                showAddCustomDialog = false
            },
            onDismiss = { showAddCustomDialog = false }
        )
    }

    // Visual Formula Builder Dialog
    editingFormulaColumnIndex?.let { idx ->
        if (idx in columns.indices) {
            val col = columns[idx]
            FormulaBuilderDialog(
                column = col,
                allColumns = columns,
                onApplyFormula = { formulaStr ->
                    columns[idx] = col.copy(
                        calculationType = "formula",
                        formula = formulaStr,
                        dataType = "formula"
                    )
                    editingFormulaColumnIndex = null
                },
                onDismiss = { editingFormulaColumnIndex = null }
            )
        }
    }
}

/**
 * Single Column Configuration Card in Itemization Customizer
 */
@Composable
fun ColumnItemCard(
    column: ItemColumnDef,
    index: Int,
    totalCount: Int,
    onMoveUp: () -> Unit,
    onMoveDown: () -> Unit,
    onUpdateColumn: (ItemColumnDef) -> Unit,
    onDelete: () -> Unit,
    onDuplicate: () -> Unit,
    onOpenFormulaBuilder: () -> Unit
) {
    var isExpandedDetails by remember { mutableStateOf(false) }

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (column.isVisible) Color.White else Color(0xFFF1F5F9)
        ),
        border = androidx.compose.foundation.BorderStroke(
            1.dp,
            if (column.isVisible) Color(0xFFE2E8F0) else Color(0xFFCBD5E1)
        )
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            // Main Row: Reorder, Label, Visibility, Actions
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                // Reorder controls & Drag icon
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Column {
                        IconButton(
                            onClick = onMoveUp,
                            enabled = index > 0,
                            modifier = Modifier.size(24.dp)
                        ) {
                            Icon(Icons.Default.ArrowUpward, contentDescription = "Move Up", modifier = Modifier.size(16.dp))
                        }
                        IconButton(
                            onClick = onMoveDown,
                            enabled = index < totalCount - 1,
                            modifier = Modifier.size(24.dp)
                        ) {
                            Icon(Icons.Default.ArrowDownward, contentDescription = "Move Down", modifier = Modifier.size(16.dp))
                        }
                    }

                    Icon(
                        imageVector = Icons.Default.DragHandle,
                        contentDescription = "Order",
                        tint = Color(0xFF94A3B8),
                        modifier = Modifier.size(20.dp)
                    )
                }

                // Display Label Field & Internal Field key
                Column(modifier = Modifier.weight(1f).padding(horizontal = 8.dp)) {
                    OutlinedTextField(
                        value = column.label,
                        onValueChange = { onUpdateColumn(column.copy(label = it)) },
                        label = { Text("Display Label", fontSize = 10.sp) },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth(),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedContainerColor = Color.White,
                            unfocusedContainerColor = Color.White
                        )
                    )

                    Row(
                        modifier = Modifier.padding(top = 2.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        Text(
                            text = "Internal: ${column.key}",
                            fontSize = 10.sp,
                            color = Color(0xFF64748B),
                            fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace
                        )

                        Surface(
                            color = Color(0xFFEFF6FF),
                            shape = RoundedCornerShape(4.dp)
                        ) {
                            Text(
                                text = column.dataType.uppercase(),
                                fontSize = 9.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color(0xFF1D4ED8),
                                modifier = Modifier.padding(horizontal = 4.dp, vertical = 1.dp)
                            )
                        }

                        if (column.calculationType == "formula" && column.formula.isNotBlank()) {
                            Surface(
                                color = Color(0xFFFEF3C7),
                                shape = RoundedCornerShape(4.dp)
                            ) {
                                Text(
                                    text = "ƒ(x)",
                                    fontSize = 9.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = Color(0xFFB45309),
                                    modifier = Modifier.padding(horizontal = 4.dp, vertical = 1.dp)
                                )
                            }
                        }
                    }
                }

                // Show/Hide Switch & Details Toggle
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Switch(
                        checked = column.isVisible,
                        onCheckedChange = { onUpdateColumn(column.copy(isVisible = it)) },
                        colors = SwitchDefaults.colors(
                            checkedThumbColor = Color.White,
                            checkedTrackColor = Color(0xFF2563EB)
                        ),
                        modifier = Modifier.size(36.dp)
                    )

                    IconButton(
                        onClick = { isExpandedDetails = !isExpandedDetails }
                    ) {
                        Icon(
                            imageVector = Icons.Default.Tune,
                            contentDescription = "Edit Properties",
                            tint = if (isExpandedDetails) Color(0xFF2563EB) else Color.Gray,
                            modifier = Modifier.size(18.dp)
                        )
                    }
                }
            }

            // Expanded Advanced Details Drawer
            AnimatedVisibility(visible = isExpandedDetails) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = 10.dp)
                        .background(Color(0xFFF8FAFC), RoundedCornerShape(8.dp))
                        .padding(10.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    // Data Type Selector
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text("Data Type:", fontSize = 12.sp, fontWeight = FontWeight.SemiBold)

                        var typeMenuExpanded by remember { mutableStateOf(false) }
                        Box {
                            Surface(
                                color = Color.White,
                                shape = RoundedCornerShape(6.dp),
                                border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFCBD5E1)),
                                modifier = Modifier.clickable { typeMenuExpanded = true }
                            ) {
                                Row(
                                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text(
                                        text = AVAILABLE_DATA_TYPES.find { it.first == column.dataType }?.second ?: column.dataType,
                                        fontSize = 11.sp,
                                        color = PrimaryNavy
                                    )
                                }
                            }

                            DropdownMenu(
                                expanded = typeMenuExpanded,
                                onDismissRequest = { typeMenuExpanded = false }
                            ) {
                                AVAILABLE_DATA_TYPES.forEach { (typeKey, typeLabel) ->
                                    DropdownMenuItem(
                                        text = { Text(typeLabel, fontSize = 12.sp) },
                                        onClick = {
                                            onUpdateColumn(column.copy(dataType = typeKey))
                                            typeMenuExpanded = false
                                        }
                                    )
                                }
                            }
                        }
                    }

                    // Required Toggle
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text("Required Field:", fontSize = 12.sp)
                        Switch(
                            checked = column.isRequired,
                            onCheckedChange = { onUpdateColumn(column.copy(isRequired = it)) },
                            colors = SwitchDefaults.colors(
                                checkedThumbColor = Color.White,
                                checkedTrackColor = Color(0xFF16A34A)
                            ),
                            modifier = Modifier.size(32.dp)
                        )
                    }

                    // Formula / Calculation Action
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text("Formula Calculation:", fontSize = 12.sp)
                            if (column.formula.isNotBlank()) {
                                Text(
                                    text = column.formula,
                                    fontSize = 10.sp,
                                    color = Color(0xFF2563EB),
                                    fontWeight = FontWeight.SemiBold
                                )
                            }
                        }

                        Button(
                            onClick = onOpenFormulaBuilder,
                            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFEFF6FF)),
                            shape = RoundedCornerShape(6.dp),
                            contentPadding = PaddingValues(horizontal = 8.dp, vertical = 2.dp)
                        ) {
                            Icon(Icons.Default.Functions, contentDescription = null, tint = Color(0xFF2563EB), modifier = Modifier.size(14.dp))
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("Edit Formula", fontSize = 11.sp, color = Color(0xFF2563EB), fontWeight = FontWeight.Bold)
                        }
                    }

                    // Duplicate & Delete Row
                    HorizontalDivider(color = Color(0xFFE2E8F0))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.End,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        OutlinedButton(
                            onClick = onDuplicate,
                            shape = RoundedCornerShape(6.dp),
                            contentPadding = PaddingValues(horizontal = 8.dp, vertical = 2.dp)
                        ) {
                            Icon(Icons.Default.ContentCopy, contentDescription = null, modifier = Modifier.size(13.dp))
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("Duplicate", fontSize = 11.sp)
                        }

                        Spacer(modifier = Modifier.width(8.dp))

                        OutlinedButton(
                            onClick = onDelete,
                            shape = RoundedCornerShape(6.dp),
                            colors = ButtonDefaults.outlinedButtonColors(contentColor = Color(0xFFDC2626)),
                            contentPadding = PaddingValues(horizontal = 8.dp, vertical = 2.dp)
                        ) {
                            Icon(Icons.Default.Delete, contentDescription = null, modifier = Modifier.size(13.dp))
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("Delete", fontSize = 11.sp)
                        }
                    }
                }
            }
        }
    }
}

/**
 * Dialog to add a brand new Custom Column
 */
@Composable
fun AddCustomColumnDialog(
    existingKeys: List<String>,
    onAdd: (ItemColumnDef) -> Unit,
    onDismiss: () -> Unit
) {
    var label by remember { mutableStateOf("") }
    var internalKey by remember { mutableStateOf("") }
    var selectedType by remember { mutableStateOf("text") }
    var isRequired by remember { mutableStateOf(false) }
    var showOnInvoice by remember { mutableStateOf(true) }

    Dialog(onDismissRequest = onDismiss) {
        Card(
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(containerColor = Color.White),
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(
                modifier = Modifier
                    .padding(20.dp)
                    .verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Text(
                    text = "Add Custom Column",
                    fontSize = 17.sp,
                    fontWeight = FontWeight.Bold,
                    color = PrimaryNavy
                )

                OutlinedTextField(
                    value = label,
                    onValueChange = {
                        label = it
                        if (internalKey.isBlank() || internalKey.startsWith("custom_")) {
                            internalKey = it.lowercase().replace(" ", "_").filter { ch -> ch.isLetterOrDigit() || ch == '_' }
                        }
                    },
                    label = { Text("Column Display Name (e.g. Project Code)") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )

                OutlinedTextField(
                    value = internalKey,
                    onValueChange = { internalKey = it.lowercase().filter { ch -> ch.isLetterOrDigit() || ch == '_' } },
                    label = { Text("Internal Field Key (e.g. project_code)") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )

                Text("Data Type", fontSize = 12.sp, fontWeight = FontWeight.SemiBold)

                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    AVAILABLE_DATA_TYPES.take(8).forEach { (k, v) ->
                        Surface(
                            color = if (selectedType == k) Color(0xFF2563EB) else Color(0xFFF1F5F9),
                            shape = RoundedCornerShape(16.dp),
                            modifier = Modifier.clickable { selectedType = k }
                        ) {
                            Text(
                                text = v.substringBefore(" ("),
                                fontSize = 11.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = if (selectedType == k) Color.White else PrimaryNavy,
                                modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp)
                            )
                        }
                    }
                }

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text("Required Column", fontSize = 13.sp)
                    Switch(checked = isRequired, onCheckedChange = { isRequired = it })
                }

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text("Show on Invoice Print/PDF", fontSize = 13.sp)
                    Switch(checked = showOnInvoice, onCheckedChange = { showOnInvoice = it })
                }

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    OutlinedButton(
                        onClick = onDismiss,
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(8.dp)
                    ) {
                        Text("Cancel")
                    }

                    Button(
                        onClick = {
                            if (label.isNotBlank()) {
                                val keySafe = internalKey.ifBlank { "custom_${System.currentTimeMillis() % 10000}" }
                                onAdd(
                                    ItemColumnDef(
                                        id = "col_${System.currentTimeMillis()}",
                                        label = label.trim(),
                                        key = keySafe,
                                        dataType = selectedType,
                                        isVisible = showOnInvoice,
                                        isRequired = isRequired,
                                        isCustom = true,
                                        widthWeight = 1.0f
                                    )
                                )
                            }
                        },
                        enabled = label.isNotBlank(),
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(8.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = PrimaryNavy)
                    ) {
                        Text("Add Column", fontWeight = FontWeight.Bold)
                    }
                }
            }
        }
    }
}

/**
 * Visual Formula Builder Dialog.
 * User can tap elements: [Quantity] [×] [Rate] [-] [Discount] [+] [Tax] = [Total]
 */
@Composable
fun FormulaBuilderDialog(
    column: ItemColumnDef,
    allColumns: List<ItemColumnDef>,
    onApplyFormula: (String) -> Unit,
    onDismiss: () -> Unit
) {
    var formulaTokens by remember {
        mutableStateOf(
            if (column.formula.isNotBlank()) column.formula else "${column.label} = "
        )
    }

    Dialog(onDismissRequest = onDismiss) {
        Card(
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(containerColor = Color.White),
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(
                modifier = Modifier
                    .padding(20.dp)
                    .verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text("Visual Formula Builder", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = PrimaryNavy)
                    IconButton(onClick = onDismiss) { Icon(Icons.Default.Close, contentDescription = null) }
                }

                Text(
                    text = "Build visual formula for column: ${column.label}",
                    fontSize = 12.sp,
                    color = Color.Gray
                )

                // Live Formula Display Box
                Surface(
                    color = Color(0xFF0F172A),
                    shape = RoundedCornerShape(10.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(14.dp)) {
                        Text("FORMULA EXPRESSION", fontSize = 10.sp, color = Color(0xFF94A3B8), fontWeight = FontWeight.Bold)
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = formulaTokens.ifBlank { "(empty formula)" },
                            fontSize = 15.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color(0xFF38BDF8),
                            fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace
                        )
                    }
                }

                // Operator Chips
                Text("Operators", fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    listOf("×", "÷", "+", "-", "(", ")").forEach { op ->
                        Surface(
                            color = Color(0xFFEFF6FF),
                            shape = RoundedCornerShape(8.dp),
                            border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFBFDBFE)),
                            modifier = Modifier
                                .weight(1f)
                                .clickable {
                                    formulaTokens = "$formulaTokens $op "
                                }
                        ) {
                            Box(modifier = Modifier.padding(vertical = 8.dp), contentAlignment = Alignment.Center) {
                                Text(op, fontWeight = FontWeight.ExtraBold, fontSize = 16.sp, color = Color(0xFF1D4ED8))
                            }
                        }
                    }
                }

                // Column Variables Chips
                Text("Insert Column Value", fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    allColumns.filter { it.key != column.key }.chunked(3).forEach { rowCols ->
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(6.dp)
                        ) {
                            rowCols.forEach { colItem ->
                                Surface(
                                    color = Color(0xFFF1F5F9),
                                    shape = RoundedCornerShape(8.dp),
                                    border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFCBD5E1)),
                                    modifier = Modifier
                                        .weight(1f)
                                        .clickable {
                                            formulaTokens = "$formulaTokens [${colItem.label}] "
                                        }
                                ) {
                                    Box(modifier = Modifier.padding(horizontal = 6.dp, vertical = 6.dp), contentAlignment = Alignment.Center) {
                                        Text(colItem.label, fontSize = 11.sp, fontWeight = FontWeight.SemiBold, maxLines = 1)
                                    }
                                }
                            }
                        }
                    }
                }

                // Quick Presets
                Text("Standard Presets", fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Surface(
                        color = Color(0xFFECFDF5),
                        shape = RoundedCornerShape(8.dp),
                        modifier = Modifier
                            .weight(1f)
                            .clickable {
                                formulaTokens = "[Quantity] × [Rate]"
                            }
                    ) {
                        Text("Qty × Rate", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = Color(0xFF047857), modifier = Modifier.padding(8.dp), textAlign = androidx.compose.ui.text.style.TextAlign.Center)
                    }

                    Surface(
                        color = Color(0xFFECFDF5),
                        shape = RoundedCornerShape(8.dp),
                        modifier = Modifier
                            .weight(1f)
                            .clickable {
                                formulaTokens = "[Hours] × [Rate/Hour]"
                            }
                    ) {
                        Text("Hours × Rate", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = Color(0xFF047857), modifier = Modifier.padding(8.dp), textAlign = androidx.compose.ui.text.style.TextAlign.Center)
                    }
                }

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    OutlinedButton(
                        onClick = { formulaTokens = "" },
                        shape = RoundedCornerShape(8.dp)
                    ) {
                        Text("Clear")
                    }

                    Button(
                        onClick = {
                            onApplyFormula(formulaTokens.trim())
                        },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(8.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = PrimaryNavy)
                    ) {
                        Text("Apply Formula", fontWeight = FontWeight.Bold)
                    }
                }
            }
        }
    }
}

/**
 * 12 Industry Templates Selector Dialog
 */
@Composable
fun IndustryTemplateSelectorDialog(
    selectedPresetId: String,
    onSelectPreset: (IndustryTemplatePreset) -> Unit,
    onDismiss: () -> Unit
) {
    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false)
    ) {
        Surface(
            modifier = Modifier
                .fillMaxSize()
                .padding(12.dp),
            shape = RoundedCornerShape(20.dp),
            color = Color(0xFFF8FAFC)
        ) {
            Column(modifier = Modifier.fillMaxSize()) {
                // Header
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(Color.White)
                        .padding(horizontal = 16.dp, vertical = 14.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text(
                            text = "Choose Your Business Type",
                            fontSize = 17.sp,
                            fontWeight = FontWeight.Bold,
                            color = PrimaryNavy
                        )
                        Text(
                            text = "Loads recommended itemization, columns & terms (fully editable)",
                            fontSize = 11.sp,
                            color = Color(0xFF64748B)
                        )
                    }

                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.Close, contentDescription = "Close", tint = Color.Gray)
                    }
                }

                HorizontalDivider(color = Color(0xFFE2E8F0))

                // Presets Grid
                LazyColumn(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    items(IndustryTemplates.allPresets.size) { index ->
                        val preset = IndustryTemplates.allPresets[index]
                        val isSelected = preset.id == selectedPresetId

                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable {
                                    onSelectPreset(preset)
                                    onDismiss()
                                }
                                .testTag("industry_preset_${preset.id}"),
                            shape = RoundedCornerShape(12.dp),
                            colors = CardDefaults.cardColors(
                                containerColor = if (isSelected) Color(0xFFEFF6FF) else Color.White
                            ),
                            border = androidx.compose.foundation.BorderStroke(
                                if (isSelected) 2.dp else 1.dp,
                                if (isSelected) Color(0xFF2563EB) else Color(0xFFE2E8F0)
                            )
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(12.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(12.dp)
                            ) {
                                Box(
                                    modifier = Modifier
                                        .size(42.dp)
                                        .clip(RoundedCornerShape(10.dp))
                                        .background(if (isSelected) Color(0xFF2563EB) else Color(0xFFF1F5F9)),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Icon(
                                        imageVector = preset.icon,
                                        contentDescription = null,
                                        tint = if (isSelected) Color.White else PrimaryNavy,
                                        modifier = Modifier.size(22.dp)
                                    )
                                }

                                Column(modifier = Modifier.weight(1f)) {
                                    Row(
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                                    ) {
                                        Text(
                                            text = preset.name,
                                            fontWeight = FontWeight.Bold,
                                            fontSize = 14.sp,
                                            color = PrimaryNavy
                                        )

                                        Surface(
                                            color = Color(0xFFF1F5F9),
                                            shape = RoundedCornerShape(4.dp)
                                        ) {
                                            Text(
                                                text = preset.industryCategory,
                                                fontSize = 9.sp,
                                                fontWeight = FontWeight.SemiBold,
                                                color = Color(0xFF475569),
                                                modifier = Modifier.padding(horizontal = 4.dp, vertical = 1.dp)
                                            )
                                        }

                                        val letterheadLabel = when (preset.recommendedTemplateId) {
                                            "ecommerce" -> "Letterhead: E-Commerce Dispatch"
                                            "classic_letterhead" -> "Letterhead: Classic Formal"
                                            "tech_clean" -> "Letterhead: Tech Strip"
                                            "compact_ledger" -> "Letterhead: Compact Retail"
                                            "corporate" -> "Letterhead: Corporate Bar"
                                            "healthcare" -> "Letterhead: Clinical Fee Bill"
                                            else -> "Letterhead: Minimalist Clean"
                                        }
                                        Surface(
                                            color = Color(0xFFEFF6FF),
                                            shape = RoundedCornerShape(4.dp),
                                            border = androidx.compose.foundation.BorderStroke(0.5.dp, Color(0xFFBFDBFE))
                                        ) {
                                            Text(
                                                text = letterheadLabel,
                                                fontSize = 9.sp,
                                                fontWeight = FontWeight.Bold,
                                                color = Color(0xFF1D4ED8),
                                                modifier = Modifier.padding(horizontal = 5.dp, vertical = 1.dp)
                                            )
                                        }
                                    }

                                    Spacer(modifier = Modifier.height(2.dp))

                                    Text(
                                        text = preset.description,
                                        fontSize = 11.sp,
                                        color = Color(0xFF64748B),
                                        maxLines = 2
                                    )

                                    Spacer(modifier = Modifier.height(4.dp))

                                    // Display column badges
                                    Row(
                                        modifier = Modifier.horizontalScroll(rememberScrollState()),
                                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                                    ) {
                                        preset.defaultColumns.filter { it.isVisible }.forEach { col ->
                                            Surface(
                                                color = Color(0xFFF8FAFC),
                                                shape = RoundedCornerShape(4.dp),
                                                border = androidx.compose.foundation.BorderStroke(0.5.dp, Color(0xFFCBD5E1))
                                            ) {
                                                Text(
                                                    text = col.label,
                                                    fontSize = 9.sp,
                                                    color = Color(0xFF334155),
                                                    modifier = Modifier.padding(horizontal = 4.dp, vertical = 1.dp)
                                                )
                                            }
                                        }
                                    }
                                }

                                if (isSelected) {
                                    Icon(
                                        imageVector = Icons.Default.Check,
                                        contentDescription = "Selected",
                                        tint = Color(0xFF2563EB),
                                        modifier = Modifier.size(22.dp)
                                    )
                                }
                            }
                        }
                    }
                }

                // Bottom Action Bar
                Surface(
                    color = Color.White,
                    shadowElevation = 8.dp,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp, vertical = 10.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        OutlinedButton(
                            onClick = onDismiss,
                            shape = RoundedCornerShape(8.dp)
                        ) {
                            Text("Skip / Keep Blank", fontSize = 12.sp)
                        }

                        Button(
                            onClick = {
                                val preset = IndustryTemplates.allPresets.find { it.id == selectedPresetId } ?: IndustryTemplates.allPresets.first()
                                onSelectPreset(preset)
                                onDismiss()
                            },
                            shape = RoundedCornerShape(8.dp),
                            colors = ButtonDefaults.buttonColors(containerColor = PrimaryNavy)
                        ) {
                            Text("Apply Template", fontSize = 12.sp, fontWeight = FontWeight.Bold)
                        }
                    }
                }
            }
        }
    }
}
