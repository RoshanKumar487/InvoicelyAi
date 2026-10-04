package com.example.ui.screens

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Apartment
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Phone
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Security
import androidx.compose.material.icons.filled.Sync
import androidx.compose.material.icons.filled.Tune
import androidx.compose.material.icons.filled.VerifiedUser
import android.content.Intent
import android.net.Uri
import java.net.URLEncoder
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.Badge
import androidx.compose.material.icons.filled.Chat
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.TextButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.TabRowDefaults
import androidx.compose.material3.TabRowDefaults.tabIndicatorOffset
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CheckboxDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
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
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.data.api.model.UserSummaryDto
import com.example.data.model.EmployeeJoinRequest
import com.example.data.model.UserRole
import com.example.data.repository.AuthSessionManager
import com.example.ui.components.AmbientGlassBackdrop
import com.example.ui.components.GlassCard
import com.example.ui.theme.PrimaryNavy

@Composable
fun TeamManagementScreen(
    onBack: () -> Unit,
    onOpenMenu: () -> Unit = {},
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val isDark = isSystemInDarkTheme()
    val currentUser by AuthSessionManager.currentUser.collectAsStateWithLifecycle()
    val currentCompany by AuthSessionManager.currentCompany.collectAsStateWithLifecycle()
    val joinRequests by AuthSessionManager.joinRequests.collectAsStateWithLifecycle()
    val allCompanies by AuthSessionManager.allCompanies.collectAsStateWithLifecycle()
    val companyEmployees by AuthSessionManager.companyEmployees.collectAsStateWithLifecycle()
    var editingEmployee by remember { mutableStateOf<UserSummaryDto?>(null) }
    var showCustomizeInviteDialog by remember { mutableStateOf(false) }
    var inviteTargetName by remember { mutableStateOf("") }
    var inviteCustomNotes by remember { mutableStateOf("") }
    var inviteTemplateTab by remember { mutableIntStateOf(0) } // 0 = WhatsApp, 1 = Email

    val userRole = currentUser?.role ?: UserRole.EMPLOYEE

    LaunchedEffect(Unit) {
        AuthSessionManager.fetchRemoteMetadata()
    }

    AmbientGlassBackdrop {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .statusBarsPadding()
        ) {
            // Header Bar
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    IconButton(
                        onClick = onBack,
                        modifier = Modifier
                            .size(38.dp)
                            .clip(CircleShape)
                            .background(if (isDark) Color(0xFF1E293B) else Color.White.copy(alpha = 0.8f))
                    ) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = if (isDark) Color.White else PrimaryNavy)
                    }

                    Column {
                        Text(
                            text = "Team & Join Requests",
                            fontSize = 18.sp,
                            fontWeight = FontWeight.ExtraBold,
                            color = if (isDark) Color.White else PrimaryNavy
                        )
                        Text(
                            text = if (userRole == UserRole.DEVELOPER) "Platform Developer (Global Mode)" else currentCompany?.companyName ?: "Organization Workspace",
                            fontSize = 12.sp,
                            color = Color(0xFF64748B)
                        )
                    }
                }

                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    IconButton(
                        onClick = {
                            AuthSessionManager.fetchRemoteMetadata()
                        },
                        modifier = Modifier
                            .size(38.dp)
                            .clip(CircleShape)
                            .background(if (isDark) Color(0xFF1E293B) else Color.White.copy(alpha = 0.8f))
                    ) {
                        Icon(Icons.Default.Sync, contentDescription = "Sync Requests", tint = if (isDark) Color.White else PrimaryNavy)
                    }

                    IconButton(
                        onClick = onOpenMenu,
                        modifier = Modifier
                            .size(38.dp)
                            .clip(CircleShape)
                            .background(if (isDark) Color(0xFF1E293B) else Color.White.copy(alpha = 0.8f))
                    ) {
                        Icon(Icons.Default.Menu, contentDescription = "Open Menu", tint = if (isDark) Color.White else PrimaryNavy)
                    }
                }
            }

            if (!userRole.canApproveJoinRequests) {
                // =================================================================
                // RESTRICTED VIEW FOR EMPLOYEES
                // =================================================================
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(24.dp),
                    contentAlignment = Alignment.Center
                ) {
                    GlassCard(
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(20.dp)
                    ) {
                        Column(
                            modifier = Modifier.padding(24.dp),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(14.dp)
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(56.dp)
                                    .clip(CircleShape)
                                    .background(Color(0xFFFEF3C7)),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(Icons.Default.Lock, contentDescription = null, tint = Color(0xFFD97706), modifier = Modifier.size(28.dp))
                            }

                            Text(
                                text = "Admin Permission Required",
                                fontWeight = FontWeight.Bold,
                                fontSize = 18.sp,
                                color = if (isDark) Color.White else Color(0xFF0F172A)
                            )

                            Text(
                                text = "You are currently logged in as a Team Employee (${currentUser?.fullName}). Staff onboarding and join request approvals are restricted to Organization Admins.",
                                fontSize = 13.sp,
                                color = Color(0xFF64748B),
                                textAlign = androidx.compose.ui.text.style.TextAlign.Center
                            )

                            Button(
                                onClick = onBack,
                                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF1D4ED8)),
                                shape = RoundedCornerShape(12.dp)
                            ) {
                                Text("Return to Workspace")
                            }
                        }
                    }
                }
            } else {
                // =================================================================
                // ADMIN / DEVELOPER VIEW
                // =================================================================
                LazyColumn(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(horizontal = 16.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    // Organization Code Card (1-Tap Share)
                    item {
                        GlassCard(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(20.dp)
                        ) {
                            Column(
                                modifier = Modifier.padding(18.dp),
                                verticalArrangement = Arrangement.spacedBy(12.dp)
                            ) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                        Icon(Icons.Default.Apartment, contentDescription = null, tint = Color(0xFF1D4ED8))
                                        Text(
                                            text = currentCompany?.companyName ?: "Organization Workspace",
                                            fontWeight = FontWeight.Bold,
                                            fontSize = 16.sp,
                                            color = if (isDark) Color.White else PrimaryNavy
                                        )
                                    }

                                    Surface(
                                        shape = RoundedCornerShape(12.dp),
                                        color = userRole.badgeBgColor
                                    ) {
                                        Text(
                                            text = userRole.shortBadge,
                                            color = userRole.badgeFgColor,
                                            fontWeight = FontWeight.ExtraBold,
                                            fontSize = 11.sp,
                                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                                        )
                                    }
                                }

                                Text(
                                    text = "Share your unique Organization Code with employees so they can register and join your workspace:",
                                    fontSize = 12.sp,
                                    color = Color(0xFF64748B)
                                )

                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .clip(RoundedCornerShape(12.dp))
                                        .background(if (isDark) Color(0xFF0F172A) else Color(0xFFEFF6FF))
                                        .border(1.dp, Color(0xFF93C5FD), RoundedCornerShape(12.dp))
                                        .clickable {
                                            val code = currentCompany?.companyCode ?: "COMP-APEX99"
                                            val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                                            clipboard.setPrimaryClip(ClipData.newPlainText("Company Code", code))
                                            Toast.makeText(context, "Copied code: $code", Toast.LENGTH_SHORT).show()
                                        }
                                        .padding(horizontal = 14.dp, vertical = 10.dp),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Column {
                                        Text("ORGANIZATION CODE", fontSize = 10.sp, fontWeight = FontWeight.Bold, color = Color(0xFF3B82F6))
                                        Text(
                                            text = currentCompany?.companyCode ?: "COMP-APEX99",
                                            fontSize = 17.sp,
                                            fontWeight = FontWeight.ExtraBold,
                                            letterSpacing = 1.sp,
                                            color = Color(0xFF1D4ED8)
                                        )
                                    }

                                    Row(
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                                    ) {
                                        Icon(Icons.Default.ContentCopy, contentDescription = "Copy", tint = Color(0xFF1D4ED8), modifier = Modifier.size(16.dp))
                                        Text("Copy", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = Color(0xFF1D4ED8))
                                    }
                                }
                            }
                        }
                    }

                    // Direct Employee Invitation Card (WhatsApp & Email)
                    item {
                        GlassCard(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(20.dp)
                        ) {
                            Column(
                                modifier = Modifier.padding(18.dp),
                                verticalArrangement = Arrangement.spacedBy(12.dp)
                            ) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                        Box(
                                            modifier = Modifier
                                                .size(36.dp)
                                                .clip(CircleShape)
                                                .background(Color(0xFFE0E7FF)),
                                            contentAlignment = Alignment.Center
                                        ) {
                                            Icon(Icons.AutoMirrored.Filled.Send, contentDescription = null, tint = Color(0xFF4338CA), modifier = Modifier.size(18.dp))
                                        }
                                        Column {
                                            Text(
                                                text = "Invite Employees & Staff",
                                                fontWeight = FontWeight.Bold,
                                                fontSize = 15.sp,
                                                color = if (isDark) Color.White else PrimaryNavy
                                            )
                                            Text(
                                                text = "Direct WhatsApp & Email Onboarding",
                                                fontSize = 11.sp,
                                                color = Color(0xFF64748B)
                                            )
                                        }
                                    }

                                    Surface(
                                        shape = RoundedCornerShape(8.dp),
                                        color = Color(0xFFEFF6FF)
                                    ) {
                                        Text(
                                            text = "1-Tap Invite",
                                            fontSize = 10.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = Color(0xFF2563EB),
                                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 3.dp)
                                        )
                                    }
                                }

                                Text(
                                    text = "Send an invite directly to your employee. They will create an account under Team Join, enter your company code (${currentCompany?.companyCode ?: "..."}), and submit their join request for your instant approval.",
                                    fontSize = 12.sp,
                                    color = Color(0xFF475569),
                                    lineHeight = 16.sp
                                )

                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                                ) {
                                    // 1-Tap WhatsApp Invite Button
                                    Button(
                                        onClick = {
                                            val compName = currentCompany?.companyName ?: "Organization Workspace"
                                            val compCode = currentCompany?.companyCode ?: "COMP-APEX99"
                                            val adminName = currentUser?.fullName ?: "Organization Admin"
                                            val msg = buildWhatsAppInviteMessage(compName, compCode, adminName, inviteTargetName, inviteCustomNotes)
                                            sendWhatsAppInvite(context, msg)
                                        },
                                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF25D366)),
                                        shape = RoundedCornerShape(12.dp),
                                        modifier = Modifier
                                            .weight(1f)
                                            .height(42.dp)
                                    ) {
                                        Icon(Icons.Default.Chat, contentDescription = null, tint = Color.White, modifier = Modifier.size(16.dp))
                                        Spacer(modifier = Modifier.width(6.dp))
                                        Text("WhatsApp", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = Color.White)
                                    }

                                    // 1-Tap Email Invite Button
                                    Button(
                                        onClick = {
                                            val compName = currentCompany?.companyName ?: "Organization Workspace"
                                            val compCode = currentCompany?.companyCode ?: "COMP-APEX99"
                                            val adminName = currentUser?.fullName ?: "Organization Admin"
                                            val adminEmail = currentUser?.email ?: "admin@company.com"
                                            val subject = buildEmailInviteSubject(compName)
                                            val body = buildEmailInviteBody(compName, compCode, adminName, adminEmail, inviteTargetName, inviteCustomNotes)
                                            sendEmailInvite(context, subject, body)
                                        },
                                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF2563EB)),
                                        shape = RoundedCornerShape(12.dp),
                                        modifier = Modifier
                                            .weight(1f)
                                            .height(42.dp)
                                    ) {
                                        Icon(Icons.Default.Email, contentDescription = null, tint = Color.White, modifier = Modifier.size(16.dp))
                                        Spacer(modifier = Modifier.width(6.dp))
                                        Text("Email Invite", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = Color.White)
                                    }
                                }

                                // Customize & Preview Button
                                OutlinedButton(
                                    onClick = { showCustomizeInviteDialog = true },
                                    shape = RoundedCornerShape(12.dp),
                                    modifier = Modifier.fillMaxWidth().height(40.dp),
                                    border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFF93C5FD))
                                ) {
                                    Icon(Icons.Default.Tune, contentDescription = null, tint = Color(0xFF1D4ED8), modifier = Modifier.size(16.dp))
                                    Spacer(modifier = Modifier.width(6.dp))
                                    Text("Customize Message & Live Preview", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = Color(0xFF1D4ED8))
                                }
                            }
                        }
                    }

                    // Developer Global Organization Switcher
                    if (userRole == UserRole.DEVELOPER) {
                        item {
                            GlassCard(
                                modifier = Modifier.fillMaxWidth(),
                                shape = RoundedCornerShape(18.dp)
                            ) {
                                Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                        Icon(Icons.Default.VerifiedUser, contentDescription = null, tint = Color(0xFF7E22CE))
                                        Text("Developer Superuser: Organization Switcher", fontWeight = FontWeight.Bold, fontSize = 14.sp, color = Color(0xFF7E22CE))
                                    }

                                    Text(
                                        text = "As a Platform Developer, you can inspect or switch into any registered organization's workspace:",
                                        fontSize = 12.sp,
                                        color = Color(0xFF64748B)
                                    )

                                    Row(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .horizontalScroll(androidx.compose.foundation.rememberScrollState()),
                                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                                    ) {
                                        allCompanies.forEach { comp ->
                                            val isSelected = currentCompany?.id == comp.id
                                            Surface(
                                                shape = RoundedCornerShape(12.dp),
                                                color = if (isSelected) Color(0xFFF3E8FF) else Color(0xFFF1F5F9),
                                                border = androidx.compose.foundation.BorderStroke(1.dp, if (isSelected) Color(0xFF7E22CE) else Color(0xFFCBD5E1)),
                                                modifier = Modifier.clickable {
                                                    AuthSessionManager.switchCompanyForDeveloper(comp)
                                                    Toast.makeText(context, "Switched view to ${comp.companyName}", Toast.LENGTH_SHORT).show()
                                                }
                                            ) {
                                                Column(modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp)) {
                                                    Text(comp.companyName, fontWeight = FontWeight.Bold, fontSize = 12.sp, color = if (isSelected) Color(0xFF7E22CE) else Color(0xFF0F172A))
                                                    Text(comp.companyCode, fontSize = 10.sp, color = Color(0xFF64748B))
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Section: Pending Join Requests
                    item {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "Pending Staff Join Requests",
                                fontSize = 15.sp,
                                fontWeight = FontWeight.Bold,
                                color = if (isDark) Color.White else PrimaryNavy
                            )

                            val pendingCount = joinRequests.count { it.status == "PENDING" }
                            Surface(
                                shape = RoundedCornerShape(10.dp),
                                color = if (pendingCount > 0) Color(0xFFFEF3C7) else Color(0xFFE2E8F0)
                            ) {
                                Text(
                                    text = "$pendingCount Pending",
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = if (pendingCount > 0) Color(0xFFB45309) else Color(0xFF475569),
                                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
                                )
                            }
                        }
                    }

                    if (joinRequests.isEmpty()) {
                        item {
                            GlassCard(modifier = Modifier.fillMaxWidth()) {
                                Box(modifier = Modifier.fillMaxWidth().padding(24.dp), contentAlignment = Alignment.Center) {
                                    Text("No join requests yet. Share your code to onboard staff.", color = Color(0xFF94A3B8), fontSize = 13.sp)
                                }
                            }
                        }
                    } else {
                        items(joinRequests) { req ->
                            JoinRequestCard(
                                request = req,
                                isDark = isDark,
                                onApprove = {
                                    AuthSessionManager.approveJoinRequest(req.id)
                                    Toast.makeText(context, "Approved ${req.userFullName}! Account activated.", Toast.LENGTH_SHORT).show()
                                },
                                onReject = {
                                    AuthSessionManager.rejectJoinRequest(req.id)
                                    Toast.makeText(context, "Rejected request from ${req.userFullName}", Toast.LENGTH_SHORT).show()
                                }
                            )
                        }
                    }

                    // Section: Active Team Members
                    item {
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = "Active Team Members",
                            fontSize = 15.sp,
                            fontWeight = FontWeight.Bold,
                            color = if (isDark) Color.White else PrimaryNavy
                        )
                    }

                    item {
                        GlassCard(modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(16.dp)) {
                            Column(modifier = Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                                TeamMemberRow(
                                    name = "Jordan Vance",
                                    email = "admin@apexnova.io",
                                    roleLabel = "👑 Admin",
                                    roleColor = Color(0xFF1D4ED8),
                                    roleBg = Color(0xFFDBEAFE),
                                    isDark = isDark
                                )
                                HorizontalDivider(color = Color(0xFFE2E8F0).copy(alpha = 0.5f))
                                TeamMemberRow(
                                    name = "Elena Rostova",
                                    email = "employee@apexnova.io",
                                    roleLabel = "👤 Employee",
                                    roleColor = Color(0xFF047857),
                                    roleBg = Color(0xFFD1FAE5),
                                    isDark = isDark
                                )
                            }
                        }
                    }

                    item { Spacer(modifier = Modifier.height(24.dp)) }
                }
            }
        }

        // =====================================================================
        // CUSTOMIZE INVITATION & TEMPLATE PREVIEW MODAL
        // =====================================================================
        if (showCustomizeInviteDialog) {
            val compName = currentCompany?.companyName ?: "Organization Workspace"
            val compCode = currentCompany?.companyCode ?: "COMP-APEX99"
            val adminName = currentUser?.fullName ?: "Organization Admin"
            val adminEmail = currentUser?.email ?: "admin@company.com"

            val whatsAppMsg = remember(compName, compCode, adminName, inviteTargetName, inviteCustomNotes) {
                buildWhatsAppInviteMessage(compName, compCode, adminName, inviteTargetName, inviteCustomNotes)
            }
            val emailSubject = remember(compName) {
                buildEmailInviteSubject(compName)
            }
            val emailBody = remember(compName, compCode, adminName, adminEmail, inviteTargetName, inviteCustomNotes) {
                buildEmailInviteBody(compName, compCode, adminName, adminEmail, inviteTargetName, inviteCustomNotes)
            }

            AlertDialog(
                onDismissRequest = { showCustomizeInviteDialog = false },
                title = {
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        Box(
                            modifier = Modifier
                                .size(36.dp)
                                .clip(CircleShape)
                                .background(Color(0xFFE0E7FF)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(Icons.AutoMirrored.Filled.Send, contentDescription = null, tint = Color(0xFF4338CA), modifier = Modifier.size(18.dp))
                        }
                        Column {
                            Text("Customize Team Invitation", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = if (isDark) Color.White else PrimaryNavy)
                            Text("Live template preview & one-tap dispatch", fontSize = 11.sp, color = Color(0xFF64748B))
                        }
                    }
                },
                text = {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .verticalScroll(rememberScrollState()),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        // Format Tab Selector (WhatsApp vs Email)
                        TabRow(
                            selectedTabIndex = inviteTemplateTab,
                            containerColor = if (isDark) Color(0xFF1E293B) else Color(0xFFF1F5F9),
                            indicator = { tabPositions ->
                                TabRowDefaults.SecondaryIndicator(
                                    modifier = Modifier.tabIndicatorOffset(tabPositions[inviteTemplateTab]),
                                    color = if (inviteTemplateTab == 0) Color(0xFF25D366) else Color(0xFF2563EB),
                                    height = 3.dp
                                )
                            },
                            modifier = Modifier.clip(RoundedCornerShape(10.dp))
                        ) {
                            Tab(
                                selected = inviteTemplateTab == 0,
                                onClick = { inviteTemplateTab = 0 },
                                text = {
                                    Text(
                                        "💬 WhatsApp",
                                        fontSize = 12.sp,
                                        fontWeight = if (inviteTemplateTab == 0) FontWeight.Bold else FontWeight.Normal,
                                        color = if (inviteTemplateTab == 0) Color(0xFF047857) else Color(0xFF64748B)
                                    )
                                }
                            )
                            Tab(
                                selected = inviteTemplateTab == 1,
                                onClick = { inviteTemplateTab = 1 },
                                text = {
                                    Text(
                                        "✉️ Email",
                                        fontSize = 12.sp,
                                        fontWeight = if (inviteTemplateTab == 1) FontWeight.Bold else FontWeight.Normal,
                                        color = if (inviteTemplateTab == 1) Color(0xFF1D4ED8) else Color(0xFF64748B)
                                    )
                                }
                            )
                        }

                        // Customization Inputs
                        OutlinedTextField(
                            value = inviteTargetName,
                            onValueChange = { inviteTargetName = it },
                            label = { Text("Recipient Employee Name (Optional)") },
                            placeholder = { Text("e.g. Elena Rostova") },
                            singleLine = true,
                            leadingIcon = { Icon(Icons.Default.Person, contentDescription = null, tint = Color(0xFF64748B)) },
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(10.dp)
                        )

                        OutlinedTextField(
                            value = inviteCustomNotes,
                            onValueChange = { inviteCustomNotes = it },
                            label = { Text("Custom Welcome Note / Instructions (Optional)") },
                            placeholder = { Text("e.g. Please join before Monday's finance sprint.") },
                            maxLines = 3,
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(10.dp)
                        )

                        // Live Template Preview Box
                        Text("LIVE TEMPLATE PREVIEW", fontSize = 10.sp, fontWeight = FontWeight.Bold, color = Color(0xFF64748B))

                        Surface(
                            shape = RoundedCornerShape(12.dp),
                            color = if (inviteTemplateTab == 0) {
                                if (isDark) Color(0xFF064E3B).copy(alpha = 0.35f) else Color(0xFFDCF8C6).copy(alpha = 0.45f)
                            } else {
                                if (isDark) Color(0xFF1E293B) else Color(0xFFEFF6FF)
                            },
                            border = androidx.compose.foundation.BorderStroke(
                                1.dp,
                                if (inviteTemplateTab == 0) Color(0xFF86EFAC) else Color(0xFFBFDBFE)
                            ),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Column(modifier = Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                                if (inviteTemplateTab == 1) {
                                    Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                                        Text("Subject:", fontWeight = FontWeight.Bold, fontSize = 11.sp, color = Color(0xFF1D4ED8))
                                        Text(emailSubject, fontSize = 11.sp, color = if (isDark) Color.White else Color(0xFF0F172A))
                                    }
                                    HorizontalDivider(color = Color(0xFFBFDBFE).copy(alpha = 0.5f))
                                }

                                Text(
                                    text = if (inviteTemplateTab == 0) whatsAppMsg else emailBody,
                                    fontSize = 11.sp,
                                    lineHeight = 16.sp,
                                    color = if (isDark) Color(0xFFE2E8F0) else Color(0xFF1E293B)
                                )
                            }
                        }

                        // Organization Code Chip
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                Text("Company Code:", fontSize = 11.sp, color = Color(0xFF64748B), fontWeight = FontWeight.SemiBold)
                                Surface(
                                    color = Color(0xFFDBEAFE),
                                    shape = RoundedCornerShape(6.dp)
                                ) {
                                    Text(compCode, fontSize = 11.sp, fontWeight = FontWeight.ExtraBold, color = Color(0xFF1D4ED8), modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp))
                                }
                            }

                            TextButton(onClick = {
                                val textToCopy = if (inviteTemplateTab == 0) whatsAppMsg else emailBody
                                val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                                clipboard.setPrimaryClip(ClipData.newPlainText("Invitation Message", textToCopy))
                                Toast.makeText(context, "Copied template to clipboard!", Toast.LENGTH_SHORT).show()
                            }) {
                                Icon(Icons.Default.ContentCopy, contentDescription = null, modifier = Modifier.size(14.dp), tint = Color(0xFF1D4ED8))
                                Spacer(modifier = Modifier.width(4.dp))
                                Text("Copy Text", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = Color(0xFF1D4ED8))
                            }
                        }
                    }
                },
                confirmButton = {
                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        if (inviteTemplateTab == 0) {
                            Button(
                                onClick = {
                                    sendWhatsAppInvite(context, whatsAppMsg)
                                },
                                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF25D366)),
                                shape = RoundedCornerShape(8.dp)
                            ) {
                                Icon(Icons.Default.Chat, contentDescription = null, tint = Color.White, modifier = Modifier.size(14.dp))
                                Spacer(modifier = Modifier.width(4.dp))
                                Text("Send on WhatsApp", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = Color.White)
                            }
                        } else {
                            Button(
                                onClick = {
                                    sendEmailInvite(context, emailSubject, emailBody)
                                },
                                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF2563EB)),
                                shape = RoundedCornerShape(8.dp)
                            ) {
                                Icon(Icons.Default.Email, contentDescription = null, tint = Color.White, modifier = Modifier.size(14.dp))
                                Spacer(modifier = Modifier.width(4.dp))
                                Text("Send via Email", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = Color.White)
                            }
                        }
                    }
                },
                dismissButton = {
                    OutlinedButton(
                        onClick = { showCustomizeInviteDialog = false },
                        shape = RoundedCornerShape(8.dp)
                    ) {
                        Text("Close", fontSize = 11.sp)
                    }
                }
            )
        }
    }
}

