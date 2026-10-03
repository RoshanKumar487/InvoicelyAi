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
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Assessment
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Calculate
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.DarkMode
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.LightMode
import androidx.compose.material.icons.filled.People
import androidx.compose.material.icons.filled.ReceiptLong
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Tune
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.SheetState
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.ui.theme.PrimaryNavy
import androidx.compose.foundation.isSystemInDarkTheme

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
    isDarkTheme: Boolean = isSystemInDarkTheme(),
    onToggleDarkTheme: ((Boolean) -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    val adaptiveInfo = rememberWindowAdaptiveInfo()
    val isTablet = adaptiveInfo.isTablet
    val columns = adaptiveInfo.menuColumns

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

    val isDark = isSystemInDarkTheme()

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = if (isDark) Color(0xF00F172A) else Color(0xF8FFFFFF),
        shape = RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp)
    ) {
        // Centered container with max width on tablets so it looks like a refined sheet
        Box(
            modifier = Modifier.fillMaxWidth(),
            contentAlignment = Alignment.TopCenter
        ) {
            Column(
                modifier = modifier
                    .fillMaxWidth()
                    .widthIn(max = if (isTablet) 720.dp else 540.dp)
                    .padding(horizontal = if (isTablet) 24.dp else 16.dp, vertical = 6.dp)
                    .verticalScroll(rememberScrollState())
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
                            fontSize = if (isTablet) 20.sp else 18.sp,
                            fontWeight = FontWeight.Bold,
                            color = if (isDark) Color.White else PrimaryNavy
                        )
                        Text(
                            text = "Quick access to all features & tools",
                            fontSize = if (isTablet) 13.sp else 12.sp,
                            color = if (isDark) Color(0xFF94A3B8) else Color.Gray
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

                Spacer(modifier = Modifier.height(12.dp))
                HorizontalDivider(color = if (isDark) Color(0xFF334155) else Color(0xFFE2E8F0))
                Spacer(modifier = Modifier.height(12.dp))

                // =================================================================
                // GLASSMORPHISM THEME MODE SWITCH (Directly in Menu)
                // =================================================================
                GlassCard(
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("menu_theme_toggle_card"),
                    shape = RoundedCornerShape(16.dp),
                    elevation = 2.dp
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = if (isTablet) 16.dp else 12.dp, vertical = 10.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(if (isTablet) 46.dp else 40.dp)
                                    .clip(CircleShape)
                                    .background(if (isDark) Color(0xFF312E81) else Color(0xFFFEF3C7)),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(
                                    imageVector = if (isDark) Icons.Default.DarkMode else Icons.Default.LightMode,
                                    contentDescription = "Theme Mode",
                                    tint = if (isDark) Color(0xFFA5B4FC) else Color(0xFFD97706),
                                    modifier = Modifier.size(if (isTablet) 24.dp else 20.dp)
                                )
                            }
                            Column {
                                Text(
                                    text = if (isDark) "Dark Glass Theme" else "Light Glass Theme",
                                    fontSize = if (isTablet) 15.5.sp else 14.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = if (isDark) Color.White else PrimaryNavy
                                )
                                Text(
                                    text = if (isDark) "Obsidian Glass & Neon Glow Orbs" else "Sapphire Frost & Crisp Translucency",
                                    fontSize = if (isTablet) 12.sp else 11.sp,
                                    color = if (isDark) Color(0xFF94A3B8) else Color(0xFF64748B)
                                )
                            }
                        }

                        Switch(
                            checked = isDark,
                            onCheckedChange = { onToggleDarkTheme?.invoke(it) },
                            colors = SwitchDefaults.colors(
                                checkedThumbColor = Color.White,
                                checkedTrackColor = Color(0xFF4F46E5),
                                uncheckedThumbColor = Color.White,
                                uncheckedTrackColor = Color(0xFFCBD5E1)
                            )
                        )
                    }
                }

                Spacer(modifier = Modifier.height(14.dp))

                // Responsive Icon-based Sections List / Grid
                val chunkedItems = menuItems.chunked(columns)
                Column(
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(bottom = 28.dp)
                ) {
                    chunkedItems.forEach { rowItems ->
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(10.dp)
                        ) {
                            rowItems.forEach { item ->
                                Box(modifier = Modifier.weight(1f)) {
                                    MenuItemCard(
                                        item = item,
                                        isDark = isDark,
                                        iconSize = if (isTablet) 44.dp else 38.dp,
                                        titleSize = if (isTablet) 15.sp else 14.sp,
                                        subtitleSize = if (isTablet) 12.sp else 11.sp
                                    )
                                }
                            }
                            if (rowItems.size < columns) {
                                repeat(columns - rowItems.size) {
                                    Spacer(modifier = Modifier.weight(1f))
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun MenuItemCard(
    item: MenuItemData,
    isDark: Boolean,
    iconSize: Dp,
    titleSize: TextUnit,
    subtitleSize: TextUnit
) {
    GlassCard(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { item.onClick() }
            .testTag(item.id),
        shape = RoundedCornerShape(16.dp),
        elevation = 1.dp
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(iconSize)
                    .clip(CircleShape)
                    .background(item.iconBgColor),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = item.icon,
                    contentDescription = item.title,
                    tint = item.iconColor,
                    modifier = Modifier.size(iconSize * 0.52f)
                )
            }

            Spacer(modifier = Modifier.width(12.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = item.title,
                    fontSize = titleSize,
                    fontWeight = FontWeight.Bold,
                    color = if (isDark) Color.White else Color(0xFF1E293B)
                )
                Text(
                    text = item.subtitle,
                    fontSize = subtitleSize,
                    color = if (isDark) Color(0xFF94A3B8) else Color(0xFF64748B)
                )
            }
        }
    }
}
