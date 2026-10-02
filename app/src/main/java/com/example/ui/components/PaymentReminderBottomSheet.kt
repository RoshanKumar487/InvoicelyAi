package com.example.ui.components

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.SheetState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.model.BusinessProfile
import com.example.data.model.InvoiceCalculations
import com.example.data.model.InvoiceEntity
import com.example.data.model.InvoiceItem
import com.example.data.model.InvoiceUtils
import com.example.ui.theme.PrimaryNavy

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PaymentReminderBottomSheet(
    invoice: InvoiceEntity,
    profile: BusinessProfile,
    onDismiss: () -> Unit,
    onReminderSent: (Long) -> Unit,
    sheetState: SheetState
) {
    val context = LocalContext.current
    val items = InvoiceUtils.deserializeInvoiceItems(invoice.itemsJson)
    val calcs = InvoiceUtils.calculateInvoice(
        items = items,
        taxRate = invoice.taxRate,
        discountPercent = invoice.discountPercent,
        discountAmount = invoice.discountAmount,
        shippingFee = invoice.shippingFee,
        amountPaid = invoice.amountPaid
    )

    val formattedBalance = InvoiceUtils.formatMoney(calcs.balanceDue, invoice.currencySymbol)

    val templates = listOf(
        "Upcoming (Friendly)" to """
Dear ${invoice.clientName},

This is a friendly reminder that invoice ${invoice.invoiceNumber} for $formattedBalance is due on ${invoice.dueDate}.

Please arrange payment via:
${if (profile.paymentLink.isNotBlank()) "Payment Link: ${profile.paymentLink}\n" else ""}Bank: ${profile.bankName}
Account: ${profile.accountNumber}
Routing / BIC: ${profile.routingNumber}

Thank you for your prompt attention.
Best regards,
${profile.businessName}
        """.trimIndent(),

        "Due Today" to """
Dear ${invoice.clientName},

We hope you are well. This is a notification that invoice ${invoice.invoiceNumber} in the amount of $formattedBalance is due today (${invoice.dueDate}).

Payment details:
${if (profile.paymentLink.isNotBlank()) "Online: ${profile.paymentLink}\n" else ""}Bank: ${profile.bankName}
Account: ${profile.accountNumber}

If you have already processed this payment, please disregard this message.
Thank you,
${profile.businessName}
        """.trimIndent(),

        "Overdue (3+ Days)" to """
Dear ${invoice.clientName},

Our records indicate that invoice ${invoice.invoiceNumber} ($formattedBalance) due on ${invoice.dueDate} is currently past due.

To avoid any disruption, please remit payment at your earliest convenience:
${if (profile.paymentLink.isNotBlank()) "Pay online: ${profile.paymentLink}\n" else ""}Bank: ${profile.bankName} | Account: ${profile.accountNumber}

If you have any questions or require an updated copy of the invoice, please let us know.
Sincerely,
${profile.businessName}
        """.trimIndent(),

        "Urgent Notice" to """
URGENT PAYMENT NOTICE

Invoice: ${invoice.invoiceNumber}
Amount Outstanding: $formattedBalance
Original Due Date: ${invoice.dueDate}

Dear ${invoice.clientName},
Payment for the above invoice is now significantly overdue. Please settle this balance immediately via:
${profile.bankName} - Account: ${profile.accountNumber}
${if (profile.paymentLink.isNotBlank()) "Direct Link: ${profile.paymentLink}" else ""}

Thank you for resolving this promptly.
${profile.legalName}
        """.trimIndent()
    )

    var selectedTemplateIndex by remember {
        mutableIntStateOf(if (invoice.status.equals("overdue", true)) 2 else 0)
    }

    var messageBody by remember(selectedTemplateIndex) {
        mutableStateOf(templates[selectedTemplateIndex].second)
    }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = MaterialTheme.colorScheme.surface
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp)
                .padding(bottom = 32.dp)
                .verticalScroll(rememberScrollState())
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        modifier = Modifier
                            .size(36.dp)
                            .clip(RoundedCornerShape(8.dp))
                            .background(MaterialTheme.colorScheme.primaryContainer),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.NotificationsActive,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                    Spacer(modifier = Modifier.width(12.dp))
                    Column {
                        Text(
                            text = "Payment Reminder",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = "${invoice.invoiceNumber} • $formattedBalance",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }

                IconButton(onClick = onDismiss) {
                    Icon(imageVector = Icons.Default.Close, contentDescription = "Close")
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = "Select Reminder Template:",
                style = MaterialTheme.typography.labelMedium,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Spacer(modifier = Modifier.height(8.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                templates.forEachIndexed { index, (label, _) ->
                    FilterChip(
                        selected = selectedTemplateIndex == index,
                        onClick = { selectedTemplateIndex = index },
                        label = { Text(label, fontSize = 12.sp) },
                        modifier = Modifier.testTag("reminder_chip_$index")
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            OutlinedTextField(
                value = messageBody,
                onValueChange = { messageBody = it },
                label = { Text("Customized Message") },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(200.dp)
                    .testTag("reminder_message_input"),
                shape = RoundedCornerShape(12.dp),
                textStyle = MaterialTheme.typography.bodyMedium
            )

            Spacer(modifier = Modifier.height(20.dp))

            // Action Buttons
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                // Email Intent
                Button(
                    onClick = {
                        val emailIntent = Intent(Intent.ACTION_SENDTO).apply {
                            data = Uri.parse("mailto:")
                            if (invoice.clientEmail.isNotBlank()) {
                                putExtra(Intent.EXTRA_EMAIL, arrayOf(invoice.clientEmail))
                            }
                            putExtra(Intent.EXTRA_SUBJECT, "Payment Reminder: ${invoice.invoiceNumber} - ${profile.businessName}")
                            putExtra(Intent.EXTRA_TEXT, messageBody)
                        }
                        try {
                            context.startActivity(Intent.createChooser(emailIntent, "Send Reminder Email"))
                            onReminderSent(invoice.id)
                            onDismiss()
                        } catch (e: Exception) {
                            Toast.makeText(context, "No email app found", Toast.LENGTH_SHORT).show()
                        }
                    },
                    modifier = Modifier
                        .weight(1f)
                        .testTag("send_email_button"),
                    colors = ButtonDefaults.buttonColors(containerColor = PrimaryNavy),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Icon(imageVector = Icons.Default.Email, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(modifier = Modifier.width(6.dp))
                    Text("Email")
                }

                // WhatsApp / Messages / Share Intent
                Button(
                    onClick = {
                        val shareIntent = Intent(Intent.ACTION_SEND).apply {
                            type = "text/plain"
                            putExtra(Intent.EXTRA_TEXT, messageBody)
                        }
                        try {
                            context.startActivity(Intent.createChooser(shareIntent, "Share Payment Reminder"))
                            onReminderSent(invoice.id)
                            onDismiss()
                        } catch (e: Exception) {
                            Toast.makeText(context, "Could not share message", Toast.LENGTH_SHORT).show()
                        }
                    },
                    modifier = Modifier
                        .weight(1f)
                        .testTag("share_reminder_button"),
                    colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.secondary),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Icon(imageVector = Icons.Default.Share, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(modifier = Modifier.width(6.dp))
                    Text("Share")
                }

                // Copy to Clipboard
                OutlinedButton(
                    onClick = {
                        val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                        val clip = ClipData.newPlainText("Payment Reminder", messageBody)
                        clipboard.setPrimaryClip(clip)
                        Toast.makeText(context, "Copied to clipboard", Toast.LENGTH_SHORT).show()
                        onReminderSent(invoice.id)
                    },
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.testTag("copy_reminder_button")
                ) {
                    Icon(imageVector = Icons.Default.ContentCopy, contentDescription = "Copy", modifier = Modifier.size(18.dp))
                }
            }
        }
    }
}
