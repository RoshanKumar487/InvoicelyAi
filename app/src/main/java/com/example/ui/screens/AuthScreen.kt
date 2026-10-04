package com.example.ui.screens

import android.widget.Toast
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
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
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material.icons.filled.Apartment
import androidx.compose.material.icons.filled.ArrowForward
import androidx.compose.material.icons.filled.Badge
import androidx.compose.material.icons.filled.Business
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Code
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Key
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Phone
import androidx.compose.material.icons.filled.ReceiptLong
import androidx.compose.material.icons.filled.Security
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.TabRowDefaults
import androidx.compose.material3.TabRowDefaults.tabIndicatorOffset
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
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
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.data.api.ApiConfig
import com.example.data.api.InvoicelyApiManager
import com.example.data.repository.AuthSessionManager
import com.example.ui.components.AmbientGlassBackdrop
import com.example.ui.components.GlassCard
import com.example.ui.theme.PrimaryNavy
import kotlinx.coroutines.launch

/**
 * Enhanced, State-of-the-Art Authentication Screen for InvoicelyAi.
 * Communicates directly with PostgreSQL via Spring Boot REST APIs.
 * Supports Organization Admin registration, Employee Join requests, and Platform Developer roles.
 */
@Composable
fun AuthScreen(
    onLoginSuccess: () -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val isDark = isSystemInDarkTheme()
    val coroutineScope = rememberCoroutineScope()

    var selectedTab by remember { mutableIntStateOf(0) } // 0 = Sign In, 1 = Create Account / Join
    var isSubmitting by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var successMessage by remember { mutableStateOf<String?>(null) }

    // Backend Connectivity State (Always defaults to Render Cloud Web Service)
    val isServerConnected by ApiConfig.isBackendReachable.collectAsStateWithLifecycle()

    // Trigger initial health check on screen load
    LaunchedEffect(Unit) {
        InvoicelyApiManager.checkConnection()
    }

    // Sign In State Fields
    var loginIdentifier by remember { mutableStateOf("") }
    var loginPassword by remember { mutableStateOf("") }
    var loginPasswordVisible by remember { mutableStateOf(false) }

    // Sign Up State Fields
    var regRoleMode by remember { mutableIntStateOf(0) } // 0 = Company Admin, 1 = Employee Join, 2 = Developer
    var regFullName by remember { mutableStateOf("") }
    var regEmail by remember { mutableStateOf("") }
    var regMobile by remember { mutableStateOf("") }
    var regPassword by remember { mutableStateOf("") }
    var regPasswordVisible by remember { mutableStateOf(false) }

    // Company Specific (Role = Admin)
    var regCompanyName by remember { mutableStateOf("") }
    var regGstin by remember { mutableStateOf("") }
    var regLocation by remember { mutableStateOf("") }
    var regCompanyDetails by remember { mutableStateOf("") }

    // Employee Specific (Role = Employee)
    var regCompanyCode by remember { mutableStateOf("") }
    var regRequestMessage by remember { mutableStateOf("") }

    // Developer Specific (Role = Developer)
    var regDeveloperKey by remember { mutableStateOf("invoicely_dev_secret_2026") }

    AmbientGlassBackdrop {
        Box(
            modifier = modifier
                .fillMaxSize()
                .statusBarsPadding()
                .navigationBarsPadding()
                .imePadding(),
            contentAlignment = Alignment.Center
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .widthIn(max = 500.dp)
                    .padding(horizontal = 20.dp, vertical = 12.dp)
                    .verticalScroll(rememberScrollState()),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(14.dp)
            ) {

                // =============================================================
                // 1. BRAND HERO HEADER
                // =============================================================
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .size(64.dp)
                            .clip(RoundedCornerShape(20.dp))
                            .background(
                                Brush.linearGradient(
                                    colors = listOf(Color(0xFF1D4ED8), Color(0xFF4F46E5), Color(0xFF7C3AED))
                                )
                            )
                            .border(1.5.dp, Color.White.copy(alpha = 0.3f), RoundedCornerShape(20.dp)),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.ReceiptLong,
                            contentDescription = "Invoicely Logo",
                            tint = Color.White,
                            modifier = Modifier.size(34.dp)
                        )
                    }

                    Text(
                        text = "Invoicely AI",
                        fontSize = 28.sp,
                        fontWeight = FontWeight.ExtraBold,
                        color = if (isDark) Color.White else PrimaryNavy,
                        letterSpacing = (-0.5).sp
                    )

                    Text(
                        text = "Cloud Invoicing & Multi-Tenant Accounting",
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Medium,
                        color = if (isDark) Color(0xFF94A3B8) else Color(0xFF64748B),
                        textAlign = TextAlign.Center
                    )
                }

                // =============================================================
                // 2. LIVE RENDER CLOUD BACKEND STATUS PILL
                // =============================================================
                Surface(
                    shape = RoundedCornerShape(20.dp),
                    color = if (isServerConnected) {
                        if (isDark) Color(0xFF064E3B).copy(alpha = 0.6f) else Color(0xFFECFDF5)
                    } else {
                        if (isDark) Color(0xFF451A03).copy(alpha = 0.6f) else Color(0xFFFFFBEB)
                    },
                    border = androidx.compose.foundation.BorderStroke(
                        1.dp,
                        if (isServerConnected) Color(0xFF10B981).copy(alpha = 0.4f) else Color(0xFFF59E0B).copy(alpha = 0.4f)
                    )
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 14.dp, vertical = 6.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .size(8.dp)
                                .clip(CircleShape)
                                .background(if (isServerConnected) Color(0xFF10B981) else Color(0xFFF59E0B))
                        )
                        Text(
                            text = if (isServerConnected) "Render Cloud API Online" else "Connecting to Render Cloud...",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = if (isServerConnected) Color(0xFF059669) else Color(0xFFD97706)
                        )
                    }
                }

                // =============================================================
                // 3. MAIN GLASS CONTAINER CARD
                // =============================================================
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

                        // NAVIGATION TAB ROW (Sign In vs Sign Up)
                        TabRow(
                            selectedTabIndex = selectedTab,
                            containerColor = if (isDark) Color(0xFF1E293B).copy(alpha = 0.5f) else Color(0xFFF1F5F9),
                            contentColor = Color(0xFF1D4ED8),
                            indicator = { tabPositions ->
                                TabRowDefaults.SecondaryIndicator(
                                    modifier = Modifier.tabIndicatorOffset(tabPositions[selectedTab]),
                                    color = Color(0xFF2563EB),
                                    height = 3.dp
                                )
                            },
                            modifier = Modifier.clip(RoundedCornerShape(14.dp))
                        ) {
                            Tab(
                                selected = selectedTab == 0,
                                onClick = {
                                    selectedTab = 0
                                    errorMessage = null
                                    successMessage = null
                                },
                                text = {
                                    Text(
                                        text = "Sign In",
                                        fontWeight = if (selectedTab == 0) FontWeight.Bold else FontWeight.Medium,
                                        fontSize = 14.sp,
                                        color = if (selectedTab == 0) Color(0xFF1D4ED8) else Color(0xFF64748B)
                                    )
                                },
                                icon = {
                                    Icon(
                                        Icons.Default.Lock,
                                        contentDescription = null,
                                        modifier = Modifier.size(16.dp),
                                        tint = if (selectedTab == 0) Color(0xFF1D4ED8) else Color(0xFF64748B)
                                    )
                                }
                            )

                            Tab(
                                selected = selectedTab == 1,
                                onClick = {
                                    selectedTab = 1
                                    errorMessage = null
                                    successMessage = null
                                },
                                text = {
                                    Text(
                                        text = "Create Account",
                                        fontWeight = if (selectedTab == 1) FontWeight.Bold else FontWeight.Medium,
                                        fontSize = 14.sp,
                                        color = if (selectedTab == 1) Color(0xFF1D4ED8) else Color(0xFF64748B)
                                    )
                                },
                                icon = {
                                    Icon(
                                        Icons.Default.Business,
                                        contentDescription = null,
                                        modifier = Modifier.size(16.dp),
                                        tint = if (selectedTab == 1) Color(0xFF1D4ED8) else Color(0xFF64748B)
                                    )
                                }
                            )
                        }

                        // ERROR ALERT BANNER
                        AnimatedVisibility(
                            visible = errorMessage != null,
                            enter = fadeIn() + expandVertically(),
                            exit = fadeOut() + shrinkVertically()
                        ) {
                            Surface(
                                shape = RoundedCornerShape(12.dp),
                                color = if (isDark) Color(0xFF450A0A) else Color(0xFFFEF2F2),
                                border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFF87171).copy(alpha = 0.5f)),
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Row(
                                    modifier = Modifier.padding(12.dp),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.Warning,
                                        contentDescription = "Error",
                                        tint = Color(0xFFDC2626),
                                        modifier = Modifier.size(20.dp)
                                    )
                                    Text(
                                        text = errorMessage ?: "",
                                        color = if (isDark) Color(0xFFFCA5A5) else Color(0xFFB91C1C),
                                        fontSize = 12.sp,
                                        fontWeight = FontWeight.Medium,
                                        modifier = Modifier.weight(1f)
                                    )
                                }
                            }
                        }

                        // SUCCESS ALERT BANNER
                        AnimatedVisibility(
                            visible = successMessage != null,
                            enter = fadeIn() + expandVertically(),
                            exit = fadeOut() + shrinkVertically()
                        ) {
                            Surface(
                                shape = RoundedCornerShape(12.dp),
                                color = if (isDark) Color(0xFF022C22) else Color(0xFFECFDF5),
                                border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFF34D399).copy(alpha = 0.5f)),
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Row(
                                    modifier = Modifier.padding(12.dp),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.CheckCircle,
                                        contentDescription = "Success",
                                        tint = Color(0xFF059669),
                                        modifier = Modifier.size(20.dp)
                                    )
                                    Text(
                                        text = successMessage ?: "",
                                        color = if (isDark) Color(0xFF6EE7B7) else Color(0xFF047857),
                                        fontSize = 12.sp,
                                        fontWeight = FontWeight.Medium,
                                        modifier = Modifier.weight(1f)
                                    )
                                }
                            }
                        }

                        // =====================================================
                        // TAB CONTENT: 0 = SIGN IN
                        // =====================================================
                        if (selectedTab == 0) {
                            Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
                                Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                                    Text(
                                        text = "Welcome Back",
                                        fontSize = 20.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = if (isDark) Color.White else Color(0xFF0F172A)
                                    )
                                    Text(
                                        text = "Sign in to access your PostgreSQL organization database",
                                        fontSize = 12.sp,
                                        color = Color(0xFF64748B)
                                    )
                                }

                                // Identifier (Email or Mobile)
                                OutlinedTextField(
                                    value = loginIdentifier,
                                    onValueChange = {
                                        loginIdentifier = it
                                        errorMessage = null
                                    },
                                    label = { Text("Email or Mobile Number") },
                                    placeholder = { Text("you@company.com or +91...") },
                                    leadingIcon = {
                                        Icon(Icons.Default.AccountCircle, contentDescription = null, tint = Color(0xFF64748B))
                                    },
                                    singleLine = true,
                                    shape = RoundedCornerShape(12.dp),
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .testTag("field_login_identifier"),
                                    colors = OutlinedTextFieldDefaults.colors(
                                        focusedBorderColor = Color(0xFF2563EB),
                                        unfocusedBorderColor = if (isDark) Color(0xFF334155) else Color(0xFFCBD5E1)
                                    )
                                )

                                // Password
                                OutlinedTextField(
                                    value = loginPassword,
                                    onValueChange = {
                                        loginPassword = it
                                        errorMessage = null
                                    },
                                    label = { Text("Password") },
                                    placeholder = { Text("Enter your account password") },
                                    leadingIcon = {
                                        Icon(Icons.Default.Lock, contentDescription = null, tint = Color(0xFF64748B))
                                    },
                                    trailingIcon = {
                                        IconButton(onClick = { loginPasswordVisible = !loginPasswordVisible }) {
                                            Icon(
                                                imageVector = if (loginPasswordVisible) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                                                contentDescription = "Toggle password visibility",
                                                tint = Color(0xFF64748B)
                                            )
                                        }
                                    },
                                    visualTransformation = if (loginPasswordVisible) VisualTransformation.None else PasswordVisualTransformation(),
                                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                                    singleLine = true,
                                    shape = RoundedCornerShape(12.dp),
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .testTag("field_login_password"),
                                    colors = OutlinedTextFieldDefaults.colors(
                                        focusedBorderColor = Color(0xFF2563EB),
                                        unfocusedBorderColor = if (isDark) Color(0xFF334155) else Color(0xFFCBD5E1)
                                    )
                                )

                                // Sign In Submit Button
                                Button(
                                    onClick = {
                                        if (loginIdentifier.isBlank() || loginPassword.isBlank()) {
                                            errorMessage = "Please enter both identifier and password"
                                            return@Button
                                        }
                                        coroutineScope.launch {
                                            isSubmitting = true
                                            errorMessage = null
                                            val result = AuthSessionManager.login(loginIdentifier, loginPassword)
                                            isSubmitting = false
                                            if (result.isSuccess) {
                                                val user = result.getOrNull()
                                                Toast.makeText(
                                                    context,
                                                    "Signed in as ${user?.fullName} (${user?.role?.name})",
                                                    Toast.LENGTH_SHORT
                                                ).show()
                                                onLoginSuccess()
                                            } else {
                                                errorMessage = result.exceptionOrNull()?.message ?: "Login failed"
                                            }
                                        }
                                    },
                                    enabled = !isSubmitting,
                                    shape = RoundedCornerShape(14.dp),
                                    colors = ButtonDefaults.buttonColors(
                                        containerColor = Color(0xFF1D4ED8)
                                    ),
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .height(52.dp)
                                        .testTag("btn_submit_login")
                                ) {
                                    if (isSubmitting) {
                                        CircularProgressIndicator(
                                            modifier = Modifier.size(22.dp),
                                            color = Color.White,
                                            strokeWidth = 2.dp
                                        )
                                        Spacer(modifier = Modifier.width(10.dp))
                                        Text("Authenticating...", fontSize = 14.sp, fontWeight = FontWeight.Bold)
                                    } else {
                                        Row(
                                            verticalAlignment = Alignment.CenterVertically,
                                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                                        ) {
                                            Text("Sign In to Organization", fontSize = 15.sp, fontWeight = FontWeight.Bold)
                                            Icon(Icons.Default.ArrowForward, contentDescription = null, modifier = Modifier.size(18.dp))
                                        }
                                    }
                                }

                                // Toggle to Create Account
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.Center,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text(
                                        text = "Don't have an organization? ",
                                        fontSize = 12.sp,
                                        color = Color(0xFF64748B)
                                    )
                                    Text(
                                        text = "Create Account",
                                        fontSize = 12.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = Color(0xFF2563EB),
                                        modifier = Modifier.clickable {
                                            selectedTab = 1
                                            errorMessage = null
                                            successMessage = null
                                        }
                                    )
                                }
                            }
                        } else {
                            // =====================================================
                            // TAB CONTENT: 1 = SIGN UP / REGISTER
                            // =====================================================
                            Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
                                Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                                    Text(
                                        text = "Register Account",
                                        fontSize = 20.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = if (isDark) Color.White else Color(0xFF0F172A)
                                    )
                                    Text(
                                        text = "Register your business or join an existing team",
                                        fontSize = 12.sp,
                                        color = Color(0xFF64748B)
                                    )
                                }

                                // Role Mode Segmented Selector (Admin, Employee, Developer)
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .clip(RoundedCornerShape(12.dp))
                                        .background(if (isDark) Color(0xFF1E293B) else Color(0xFFF1F5F9))
                                        .padding(4.dp),
                                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                                ) {
                                    // 1. Company Admin
                                    Surface(
                                        shape = RoundedCornerShape(10.dp),
                                        color = if (regRoleMode == 0) Color(0xFF1D4ED8) else Color.Transparent,
                                        modifier = Modifier
                                            .weight(1f)
                                            .clickable { regRoleMode = 0; errorMessage = null }
                                    ) {
                                        Text(
                                            text = "🏢 Company",
                                            fontSize = 11.sp,
                                            fontWeight = if (regRoleMode == 0) FontWeight.Bold else FontWeight.Medium,
                                            color = if (regRoleMode == 0) Color.White else Color(0xFF64748B),
                                            textAlign = TextAlign.Center,
                                            modifier = Modifier.padding(vertical = 8.dp)
                                        )
                                    }

                                    // 2. Employee Join
                                    Surface(
                                        shape = RoundedCornerShape(10.dp),
                                        color = if (regRoleMode == 1) Color(0xFF059669) else Color.Transparent,
                                        modifier = Modifier
                                            .weight(1f)
                                            .clickable { regRoleMode = 1; errorMessage = null }
                                    ) {
                                        Text(
                                            text = "👥 Team Join",
                                            fontSize = 11.sp,
                                            fontWeight = if (regRoleMode == 1) FontWeight.Bold else FontWeight.Medium,
                                            color = if (regRoleMode == 1) Color.White else Color(0xFF64748B),
                                            textAlign = TextAlign.Center,
                                            modifier = Modifier.padding(vertical = 8.dp)
                                        )
                                    }

                                    // 3. Platform Developer
                                    Surface(
                                        shape = RoundedCornerShape(10.dp),
                                        color = if (regRoleMode == 2) Color(0xFF7C3AED) else Color.Transparent,
                                        modifier = Modifier
                                            .weight(1f)
                                            .clickable { regRoleMode = 2; errorMessage = null }
                                    ) {
                                        Text(
                                            text = "⚡ Developer",
                                            fontSize = 11.sp,
                                            fontWeight = if (regRoleMode == 2) FontWeight.Bold else FontWeight.Medium,
                                            color = if (regRoleMode == 2) Color.White else Color(0xFF64748B),
                                            textAlign = TextAlign.Center,
                                            modifier = Modifier.padding(vertical = 8.dp)
                                        )
                                    }
                                }

                                // USER IDENTITY FIELDS (Common across all roles)
                                OutlinedTextField(
                                    value = regFullName,
                                    onValueChange = { regFullName = it; errorMessage = null },
                                    label = { Text("Full Name *") },
                                    placeholder = { Text("e.g. Roshan Kumar") },
                                    leadingIcon = { Icon(Icons.Default.Person, contentDescription = null, tint = Color(0xFF64748B)) },
                                    singleLine = true,
                                    shape = RoundedCornerShape(12.dp),
                                    modifier = Modifier.fillMaxWidth().testTag("field_reg_fullname")
                                )

                                OutlinedTextField(
                                    value = regEmail,
                                    onValueChange = { regEmail = it; errorMessage = null },
                                    label = { Text("Email Address *") },
                                    placeholder = { Text("name@company.com") },
                                    leadingIcon = { Icon(Icons.Default.Email, contentDescription = null, tint = Color(0xFF64748B)) },
                                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email),
                                    singleLine = true,
                                    shape = RoundedCornerShape(12.dp),
                                    modifier = Modifier.fillMaxWidth().testTag("field_reg_email")
                                )

                                OutlinedTextField(
                                    value = regMobile,
                                    onValueChange = { regMobile = it; errorMessage = null },
                                    label = { Text("Mobile Number *") },
                                    placeholder = { Text("+91 98765 43210") },
                                    leadingIcon = { Icon(Icons.Default.Phone, contentDescription = null, tint = Color(0xFF64748B)) },
                                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
                                    singleLine = true,
                                    shape = RoundedCornerShape(12.dp),
                                    modifier = Modifier.fillMaxWidth().testTag("field_reg_mobile")
                                )

                                OutlinedTextField(
                                    value = regPassword,
                                    onValueChange = { regPassword = it; errorMessage = null },
                                    label = { Text("Password (min 6 characters) *") },
                                    placeholder = { Text("Create a secure password") },
                                    leadingIcon = { Icon(Icons.Default.Lock, contentDescription = null, tint = Color(0xFF64748B)) },
                                    trailingIcon = {
                                        IconButton(onClick = { regPasswordVisible = !regPasswordVisible }) {
                                            Icon(
                                                imageVector = if (regPasswordVisible) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                                                contentDescription = null,
                                                tint = Color(0xFF64748B)
                                            )
                                        }
                                    },
                                    visualTransformation = if (regPasswordVisible) VisualTransformation.None else PasswordVisualTransformation(),
                                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                                    singleLine = true,
                                    shape = RoundedCornerShape(12.dp),
                                    modifier = Modifier.fillMaxWidth().testTag("field_reg_password")
                                )

                                // ROLE SPECIFIC FIELDS
                                when (regRoleMode) {
                                    0 -> {
                                        // =====================================
                                        // ROLE: COMPANY ADMIN
                                        // =====================================
                                        Text(
                                            text = "Business Organization Details",
                                            fontSize = 13.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = Color(0xFF1D4ED8)
                                        )

                                        OutlinedTextField(
                                            value = regCompanyName,
                                            onValueChange = { regCompanyName = it; errorMessage = null },
                                            label = { Text("Company / Business Name *") },
                                            placeholder = { Text("e.g. Acme Tech Solutions LLC") },
                                            leadingIcon = { Icon(Icons.Default.Apartment, contentDescription = null, tint = Color(0xFF64748B)) },
                                            singleLine = true,
                                            shape = RoundedCornerShape(12.dp),
                                            modifier = Modifier.fillMaxWidth().testTag("field_reg_company_name")
                                        )

                                        OutlinedTextField(
                                            value = regGstin,
                                            onValueChange = { regGstin = it },
                                            label = { Text("GSTIN / Tax Registration ID") },
                                            placeholder = { Text("e.g. 27AABCU9603R1ZN") },
                                            leadingIcon = { Icon(Icons.Default.Badge, contentDescription = null, tint = Color(0xFF64748B)) },
                                            singleLine = true,
                                            shape = RoundedCornerShape(12.dp),
                                            modifier = Modifier.fillMaxWidth()
                                        )

                                        OutlinedTextField(
                                            value = regLocation,
                                            onValueChange = { regLocation = it },
                                            label = { Text("Business Address / City") },
                                            placeholder = { Text("e.g. Mumbai, Maharashtra") },
                                            leadingIcon = { Icon(Icons.Default.LocationOn, contentDescription = null, tint = Color(0xFF64748B)) },
                                            singleLine = true,
                                            shape = RoundedCornerShape(12.dp),
                                            modifier = Modifier.fillMaxWidth()
                                        )

                                        OutlinedTextField(
                                            value = regCompanyDetails,
                                            onValueChange = { regCompanyDetails = it },
                                            label = { Text("Business Category / Description") },
                                            placeholder = { Text("e.g. IT Consulting & Software Development") },
                                            singleLine = true,
                                            shape = RoundedCornerShape(12.dp),
                                            modifier = Modifier.fillMaxWidth()
                                        )
                                    }
                                    1 -> {
                                        // =====================================
                                        // ROLE: EMPLOYEE JOIN
                                        // =====================================
                                        Text(
                                            text = "Company Join Details",
                                            fontSize = 13.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = Color(0xFF059669)
                                        )

                                        OutlinedTextField(
                                            value = regCompanyCode,
                                            onValueChange = { regCompanyCode = it.uppercase(); errorMessage = null },
                                            label = { Text("Company Code to Join *") },
                                            placeholder = { Text("e.g. COMP-APEX99") },
                                            leadingIcon = { Icon(Icons.Default.Apartment, contentDescription = null, tint = Color(0xFF64748B)) },
                                            singleLine = true,
                                            shape = RoundedCornerShape(12.dp),
                                            modifier = Modifier.fillMaxWidth().testTag("field_reg_company_code")
                                        )

                                        OutlinedTextField(
                                            value = regRequestMessage,
                                            onValueChange = { regRequestMessage = it },
                                            label = { Text("Request Note for Administrator") },
                                            placeholder = { Text("e.g. Junior Accountant joining the finance team") },
                                            singleLine = false,
                                            maxLines = 3,
                                            shape = RoundedCornerShape(12.dp),
                                            modifier = Modifier.fillMaxWidth()
                                        )

                                        Surface(
                                            shape = RoundedCornerShape(10.dp),
                                            color = if (isDark) Color(0xFF064E3B).copy(alpha = 0.5f) else Color(0xFFECFDF5),
                                            modifier = Modifier.fillMaxWidth()
                                        ) {
                                            Row(
                                                modifier = Modifier.padding(10.dp),
                                                verticalAlignment = Alignment.CenterVertically,
                                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                                            ) {
                                                Icon(Icons.Default.Info, contentDescription = null, tint = Color(0xFF059669), modifier = Modifier.size(18.dp))
                                                Text(
                                                    text = "Once submitted, your company Admin will review and approve your account before you can log in.",
                                                    fontSize = 11.sp,
                                                    color = if (isDark) Color(0xFFA7F3D0) else Color(0xFF065F46)
                                                )
                                            }
                                        }
                                    }
                                    2 -> {
                                        // =====================================
                                        // ROLE: PLATFORM DEVELOPER
                                        // =====================================
                                        Text(
                                            text = "Developer Authentication",
                                            fontSize = 13.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = Color(0xFF7C3AED)
                                        )

                                        OutlinedTextField(
                                            value = regDeveloperKey,
                                            onValueChange = { regDeveloperKey = it; errorMessage = null },
                                            label = { Text("Developer Master Secret Key *") },
                                            leadingIcon = { Icon(Icons.Default.Key, contentDescription = null, tint = Color(0xFF64748B)) },
                                            singleLine = true,
                                            shape = RoundedCornerShape(12.dp),
                                            modifier = Modifier.fillMaxWidth().testTag("field_reg_dev_key")
                                        )
                                    }
                                }

                                // Sign Up Submit Button
                                Button(
                                    onClick = {
                                        coroutineScope.launch {
                                            isSubmitting = true
                                            errorMessage = null
                                            successMessage = null

                                            when (regRoleMode) {
                                                0 -> {
                                                    // Register Company & Admin
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
                                                        Toast.makeText(context, "Organization created successfully in PostgreSQL!", Toast.LENGTH_SHORT).show()
                                                        onLoginSuccess()
                                                    } else {
                                                        errorMessage = res.exceptionOrNull()?.message ?: "Registration failed"
                                                    }
                                                }
                                                1 -> {
                                                    // Submit Employee Join Request
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
                                                        successMessage = res.getOrNull() ?: "Join request submitted! Awaiting Admin approval."
                                                    } else {
                                                        errorMessage = res.exceptionOrNull()?.message ?: "Failed to submit join request"
                                                    }
                                                }
                                                2 -> {
                                                    // Register Developer
                                                    val res = AuthSessionManager.registerDeveloper(
                                                        fullName = regFullName,
                                                        email = regEmail,
                                                        mobile = regMobile,
                                                        password = regPassword,
                                                        developerSecretKey = regDeveloperKey
                                                    )
                                                    isSubmitting = false
                                                    if (res.isSuccess) {
                                                        Toast.makeText(context, "Platform Developer account created!", Toast.LENGTH_SHORT).show()
                                                        onLoginSuccess()
                                                    } else {
                                                        errorMessage = res.exceptionOrNull()?.message ?: "Developer registration failed"
                                                    }
                                                }
                                            }
                                        }
                                    },
                                    enabled = !isSubmitting,
                                    shape = RoundedCornerShape(14.dp),
                                    colors = ButtonDefaults.buttonColors(
                                        containerColor = when (regRoleMode) {
                                            1 -> Color(0xFF059669)
                                            2 -> Color(0xFF7C3AED)
                                            else -> Color(0xFF1D4ED8)
                                        }
                                    ),
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .height(52.dp)
                                        .testTag("btn_submit_register")
                                ) {
                                    if (isSubmitting) {
                                        CircularProgressIndicator(modifier = Modifier.size(22.dp), color = Color.White, strokeWidth = 2.dp)
                                        Spacer(modifier = Modifier.width(10.dp))
                                        Text("Registering in PostgreSQL...", fontSize = 14.sp, fontWeight = FontWeight.Bold)
                                    } else {
                                        val btnLabel = when (regRoleMode) {
                                            1 -> "Submit Employee Join Request"
                                            2 -> "Activate Developer Access"
                                            else -> "Register Organization & Admin"
                                        }
                                        Text(btnLabel, fontSize = 14.sp, fontWeight = FontWeight.Bold)
                                    }
                                }

                                // Toggle to Sign In
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.Center,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text(text = "Already have an account? ", fontSize = 12.sp, color = Color(0xFF64748B))
                                    Text(
                                        text = "Sign In",
                                        fontSize = 12.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = Color(0xFF2563EB),
                                        modifier = Modifier.clickable {
                                            selectedTab = 0
                                            errorMessage = null
                                            successMessage = null
                                        }
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