@Composable
private fun JoinRequestCard(
    request: EmployeeJoinRequest,
    isDark: Boolean,
    onApprove: () -> Unit,
    onReject: () -> Unit
) {
    GlassCard(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        modifier = Modifier
                            .size(42.dp)
                            .clip(CircleShape)
                            .background(
                                Brush.linearGradient(
                                    listOf(Color(0xFF2563EB), Color(0xFF7C3AED))
                                )
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = request.userFullName.take(2).uppercase(),
                            fontWeight = FontWeight.ExtraBold,
                            fontSize = 14.sp,
                            color = Color.White
                        )
                    }

                    Column {
                        Text(
                            text = request.userFullName,
                            fontWeight = FontWeight.Bold,
                            fontSize = 14.sp,
                            color = if (isDark) Color.White else Color(0xFF0F172A)
                        )
                        Text(
                            text = request.userEmail,
                            fontSize = 12.sp,
                            color = Color(0xFF64748B)
                        )
                        if (request.userMobile.isNotBlank()) {
                            Text(
                                text = "📱 ${request.userMobile}",
                                fontSize = 11.sp,
                                color = Color(0xFF64748B)
                            )
                        }
                    }
                }

                val (badgeBg, badgeFg) = when (request.status) {
                    "APPROVED" -> Pair(Color(0xFFD1FAE5), Color(0xFF047857))
                    "REJECTED" -> Pair(Color(0xFFFEE2E2), Color(0xFFBE123C))
                    else -> Pair(Color(0xFFFEF3C7), Color(0xFFB45309))
                }

                Column(horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Surface(shape = RoundedCornerShape(8.dp), color = badgeBg) {
                        Text(
                            text = request.status,
                            fontWeight = FontWeight.ExtraBold,
                            fontSize = 10.sp,
                            color = badgeFg,
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
                        )
                    }
                    Text(
                        text = request.requestedDate,
                        fontSize = 10.sp,
                        color = Color(0xFF94A3B8)
                    )
                }
            }

            if (request.requestMessage.isNotBlank()) {
                Surface(
                    shape = RoundedCornerShape(10.dp),
                    color = if (isDark) Color(0xFF1E293B) else Color(0xFFF8FAFC),
                    border = androidx.compose.foundation.BorderStroke(1.dp, if (isDark) Color(0xFF334155) else Color(0xFFE2E8F0)),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Row(
                        modifier = Modifier.padding(10.dp),
                        verticalAlignment = Alignment.Top,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Icon(Icons.Default.Info, contentDescription = null, tint = Color(0xFF3B82F6), modifier = Modifier.size(16.dp))
                        Text(
                            text = "\"${request.requestMessage}\"",
                            fontSize = 12.sp,
                            color = if (isDark) Color(0xFFCBD5E1) else Color(0xFF475569),
                            lineHeight = 16.sp
                        )
                    }
                }
            }

            if (request.status == "PENDING") {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Button(
                        onClick = onApprove,
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF059669)),
                        shape = RoundedCornerShape(10.dp),
                        modifier = Modifier.weight(1f).height(40.dp)
                    ) {
                        Icon(Icons.Default.Check, contentDescription = null, modifier = Modifier.size(16.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Approve Access", fontSize = 12.sp, fontWeight = FontWeight.Bold)
                    }

                    OutlinedButton(
                        onClick = onReject,
                        shape = RoundedCornerShape(10.dp),
                        modifier = Modifier.weight(1f).height(40.dp),
                        border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFFCA5A5))
                    ) {
                        Icon(Icons.Default.Close, contentDescription = null, tint = Color(0xFFDC2626), modifier = Modifier.size(16.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Reject", color = Color(0xFFDC2626), fontSize = 12.sp, fontWeight = FontWeight.Bold)
                    }
                }
            }
        }
    }
}

