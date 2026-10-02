package com.example.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Assessment
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Calculate
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.People
import androidx.compose.material.icons.filled.ReceiptLong
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Tune
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.SheetState
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.ui.theme.PrimaryNavy

data class MenuItemData(
    val id: String,
    val title: String,
    val subtitle: String,
    val icon: ImageVector,
    val iconColor: Color,
    val iconBgColor: Color,
    val onClick: () -> Unit
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AppMenuModalSheet(
    sheetState: SheetState,
    onDismiss: () -> Unit,
    onNavigateToClients: () -> Unit,
    onNavigateToReports: () -> Unit,
    onNavigateToTemplates: () -> Unit,
    onNavigateToTaxTool: () -> Unit,
    onNavigateToSettings: () -> Unit,
    onNavigateToExpenses: () -> Unit,
    onNavigateToAiAgent: () -> Unit,
    onNavigateToInvoiceSettings: () -> Unit = {},
    modifier: Modifier = Modifier
) {
    val menuItems = listOf(
        MenuItemData(
            id = "menu_invoice_settings",
            title = "Invoice Settings",
            subtitle = "Section Controls & Layout",
            icon = Icons.Default.Tune,
            iconColor = Color(0xFF0284C7),
            iconBgColor = Color(0xFFE0F2FE),
            onClick = { onDismiss(); onNavigateToInvoiceSettings() }
        ),
        MenuItemData(
            id = "menu_clients",
            title = "Clients",
            subtitle = "Directory & Contacts",
            icon = Icons.Default.People,
            iconColor = Color(0xFF2563EB),
            iconBgColor = Color(0xFFDBEAFE),
            onClick = { onDismiss(); onNavigateToClients() }
        ),
        MenuItemData(
            id = "menu_reports",
            title = "Reports",
            subtitle = "Revenue & Tax Metrics",
            icon = Icons.Default.Assessment,
            iconColor = Color(0xFF059669),
            iconBgColor = Color(0xFFD1FAE5),
            onClick = { onDismiss(); onNavigateToReports() }
        ),
        MenuItemData(
            id = "menu_templates",
            title = "DOCX Templates",
            subtitle = "10 Styled Formats",
            icon = Icons.Default.Description,
            iconColor = Color(0xFF7C3AED),
            iconBgColor = Color(0xFFEDE9FE),
            onClick = { onDismiss(); onNavigateToTemplates() }
        ),
        MenuItemData(
            id = "menu_tax_tool",
            title = "Tax Calculator",
            subtitle = "GST & VAT Slabs",
            icon = Icons.Default.Calculate,
            iconColor = Color(0xFFD97706),
            iconBgColor = Color(0xFFFEF3C7),
            onClick = { onDismiss(); onNavigateToTaxTool() }
        ),
        MenuItemData(
            id = "menu_expenses",
            title = "Expenses & Bills",
            subtitle = "Scan & Track Deductions",
            icon = Icons.Default.ReceiptLong,
            iconColor = Color(0xFFDC2626),
            iconBgColor = Color(0xFFFEE2E2),
            onClick = { onDismiss(); onNavigateToExpenses() }
        ),
        MenuItemData(
            id = "menu_ai_agent",
            title = "Gemini AI Agent",
            subtitle = "Voice & Chat Invoicing",
            icon = Icons.Default.AutoAwesome,
            iconColor = Color(0xFF4F46E5),
            iconBgColor = Color(0xFFEEF2FF),
            onClick = { onDismiss(); onNavigateToAiAgent() }
        ),
        MenuItemData(
            id = "menu_settings",
            title = "Business Settings",
            subtitle = "Profile, Bank, UPI, Taxes",
            icon = Icons.Default.Settings,
            iconColor = Color(0xFF475569),
            iconBgColor = Color(0xFFF1F5F9),
            onClick = { onDismiss(); onNavigateToSettings() }
        )
    )

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = Color.White,
        shape = RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp)
    ) {
        Column(
            modifier = modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp, vertical = 8.dp)
        ) {
            // Header Row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        text = "App Navigation Menu",
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold,
                        color = PrimaryNavy
                    )
                    Text(
                        text = "Quick access to all features & tools",
                        fontSize = 12.sp,
                        color = Color.Gray
                    )
                }
                IconButton(onClick = onDismiss) {
                    Icon(
                        imageVector = Icons.Default.Close,
                        contentDescription = "Close Menu",
                        tint = Color.Gray
                    )
                }
            }

            Spacer(modifier = Modifier.height(14.dp))
            HorizontalDivider(color = Color(0xFFE2E8F0))
            Spacer(modifier = Modifier.height(14.dp))

            // Icon-based Sections List / Grid
            Column(
                verticalArrangement = Arrangement.spacedBy(10.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 24.dp)
            ) {
                menuItems.forEach { item ->
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { item.onClick() }
                            .testTag(item.id),
                        shape = RoundedCornerShape(12.dp),
                        colors = CardDefaults.cardColors(containerColor = Color(0xFFF8FAFC)),
                        border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFE2E8F0))
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(12.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(42.dp)
                                    .clip(CircleShape)
                                    .background(item.iconBgColor),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(
                                    imageVector = item.icon,
                                    contentDescription = item.title,
                                    tint = item.iconColor,
                                    modifier = Modifier.size(22.dp)
                                )
                            }

                            Spacer(modifier = Modifier.width(14.dp))

                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = item.title,
                                    fontSize = 15.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = Color(0xFF1E293B)
                                )
                                Text(
                                    text = item.subtitle,
                                    fontSize = 12.sp,
                                    color = Color(0xFF64748B)
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}
