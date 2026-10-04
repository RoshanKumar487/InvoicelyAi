package com.example

import android.content.res.Configuration
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.compose.foundation.background
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Business
import androidx.compose.material.icons.filled.Calculate
import androidx.compose.material.icons.filled.Dashboard
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.People
import androidx.compose.material.icons.filled.Receipt
import androidx.compose.material.icons.filled.ReceiptLong
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.data.model.ClientEntity
import com.example.data.repository.AuthSessionManager
import com.example.ui.components.AmbientGlassBackdrop
import com.example.ui.components.AppMenuModalSheet
import com.example.ui.components.GlassCard
import com.example.ui.components.rememberWindowAdaptiveInfo
import com.example.ui.screens.AiChatScreen
import com.example.ui.screens.AuthScreen
import com.example.ui.screens.ClientsScreen
import com.example.ui.screens.DashboardScreen
import com.example.ui.screens.ExpensesScreen
import com.example.ui.screens.InvoiceEditScreen
import com.example.ui.screens.InvoicePreviewScreen
import com.example.ui.screens.InvoiceSettingsScreen
import com.example.ui.screens.InvoicesListScreen
import com.example.ui.screens.ReportsScreen
import com.example.ui.screens.SettingsScreen
import com.example.ui.screens.TaxCalculatorScreen
import com.example.ui.screens.TeamManagementScreen
import com.example.ui.screens.TemplatesScreen
import com.example.ui.theme.MyApplicationTheme
import com.example.ui.theme.PrimaryNavy
import com.example.ui.viewmodel.InvoiceViewModel

enum class MainTab(val title: String, val icon: ImageVector) {
    DASHBOARD("Dashboard", Icons.Default.Dashboard),
    INVOICES("Invoices", Icons.Default.Receipt),
    AI_AGENT("AI Agent", Icons.Default.AutoAwesome),
    EXPENSES("Expenses", Icons.Default.ReceiptLong),
    MENU("Menu", Icons.Default.Menu)
}

sealed class AppScreen {
    data class TabScreen(val tab: MainTab) : AppScreen()
    data class InvoiceEdit(val invoiceId: Long) : AppScreen()
    data class InvoicePreview(val invoiceId: Long, val initialFullPage: Boolean = true) : AppScreen()
    object TaxTool : AppScreen()
    object ClientsList : AppScreen()
    object Reports : AppScreen()
    object TemplatesList : AppScreen()
    object Settings : AppScreen()
    object InvoiceSettings : AppScreen()
    object TeamManagement : AppScreen()
    object Auth : AppScreen()
}


class MainActivity : ComponentActivity() {