@Composable
private fun TeamMemberRow(
    name: String,
    email: String,
    roleLabel: String,
    roleColor: Color,
    roleBg: Color,
    isDark: Boolean
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(
                modifier = Modifier
                    .size(34.dp)
                    .clip(CircleShape)
                    .background(roleBg),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = name.take(2).uppercase(),
                    fontWeight = FontWeight.Bold,
                    fontSize = 12.sp,
                    color = roleColor
                )
            }

            Column {
                Text(name, fontWeight = FontWeight.Bold, fontSize = 13.sp, color = if (isDark) Color.White else Color(0xFF0F172A))
                Text(email, fontSize = 11.sp, color = Color(0xFF64748B))
            }
        }

        Surface(shape = RoundedCornerShape(8.dp), color = roleBg) {
            Text(
                text = roleLabel,
                fontWeight = FontWeight.Bold,
                fontSize = 10.sp,
                color = roleColor,
                modifier = Modifier.padding(horizontal = 6.dp, vertical = 3.dp)
            )
        }
    }
}

// =============================================================================
// INVITATION TEMPLATE & INTENT DISPATCH HELPERS
// =============================================================================

private fun buildWhatsAppInviteMessage(
    companyName: String,
    companyCode: String,
    adminName: String,
    employeeName: String,
    customNote: String
): String {
    val greeting = if (employeeName.isNotBlank()) "Hello $employeeName! 👋" else "Hello! 👋"
    val noteBlock = if (customNote.isNotBlank()) "\n📝 *Note from Admin:*\n\"$customNote\"\n" else ""
    return """
🚀 *Invitation to Join $companyName on Invoicely AI*
$greeting

You have been invited by *$adminName* to join our official organization workspace on *Invoicely AI* — smart invoicing, estimates, and client billing platform.$noteBlock
🔑 *Your Organization Access Code:*
👉 *$companyCode* 👈

*How to join in 3 quick steps:*
1️⃣ Open the *Invoicely AI* app.
2️⃣ Tap *Create Account* ➔ choose *👥 Team Join*.
3️⃣ Fill in your name, work email, and enter code: *$companyCode*.

Once submitted, your request will be approved by the admin so you can access company workspace records immediately!
    """.trimIndent()
}

