package com.example.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Business
import androidx.compose.material.icons.filled.Calculate
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.LocalShipping
import androidx.compose.material.icons.filled.Payments
import androidx.compose.material.icons.filled.Tune
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.SheetState
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.ui.theme.PrimaryNavy

data class InvoiceFormConfig(
    val showPoNumber: Boolean,
    val showPaymentTerms: Boolean,
    val showStatus: Boolean,
    val showClientTaxId: Boolean,
    val showClientAddress: Boolean,
    val showClientEmail: Boolean,
    val showClientPhone: Boolean,
    val showShippingSection: Boolean,
    val showNotesSection: Boolean,
    val showPaymentInstructions: Boolean,
    val isAutoRoundOff: Boolean,
    val isTaxInclusive: Boolean,
    val isRcm: Boolean
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InvoiceFormCustomizerSheet(
    sheetState: SheetState,
    config: InvoiceFormConfig,
    onConfigChange: (InvoiceFormConfig) -> Unit,
    onSaveAsDefault: () -> Unit,
    onDismissRequest: () -> Unit
) {
    ModalBottomSheet(
        onDismissRequest = onDismissRequest,
        sheetState = sheetState,
        containerColor = Color.White,
        shape = RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp)
                .navigationBarsPadding()
        ) {
            // Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .size(36.dp)
                            .clip(CircleShape)
                            .background(Color(0xFFEFF6FF)),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            Icons.Default.Tune,
                            contentDescription = null,
                            tint = Color(0xFF2563EB),
                            modifier = Modifier.size(18.dp)
                        )
                    }
                    Column {
                        Text(
                            text = "Customize Invoice Form",
                            fontSize = 16.sp,
                            fontWeight = FontWeight.Bold,
                            color = PrimaryNavy
                        )
                        Text(
                            text = "Show or hide fields tailored to your business workflow",
                            fontSize = 11.sp,
                            color = Color(0xFF64748B)
                        )
                    }
                }

                IconButton(onClick = onDismissRequest) {
                    Icon(Icons.Default.Close, contentDescription = "Close", tint = Color(0xFF64748B))
                }
            }

            Spacer(modifier = Modifier.height(14.dp))

            // Scrollable Toggles
            Column(
                modifier = Modifier
                    .weight(1f, fill = false)
                    .verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(14.dp)
            ) {
                // Group 1: Client Fields
                FormCustomizerGroup(
                    title = "Client Company Details",
                    icon = Icons.Default.Business
                ) {
                    CustomizerToggleRow(
                        title = "GSTIN / Tax ID",
                        description = "Show GST / Tax identifier field",
                        checked = config.showClientTaxId,
                        onCheckedChange = { onConfigChange(config.copy(showClientTaxId = it)) }
                    )
                    HorizontalDivider(color = Color(0xFFF1F5F9))
                    CustomizerToggleRow(
                        title = "Billing Address",
                        description = "Street address and postal code",
                        checked = config.showClientAddress,
                        onCheckedChange = { onConfigChange(config.copy(showClientAddress = it)) }
                    )
                    HorizontalDivider(color = Color(0xFFF1F5F9))
                    CustomizerToggleRow(
                        title = "Client Email Address",
                        description = "Billing email for instant invoices",
                        checked = config.showClientEmail,
                        onCheckedChange = { onConfigChange(config.copy(showClientEmail = it)) }
                    )
                    HorizontalDivider(color = Color(0xFFF1F5F9))
                    CustomizerToggleRow(
                        title = "Client Phone Number",
                        description = "Direct contact & WhatsApp alerts",
                        checked = config.showClientPhone,
                        onCheckedChange = { onConfigChange(config.copy(showClientPhone = it)) }
                    )
                }

                // Group 2: Invoice Details & Header
                FormCustomizerGroup(
                    title = "Invoice Details & Header",
                    icon = Icons.Default.Description
                ) {
                    CustomizerToggleRow(
                        title = "PO / Order Reference Number",
                        description = "Purchase order or reference tracking",
                        checked = config.showPoNumber,
                        onCheckedChange = { onConfigChange(config.copy(showPoNumber = it)) }
                    )
                    HorizontalDivider(color = Color(0xFFF1F5F9))
                    CustomizerToggleRow(
                        title = "Payment Terms Quick Chips",
                        description = "Due on receipt, Net 15, Net 30 buttons",
                        checked = config.showPaymentTerms,
                        onCheckedChange = { onConfigChange(config.copy(showPaymentTerms = it)) }
                    )
                    HorizontalDivider(color = Color(0xFFF1F5F9))
                    CustomizerToggleRow(
                        title = "Status Selector Pill",
                        description = "Draft, Sent, Paid, Overdue switcher",
                        checked = config.showStatus,
                        onCheckedChange = { onConfigChange(config.copy(showStatus = it)) }
                    )
                }

                // Group 3: Optional Sections
                FormCustomizerGroup(
                    title = "Optional Form Sections",
                    icon = Icons.Default.LocalShipping
                ) {
                    CustomizerToggleRow(
                        title = "Shipping & Logistics Section",
                        description = "Carrier, tracking, and delivery address",
                        checked = config.showShippingSection,
                        onCheckedChange = { onConfigChange(config.copy(showShippingSection = it)) }
                    )
                    HorizontalDivider(color = Color(0xFFF1F5F9))
                    CustomizerToggleRow(
                        title = "Payment Instructions (Bank / UPI)",
                        description = "Bank details, account # and UPI QR instructions",
                        checked = config.showPaymentInstructions,
                        onCheckedChange = { onConfigChange(config.copy(showPaymentInstructions = it)) }
                    )
                    HorizontalDivider(color = Color(0xFFF1F5F9))
                    CustomizerToggleRow(
                        title = "Notes & Terms & Conditions",
                        description = "Legal clauses, warranty, and customer notes",
                        checked = config.showNotesSection,
                        onCheckedChange = { onConfigChange(config.copy(showNotesSection = it)) }
                    )
                }

                // Group 4: Tax & Calculation Preferences
                FormCustomizerGroup(
                    title = "Calculation & Tax Defaults",
                    icon = Icons.Default.Calculate
                ) {
                    CustomizerToggleRow(
                        title = "Auto Round-off",
                        description = "Round final total to nearest whole currency rupee",
                        checked = config.isAutoRoundOff,
                        onCheckedChange = { onConfigChange(config.copy(isAutoRoundOff = it)) }
                    )
                    HorizontalDivider(color = Color(0xFFF1F5F9))
                    CustomizerToggleRow(
                        title = "Tax-Inclusive Pricing Mode",
                        description = "Unit rates already include GST/sales tax",
                        checked = config.isTaxInclusive,
                        onCheckedChange = { onConfigChange(config.copy(isTaxInclusive = it)) }
                    )
                    HorizontalDivider(color = Color(0xFFF1F5F9))
                    CustomizerToggleRow(
                        title = "Reverse Charge Mechanism (RCM)",
                        description = "Recipient pays GST under section 9(3)/9(4)",
                        checked = config.isRcm,
                        onCheckedChange = { onConfigChange(config.copy(isRcm = it)) }
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Bottom Action
            Button(
                onClick = {
                    onSaveAsDefault()
                    onDismissRequest()
                },
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF1D4ED8)),
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .height(48.dp)
            ) {
                Icon(Icons.Default.Check, contentDescription = null, modifier = Modifier.size(16.dp))
                Spacer(modifier = Modifier.width(6.dp))
                Text("Apply & Save Preferences", fontSize = 13.sp, fontWeight = FontWeight.Bold)
            }

            Spacer(modifier = Modifier.height(12.dp))
        }
    }
}

@Composable
private fun FormCustomizerGroup(
    title: String,
    icon: ImageVector,
    content: @Composable () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = Color(0xFFF8FAFC)),
        border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFE2E8F0))
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp),
                modifier = Modifier.padding(bottom = 6.dp)
            ) {
                Icon(icon, contentDescription = null, tint = PrimaryNavy, modifier = Modifier.size(16.dp))
                Text(title, fontSize = 12.sp, fontWeight = FontWeight.Bold, color = PrimaryNavy)
            }
            content()
        }
    }
}

@Composable
private fun CustomizerToggleRow(
    title: String,
    description: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onCheckedChange(!checked) }
            .padding(vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(title, fontSize = 12.sp, fontWeight = FontWeight.SemiBold, color = Color(0xFF0F172A))
            Text(description, fontSize = 10.sp, color = Color(0xFF64748B))
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