    private val viewModel: InvoiceViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        AuthSessionManager.init(applicationContext)
        enableEdgeToEdge()
        setContent {
            val systemDark = isSystemInDarkTheme()
            var darkThemeChoice by remember { mutableStateOf<Boolean?>(null) }
            val isDark = darkThemeChoice ?: systemDark

            val currentConfig = LocalConfiguration.current
            val updatedConfig = remember(isDark, currentConfig) {
                Configuration(currentConfig).apply {
                    uiMode = if (isDark) {
                        (uiMode and Configuration.UI_MODE_NIGHT_MASK.inv()) or Configuration.UI_MODE_NIGHT_YES
                    } else {
                        (uiMode and Configuration.UI_MODE_NIGHT_MASK.inv()) or Configuration.UI_MODE_NIGHT_NO
                    }
                }
            }

            CompositionLocalProvider(LocalConfiguration provides updatedConfig) {
                MyApplicationTheme(darkTheme = isDark) {
                    MainAppContainer(
                        viewModel = viewModel,
                        isDarkTheme = isDark,
                        onToggleDarkTheme = { darkThemeChoice = it }
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainAppContainer(
    viewModel: InvoiceViewModel,
    isDarkTheme: Boolean = isSystemInDarkTheme(),
    onToggleDarkTheme: ((Boolean) -> Unit)? = null
) {
    val isLoggedIn by AuthSessionManager.isLoggedIn.collectAsStateWithLifecycle()
    var currentScreen by remember {
        mutableStateOf<AppScreen>(
            if (AuthSessionManager.isLoggedIn.value) AppScreen.TabScreen(MainTab.DASHBOARD) else AppScreen.Auth
        )
    }
    var currentTab by remember { mutableStateOf(MainTab.DASHBOARD) }
    var showMenuSheet by remember { mutableStateOf(false) }
    val menuSheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    LaunchedEffect(isLoggedIn) {
        if (!isLoggedIn) {
            currentScreen = AppScreen.Auth
        }
    }

    // Navigation backstack handler
    BackHandler(enabled = showMenuSheet || (isLoggedIn && (currentScreen !is AppScreen.TabScreen || currentTab != MainTab.DASHBOARD))) {
        if (showMenuSheet) {
            showMenuSheet = false
        } else {
            when (currentScreen) {
                is AppScreen.InvoiceEdit,
                is AppScreen.InvoicePreview,
                is AppScreen.TaxTool,
                is AppScreen.ClientsList,
                is AppScreen.Reports,
                is AppScreen.TemplatesList,
                is AppScreen.Settings,
                is AppScreen.InvoiceSettings,
                is AppScreen.TeamManagement -> {
                    currentScreen = AppScreen.TabScreen(currentTab)
                }
                is AppScreen.Auth -> {
                    // Keep on Auth screen if logged out
                }
                is AppScreen.TabScreen -> {
                    if (currentTab != MainTab.DASHBOARD) {
                        currentTab = MainTab.DASHBOARD
                        currentScreen = AppScreen.TabScreen(MainTab.DASHBOARD)
                    }
                }
            }
        }
    }

    val isTopLevelTab = isLoggedIn && currentScreen is AppScreen.TabScreen

    AmbientGlassBackdrop {
        Scaffold(
            modifier = Modifier.fillMaxSize(),
            containerColor = Color.Transparent,
            contentWindowInsets = WindowInsets(0, 0, 0, 0),
            bottomBar = {
                if (isTopLevelTab) {
                    val adaptiveInfo = rememberWindowAdaptiveInfo()
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .navigationBarsPadding()
                            .padding(
                                horizontal = if (adaptiveInfo.isTablet) 32.dp else 14.dp,
                                vertical = 6.dp
                            ),
                        contentAlignment = Alignment.BottomCenter
                    ) {
                        GlassCard(
                            modifier = Modifier
                                .fillMaxWidth()
                                .widthIn(max = 640.dp),
                            shape = RoundedCornerShape(26.dp),
                            elevation = 8.dp
                        ) {
                            NavigationBar(
                                containerColor = Color.Transparent,
                                contentColor = PrimaryNavy,
                                tonalElevation = 0.dp,
                                windowInsets = WindowInsets(0, 0, 0, 0),
                                modifier = Modifier.height(68.dp)
                            ) {
                                MainTab.values().forEach { tab ->
                                    val selected = if (tab == MainTab.MENU) showMenuSheet else currentTab == tab
                                    NavigationBarItem(
                                        selected = selected,
                                        onClick = {
                                            if (tab == MainTab.MENU) {
                                                showMenuSheet = true
                                            } else {
                                                currentTab = tab
                                                currentScreen = AppScreen.TabScreen(tab)
                                            }
                                        },
                                        icon = {
                                            if (tab == MainTab.AI_AGENT) {
                                                Box(
                                                    modifier = Modifier
                                                        .size(if (selected) 38.dp else 34.dp)
                                                        .clip(CircleShape)
                                                        .background(
                                                            Brush.linearGradient(
                                                                colors = if (selected) listOf(Color(0xFF1D4ED8), Color(0xFF7C3AED))
                                                                else listOf(Color(0xFF3B82F6), Color(0xFF8B5CF6))
                                                            )
                                                        ),
                                                    contentAlignment = Alignment.Center
                                                ) {
                                                    Icon(
                                                        imageVector = Icons.Default.AutoAwesome,
                                                        contentDescription = tab.title,
                                                        tint = Color.White,
                                                        modifier = Modifier.size(if (selected) 20.dp else 18.dp)
                                                    )
                                                }
                                            } else {
                                                Icon(
                                                    imageVector = tab.icon,
                                                    contentDescription = tab.title,
                                                    modifier = Modifier.size(22.dp)
                                                )
                                            }
                                        },
                                        label = {
                                            Text(
                                                text = tab.title,
                                                fontSize = 11.sp,
                                                fontWeight = if (selected) FontWeight.ExtraBold else FontWeight.Medium
                                            )
                                        },
                                        colors = NavigationBarItemDefaults.colors(
                                            selectedIconColor = Color(0xFF1D4ED8),
                                            selectedTextColor = Color(0xFF1D4ED8),
                                            indicatorColor = if (tab == MainTab.AI_AGENT) Color.Transparent else Color(0xFF3B82F6).copy(alpha = 0.16f),
                                            unselectedIconColor = Color(0xFF64748B),
                                            unselectedTextColor = Color(0xFF64748B)
                                        ),
                                        modifier = Modifier.testTag("nav_item_${tab.name.lowercase()}")
                                    )
                                }
                            }
                        }
                    }
                }
            }
        ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(bottom = if (isTopLevelTab) innerPadding.calculateBottomPadding() else 0.dp)
        ) {
            when (val screen = currentScreen) {
                is AppScreen.TabScreen -> {
                    when (screen.tab) {
                        MainTab.DASHBOARD -> {
                            DashboardScreen(
                                viewModel = viewModel,
                                onCreateInvoice = { currentScreen = AppScreen.InvoiceEdit(0L) },
                                onViewInvoices = {
                                    currentTab = MainTab.INVOICES
                                    currentScreen = AppScreen.TabScreen(MainTab.INVOICES)
                                },
                                onViewClients = {
                                    currentScreen = AppScreen.ClientsList
                                },
                                onViewTemplates = {
                                    currentScreen = AppScreen.TemplatesList
                                },
                                onViewTaxTool = { currentScreen = AppScreen.TaxTool },
                                onOpenInvoice = { id -> currentScreen = AppScreen.InvoicePreview(id) },
                                onOpenAiChat = {
                                    currentTab = MainTab.AI_AGENT
                                    currentScreen = AppScreen.TabScreen(MainTab.AI_AGENT)
                                },
                                onOpenMenu = { showMenuSheet = true }
                            )
                        }
                        MainTab.INVOICES -> {
                            InvoicesListScreen(
                                viewModel = viewModel,
                                onBack = {
                                    currentTab = MainTab.DASHBOARD
                                    currentScreen = AppScreen.TabScreen(MainTab.DASHBOARD)
                                },
                                onCreateInvoice = { currentScreen = AppScreen.InvoiceEdit(0L) },
                                onOpenInvoice = { id -> currentScreen = AppScreen.InvoicePreview(id) },
                                onEditInvoice = { id -> currentScreen = AppScreen.InvoiceEdit(id) },
                                onOpenMenu = { showMenuSheet = true }
                            )
                        }
                        MainTab.AI_AGENT -> {
                            AiChatScreen(
                                viewModel = viewModel,
                                onNavigateToInvoicePreview = { id ->
                                    currentScreen = AppScreen.InvoicePreview(id)
                                },
                                onNavigateToInvoiceEdit = { id ->
                                    currentScreen = AppScreen.InvoiceEdit(id)
                                },
                                onNavigateToDashboard = {
                                    currentTab = MainTab.DASHBOARD
                                    currentScreen = AppScreen.TabScreen(MainTab.DASHBOARD)
                                },
                                onOpenMenu = { showMenuSheet = true }
                            )
                        }
                        MainTab.EXPENSES -> {
                            ExpensesScreen(
                                viewModel = viewModel,
                                onOpenAiChat = {
                                    currentTab = MainTab.AI_AGENT
                                    currentScreen = AppScreen.TabScreen(MainTab.AI_AGENT)
                                },
                                onOpenMenu = { showMenuSheet = true }
                            )
                        }
                        MainTab.MENU -> {
                            // Falling back to Dashboard if tab selected
                            DashboardScreen(
                                viewModel = viewModel,
                                onCreateInvoice = { currentScreen = AppScreen.InvoiceEdit(0L) },
                                onViewInvoices = {
                                    currentTab = MainTab.INVOICES
                                    currentScreen = AppScreen.TabScreen(MainTab.INVOICES)
                                },
                                onViewClients = {
                                    currentScreen = AppScreen.ClientsList
                                },
                                onViewTemplates = {
                                    currentScreen = AppScreen.TemplatesList
                                },
                                onViewTaxTool = { currentScreen = AppScreen.TaxTool },
                                onOpenInvoice = { id -> currentScreen = AppScreen.InvoicePreview(id) },
                                onOpenAiChat = {
                                    currentTab = MainTab.AI_AGENT
                                    currentScreen = AppScreen.TabScreen(MainTab.AI_AGENT)
                                },
                                onOpenMenu = { showMenuSheet = true }
                            )
                        }
                    }
                }
                is AppScreen.ClientsList -> {
                    ClientsScreen(
                        viewModel = viewModel,
                        onBack = { currentScreen = AppScreen.TabScreen(currentTab) },
                        onCreateInvoiceForClient = { client ->
                            currentScreen = AppScreen.InvoiceEdit(0L)
                        },
                        onOpenInvoice = { id -> currentScreen = AppScreen.InvoicePreview(id) },
                        onOpenMenu = { showMenuSheet = true }
                    )
                }
                is AppScreen.Reports -> {
                    ReportsScreen(
                        viewModel = viewModel,
                        onBack = { currentScreen = AppScreen.TabScreen(currentTab) },
                        onOpenMenu = { showMenuSheet = true }
                    )
                }
                is AppScreen.TemplatesList -> {
                    TemplatesScreen(
                        viewModel = viewModel,
                        onBack = { currentScreen = AppScreen.TabScreen(currentTab) },
                        onPreviewWithInvoice = { id -> currentScreen = AppScreen.InvoicePreview(id) },
                        onOpenMenu = { showMenuSheet = true }
                    )
                }
                is AppScreen.Settings -> {
                    SettingsScreen(
                        viewModel = viewModel,
                        onBack = {
                            currentTab = MainTab.DASHBOARD
                            currentScreen = AppScreen.TabScreen(MainTab.DASHBOARD)
                        },
                        onCreateInvoice = {
                            currentScreen = AppScreen.InvoiceEdit(0L)
                        },
                        onViewFullPageInvoice = { id ->
                            currentScreen = AppScreen.InvoicePreview(id, initialFullPage = true)
                        },
                        onViewTaxCalculator = {
                            currentScreen = AppScreen.TaxTool
                        },
                        onViewClients = {
                            currentScreen = AppScreen.ClientsList
                        },
                        onViewTemplates = {
                            currentScreen = AppScreen.TemplatesList
                        },
                        onViewExpenses = {
                            currentTab = MainTab.EXPENSES
                            currentScreen = AppScreen.TabScreen(MainTab.EXPENSES)
                        },
                        onViewAiChat = {
                            currentTab = MainTab.AI_AGENT
                            currentScreen = AppScreen.TabScreen(MainTab.AI_AGENT)
                        },
                        onOpenMenu = { showMenuSheet = true }
                    )
                }
                is AppScreen.InvoiceEdit -> {
                    InvoiceEditScreen(
                        invoiceId = screen.invoiceId,
                        viewModel = viewModel,
                        onBack = { currentScreen = AppScreen.TabScreen(currentTab) },
                        onSavedAndPreview = { savedId -> currentScreen = AppScreen.InvoicePreview(savedId) },
                        onOpenMenu = { showMenuSheet = true }
                    )
                }
                is AppScreen.InvoicePreview -> {
                    InvoicePreviewScreen(
                        invoiceId = screen.invoiceId,
                        viewModel = viewModel,
                        onBack = { currentScreen = AppScreen.TabScreen(currentTab) },
                        onEditInvoice = { id -> currentScreen = AppScreen.InvoiceEdit(id) },
                        initialFullPage = screen.initialFullPage,
                        onOpenMenu = { showMenuSheet = true }
                    )
                }
                is AppScreen.TaxTool -> {
                    TaxCalculatorScreen(
                        onBack = { currentScreen = AppScreen.TabScreen(currentTab) },
                        onOpenMenu = { showMenuSheet = true }
                    )
                }
                is AppScreen.InvoiceSettings -> {
                    InvoiceSettingsScreen(
                        viewModel = viewModel,
                        onBack = { currentScreen = AppScreen.TabScreen(currentTab) },
                        onOpenMenu = { showMenuSheet = true }
                    )
                }
                is AppScreen.TeamManagement -> {
                    TeamManagementScreen(
                        onBack = { currentScreen = AppScreen.TabScreen(currentTab) },
                        onOpenMenu = { showMenuSheet = true }
                    )
                }
                is AppScreen.Auth -> {
                    AuthScreen(
                        onLoginSuccess = {
                            currentTab = MainTab.DASHBOARD
                            currentScreen = AppScreen.TabScreen(MainTab.DASHBOARD)
                            viewModel.syncAllDataWithBackend()
                        }
                    )
                }
            }
        }

        // App Menu Modal Sheet (Hamburger menu action)
        if (showMenuSheet) {
            AppMenuModalSheet(
                sheetState = menuSheetState,
                onDismiss = { showMenuSheet = false },
                isDarkTheme = isDarkTheme,
                onToggleDarkTheme = onToggleDarkTheme,
                onNavigateToClients = {
                    currentScreen = AppScreen.ClientsList
                },
                onNavigateToReports = {
                    currentScreen = AppScreen.Reports
                },
                onNavigateToTemplates = {
                    currentScreen = AppScreen.TemplatesList
                },
                onNavigateToTaxTool = {
                    currentScreen = AppScreen.TaxTool
                },
                onNavigateToSettings = {
                    currentScreen = AppScreen.Settings
                },
                onNavigateToInvoiceSettings = {
                    currentScreen = AppScreen.InvoiceSettings
                },
                onNavigateToTeamManagement = {
                    currentScreen = AppScreen.TeamManagement
                },
                onSignOut = {
                    AuthSessionManager.logout()
                    viewModel.clearAllLocalData()
                    currentScreen = AppScreen.Auth
                },
                onNavigateToExpenses = {
                    currentTab = MainTab.EXPENSES
                    currentScreen = AppScreen.TabScreen(MainTab.EXPENSES)
                },
                onNavigateToAiAgent = {
                    currentTab = MainTab.AI_AGENT
                    currentScreen = AppScreen.TabScreen(MainTab.AI_AGENT)
                }
            )
        }
    }
}
}

