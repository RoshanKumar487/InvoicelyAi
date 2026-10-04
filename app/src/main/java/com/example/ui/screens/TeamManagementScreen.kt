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
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
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
                            .size(38.dp)
                            .clip(CircleShape)
                            .background(Color(0xFF3B82F6).copy(alpha = 0.15f)),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = request.userFullName.take(2).uppercase(),
                            fontWeight = FontWeight.Bold,
                            fontSize = 13.sp,
                            color = Color(0xFF1D4ED8)
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
                    }
                }

                val (badgeBg, badgeFg) = when (request.status) {
                    "APPROVED" -> Pair(Color(0xFFD1FAE5), Color(0xFF047857))
                    "REJECTED" -> Pair(Color(0xFFFEE2E2), Color(0xFFBE123C))
                    else -> Pair(Color(0xFFFEF3C7), Color(0xFFB45309))
                }

                Surface(shape = RoundedCornerShape(8.dp), color = badgeBg) {
                    Text(
                        text = request.status,
                        fontWeight = FontWeight.ExtraBold,
                        fontSize = 10.sp,
                        color = badgeFg,
                        modifier = Modifier.padding(horizontal = 6.dp, vertical = 3.dp)
                    )
                }
            }

            if (request.requestMessage.isNotBlank()) {
                Surface(
                    shape = RoundedCornerShape(10.dp),
                    color = if (isDark) Color(0xFF1E293B) else Color(0xFFF8FAFC),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(
                        text = "\"${request.requestMessage}\"",
                        fontSize = 12.sp,
                        color = if (isDark) Color(0xFFCBD5E1) else Color(0xFF475569),
                        modifier = Modifier.padding(10.dp)
                    )
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
                        modifier = Modifier.weight(1f).height(38.dp)
                    ) {
                        Icon(Icons.Default.Check, contentDescription = null, modifier = Modifier.size(16.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Approve Access", fontSize = 12.sp, fontWeight = FontWeight.Bold)
                    }

                    OutlinedButton(
                        onClick = onReject,
                        shape = RoundedCornerShape(10.dp),
                        modifier = Modifier.weight(1f).height(38.dp)
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
