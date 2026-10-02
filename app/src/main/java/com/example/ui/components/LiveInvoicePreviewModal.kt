package com.example.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTransformGestures
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.RestartAlt
import androidx.compose.material.icons.filled.ZoomIn
import androidx.compose.material.icons.filled.ZoomOut
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.example.data.model.BusinessProfile
import com.example.data.model.CustomClientField
import com.example.data.model.InvoiceCalculations
import com.example.data.model.InvoiceItem
import com.example.data.model.ItemColumnDef
import com.example.data.model.ShippingDetails

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LiveInvoicePreviewModal(
    invoiceNumber: String,
    issueDate: String,
    dueDate: String,
    poNumber: String,
    paymentTerms: String,
    currencySymbol: String,
    currencyCode: String,
    clientName: String,
    clientCompany: String,
    clientEmail: String,
    clientPhone: String,
    clientAddress: String,
    clientTaxId: String,
    customClientFields: List<CustomClientField>,
    shippingDetails: ShippingDetails,
    activeColumns: List<ItemColumnDef>,
    items: List<InvoiceItem>,
    taxRate: Double,
    taxLabel: String,
    taxType: String,
    isTaxInclusive: Boolean,
    calculations: InvoiceCalculations,
    notes: String,
    terms: String,
    paymentInstructions: String,
    notesLabel: String = "Notes",
    termsLabel: String = "Terms & Conditions",
    profile: BusinessProfile,
    templateId: String = "minimalist",
    onDismiss: () -> Unit
) {
    var scale by remember { mutableFloatStateOf(1.0f) }

    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false)
    ) {
        Surface(
            modifier = Modifier.fillMaxSize(),
            color = Color(0xFF0F172A)
        ) {
            Column(modifier = Modifier.fillMaxSize()) {
                // Top App Bar
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(Color(0xFF1E293B))
                        .padding(horizontal = 14.dp, vertical = 10.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        IconButton(onClick = onDismiss) {
                            Icon(Icons.Default.Close, contentDescription = "Close", tint = Color.White)
                        }
                        Spacer(modifier = Modifier.width(6.dp))
                        Column {
                            Text(
                                text = "Live Document Preview",
                                fontSize = 16.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color.White
                            )
                            Text(
                                text = "Instant real-time rendering (#$invoiceNumber)",
                                fontSize = 11.sp,
                                color = Color(0xFF94A3B8)
                            )
                        }
                    }

                    // Zoom Controls
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        IconButton(
                            onClick = { scale = maxOf(0.6f, scale - 0.15f) }
                        ) {
                            Icon(Icons.Default.ZoomOut, contentDescription = "Zoom Out", tint = Color.White, modifier = Modifier.size(20.dp))
                        }

                        Surface(
                            color = Color(0xFF334155),
                            shape = RoundedCornerShape(12.dp),
                            modifier = Modifier.padding(horizontal = 4.dp)
                        ) {
                            Text(
                                text = "${(scale * 100).toInt()}%",
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color(0xFF38BDF8),
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                            )
                        }

                        IconButton(
                            onClick = { scale = minOf(2.5f, scale + 0.15f) }
                        ) {
                            Icon(Icons.Default.ZoomIn, contentDescription = "Zoom In", tint = Color.White, modifier = Modifier.size(20.dp))
                        }

                        IconButton(onClick = { scale = 1.0f }) {
                            Icon(Icons.Default.RestartAlt, contentDescription = "Reset Zoom", tint = Color(0xFF94A3B8), modifier = Modifier.size(20.dp))
                        }
                    }
                }

                // Interactive Document Canvas (Pinch zoom & pan)
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxWidth()
                        .pointerInput(Unit) {
                            detectTransformGestures { _, _, zoom, _ ->
                                scale = (scale * zoom).coerceIn(0.6f, 2.5f)
                            }
                        }
                        .verticalScroll(rememberScrollState())
                        .horizontalScroll(rememberScrollState())
                        .padding(16.dp),
                    contentAlignment = Alignment.TopCenter
                ) {
                    Card(
                        modifier = Modifier
                            .widthIn(min = 340.dp, max = 640.dp)
                            .graphicsLayer(
                                scaleX = scale,
                                scaleY = scale
                            )
                            .testTag("live_invoice_paper_card"),
                        shape = RoundedCornerShape(8.dp),
                        colors = CardDefaults.cardColors(containerColor = Color.White),
                        elevation = CardDefaults.cardElevation(defaultElevation = 8.dp)
                    ) {
                        InvoiceTemplateRenderer(
                            templateId = templateId,
                            invoiceNumber = invoiceNumber,
                            issueDate = issueDate,
                            dueDate = dueDate,
                            poNumber = poNumber,
                            paymentTerms = paymentTerms,
                            currencySymbol = currencySymbol,
                            currencyCode = currencyCode,
                            clientName = clientName,
                            clientCompany = clientCompany,
                            clientEmail = clientEmail,
                            clientPhone = clientPhone,
                            clientAddress = clientAddress,
                            clientTaxId = clientTaxId,
                            customClientFields = customClientFields,
                            shippingDetails = shippingDetails,
                            activeColumns = activeColumns,
                            items = items,
                            taxRate = taxRate,
                            taxLabel = taxLabel,
                            taxType = taxType,
                            isTaxInclusive = isTaxInclusive,
                            calculations = calculations,
                            notes = notes,
                            terms = terms,
                            paymentInstructions = paymentInstructions,
                            notesLabel = notesLabel,
                            termsLabel = termsLabel,
                            profile = profile,
                            status = "Draft"
                        )
                    }
                }
            }
        }
    }
}