private fun buildEmailInviteSubject(companyName: String): String {
    return "Invitation to Join $companyName Workspace on Invoicely AI"
}

private fun buildEmailInviteBody(
    companyName: String,
    companyCode: String,
    adminName: String,
    adminEmail: String,
    employeeName: String,
    customNote: String
): String {
    val salutation = if (employeeName.isNotBlank()) "Dear $employeeName," else "Dear Team Member,"
    val noteBlock = if (customNote.isNotBlank()) "\nNote from Administration:\n\"$customNote\"\n" else ""
    return """
$salutation

You have been officially invited by $adminName to collaborate on the $companyName workspace using Invoicely AI.$noteBlock
To set up your employee account and access company invoices, clients, and accounting tools, please follow the steps below:

1. Launch the Invoicely AI mobile app.
2. On the sign-in screen, tap "Create Account".
3. Select the "Team Join" tab.
4. Enter your full name, work email, set a password, and enter our Organization Code:

   Organization Code: $companyCode
   Organization: $companyName

5. Submit your request.

Once submitted, our administration team will review and approve your account.

For questions or assistance, please reach out to $adminName at $adminEmail.

Best regards,
$adminName
$companyName Administration Team
Powered by Invoicely AI
    """.trimIndent()
}

private fun sendWhatsAppInvite(context: Context, message: String) {
    try {
        val intent = Intent(Intent.ACTION_VIEW).apply {
            data = Uri.parse("https://api.whatsapp.com/send?text=" + URLEncoder.encode(message, "UTF-8"))
        }
        context.startActivity(intent)
    } catch (e: Exception) {
        val sendIntent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_TEXT, message)
        }
        context.startActivity(Intent.createChooser(sendIntent, "Share Invitation via WhatsApp"))
    }
}

private fun sendEmailInvite(context: Context, subject: String, body: String) {
    try {
        val intent = Intent(Intent.ACTION_SENDTO).apply {
            data = Uri.parse("mailto:")
            putExtra(Intent.EXTRA_SUBJECT, subject)
            putExtra(Intent.EXTRA_TEXT, body)
        }
        context.startActivity(intent)
    } catch (e: Exception) {
        val sendIntent = Intent(Intent.ACTION_SEND).apply {
            type = "message/rfc822"
            putExtra(Intent.EXTRA_SUBJECT, subject)
            putExtra(Intent.EXTRA_TEXT, body)
        }
        context.startActivity(Intent.createChooser(sendIntent, "Send Invitation Email"))
    }
}
