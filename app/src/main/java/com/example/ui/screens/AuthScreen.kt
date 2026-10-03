package com.example.ui.screens

import android.widget.Toast
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Apartment
import androidx.compose.material.icons.filled.Badge
import androidx.compose.material.icons.filled.Business
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Code
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Key
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Phone
import androidx.compose.material.icons.filled.Receipt
import androidx.compose.material.icons.filled.Security
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.TabRowDefaults
import androidx.compose.material3.TabRowDefaults.tabIndicatorOffset
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
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.rememberCoroutineScope
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.data.api.ApiConfig
import com.example.data.model.UserRole
import com.example.data.repository.AuthSessionManager
import com.example.ui.components.AmbientGlassBackdrop
import com.example.ui.components.GlassCard
import com.example.ui.theme.PrimaryNavy
import kotlinx.coroutines.launch

@Composable
fun AuthScreen(
    onLoginSuccess: () -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val isDark = isSystemInDarkTheme()
    val coroutineScope = rememberCoroutineScope()
    var isSubmitting by remember { mutableStateOf(false) }
    var selectedTab by remember { mutableIntStateOf(0) } // 0 = Sign In, 1 = Register / Join
    val serverBaseUrl by ApiConfig.baseUrl.collectAsStateWithLifecycle()
    val isServerConnected by ApiConfig.isBackendReachable.collectAsStateWithLifecycle()

    // Sign In Fields
    var loginIdentifier by remember { mutableStateOf("admin@apexnova.io") }
    var loginPassword by remember { mutableStateOf("admin123") }
    var passwordVisible by remember { mutableStateOf(false) }
    var loginError by remember { mutableStateOf<String?>(null) }

    // Register Fields
    var regRoleMode by remember { mutableIntStateOf(0) } // 0 = Admin (Create Org), 1 = Employee (Join Org), 2 = Developer
    var regFullName by remember { mutableStateOf("") }
    var regEmail by remember { mutableStateOf("") }
    var regMobile by remember { mutableStateOf("") }
    var regPassword by remember { mutableStateOf("") }
    var regCompanyName by remember { mutableStateOf("") }
    var regGstin by remember { mutableStateOf("") }
    var regLocation by remember { mutableStateOf("") }
    var regCompanyDetails by remember { mutableStateOf("") }
    var regCompanyCode by remember { mutableStateOf("COMP-APEX99") }
    var regRequestMessage by remember { mutableStateOf("") }
    var regSecretKey by remember { mutableStateOf("invoicely_dev_secret_2026") }
    var regFeedbackMessage by remember { mutableStateOf<String?>(null) }
    var regIsSuccess by remember { mutableStateOf(false) }

    AmbientGlassBackdrop {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .statusBarsPadding()
                .navigationBarsPadding()
                .imePadding(),
            contentAlignment = Alignment.Center
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .widthIn(max = 520.dp)
                    .padding(horizontal = 20.dp, vertical = 12.dp)
                    .verticalScroll(rememberScrollState()),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Brand Header
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .size(60.dp)
                            .clip(RoundedCornerShape(18.dp))
                            .background(
                                Brush.linearGradient(
                                    colors = listOf(Color(0xFF1D4ED8), Color(0xFF6366F1), Color(0xFF8B5CF6))
                                )
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.Receipt,
                            contentDescription = "InvoicelyAi Logo",
                            tint = Color.White,
                            modifier = Modifier.size(32.dp)
                        )
                    }

                    Text(
                        text = "InvoicelyAi",
                        fontSize = 26.sp,
                        fontWeight = FontWeight.ExtraBold,
                        color = if (isDark) Color.White else PrimaryNavy
                    )

                    Text(
                        text = "Role-Based Multi-Tenant Billing & Accounting",
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Medium,
                        color = if (isDark) Color(0xFF94A3B8) else Color(0xFF64748B)
                    )
                }

                // Main Container Glass Card
                GlassCard(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(24.dp),
                    elevation = 6.dp
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(20.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        // Navigation Tabs (Sign In vs Register)
                        TabRow(
                            selectedTabIndex = selectedTab,
                            containerColor = Color.Transparent,
                            contentColor = Color(0xFF1D4ED8),
                            indicator = { tabPositions ->
                                TabRowDefaults.SecondaryIndicator(
                                    modifier = Modifier.tabIndicatorOffset(tabPositions[selectedTab]),
                                    color = Color(0xFF2563EB),
                                    height = 3.dp
                                )
                            },
                            divider = { HorizontalDivider(color = Color(0xFFE2E8F0).copy(alpha = 0.4f)) }
                        ) {
                            Tab(
                                selected = selectedTab == 0,
                                onClick = { selectedTab = 0; loginError = null },
                                text = {
                                    Text(
                                        text = "Sign In",
                                        fontWeight = if (selectedTab == 0) FontWeight.Bold else FontWeight.Medium,
                                        fontSize = 14.sp
                                    )
                                },
                                icon = {
                                    Icon(Icons.Default.Lock, contentDescription = "Sign In", modifier = Modifier.size(16.dp))
                                }
                            )
                            Tab(
                                selected = selectedTab == 1,
                                onClick = { selectedTab = 1; regFeedbackMessage = null },
                                text = {
                                    Text(
                                        text = "Sign Up / Join",
                                        fontWeight = if (selectedTab == 1) FontWeight.Bold else FontWeight.Medium,
                                        fontSize = 14.sp
                                    )
                                },
                                icon = {
                                    Icon(Icons.Default.Business, contentDescription = "Register", modifier = Modifier.size(16.dp))
                                }
                            )
                        }

                        if (selectedTab == 0) {
                            // =================================================================
                            // TAB 1: SIGN IN (EMAIL / PASSWORD + QUICK ROLE SWITCHER)
                            // =================================================================
                            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                                Text(
                                    text = "Welcome Back",
                                    fontSize = 18.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = if (isDark) Color.White else Color(0xFF0F172A)
                                )

                                // Quick Role Pills for instant testing
                                Column(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .clip(RoundedCornerShape(12.dp))
                                        .background(if (isDark) Color(0xFF1E293B) else Color(0xFFF1F5F9))
                                        .padding(10.dp),
                                    verticalArrangement = Arrangement.spacedBy(6.dp)
                                ) {
                                    Row(
                                        modifier = Modifier.fillMaxWidth(),
                                        horizontalArrangement = Arrangement.SpaceBetween,
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Text(
                                            text = "QUICK ROLE DEMO (1-TAP)",
                                            fontSize = 10.sp,
                                            fontWeight = FontWeight.ExtraBold,
                                            color = Color(0xFF64748B)
                                        )
                                        Text(
                                            text = "Tap to switch role",
                                            fontSize = 10.sp,
                                            color = Color(0xFF3B82F6)
                                        )
                                    }

                                    Row(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .horizontalScroll(rememberScrollState()),
                                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                                    ) {
                                        // Admin Pill
                                        Surface(
                                            shape = RoundedCornerShape(16.dp),
                                            color = Color(0xFFDBEAFE),
                                            border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFF93C5FD)),
                                            modifier = Modifier.clickable {
                                                AuthSessionManager.switchRoleQuick(UserRole.ADMIN)
                                                Toast.makeText(context, "Logged in as Organization Admin (Apex Nova)", Toast.LENGTH_SHORT).show()
                                                onLoginSuccess()
                                            }
                                        ) {
                                            Text(
                                                text = "👑 Org Admin",
                                                color = Color(0xFF1D4ED8),
                                                fontWeight = FontWeight.Bold,
                                                fontSize = 11.sp,
                                                modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp)
                                            )
                                        }

                                        // Employee Pill
                                        Surface(
                                            shape = RoundedCornerShape(16.dp),
                                            color = Color(0xFFD1FAE5),
                                            border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFF6EE7B7)),
                                            modifier = Modifier.clickable {
                                                AuthSessionManager.switchRoleQuick(UserRole.EMPLOYEE)
                                                Toast.makeText(context, "Logged in as Team Employee (Operational & Expenses)", Toast.LENGTH_SHORT).show()
                                                onLoginSuccess()
                                            }
                                        ) {
                                            Text(
                                                text = "👤 Team Employee",
                                                color = Color(0xFF047857),
                                                fontWeight = FontWeight.Bold,
                                                fontSize = 11.sp,
                                                modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp)
                                            )
                                        }

                                        // Developer Pill
                                        Surface(
                                            shape = RoundedCornerShape(16.dp),
                                            color = Color(0xFFF3E8FF),
                                            border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFD8B4FE)),
                                            modifier = Modifier.clickable {
                                                AuthSessionManager.switchRoleQuick(UserRole.DEVELOPER)
                                                Toast.makeText(context, "Logged in as Platform Developer (Global All-Org)", Toast.LENGTH_SHORT).show()
                                                onLoginSuccess()
                                            }
                                        ) {
                                            Text(
                                                text = "⚡ Global Dev",
                                                color = Color(0xFF7E22CE),
                                                fontWeight = FontWeight.Bold,
                                                fontSize = 11.sp,
                                                modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp)
                                            )
                                        }
                                    }
                                }

                                // Identifier (Email/Mobile)
                                OutlinedTextField(
                                    value = loginIdentifier,
                                    onValueChange = { loginIdentifier = it },
                                    label = { Text("Email or Mobile Number") },
                                    leadingIcon = { Icon(Icons.Default.Email, contentDescription = null, tint = Color(0xFF64748B)) },
                                    singleLine = true,
                                    modifier = Modifier.fillMaxWidth().testTag("field_login_identifier"),
                                    shape = RoundedCornerShape(12.dp),
                                    colors = OutlinedTextFieldDefaults.colors(
                                        focusedBorderColor = Color(0xFF2563EB),
                                        unfocusedBorderColor = if (isDark) Color(0xFF334155) else Color(0xFFCBD5E1)
                                    )
                                )

                                // Password
                                OutlinedTextField(
                                    value = loginPassword,
                                    onValueChange = { loginPassword = it },
                                    label = { Text("Password") },
                                    leadingIcon = { Icon(Icons.Default.Lock, contentDescription = null, tint = Color(0xFF64748B)) },
                                    trailingIcon = {
                                        IconButton(onClick = { passwordVisible = !passwordVisible }) {
                                            Icon(
                                                imageVector = if (passwordVisible) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                                                contentDescription = "Toggle password visibility"
                                            )
                                        }
                                    },
                                    singleLine = true,
                                    visualTransformation = if (passwordVisible) VisualTransformation.None else PasswordVisualTransformation(),
                                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                                    modifier = Modifier.fillMaxWidth().testTag("field_login_password"),
                                    shape = RoundedCornerShape(12.dp),
                                    colors = OutlinedTextFieldDefaults.colors(
                                        focusedBorderColor = Color(0xFF2563EB),
                                        unfocusedBorderColor = if (isDark) Color(0xFF334155) else Color(0xFFCBD5E1)
                                    )
                                )

                                if (loginError != null) {
                                    Text(
                                        text = loginError ?: "",
                                        color = Color(0xFFDC2626),
                                        fontSize = 12.sp,
                                        fontWeight = FontWeight.SemiBold
                                    )
                                }

                                // Sign In Button
                                Button(
                                    onClick = {
                                        coroutineScope.launch {
                                            isSubmitting = true
                                            loginError = null
                                            val result = AuthSessionManager.login(loginIdentifier, loginPassword)
                                            isSubmitting = false
                                            if (result.isSuccess) {
                                                loginError = null
                                                Toast.makeText(context, "Welcome back, ${result.getOrNull()?.fullName}!", Toast.LENGTH_SHORT).show()
                                                onLoginSuccess()
                                            } else {
                                                loginError = result.exceptionOrNull()?.message ?: "Login failed"
                                            }
                                        }
                                    },
                                    enabled = !isSubmitting,
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .height(48.dp)
                                        .testTag("btn_submit_login"),
                                    shape = RoundedCornerShape(12.dp),
                                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF1D4ED8))
                                ) {
                                    if (isSubmitting) {
                                        CircularProgressIndicator(
                                            modifier = Modifier.size(20.dp),
                                            color = Color.White,
                                            strokeWidth = 2.dp
                                        )
                                    } else {
                                        Text(
                                            text = "Sign In",
                                            fontWeight = FontWeight.Bold,
                                            fontSize = 15.sp,
                                            color = Color.White
                                        )
                                    }
                                }
                            }
                        } else {
                            // =================================================================
                            // TAB 2: REGISTER / JOIN WITH COMPANY DETAILS
                            // =================================================================
                            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                                Text(
                                    text = "Choose Your Role",
                                    fontSize = 13.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = Color(0xFF64748B)
                                )

                                // Role selector pills (Admin, Employee, Developer)
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .clip(RoundedCornerShape(12.dp))
                                        .background(if (isDark) Color(0xFF1E293B) else Color(0xFFF1F5F9))
                                        .padding(4.dp),
                                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                                ) {
                                    listOf(
                                        "👑 Org Admin" to 0,
                                        "👤 Employee" to 1,
                                        "⚡ Developer" to 2
                                    ).forEach { (label, index) ->
                                        val isSelected = regRoleMode == index
                                        Box(
                                            modifier = Modifier
                                                .weight(1f)
                                                .clip(RoundedCornerShape(10.dp))
                                                .background(
                                                    if (isSelected) Color(0xFF2563EB) else Color.Transparent
                                                )
                                                .clickable {
                                                    regRoleMode = index
                                                    regFeedbackMessage = null
                                                }
                                                .padding(vertical = 8.dp),
                                            contentAlignment = Alignment.Center
                                        ) {
                                            Text(
                                                text = label,
                                                fontSize = 11.sp,
                                                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                                                color = if (isSelected) Color.White else Color(0xFF64748B)
                                            )
                                        }
                                    }
                                }

                                // Personal Info Fields
                                OutlinedTextField(
                                    value = regFullName,
                                    onValueChange = { regFullName = it },
                                    label = { Text("Your Full Name") },
                                    leadingIcon = { Icon(Icons.Default.Person, contentDescription = null, tint = Color(0xFF64748B)) },
                                    singleLine = true,
                                    modifier = Modifier.fillMaxWidth().testTag("field_reg_name"),
                                    shape = RoundedCornerShape(12.dp)
                                )

                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                                ) {
                                    OutlinedTextField(
                                        value = regEmail,
                                        onValueChange = { regEmail = it },
                                        label = { Text("Work Email") },
                                        leadingIcon = { Icon(Icons.Default.Email, contentDescription = null, tint = Color(0xFF64748B)) },
                                        singleLine = true,
                                        modifier = Modifier.weight(1f).testTag("field_reg_email"),
                                        shape = RoundedCornerShape(12.dp)
                                    )
                                    OutlinedTextField(
                                        value = regMobile,
                                        onValueChange = { regMobile = it },
                                        label = { Text("Mobile #") },
                                        leadingIcon = { Icon(Icons.Default.Phone, contentDescription = null, tint = Color(0xFF64748B)) },
                                        singleLine = true,
                                        modifier = Modifier.weight(1f).testTag("field_reg_mobile"),
                                        shape = RoundedCornerShape(12.dp)
                                    )
                                }

                                OutlinedTextField(
                                    value = regPassword,
                                    onValueChange = { regPassword = it },
                                    label = { Text("Password (Min 4 chars)") },
                                    leadingIcon = { Icon(Icons.Default.Lock, contentDescription = null, tint = Color(0xFF64748B)) },
                                    singleLine = true,
                                    visualTransformation = PasswordVisualTransformation(),
                                    modifier = Modifier.fillMaxWidth().testTag("field_reg_password"),
                                    shape = RoundedCornerShape(12.dp)
                                )

                                // ROLE-SPECIFIC SECTIONS:
                                when (regRoleMode) {
                                    0 -> {
                                        // -------------------------------------------------------------
                                        // MODE 0: CREATE NEW COMPANY (ADMIN)
                                        // -------------------------------------------------------------
                                        Card(
                                            modifier = Modifier.fillMaxWidth(),
                                            colors = CardDefaults.cardColors(containerColor = if (isDark) Color(0xFF1E293B) else Color(0xFFEFF6FF)),
                                            border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFBFDBFE)),
                                            shape = RoundedCornerShape(14.dp)
                                        ) {
                                            Column(modifier = Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                                                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                                    Icon(Icons.Default.Apartment, contentDescription = null, tint = Color(0xFF1D4ED8), modifier = Modifier.size(18.dp))
                                                    Text("Company & Business Details", fontWeight = FontWeight.Bold, fontSize = 13.sp, color = Color(0xFF1D4ED8))
                                                }

                                                OutlinedTextField(
                                                    value = regCompanyName,
                                                    onValueChange = { regCompanyName = it },
                                                    label = { Text("Company Name (e.g. Apex Nova LLC)") },
                                                    singleLine = true,
                                                    modifier = Modifier.fillMaxWidth().testTag("field_reg_company_name"),
                                                    shape = RoundedCornerShape(10.dp)
                                                )

                                                Row(
                                                    modifier = Modifier.fillMaxWidth(),
                                                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                                                ) {
                                                    OutlinedTextField(
                                                        value = regGstin,
                                                        onValueChange = { regGstin = it },
                                                        label = { Text("GSTIN / Tax ID") },
                                                        singleLine = true,
                                                        modifier = Modifier.weight(1f).testTag("field_reg_gstin"),
                                                        shape = RoundedCornerShape(10.dp)
                                                    )
                                                    OutlinedTextField(
                                                        value = regLocation,
                                                        onValueChange = { regLocation = it },
                                                        label = { Text("City / State") },
                                                        singleLine = true,
                                                        modifier = Modifier.weight(1f).testTag("field_reg_location"),
                                                        shape = RoundedCornerShape(10.dp)
                                                    )
                                                }

                                                OutlinedTextField(
                                                    value = regCompanyDetails,
                                                    onValueChange = { regCompanyDetails = it },
                                                    label = { Text("Business Tagline / Specialty") },
                                                    singleLine = true,
                                                    modifier = Modifier.fillMaxWidth(),
                                                    shape = RoundedCornerShape(10.dp)
                                                )

                                                Text(
                                                    text = "ℹ A unique company code will be auto-generated so your employees can join your workspace.",
                                                    fontSize = 11.sp,
                                                    color = Color(0xFF2563EB)
                                                )
                                            }
                                        }
                                    }
                                    1 -> {
                                        // -------------------------------------------------------------
                                        // MODE 1: JOIN EXISTING TEAM (EMPLOYEE)
                                        // -------------------------------------------------------------
                                        Card(
                                            modifier = Modifier.fillMaxWidth(),
                                            colors = CardDefaults.cardColors(containerColor = if (isDark) Color(0xFF1E293B) else Color(0xFFECFDF5)),
                                            border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFA7F3D0)),
                                            shape = RoundedCornerShape(14.dp)
                                        ) {
                                            Column(modifier = Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                                                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                                    Icon(Icons.Default.Badge, contentDescription = null, tint = Color(0xFF047857), modifier = Modifier.size(18.dp))
                                                    Text("Join Organization Workspace", fontWeight = FontWeight.Bold, fontSize = 13.sp, color = Color(0xFF047857))
                                                }

                                                OutlinedTextField(
                                                    value = regCompanyCode,
                                                    onValueChange = { regCompanyCode = it },
                                                    label = { Text("Organization Code (e.g. COMP-APEX99)") },
                                                    singleLine = true,
                                                    modifier = Modifier.fillMaxWidth().testTag("field_reg_join_code"),
                                                    shape = RoundedCornerShape(10.dp)
                                                )

                                                OutlinedTextField(
                                                    value = regRequestMessage,
                                                    onValueChange = { regRequestMessage = it },
                                                    label = { Text("Note for Admin (e.g. Sales desk staff)") },
                                                    singleLine = true,
                                                    modifier = Modifier.fillMaxWidth().testTag("field_reg_join_note"),
                                                    shape = RoundedCornerShape(10.dp)
                                                )

                                                Text(
                                                    text = "ℹ Once submitted, your company Admin can approve your account from their Team Management dashboard.",
                                                    fontSize = 11.sp,
                                                    color = Color(0xFF059669)
                                                )
                                            }
                                        }
                                    }
                                    2 -> {
                                        // -------------------------------------------------------------
                                        // MODE 2: DEVELOPER
                                        // -------------------------------------------------------------
                                        Card(
                                            modifier = Modifier.fillMaxWidth(),
                                            colors = CardDefaults.cardColors(containerColor = if (isDark) Color(0xFF1E293B) else Color(0xFFFAF5FF)),
                                            border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFE9D5FF)),
                                            shape = RoundedCornerShape(14.dp)
                                        ) {
                                            Column(modifier = Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                                                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                                    Icon(Icons.Default.Code, contentDescription = null, tint = Color(0xFF7E22CE), modifier = Modifier.size(18.dp))
                                                    Text("Platform Developer Registration", fontWeight = FontWeight.Bold, fontSize = 13.sp, color = Color(0xFF7E22CE))
                                                }

                                                OutlinedTextField(
                                                    value = regSecretKey,
                                                    onValueChange = { regSecretKey = it },
                                                    label = { Text("Developer Secret Key") },
                                                    leadingIcon = { Icon(Icons.Default.Key, contentDescription = null) },
                                                    singleLine = true,
                                                    modifier = Modifier.fillMaxWidth().testTag("field_reg_dev_key"),
                                                    shape = RoundedCornerShape(10.dp)
                                                )

                                                Text(
                                                    text = "Default verification key: invoicely_dev_secret_2026",
                                                    fontSize = 11.sp,
                                                    color = Color(0xFF7E22CE)
                                                )
                                            }
                                        }
                                    }
                                }

                                if (regFeedbackMessage != null) {
                                    Text(
                                        text = regFeedbackMessage ?: "",
                                        color = if (regIsSuccess) Color(0xFF059669) else Color(0xFFDC2626),
                                        fontSize = 12.sp,
                                        fontWeight = FontWeight.SemiBold
                                    )
                                }

                                Button(
                                    onClick = {
                                        coroutineScope.launch {
                                            isSubmitting = true
                                            regFeedbackMessage = null
                                            when (regRoleMode) {
                                                0 -> {
                                                    val res = AuthSessionManager.registerCompany(
                                                        fullName = regFullName,
                                                        email = regEmail,
                                                        mobile = regMobile,
                                                        password = regPassword,
                                                        companyName = regCompanyName,
                                                        gstin = regGstin,
                                                        location = regLocation,
                                                        details = regCompanyDetails
                                                    )
                                                    isSubmitting = false
                                                    if (res.isSuccess) {
                                                        regIsSuccess = true
                                                        regFeedbackMessage = "Organization & Admin registered! Code: ${res.getOrNull()?.companyCode}"
                                                        Toast.makeText(context, "Organization created successfully!", Toast.LENGTH_SHORT).show()
                                                        onLoginSuccess()
                                                    } else {
                                                        regIsSuccess = false
                                                        regFeedbackMessage = res.exceptionOrNull()?.message ?: "Registration failed"
                                                    }
                                                }
                                                1 -> {
                                                    val res = AuthSessionManager.registerEmployee(
                                                        fullName = regFullName,
                                                        email = regEmail,
                                                        mobile = regMobile,
                                                        password = regPassword,
                                                        companyCode = regCompanyCode,
                                                        message = regRequestMessage
                                                    )
                                                    isSubmitting = false
                                                    if (res.isSuccess) {
                                                        regIsSuccess = true
                                                        regFeedbackMessage = res.getOrNull()
                                                        Toast.makeText(context, "Join request submitted! Awaiting Admin approval.", Toast.LENGTH_LONG).show()
                                                    } else {
                                                        regIsSuccess = false
                                                        regFeedbackMessage = res.exceptionOrNull()?.message ?: "Join request failed"
                                                    }
                                                }
                                                2 -> {
                                                    val res = AuthSessionManager.registerDeveloper(
                                                        fullName = regFullName,
                                                        email = regEmail,
                                                        mobile = regMobile,
                                                        password = regPassword,
                                                        secretKey = regSecretKey
                                                    )
                                                    isSubmitting = false
                                                    if (res.isSuccess) {
                                                        regIsSuccess = true
                                                        regFeedbackMessage = "Developer account activated!"
                                                        Toast.makeText(context, "Developer Superuser logged in!", Toast.LENGTH_SHORT).show()
                                                        onLoginSuccess()
                                                    } else {
                                                        regIsSuccess = false
                                                        regFeedbackMessage = res.exceptionOrNull()?.message ?: "Developer key invalid"
                                                    }
                                                }
                                            }
                                        }
                                    },
                                    enabled = !isSubmitting,
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .height(48.dp)
                                        .testTag("btn_submit_register"),
                                    shape = RoundedCornerShape(12.dp),
                                    colors = ButtonDefaults.buttonColors(
                                        containerColor = when (regRoleMode) {
                                            0 -> Color(0xFF1D4ED8)
                                            1 -> Color(0xFF047857)
                                            else -> Color(0xFF7E22CE)
                                        }
                                    )
                                ) {
                                    if (isSubmitting) {
                                        CircularProgressIndicator(
                                            modifier = Modifier.size(20.dp),
                                            color = Color.White,
                                            strokeWidth = 2.dp
                                        )
                                    } else {
                                        Text(
                                            text = when (regRoleMode) {
                                                0 -> "Create Organization & Admin Account"
                                                1 -> "Submit Join Request to Admin"
                                                else -> "Activate Developer Access"
                                            },
                                            fontWeight = FontWeight.Bold,
                                            fontSize = 14.sp,
                                            color = Color.White
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
