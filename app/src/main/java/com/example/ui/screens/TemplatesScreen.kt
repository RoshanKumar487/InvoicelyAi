package com.example.ui.screens

import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Download
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.Palette
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.data.model.InvoiceEntity
import com.example.data.model.InvoiceItem
import com.example.data.model.InvoiceUtils
import com.example.data.model.TemplateConfig
import com.example.docx.DocxTemplatePreset
import com.example.ui.theme.PrimaryNavy
import com.example.ui.viewmodel.InvoiceViewModel
import androidx.compose.foundation.isSystemInDarkTheme
import com.example.ui.components.AmbientGlassBackdrop
import com.example.ui.components.AdaptiveContainer
import com.example.ui.components.GlassCard
import com.example.ui.components.glassTextFieldColors
import com.example.ui.components.rememberWindowAdaptiveInfo

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TemplatesScreen(
    viewModel: InvoiceViewModel,
    onBack: () -> Unit,
    onPreviewWithInvoice: (Long) -> Unit,
    onOpenMenu: () -> Unit = {},
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val allInvoices by viewModel.allInvoices.collectAsStateWithLifecycle()
    val activeConfig by viewModel.activeTemplateConfig.collectAsStateWithLifecycle()
    val profile by viewModel.businessProfile.collectAsStateWithLifecycle()

    var editingConfig by remember(activeConfig) { mutableStateOf(activeConfig) }
    var selectedPresetId by remember { mutableStateOf(activeConfig.templateId) }

    val presetColors = listOf(
        "#1E3A8A" to "Royal Navy",
        "#2563EB" to "Sapphire Blue",
        "#0D9488" to "Ocean Teal",
        "#4F46E5" to "Royal Indigo",
        "#059669" to "Emerald Green",
        "#DC2626" to "Crimson Red",
        "#0F172A" to "Charcoal Slate"
    )

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
                            text = "DOCX Templates & Editor",
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
                                viewModel.updateActiveTemplateConfig(editingConfig)
                                Toast.makeText(context, "Template configuration saved", Toast.LENGTH_SHORT).show()
                            },
                            modifier = Modifier.testTag("save_template_config_btn")
                        ) {
                            Icon(imageVector = Icons.Default.Check, contentDescription = "Save", tint = if (isDark) Color.White else PrimaryNavy)
                        }

                        IconButton(
                            onClick = onOpenMenu,
                            modifier = Modifier.testTag("templates_menu_btn")
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
            AdaptiveContainer(maxWidth = adaptiveInfo.formMaxWidth) {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(padding)
                        .verticalScroll(rememberScrollState())
                        .padding(horizontal = adaptiveInfo.horizontalPadding, vertical = 16.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
            // Section 1: Template Presets Grid
            Text(
                text = "Select Document Template Preset:",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = PrimaryNavy
            )

            DocxTemplatePreset.allTemplates.forEach { preset ->
                val isSelected = preset.templateId == selectedPresetId
                val presetColor = try {
                    Color(android.graphics.Color.parseColor(preset.primaryColorHex))
                } catch (_: Exception) {
                    PrimaryNavy
                }

                GlassCard(
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("template_preset_${preset.templateId}")
                        .clickable {
                            selectedPresetId = preset.templateId
                            editingConfig = preset
                            viewModel.selectTemplatePreset(preset)
                        }
                        .then(
                            if (isSelected) Modifier.border(2.dp, Color(0xFF2563EB), RoundedCornerShape(18.dp))
                            else Modifier
                        ),
                    shape = RoundedCornerShape(18.dp),
                    elevation = if (isSelected) 4.dp else 2.dp
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Box(
                            modifier = Modifier
                                .size(48.dp)
                                .clip(RoundedCornerShape(12.dp))
                                .background(presetColor),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Default.Description,
                                contentDescription = null,
                                tint = Color.White,
                                modifier = Modifier.size(24.dp)
                            )
                        }

                        Spacer(modifier = Modifier.width(14.dp))

                        Column(modifier = Modifier.weight(1f)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(
                                    text = preset.templateName,
                                    style = MaterialTheme.typography.titleMedium,
                                    fontWeight = FontWeight.Bold,
                                    color = MaterialTheme.colorScheme.onSurface
                                )
                                if (isSelected) {
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Box(
                                        modifier = Modifier
                                            .clip(RoundedCornerShape(10.dp))
                                            .background(PrimaryNavy)
                                            .padding(horizontal = 6.dp, vertical = 2.dp)
                                    ) {
                                        Text("ACTIVE", color = Color.White, fontSize = 9.sp, fontWeight = FontWeight.Bold)
                                    }
                                }
                            }
                            Spacer(modifier = Modifier.height(2.dp))
                            Text(
                                text = "Title: ${preset.docxTitle} • Font: ${preset.fontStyle}",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
            }

            // Section 2: In-Tool Template Customizer & Editor
            GlassCard(
                shape = RoundedCornerShape(18.dp),
                elevation = 2.dp
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Text(
                        text = "Edit Template Fields & Labels",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = PrimaryNavy
                    )

                    Text(
                        text = "Customize invoice headers, column names, brand color and layout rules for this DOCX export:",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )

                    OutlinedTextField(
                        value = editingConfig.docxTitle,
                        onValueChange = { editingConfig = editingConfig.copy(docxTitle = it) },
                        label = { Text("Invoice Document Title") },
                        modifier = Modifier.fillMaxWidth().testTag("edit_template_title"),
                        shape = RoundedCornerShape(12.dp),
                        colors = glassTextFieldColors()
                    )

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        OutlinedTextField(
                            value = editingConfig.colHeaderItem,
                            onValueChange = { editingConfig = editingConfig.copy(colHeaderItem = it) },
                            label = { Text("Description Header") },
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(12.dp),
                            colors = glassTextFieldColors()
                        )
                        OutlinedTextField(
                            value = editingConfig.colHeaderQty,
                            onValueChange = { editingConfig = editingConfig.copy(colHeaderQty = it) },
                            label = { Text("Qty Header") },
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(12.dp),
                            colors = glassTextFieldColors()
                        )
                    }

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        OutlinedTextField(
                            value = editingConfig.colHeaderRate,
                            onValueChange = { editingConfig = editingConfig.copy(colHeaderRate = it) },
                            label = { Text("Rate Header") },
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(12.dp),
                            colors = glassTextFieldColors()
                        )
                        OutlinedTextField(
                            value = editingConfig.colHeaderAmount,
                            onValueChange = { editingConfig = editingConfig.copy(colHeaderAmount = it) },
                            label = { Text("Amount Header") },
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(12.dp),
                            colors = glassTextFieldColors()
                        )
                    }

                    // Primary Accent Color
                    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text(
                            text = "Template Accent Color:",
                            style = MaterialTheme.typography.labelMedium,
                            fontWeight = FontWeight.SemiBold
                        )
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            presetColors.forEach { (hex, _) ->
                                val isColorSelected = editingConfig.primaryColorHex.equals(hex, ignoreCase = true)
                                Box(
                                    modifier = Modifier
                                        .size(32.dp)
                                        .clip(CircleShape)
                                        .background(Color(android.graphics.Color.parseColor(hex)))
                                        .clickable { editingConfig = editingConfig.copy(primaryColorHex = hex) }
                                        .then(
                                            if (isColorSelected) Modifier.border(3.dp, Color.Black, CircleShape)
                                            else Modifier
                                        ),
                                    contentAlignment = Alignment.Center
                                ) {
                                    if (isColorSelected) {
                                        Icon(imageVector = Icons.Default.Check, contentDescription = null, tint = Color.White, modifier = Modifier.size(16.dp))
                                    }
                                }
                            }
                        }
                    }

                    HorizontalDivider()

                    // Layout Switches
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text("Show Payment & Wire Instructions", fontSize = 13.sp)
                        Switch(
                            checked = editingConfig.showPaymentInstructions,
                            onCheckedChange = { editingConfig = editingConfig.copy(showPaymentInstructions = it) }
                        )
                    }

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text("Show Authorized Signature Block", fontSize = 13.sp)
                        Switch(
                            checked = editingConfig.showSignature,
                            onCheckedChange = { editingConfig = editingConfig.copy(showSignature = it) }
                        )
                    }

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text("Show Tax Rate Breakdown", fontSize = 13.sp)
                        Switch(
                            checked = editingConfig.showTaxBreakdown,
                            onCheckedChange = { editingConfig = editingConfig.copy(showTaxBreakdown = it) }
                        )
                    }

                    OutlinedTextField(
                        value = editingConfig.customFooterNote,
                        onValueChange = { editingConfig = editingConfig.copy(customFooterNote = it) },
                        label = { Text("Custom Footer Note") },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(10.dp)
                    )

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        OutlinedButton(
                            onClick = {
                                viewModel.setDefaultTemplate(editingConfig.templateId)
                                Toast.makeText(context, "${editingConfig.templateName} set as Default Template!", Toast.LENGTH_SHORT).show()
                            },
                            modifier = Modifier.weight(1f).height(48.dp),
                            shape = RoundedCornerShape(10.dp)
                        ) {
                            Text("Set as Default", fontSize = 12.sp)
                        }

                        Button(
                            onClick = {
                                viewModel.updateActiveTemplateConfig(editingConfig)
                                Toast.makeText(context, "Template saved successfully!", Toast.LENGTH_SHORT).show()
                            },
                            modifier = Modifier.weight(1.3f).height(48.dp),
                            colors = ButtonDefaults.buttonColors(containerColor = PrimaryNavy),
                            shape = RoundedCornerShape(10.dp)
                        ) {
                            Icon(imageVector = Icons.Default.Check, contentDescription = null)
                            Spacer(modifier = Modifier.width(6.dp))
                            Text("Apply & Save", fontSize = 12.sp)
                        }
                    }
                }
            }

            // Section 3: Test Preview with any Invoice
            Card(
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                shape = RoundedCornerShape(16.dp),
                elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
            ) {
                Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text(
                        text = "Test Preview with Template",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = PrimaryNavy
                    )
                    Text(
                        text = "Preview how this template renders in full A4 mobile layout & DOCX format:",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )

                    if (allInvoices.isNotEmpty()) {
                        allInvoices.take(3).forEach { inv ->
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(Color(0xFFF8FAFC))
                                    .clickable {
                                        viewModel.updateActiveTemplateConfig(editingConfig)
                                        onPreviewWithInvoice(inv.id)
                                    }
                                    .padding(12.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column {
                                    Text(inv.invoiceNumber, fontWeight = FontWeight.Bold, fontSize = 13.sp)
                                    Text(inv.clientName, fontSize = 11.sp, color = Color(0xFF64748B))
                                }
                                OutlinedButton(
                                    onClick = {
                                        viewModel.updateActiveTemplateConfig(editingConfig)
                                        onPreviewWithInvoice(inv.id)
                                    },
                                    shape = RoundedCornerShape(8.dp),
                                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 2.dp)
                                ) {
                                    Icon(imageVector = Icons.Default.Visibility, contentDescription = null, modifier = Modifier.size(14.dp))
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text("Preview", fontSize = 11.sp)
                                }
                            }
                        }
                    } else {
                        Button(
                            onClick = {
                                viewModel.updateActiveTemplateConfig(editingConfig)
                                onPreviewWithInvoice(0L)
                            },
                            colors = ButtonDefaults.buttonColors(containerColor = PrimaryNavy),
                            shape = RoundedCornerShape(10.dp),
                            modifier = Modifier.fillMaxWidth().testTag("launch_live_preview_btn")
                        ) {
                            Icon(imageVector = Icons.Default.Visibility, contentDescription = null, modifier = Modifier.size(16.dp))
                            Spacer(modifier = Modifier.width(6.dp))
                            Text("Launch Live Template Preview")
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))
        }
    }
}
}
}
