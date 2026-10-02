package com.example

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
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
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.model.ClientEntity
import com.example.ui.components.AppMenuModalSheet
import com.example.ui.screens.AiChatScreen
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
}

class MainActivity : ComponentActivity() {

    private val viewModel: InvoiceViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            MyApplicationTheme {
                MainAppContainer(viewModel = viewModel)
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainAppContainer(viewModel: InvoiceViewModel) {
    var currentScreen by remember { mutableStateOf<AppScreen>(AppScreen.TabScreen(MainTab.DASHBOARD)) }
    var currentTab by remember { mutableStateOf(MainTab.DASHBOARD) }
    var showMenuSheet by remember { mutableStateOf(false) }
    val menuSheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    // Navigation backstack handler
    BackHandler(enabled = showMenuSheet || currentScreen !is AppScreen.TabScreen || currentTab != MainTab.DASHBOARD) {
        if (showMenuSheet) {
            showMenuSheet = false
        } else {
            when (currentScreen) {
                is AppScreen.InvoiceEdit -> {
                    currentScreen = AppScreen.TabScreen(currentTab)
                }
                is AppScreen.InvoicePreview -> {
                    currentScreen = AppScreen.TabScreen(currentTab)
                }
                is AppScreen.TaxTool -> {
                    currentScreen = AppScreen.TabScreen(currentTab)
                }
                is AppScreen.ClientsList -> {
                    currentScreen = AppScreen.TabScreen(currentTab)
                }
                is AppScreen.Reports -> {
                    currentScreen = AppScreen.TabScreen(currentTab)
                }
                is AppScreen.TemplatesList -> {
                    currentScreen = AppScreen.TabScreen(currentTab)
                }
                is AppScreen.Settings -> {
                    currentScreen = AppScreen.TabScreen(currentTab)
                }
                is AppScreen.InvoiceSettings -> {
                    currentScreen = AppScreen.TabScreen(currentTab)
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

    val isTopLevelTab = currentScreen is AppScreen.TabScreen

    Scaffold(
        modifier = Modifier.fillMaxSize(),
        contentWindowInsets = WindowInsets(0, 0, 0, 0),
        bottomBar = {
            if (isTopLevelTab) {
                Surface(
                    color = MaterialTheme.colorScheme.surface,
                    shadowElevation = 8.dp
                ) {
                    NavigationBar(
                        containerColor = MaterialTheme.colorScheme.surface,
                        contentColor = PrimaryNavy,
                        tonalElevation = 0.dp
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
                                            contentDescription = tab.title
                                        )
                                    }
                                },
                                label = {
                                    Text(
                                        text = tab.title,
                                        fontSize = 11.sp,
                                        fontWeight = if (selected) FontWeight.Bold else FontWeight.Normal
                                    )
                                },
                                colors = NavigationBarItemDefaults.colors(
                                    selectedIconColor = PrimaryNavy,
                                    selectedTextColor = PrimaryNavy,
                                    indicatorColor = if (tab == MainTab.AI_AGENT) Color.Transparent else MaterialTheme.colorScheme.primaryContainer,
                                    unselectedIconColor = MaterialTheme.colorScheme.onSurfaceVariant,
                                    unselectedTextColor = MaterialTheme.colorScheme.onSurfaceVariant
                                ),
                                modifier = Modifier.testTag("nav_item_${tab.name.lowercase()}")
                            )
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
                                }
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
                                onEditInvoice = { id -> currentScreen = AppScreen.InvoiceEdit(id) }
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
                                }
                            )
                        }
                        MainTab.EXPENSES -> {
                            ExpensesScreen(
                                viewModel = viewModel,
                                onOpenAiChat = {
                                    currentTab = MainTab.AI_AGENT
                                    currentScreen = AppScreen.TabScreen(MainTab.AI_AGENT)
                                }
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
                                }
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
                        onOpenInvoice = { id -> currentScreen = AppScreen.InvoicePreview(id) }
                    )
                }
                is AppScreen.Reports -> {
                    ReportsScreen(
                        viewModel = viewModel,
                        onBack = { currentScreen = AppScreen.TabScreen(currentTab) }
                    )
                }
                is AppScreen.TemplatesList -> {
                    TemplatesScreen(
                        viewModel = viewModel,
                        onBack = { currentScreen = AppScreen.TabScreen(currentTab) },
                        onPreviewWithInvoice = { id -> currentScreen = AppScreen.InvoicePreview(id) }
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
                        }
                    )
                }
                is AppScreen.InvoiceEdit -> {
                    InvoiceEditScreen(
                        invoiceId = screen.invoiceId,
                        viewModel = viewModel,
                        onBack = { currentScreen = AppScreen.TabScreen(currentTab) },
                        onSavedAndPreview = { savedId -> currentScreen = AppScreen.InvoicePreview(savedId) }
                    )
                }
                is AppScreen.InvoicePreview -> {
                    InvoicePreviewScreen(
                        invoiceId = screen.invoiceId,
                        viewModel = viewModel,
                        onBack = { currentScreen = AppScreen.TabScreen(currentTab) },
                        onEditInvoice = { id -> currentScreen = AppScreen.InvoiceEdit(id) },
                        initialFullPage = screen.initialFullPage
                    )
                }
                is AppScreen.TaxTool -> {
                    TaxCalculatorScreen(
                        onBack = { currentScreen = AppScreen.TabScreen(currentTab) }
                    )
                }
                is AppScreen.InvoiceSettings -> {
                    InvoiceSettingsScreen(
                        viewModel = viewModel,
                        onBack = { currentScreen = AppScreen.TabScreen(currentTab) }
                    )
                }
            }
        }

        // App Menu Modal Sheet (Hamburger menu action)
        if (showMenuSheet) {
            AppMenuModalSheet(
                sheetState = menuSheetState,
                onDismiss = { showMenuSheet = false },
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
