package com.example.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.isSystemInDarkTheme
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
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowForward
import androidx.compose.material.icons.filled.Business
import androidx.compose.material.icons.filled.Calculate
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.HourglassTop
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.People
import androidx.compose.material.icons.filled.Receipt
import androidx.compose.material.icons.filled.Security
import androidx.compose.material.icons.filled.TrendingUp
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material.icons.filled.CloudDone
import androidx.compose.material.icons.filled.CloudOff
import androidx.compose.material.icons.filled.AccountBalanceWallet
import com.example.ui.components.rememberWindowAdaptiveInfo
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.ui.graphics.Brush
import com.example.data.model.InvoiceEntity
import com.example.data.model.InvoiceUtils
import com.example.ui.components.BusinessCustomIcon
import com.example.ui.components.GlassCard
import com.example.ui.components.GlassHeroCard
import com.example.ui.components.GlassPrimaryButton
import com.example.ui.components.InvoiceStatusBadge
import com.example.ui.components.PaymentReminderBottomSheet
import com.example.ui.components.RevenueChart
import com.example.ui.components.AdaptiveContainer
import com.example.ui.components.rememberWindowAdaptiveInfo
import com.example.ui.components.StatMetricCard
import com.example.ui.theme.AccentIndigo
import com.example.ui.theme.AccentTeal
import com.example.ui.theme.PrimaryNavy
import com.example.ui.theme.StatusOverdueRose
import com.example.ui.theme.StatusPaidGreen
import com.example.ui.theme.StatusPendingAmber
import com.example.ui.viewmodel.InvoiceViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DashboardScreen(
    viewModel: InvoiceViewModel,
    onCreateInvoice: () -> Unit,
    onViewInvoices: () -> Unit,
    onViewClients: () -> Unit,
    onViewTemplates: () -> Unit,
    onViewTaxTool: () -> Unit,
    onOpenInvoice: (Long) -> Unit,
    onOpenAiChat: () -> Unit = {},
    onOpenMenu: () -> Unit = {},
    modifier: Modifier = Modifier
) {
    val analytics by viewModel.dashboardAnalytics.collectAsStateWithLifecycle()
    val allInvoices by viewModel.allInvoices.collectAsStateWithLifecycle()
    val profile by viewModel.businessProfile.collectAsStateWithLifecycle()
    val currentUser by com.example.data.repository.AuthSessionManager.currentUser.collectAsStateWithLifecycle()

    var reminderInvoice by remember { mutableStateOf<InvoiceEntity?>(null) }
    val reminderSheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    val recentInvoices = allInvoices.take(5)

    val isOnline by viewModel.isBackendOnline.collectAsStateWithLifecycle()
    val isLiveRefreshing by viewModel.isLiveRefreshing.collectAsStateWithLifecycle()
    val isSyncing by viewModel.isSyncing.collectAsStateWithLifecycle()
    val backendStats by viewModel.backendStats.collectAsStateWithLifecycle()
    val lastSyncTime by viewModel.lastSyncTime.collectAsStateWithLifecycle()
    val allCompanies by com.example.data.repository.AuthSessionManager.allCompanies.collectAsStateWithLifecycle()
    val selectedDevCompId by viewModel.selectedDeveloperCompanyId.collectAsStateWithLifecycle()
    val developerOverview by viewModel.developerOverview.collectAsStateWithLifecycle()
    val context = androidx.compose.ui.platform.LocalContext.current
    val isDark = isSystemInDarkTheme()
    val adaptiveInfo = rememberWindowAdaptiveInfo()

    Scaffold(
        contentWindowInsets = androidx.compose.foundation.layout.WindowInsets(0, 0, 0, 0),
        modifier = modifier.fillMaxSize(),
        containerColor = Color.Transparent,
        topBar = {
            val currentUser by com.example.data.repository.AuthSessionManager.currentUser.collectAsStateWithLifecycle()
            val userRole = currentUser?.role ?: com.example.data.model.UserRole.ADMIN
            TopAppBar(
                navigationIcon = {
                    Box(modifier = Modifier.padding(start = 12.dp, end = 4.dp)) {
                        BusinessCustomIcon(
                            profile = profile,
                            size = 40.dp
                        )
                    }
                },
                title = {
                    Column {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(6.dp)
                        ) {
                            Text(
                                text = if (userRole == com.example.data.model.UserRole.DEVELOPER) "Platform Developer" else profile.businessName,
                                style = MaterialTheme.typography.titleLarge,
                                fontWeight = FontWeight.ExtraBold,
                                color = if (isDark) Color.White else Color(0xFF0F172A),
                                fontSize = adaptiveInfo.titleLargeSize
                            )
                            Surface(
                                shape = RoundedCornerShape(8.dp),
                                color = userRole.badgeBgColor
                            ) {
                                Text(
                                    text = userRole.shortBadge,
                                    color = userRole.badgeFgColor,
                                    fontSize = 10.sp,
                                    fontWeight = FontWeight.ExtraBold,
                                    modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                )
                            }
                        }
                        Text(
                            text = when (userRole) {
                                com.example.data.model.UserRole.DEVELOPER -> "Cross-Company Platform Control & Monitoring"
                                com.example.data.model.UserRole.EMPLOYEE -> "Staff Workspace • Operational Access"
                                else -> "Organization Overview & Real-Time Analytics"
                            },
                            style = MaterialTheme.typography.bodySmall,
                            color = if (isDark) Color(0xFF94A3B8) else Color(0xFF64748B),
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Medium
                        )
                    }
                },
                actions = {
                    // Live Real-Time Connection / Refresh status indicator
                    IconButton(
                        onClick = {
                            viewModel.refreshRealtimeData()
                        },
                        modifier = Modifier.testTag("dashboard_sync_btn")
                    ) {
                        Box(
                            modifier = Modifier
                                .size(36.dp)
                                .clip(CircleShape)
                                .background(if (isOnline) Color(0xFFDCFCE7) else (if (isDark) Color(0xFF1E293B) else Color(0xFFF1F5F9))),
                            contentAlignment = Alignment.Center
                        ) {
                            if (isLiveRefreshing) {
                                CircularProgressIndicator(
                                    modifier = Modifier.size(18.dp),
                                    strokeWidth = 2.dp,
                                    color = Color(0xFF16A34A)
                                )
                            } else {
                                Icon(
                                    imageVector = if (isOnline) Icons.Default.CloudDone else Icons.Default.CloudOff,
                                    contentDescription = "Cloud Realtime",
                                    tint = if (isOnline) Color(0xFF16A34A) else Color(0xFF64748B),
                                    modifier = Modifier.size(20.dp)
                                )
                            }
                        }
                    }

                    // New Invoice Button (if allowed by role and permissions)
                    val canCreateInvoice = currentUser?.role != com.example.data.model.UserRole.EMPLOYEE || (currentUser?.canAccessFeature("INVOICES") == true)
                    if (canCreateInvoice) {
                        IconButton(
                            onClick = onCreateInvoice,
                            modifier = Modifier.testTag("create_invoice_fab")
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
                                    contentDescription = "New Invoice",
                                    tint = Color.White,
                                    modifier = Modifier.size(20.dp)
                                )
                            }
                        }
                    }

                    // Tax Calculator
                    IconButton(
                        onClick = onViewTaxTool,
                        modifier = Modifier.testTag("dashboard_tax_calc_btn")
                    ) {
                        Box(
                            modifier = Modifier
                                .size(36.dp)
                                .clip(CircleShape)
                                .background(if (isDark) Color(0xFF1E293B) else Color(0xFFEFF6FF)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Default.Calculate,
                                contentDescription = "Tax Calculator",
                                tint = Color(0xFF2563EB),
                                modifier = Modifier.size(20.dp)
                            )
                        }
                    }

                    // Menu Action
                    IconButton(
                        onClick = onOpenMenu,
                        modifier = Modifier.testTag("dashboard_menu_btn")
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
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Transparent
                )
            )
        }
    ) { padding ->
        AdaptiveContainer(maxWidth = adaptiveInfo.contentMaxWidth) {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding),
                contentPadding = PaddingValues(horizontal = adaptiveInfo.horizontalPadding, vertical = 10.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
            // Real-Time Live Cloud Status & Identity Mapping Banner
            item {
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("backend_sync_banner"),
                    colors = CardDefaults.cardColors(
                        containerColor = if (isOnline) {
                            if (isDark) Color(0xFF064E3B).copy(alpha = 0.35f) else Color(0xFFF0FDF4)
                        } else {
                            if (isDark) Color(0xFF1E293B).copy(alpha = 0.5f) else Color(0xFFF8FAFC)
                        }
                    ),
                    shape = RoundedCornerShape(16.dp),
                    border = BorderStroke(1.dp, if (isOnline) Color(0xFF86EFAC) else Color(0xFFCBD5E1))
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 14.dp, vertical = 11.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(10.dp),
                            modifier = Modifier.weight(1f)
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(10.dp)
                                    .clip(CircleShape)
                                    .background(if (isOnline) Color(0xFF22C55E) else Color(0xFF94A3B8))
                            )
                            Column {
                                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                    Text(
                                        text = if (isOnline) "PostgreSQL Real-Time Connected" else "Local Offline Mode",
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 12.sp,
                                        color = if (isOnline) (if (isDark) Color(0xFF86EFAC) else Color(0xFF15803D)) else Color(0xFF64748B)
                                    )
                                    if (isLiveRefreshing) {
                                        Text(
                                            text = "• Live Updating...",
                                            fontSize = 11.sp,
                                            color = Color(0xFF2563EB),
                                            fontWeight = FontWeight.SemiBold
                                        )
                                    }
                                }
                                val mappingInfo = buildString {
                                    append(currentUser?.fullName ?: "User")
                                    append(" • ")
                                    append(currentUser?.role?.name ?: "ADMIN")
                                    if (!currentUser?.companyCode.isNullOrBlank()) {
                                        append(" • Org: ${currentUser?.companyCode}")
                                    }
                                    if (currentUser?.id != null && currentUser?.id != 0L) {
                                        append(" • User ID: #${currentUser?.id}")
                                    }
                                }
                                Text(
                                    text = mappingInfo,
                                    fontSize = 11.sp,
                                    color = if (isDark) Color(0xFFCBD5E1) else Color(0xFF475569)
                                )
                            }
                        }

                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = if (isOnline) Color(0xFFDCFCE7) else Color(0xFFE2E8F0)
                        ) {
                            Text(
                                text = "REAL-TIME",
                                fontSize = 10.sp,
                                fontWeight = FontWeight.ExtraBold,
                                color = if (isOnline) Color(0xFF16A34A) else Color(0xFF475569),
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
                            )
                        }
                    }
                }
            }

            // Developer Platform Multi-Company Control Center
            if (currentUser?.role == com.example.data.model.UserRole.DEVELOPER) {
                item {
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        colors = CardDefaults.cardColors(containerColor = if (isDark) Color(0xFF1E1B4B) else Color(0xFFFAF5FF)),
                        shape = RoundedCornerShape(18.dp),
                        border = BorderStroke(1.dp, Color(0xFFC084FC).copy(alpha = 0.5f))
                    ) {
                        Column(modifier = Modifier.padding(14.dp)) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                Icon(Icons.Default.Security, contentDescription = null, tint = Color(0xFF9333EA), modifier = Modifier.size(20.dp))
                                Text(
                                    text = "Developer Multi-Company Control Center",
                                    fontWeight = FontWeight.ExtraBold,
                                    fontSize = 14.sp,
                                    color = if (isDark) Color(0xFFE9D5FF) else Color(0xFF581C87)
                                )
                            }
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = "Independent superuser mode. Filter data by company ID or inspect all registered organizations globally.",
                                fontSize = 11.5.sp,
                                color = if (isDark) Color(0xFFD8B4FE) else Color(0xFF7E22CE)
                            )
                            Spacer(modifier = Modifier.height(10.dp))

                            // Horizontal Company Switcher Chips
                            LazyRow(
                                horizontalArrangement = Arrangement.spacedBy(8.dp),
                                contentPadding = PaddingValues(vertical = 4.dp)
                            ) {
                                item {
                                    val isGlobal = selectedDevCompId == null
                                    Surface(
                                        shape = RoundedCornerShape(20.dp),
                                        color = if (isGlobal) Color(0xFF9333EA) else (if (isDark) Color(0xFF3B0764) else Color(0xFFF3E8FF)),
                                        border = BorderStroke(1.dp, if (isGlobal) Color(0xFF9333EA) else Color(0xFFD8B4FE)),
                                        modifier = Modifier.clickable { viewModel.setDeveloperSelectedCompany(null) }
                                    ) {
                                        Text(
                                            text = "🌐 All Companies (Global)",
                                            fontSize = 11.5.sp,
                                            fontWeight = if (isGlobal) FontWeight.Bold else FontWeight.Medium,
                                            color = if (isGlobal) Color.White else (if (isDark) Color(0xFFE9D5FF) else Color(0xFF581C87)),
                                            modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp)
                                        )
                                    }
                                }

                                val compList = developerOverview?.companies ?: emptyList()
                                items(compList) { comp ->
                                    val isSelected = selectedDevCompId == comp.companyId
                                    Surface(
                                        shape = RoundedCornerShape(20.dp),
                                        color = if (isSelected) Color(0xFF9333EA) else (if (isDark) Color(0xFF3B0764) else Color(0xFFF3E8FF)),
                                        border = BorderStroke(1.dp, if (isSelected) Color(0xFF9333EA) else Color(0xFFD8B4FE)),
                                        modifier = Modifier.clickable { viewModel.setDeveloperSelectedCompany(comp.companyId) }
                                    ) {
                                        Text(
                                            text = "🏢 ${comp.companyName} (${comp.companyCode})",
                                            fontSize = 11.5.sp,
                                            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                                            color = if (isSelected) Color.White else (if (isDark) Color(0xFFE9D5FF) else Color(0xFF581C87)),
                                            modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp)
                                        )
                                    }
                                }
                            }
                        }
                    }
                }

                // Global Platform Overview KPI Cards (When viewing globally or selected company)
                item {
                    val dev = developerOverview
                    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                            StatMetricCard(
                                title = "Total Orgs",
                                value = "${dev?.totalCompanies ?: allCompanies.size}",
                                subtext = "Registered businesses",
                                icon = Icons.Default.Business,
                                iconTint = Color(0xFF7E22CE),
                                iconBgColor = Color(0xFFF3E8FF),
                                modifier = Modifier.weight(1f),
                                testTag = "dev_stat_companies"
                            )
                            StatMetricCard(
                                title = "Platform Users",
                                value = "${dev?.totalUsers ?: 0}",
                                subtext = "Mapped across companies",
                                icon = Icons.Default.People,
                                iconTint = PrimaryNavy,
                                iconBgColor = Color(0xFFEFF6FF),
                                modifier = Modifier.weight(1f),
                                testTag = "dev_stat_users"
                            )
                        }
                        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                            StatMetricCard(
                                title = "Platform Revenue",
                                value = InvoiceUtils.formatMoney(dev?.totalPlatformRevenue ?: 0.0, "$"),
                                subtext = "${dev?.totalInvoices ?: 0} invoices created",
                                icon = Icons.Default.TrendingUp,
                                iconTint = StatusPaidGreen,
                                iconBgColor = Color(0xFFD1FAE5),
                                modifier = Modifier.weight(1f),
                                testTag = "dev_stat_revenue"
                            )
                            StatMetricCard(
                                title = "Platform Expenses",
                                value = InvoiceUtils.formatMoney(dev?.totalPlatformExpenses ?: 0.0, "$"),
                                subtext = "${dev?.totalExpenses ?: 0} recorded items",
                                icon = Icons.Default.AccountBalanceWallet,
                                iconTint = StatusOverdueRose,
                                iconBgColor = Color(0xFFFEE2E2),
                                modifier = Modifier.weight(1f),
                                testTag = "dev_stat_expenses"
                            )
                        }
                    }
                }
            }

            // Operational Role Guidance Banner
            if (currentUser?.role == com.example.data.model.UserRole.EMPLOYEE) {
                item {
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        colors = CardDefaults.cardColors(containerColor = if (isDark) Color(0xFF064E3B).copy(alpha = 0.45f) else Color(0xFFECFDF5)),
                        shape = RoundedCornerShape(18.dp),
                        border = BorderStroke(1.dp, Color(0xFFA7F3D0))
                    ) {
                        Row(
                            modifier = Modifier.padding(14.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(36.dp)
                                    .clip(CircleShape)
                                    .background(Color(0xFF059669)),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(Icons.Default.Receipt, contentDescription = null, tint = Color.White, modifier = Modifier.size(20.dp))
                            }
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = "Staff Operations: ${currentUser?.fullName}",
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 13.5.sp,
                                    color = if (isDark) Color(0xFFA7F3D0) else Color(0xFF065F46)
                                )
                                val toolPerms = currentUser?.permissions?.replace(",", " • ") ?: "INVOICES • EXPENSES"
                                Text(
                                    text = "Granted Tool Access: $toolPerms\nYou are viewing data created and mapped to your account.",
                                    fontSize = 11.5.sp,
                                    color = if (isDark) Color(0xFFD1FAE5) else Color(0xFF047857)
                                )
                            }
                        }
                    }
                }
            }

            // Gemini AI Voice & Chat Assistant Hero Banner
            item {
                GlassHeroCard(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { onOpenAiChat() }
                        .testTag("dashboard_ai_banner"),
                    shape = RoundedCornerShape(22.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(
                                Brush.linearGradient(
                                    colors = if (isDark) {
                                        listOf(
                                            Color(0xFF1E3A8A).copy(alpha = 0.90f),
                                            Color(0xFF312E81).copy(alpha = 0.85f),
                                            Color(0xFF581C87).copy(alpha = 0.80f)
                                        )
                                    } else {
                                        listOf(
                                            Color(0xFF1E40AF),
                                            Color(0xFF2563EB),
                                            Color(0xFF6366F1)
                                        )
                                    }
                                )
                            )
                            .padding(18.dp)
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.SpaceBetween,
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Column(modifier = Modifier.weight(1f)) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Surface(
                                        color = Color.White.copy(alpha = 0.22f),
                                        shape = RoundedCornerShape(10.dp),
                                        border = BorderStroke(1.dp, Color.White.copy(alpha = 0.35f))
                                    ) {
                                        Text(
                                            text = "GEMINI 2.0 FLASH",
                                            fontSize = 9.5.sp,
                                            fontWeight = FontWeight.ExtraBold,
                                            color = Color.White,
                                            modifier = Modifier.padding(horizontal = 7.dp, vertical = 2.5.dp),
                                            letterSpacing = 0.5.sp
                                        )
                                    }
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text(
                                        text = "Voice & Chat Assistant",
                                        fontSize = 11.5.sp,
                                        fontWeight = FontWeight.SemiBold,
                                        color = Color.White.copy(alpha = 0.92f)
                                    )
                                }
                                Spacer(modifier = Modifier.height(6.dp))
                                Text(
                                    text = "Generate Invoices via Chat",
                                    fontSize = 17.sp,
                                    fontWeight = FontWeight.ExtraBold,
                                    color = Color.White,
                                    letterSpacing = (-0.3).sp
                                )
                                Spacer(modifier = Modifier.height(3.dp))
                                Text(
                                    text = "Speak or text to generate invoices, save clients, or ask tax questions",
                                    fontSize = 12.5.sp,
                                    color = Color.White.copy(alpha = 0.88f),
                                    lineHeight = 16.5.sp
                                )
                            }
                            Spacer(modifier = Modifier.width(12.dp))
                            Box(
                                modifier = Modifier
                                    .size(46.dp)
                                    .clip(CircleShape)
                                    .background(Color.White)
                                    .border(1.5.dp, Color.White.copy(alpha = 0.6f), CircleShape),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(
                                    imageVector = Icons.Default.AutoAwesome,
                                    contentDescription = "AI",
                                    tint = Color(0xFF1D4ED8),
                                    modifier = Modifier.size(24.dp)
                                )
                            }
                        }
                    }
                }
            }

            // Quick Action Shortcuts Bar (Role & Permissions Filtered)
            item {
                val canAccessInvoices = currentUser?.role != com.example.data.model.UserRole.EMPLOYEE || (currentUser?.canAccessFeature("INVOICES") == true)
                val canAccessExpenses = currentUser?.role != com.example.data.model.UserRole.EMPLOYEE || (currentUser?.canAccessFeature("EXPENSES") == true)
                val canAccessClients = currentUser?.role != com.example.data.model.UserRole.EMPLOYEE || (currentUser?.canAccessFeature("CLIENTS") == true)
                val isStaff = currentUser?.role == com.example.data.model.UserRole.EMPLOYEE

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    if (canAccessInvoices) {
                        QuickActionChip(
                            icon = Icons.Default.Receipt,
                            label = "Invoices",
                            badge = "${analytics.totalInvoiceCount}",
                            onClick = onViewInvoices,
                            modifier = Modifier.weight(1f),
                            testTag = "quick_invoices"
                        )
                    }
                    if (canAccessExpenses) {
                        QuickActionChip(
                            icon = Icons.Default.AccountBalanceWallet,
                            label = "Expenses",
                            onClick = onViewTaxTool,
                            modifier = Modifier.weight(1f),
                            testTag = "quick_expenses"
                        )
                    }
                    if (canAccessClients) {
                        QuickActionChip(
                            icon = Icons.Default.People,
                            label = "Clients",
                            onClick = onViewClients,
                            modifier = Modifier.weight(1f),
                            testTag = "quick_clients"
                        )
                    }
                    if (!isStaff) {
                        QuickActionChip(
                            icon = Icons.Default.Description,
                            label = "Templates",
                            onClick = onViewTemplates,
                            modifier = Modifier.weight(1f),
                            testTag = "quick_templates"
                        )
                    }
                }
            }

            // High Level KPI Stat Cards Grid (Adaptive: 4 across on tablet, 2x2 on phone)
            item {
                if (adaptiveInfo.metricColumns == 4) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        StatMetricCard(
                            title = "Total Invoiced",
                            value = InvoiceUtils.formatMoney(analytics.totalInvoiced, profile.defaultCurrencySymbol),
                            subtext = "${analytics.totalInvoiceCount} total invoices",
                            icon = Icons.Default.TrendingUp,
                            iconTint = PrimaryNavy,
                            iconBgColor = Color(0xFFEFF6FF),
                            modifier = Modifier.weight(1f),
                            testTag = "stat_total_invoiced"
                        )
                        StatMetricCard(
                            title = "Paid Collected",
                            value = InvoiceUtils.formatMoney(analytics.totalPaid, profile.defaultCurrencySymbol),
                            subtext = "${analytics.paidCount} fully settled",
                            icon = Icons.Default.CheckCircle,
                            iconTint = StatusPaidGreen,
                            iconBgColor = Color(0xFFD1FAE5),
                            modifier = Modifier.weight(1f),
                            testTag = "stat_total_paid"
                        )
                        StatMetricCard(
                            title = "Outstanding",
                            value = InvoiceUtils.formatMoney(analytics.totalOutstanding, profile.defaultCurrencySymbol),
                            subtext = "${analytics.pendingCount} pending payment",
                            icon = Icons.Default.HourglassTop,
                            iconTint = StatusPendingAmber,
                            iconBgColor = Color(0xFFFEF3C7),
                            modifier = Modifier.weight(1f),
                            testTag = "stat_total_outstanding"
                        )
                        StatMetricCard(
                            title = "Overdue",
                            value = InvoiceUtils.formatMoney(analytics.totalOverdue, profile.defaultCurrencySymbol),
                            subtext = "${analytics.overdueCount} require reminder",
                            icon = Icons.Default.Warning,
                            iconTint = StatusOverdueRose,
                            iconBgColor = Color(0xFFFEE2E2),
                            modifier = Modifier.weight(1f),
                            testTag = "stat_total_overdue"
                        )
                    }
                } else {
                    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            StatMetricCard(
                                title = "Total Invoiced",
                                value = InvoiceUtils.formatMoney(analytics.totalInvoiced, profile.defaultCurrencySymbol),
                                subtext = "${analytics.totalInvoiceCount} total invoices",
                                icon = Icons.Default.TrendingUp,
                                iconTint = PrimaryNavy,
                                iconBgColor = Color(0xFFEFF6FF),
                                modifier = Modifier.weight(1f),
                                testTag = "stat_total_invoiced"
                            )
                            StatMetricCard(
                                title = "Paid Collected",
                                value = InvoiceUtils.formatMoney(analytics.totalPaid, profile.defaultCurrencySymbol),
                                subtext = "${analytics.paidCount} fully settled",
                                icon = Icons.Default.CheckCircle,
                                iconTint = StatusPaidGreen,
                                iconBgColor = Color(0xFFD1FAE5),
                                modifier = Modifier.weight(1f),
                                testTag = "stat_total_paid"
                            )
                        }

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            StatMetricCard(
                                title = "Outstanding",
                                value = InvoiceUtils.formatMoney(analytics.totalOutstanding, profile.defaultCurrencySymbol),
                                subtext = "${analytics.pendingCount} pending payment",
                                icon = Icons.Default.HourglassTop,
                                iconTint = StatusPendingAmber,
                                iconBgColor = Color(0xFFFEF3C7),
                                modifier = Modifier.weight(1f),
                                testTag = "stat_total_outstanding"
                            )
                            StatMetricCard(
                                title = "Overdue",
                                value = InvoiceUtils.formatMoney(analytics.totalOverdue, profile.defaultCurrencySymbol),
                                subtext = "${analytics.overdueCount} require reminder",
                                icon = Icons.Default.Warning,
                                iconTint = StatusOverdueRose,
                                iconBgColor = Color(0xFFFEE2E2),
                                modifier = Modifier.weight(1f),
                                testTag = "stat_total_overdue"
                            )
                        }
                    }
                }
            }

            // Monthly Revenue & Trend Chart
            item {
                RevenueChart(
                    items = analytics.monthlyRevenue,
                    currencySymbol = profile.defaultCurrencySymbol
                )
            }

            // Recent Invoices Header
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Recent Invoices",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    TextButton(
                        onClick = onViewInvoices,
                        modifier = Modifier.testTag("view_all_invoices_btn")
                    ) {
                        Text("View All", fontWeight = FontWeight.SemiBold)
                        Spacer(modifier = Modifier.width(4.dp))
                        Icon(imageVector = Icons.Default.ArrowForward, contentDescription = null, modifier = Modifier.size(16.dp))
                    }
                }
            }

            // Recent Invoices Items
            if (recentInvoices.isEmpty()) {
                item {
                    GlassCard(
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(20.dp),
                        elevation = 4.dp
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(32.dp),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(56.dp)
                                    .clip(CircleShape)
                                    .background(if (isDark) Color(0xFF1E293B) else Color(0xFFEFF6FF)),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Receipt,
                                    contentDescription = null,
                                    tint = Color(0xFF2563EB),
                                    modifier = Modifier.size(28.dp)
                                )
                            }
                            Spacer(modifier = Modifier.height(14.dp))
                            Text(
                                text = "No Invoices Yet",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold,
                                color = if (isDark) Color.White else Color(0xFF0F172A)
                            )
                            Spacer(modifier = Modifier.height(6.dp))
                            Text(
                                text = "Create your first professional invoice in seconds",
                                style = MaterialTheme.typography.bodySmall,
                                color = if (isDark) Color(0xFF94A3B8) else Color(0xFF64748B),
                                fontSize = 12.sp
                            )
                            Spacer(modifier = Modifier.height(18.dp))
                            GlassPrimaryButton(
                                text = "Create Invoice",
                                onClick = onCreateInvoice,
                                icon = Icons.Default.Add
                            )
                        }
                    }
                }
            } else {
                items(recentInvoices, key = { it.id }) { invoice ->
                    val items = InvoiceUtils.deserializeInvoiceItems(invoice.itemsJson)
                    val calcs = InvoiceUtils.calculateInvoice(
                        items = items,
                        taxRate = invoice.taxRate,
                        discountPercent = invoice.discountPercent,
                        discountAmount = invoice.discountAmount,
                        shippingFee = invoice.shippingFee,
                        amountPaid = invoice.amountPaid
                    )

                    GlassCard(
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("recent_invoice_${invoice.id}"),
                        shape = RoundedCornerShape(18.dp),
                        elevation = 4.dp,
                        onClick = { onOpenInvoice(invoice.id) }
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(16.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(44.dp)
                                    .clip(RoundedCornerShape(12.dp))
                                    .background(if (isDark) Color(0xFF1E293B) else Color(0xFFEFF6FF))
                                    .border(1.dp, Color(0xFF2563EB).copy(alpha = 0.25f), RoundedCornerShape(12.dp)),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Receipt,
                                    contentDescription = null,
                                    tint = Color(0xFF2563EB),
                                    modifier = Modifier.size(22.dp)
                                )
                            }

                            Spacer(modifier = Modifier.width(14.dp))

                            Column(modifier = Modifier.weight(1f)) {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text(
                                        text = invoice.invoiceNumber,
                                        style = MaterialTheme.typography.bodyMedium,
                                        fontWeight = FontWeight.Bold,
                                        color = if (isDark) Color.White else Color(0xFF0F172A),
                                        fontSize = 14.5.sp
                                    )
                                    Spacer(modifier = Modifier.width(8.dp))
                                    InvoiceStatusBadge(status = invoice.status)
                                }
                                Spacer(modifier = Modifier.height(3.dp))
                                Text(
                                    text = if (invoice.clientCompany.isNotBlank()) "${invoice.clientName} • ${invoice.clientCompany}" else invoice.clientName,
                                    style = MaterialTheme.typography.bodySmall,
                                    color = if (isDark) Color(0xFFCBD5E1) else Color(0xFF475569),
                                    maxLines = 1,
                                    fontWeight = FontWeight.Medium,
                                    fontSize = 12.sp
                                )
                                if (!invoice.createdByUserName.isNullOrBlank()) {
                                    Spacer(modifier = Modifier.height(2.dp))
                                    Text(
                                        text = "👤 ${invoice.createdByUserName}",
                                        fontSize = 11.sp,
                                        fontWeight = FontWeight.SemiBold,
                                        color = Color(0xFF2563EB)
                                    )
                                }
                                if (currentUser?.role == com.example.data.model.UserRole.DEVELOPER && selectedDevCompId == null && invoice.companyId != null) {
                                    Text(
                                        text = "🏢 Org #${invoice.companyId}",
                                        fontSize = 10.5.sp,
                                        fontWeight = FontWeight.Medium,
                                        color = Color(0xFF7E22CE)
                                    )
                                }
                                Spacer(modifier = Modifier.height(3.dp))
                                Text(
                                    text = "Due ${invoice.dueDate}",
                                    style = MaterialTheme.typography.labelSmall,
                                    color = if (invoice.status.equals("overdue", true)) StatusOverdueRose else Color(0xFF64748B),
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.Medium
                                )
                            }

                            Column(horizontalAlignment = Alignment.End) {
                                Text(
                                    text = InvoiceUtils.formatMoney(calcs.grandTotal, invoice.currencySymbol),
                                    style = MaterialTheme.typography.titleMedium,
                                    fontWeight = FontWeight.ExtraBold,
                                    color = if (isDark) Color.White else Color(0xFF0F172A),
                                    fontSize = 15.sp
                                )

                                if (invoice.status.equals("overdue", true) || invoice.status.equals("sent", true)) {
                                    IconButton(
                                        onClick = { reminderInvoice = invoice },
                                        modifier = Modifier
                                            .size(28.dp)
                                            .testTag("send_reminder_btn_${invoice.id}")
                                    ) {
                                        Icon(
                                            imageVector = Icons.Default.NotificationsActive,
                                            contentDescription = "Send Reminder",
                                            tint = if (invoice.status.equals("overdue", true)) StatusOverdueRose else StatusPendingAmber,
                                            modifier = Modifier.size(16.dp)
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Bottom spacing
            item {
                Spacer(modifier = Modifier.height(16.dp))
            }
        }
    }
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

@Composable
fun QuickActionChip(
    icon: ImageVector,
    label: String,
    badge: String? = null,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    testTag: String = "quick_chip"
) {
    val isDark = isSystemInDarkTheme()

    GlassCard(
        modifier = modifier
            .testTag(testTag),
        shape = RoundedCornerShape(16.dp),
        elevation = 3.dp,
        onClick = onClick
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 12.dp, horizontal = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.Center
        ) {
            Box(
                modifier = Modifier
                    .size(28.dp)
                    .clip(CircleShape)
                    .background(Color(0xFF2563EB).copy(alpha = if (isDark) 0.25f else 0.12f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = Color(0xFF2563EB),
                    modifier = Modifier.size(15.dp)
                )
            }
            Spacer(modifier = Modifier.width(6.dp))
            Text(
                text = label,
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold,
                color = if (isDark) Color.White else Color(0xFF0F172A),
                maxLines = 1
            )
            if (badge != null) {
                Spacer(modifier = Modifier.width(4.dp))
                Box(
                    modifier = Modifier
                        .clip(CircleShape)
                        .background(Color(0xFF2563EB).copy(alpha = 0.15f))
                        .padding(horizontal = 6.dp, vertical = 2.dp)
                ) {
                    Text(
                        text = badge,
                        fontSize = 10.sp,
                        fontWeight = FontWeight.ExtraBold,
                        color = Color(0xFF2563EB)
                    )
                }
            }
        }
    }
}
