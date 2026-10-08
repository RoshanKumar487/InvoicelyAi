package com.example.ui.screens

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.speech.RecognizerIntent
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
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
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.AccountBalanceWallet
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.ArrowDownward
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.DeleteSweep
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.GraphicEq
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.People
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Receipt
import androidx.compose.material.icons.filled.ReceiptLong
import androidx.compose.material.icons.filled.RecordVoiceOver
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.SmartToy
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material.icons.filled.TrendingUp
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VolumeOff
import androidx.compose.material.icons.filled.VolumeUp
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.ai.ChatMessage
import com.example.ai.FinancialSummaryData
import com.example.ui.components.AdaptiveContainer
import com.example.ui.components.rememberWindowAdaptiveInfo
import com.example.data.model.ClientEntity
import com.example.data.model.ExpenseEntity
import com.example.data.model.InvoiceEntity
import com.example.data.model.InvoiceUtils
import com.example.ui.theme.PrimaryNavy
import com.example.ui.theme.StatusPaidGreen
import com.example.ui.viewmodel.InvoiceViewModel
import androidx.compose.foundation.isSystemInDarkTheme
import com.example.ui.components.AmbientGlassBackdrop
import com.example.ui.components.GlassCard
import com.example.ui.components.glassTextFieldColors
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AiChatScreen(
    viewModel: InvoiceViewModel,
    onNavigateToInvoicePreview: (Long) -> Unit,
    onNavigateToInvoiceEdit: (Long) -> Unit,
    onNavigateToDashboard: () -> Unit = {},
    onOpenMenu: () -> Unit = {},
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val chatMessages by viewModel.chatMessages.collectAsStateWithLifecycle()
    val isAiThinking by viewModel.isAiThinking.collectAsStateWithLifecycle()

    var inputPrompt by remember { mutableStateOf("") }
    var pendingVoiceInput by remember { mutableStateOf(false) }
    val listState = rememberLazyListState()

    // -------------------------------------------------------------------------
    // TEXT-TO-SPEECH (TTS) ENGINE FOR AI VOICE SPEAKING
    // -------------------------------------------------------------------------
    var tts: TextToSpeech? by remember { mutableStateOf(null) }
    var isTtsReady by remember { mutableStateOf(false) }
    var isSpeaking by remember { mutableStateOf(false) }
    var currentlySpeakingId by remember { mutableStateOf<String?>(null) }
    var autoSpeakEnabled by remember { mutableStateOf(true) }
    var userSpokeLastPrompt by remember { mutableStateOf(false) }
    var latestUserTranscript by remember { mutableStateOf("") }
    var latestAiSpokenReply by remember { mutableStateOf("") }

    // Setup Text-to-Speech lifecycle
    DisposableEffect(context) {
        var textToSpeech: TextToSpeech? = null
        textToSpeech = TextToSpeech(context) { status ->
            if (status == TextToSpeech.SUCCESS) {
                textToSpeech?.language = Locale.US
                textToSpeech?.setPitch(1.0f)
                textToSpeech?.setSpeechRate(1.05f)
                isTtsReady = true
            }
        }
        textToSpeech.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
            override fun onStart(utteranceId: String?) {
                isSpeaking = true
            }

            override fun onDone(utteranceId: String?) {
                isSpeaking = false
                currentlySpeakingId = null
            }

            override fun onError(utteranceId: String?) {
                isSpeaking = false
                currentlySpeakingId = null
            }
        })
        tts = textToSpeech

        onDispose {
            textToSpeech?.stop()
            textToSpeech?.shutdown()
        }
    }

    fun speakText(text: String, messageId: String? = null) {
        if (tts != null && isTtsReady) {
            currentlySpeakingId = messageId

            // Dynamic Hindi voice detection for native Indian speech flow
            val hasHindiChars = text.any { it in '\u0900'..'\u097F' } ||
                    text.contains("नमस्ते", true) || text.contains("जी सर", true) ||
                    text.contains("हाँजी", true) || text.contains("धन्यवाद", true) ||
                    text.contains("पेंडिंग", true)
            if (hasHindiChars) {
                val hindiLocale = Locale("hi", "IN")
                val isAvailable = tts?.isLanguageAvailable(hindiLocale) ?: TextToSpeech.LANG_NOT_SUPPORTED
                if (isAvailable >= TextToSpeech.LANG_AVAILABLE) {
                    tts?.language = hindiLocale
                }
            } else {
                tts?.language = Locale.US
            }

            // Clean markdown syntax, tags, and bullet points for clean, natural speech
            val cleanText = text
                .replace(Regex("<.*?>"), "")
                .replace(Regex("<<<.*?>>>"), "")
                .replace(Regex("[*#_`~•]"), "")
                .replace(Regex("\n+"), ". ")
                .trim()
            latestAiSpokenReply = cleanText
            tts?.speak(cleanText, TextToSpeech.QUEUE_FLUSH, null, messageId ?: "AI_RESPONSE")
        }
    }

    fun stopSpeaking() {
        tts?.stop()
        isSpeaking = false
        currentlySpeakingId = null
    }

    // Auto-speak newly received AI message natively
    LaunchedEffect(chatMessages.size) {
        val lastMsg = chatMessages.lastOrNull()
        if (lastMsg != null && !lastMsg.isUser) {
            latestAiSpokenReply = lastMsg.text
            if (autoSpeakEnabled || userSpokeLastPrompt) {
                speakText(lastMsg.text, lastMsg.id)
                userSpokeLastPrompt = false
            }
        }
    }

    // Speech-to-Text Recognition Launcher (Native voice interaction)
    val speechRecognizerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode == Activity.RESULT_OK && result.data != null) {
            val spokenMatches = result.data?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)
            val recognizedText = spokenMatches?.firstOrNull()
            if (!recognizedText.isNullOrBlank()) {
                inputPrompt = recognizedText
                pendingVoiceInput = true
                latestUserTranscript = recognizedText
                userSpokeLastPrompt = true
                stopSpeaking()
            }
        }
    }

    // Audio Permission Launcher
    val recordAudioPermissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        if (isGranted) {
            launchVoiceInput(context, speechRecognizerLauncher)
        } else {
            Toast.makeText(context, "Microphone permission is required to talk with Gemini", Toast.LENGTH_SHORT).show()
        }
    }

    // Auto-scroll to latest message
    LaunchedEffect(chatMessages.size, isAiThinking) {
        if (chatMessages.isNotEmpty()) {
            listState.animateScrollToItem(chatMessages.size - 1)
        }
    }

    val dynamicPredictions by viewModel.dynamicPredictions.collectAsStateWithLifecycle()

    val isDark = isSystemInDarkTheme()

    AmbientGlassBackdrop {
        Scaffold(
            contentWindowInsets = androidx.compose.foundation.layout.WindowInsets(0, 0, 0, 0),
            modifier = modifier.fillMaxSize(),
            containerColor = Color.Transparent,
        topBar = {
            TopAppBar(
                title = {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .size(38.dp)
                                .clip(CircleShape)
                                .background(
                                    Brush.linearGradient(
                                        colors = listOf(Color(0xFF2563EB), Color(0xFF7C3AED))
                                    )
                                ),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Default.AutoAwesome,
                                contentDescription = "Gemini AI",
                                tint = Color.White,
                                modifier = Modifier.size(20.dp)
                            )
                        }
                        Column {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(
                                    text = "Invoicely AI",
                                    fontSize = 16.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = if (isDark) Color.White else PrimaryNavy
                                )
                                Spacer(modifier = Modifier.width(6.dp))
                                Surface(
                                    color = if (isDark) Color(0xFF1E3A8A).copy(alpha = 0.6f) else Color(0xFFEFF6FF),
                                    shape = RoundedCornerShape(12.dp),
                                    border = androidx.compose.foundation.BorderStroke(1.dp, if (isDark) Color(0xFF3B82F6) else Color(0xFFBFDBFE))
                                ) {
                                    Text(
                                        text = "Employee Agent • Gemini 3.8",
                                        fontSize = 9.5.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = if (isDark) Color(0xFF93C5FD) else Color(0xFF1D4ED8),
                                        modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                    )
                                }
                            }
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Box(
                                    modifier = Modifier
                                        .size(6.dp)
                                        .clip(CircleShape)
                                        .background(if (isSpeaking) Color(0xFF10B981) else Color(0xFF22C55E))
                                )
                                Spacer(modifier = Modifier.width(4.dp))
                                Text(
                                    text = if (isSpeaking) "Speaking to you in voice..." else "Online • Speaks Hindi (हिंदी) & English",
                                    fontSize = 11.sp,
                                    color = if (isSpeaking) Color(0xFF16A34A) else (if (isDark) Color(0xFF94A3B8) else Color(0xFF64748B)),
                                    fontWeight = if (isSpeaking) FontWeight.SemiBold else FontWeight.Normal
                                )
                            }
                        }
                    }
                },
                actions = {
                    // Auto-Speak Audio Output Toggle
                    IconButton(
                        onClick = {
                            autoSpeakEnabled = !autoSpeakEnabled
                            if (!autoSpeakEnabled) stopSpeaking()
                        },
                        modifier = Modifier.testTag("toggle_auto_speak_button")
                    ) {
                        Icon(
                            imageVector = if (autoSpeakEnabled) Icons.Default.VolumeUp else Icons.Default.VolumeOff,
                            contentDescription = if (autoSpeakEnabled) "Voice enabled" else "Voice muted",
                            tint = if (autoSpeakEnabled) Color(0xFF2563EB) else Color.Gray
                        )
                    }

                    // Clear Chat Button
                    IconButton(
                        onClick = {
                            stopSpeaking()
                            viewModel.clearAiChat()
                        },
                        modifier = Modifier.testTag("clear_chat_button")
                    ) {
                        Icon(
                            imageVector = Icons.Default.DeleteSweep,
                            contentDescription = "Clear Chat",
                            tint = Color.Gray
                        )
                    }

                    // App Menu
                    IconButton(
                        onClick = onOpenMenu,
                        modifier = Modifier.testTag("ai_chat_menu_button")
                    ) {
                        Icon(
                            imageVector = Icons.Default.Menu,
                            contentDescription = "Menu",
                            tint = PrimaryNavy
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Transparent
                )
            )
        }
    ) { innerPadding ->
        AdaptiveContainer(maxWidth = 920.dp) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding)
            ) {
            // Suggested Prompts Carousel
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState())
                    .padding(horizontal = 12.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                dynamicPredictions.forEach { suggestion ->
                    val isAlert = suggestion.startsWith("⚠️")
                    val isPending = suggestion.startsWith("💰")
                    Surface(
                        color = when {
                            isAlert -> if (isDark) Color(0xFF450A0A).copy(alpha = 0.6f) else Color(0xFFFEF2F2)
                            isPending -> if (isDark) Color(0xFF052E16).copy(alpha = 0.6f) else Color(0xFFF0FDF4)
                            else -> if (isDark) Color(0xFF1E293B).copy(alpha = 0.7f) else Color(0xF2FFFFFF)
                        },
                        shape = RoundedCornerShape(16.dp),
                        border = androidx.compose.foundation.BorderStroke(
                            1.dp,
                            when {
                                isAlert -> Color(0xFFEF4444).copy(alpha = 0.5f)
                                isPending -> Color(0xFF22C55E).copy(alpha = 0.5f)
                                isDark -> Color.White.copy(alpha = 0.15f)
                                else -> Color(0xFF0F172A).copy(alpha = 0.08f)
                            }
                        ),
                        modifier = Modifier.clickable {
                            val cleanPrompt = suggestion.substringAfter(" ").trim()
                            inputPrompt = cleanPrompt
                            latestUserTranscript = cleanPrompt
                            stopSpeaking()
                            viewModel.sendAiChatMessage(cleanPrompt)
                        }
                    ) {
                        Text(
                            text = suggestion,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Medium,
                            color = when {
                                isAlert -> if (isDark) Color(0xFFFCA5A5) else Color(0xFFDC2626)
                                isPending -> if (isDark) Color(0xFF86EFAC) else Color(0xFF16A34A)
                                else -> if (isDark) Color.White else PrimaryNavy
                            },
                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp)
                        )
                    }
                }
            }

            HorizontalDivider(
                color = if (isDark) Color.White.copy(alpha = 0.1f) else Color(0xFF0F172A).copy(alpha = 0.08f),
                thickness = 1.dp
            )

            // Chat Messages List
            LazyColumn(
                state = listState,
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .padding(horizontal = 12.dp),
                contentPadding = PaddingValues(vertical = 12.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                // If fresh chat, show modern ChatGPT Welcome Hero
                if (chatMessages.size <= 1) {
                    item {
                        WelcomeEmployeeHero(
                            onSelectPrompt = { selectedPrompt ->
                                inputPrompt = selectedPrompt
                                latestUserTranscript = selectedPrompt
                                stopSpeaking()
                                viewModel.sendAiChatMessage(selectedPrompt)
                            },
                            onStartVoice = {
                                recordAudioPermissionLauncher.launch(android.Manifest.permission.RECORD_AUDIO)
                            },
                            isDark = isDark
                        )
                    }
                }

                items(chatMessages, key = { it.id }) { message ->
                    ChatMessageItem(
                        message = message,
                        isSpeaking = isSpeaking && currentlySpeakingId == message.id,
                        onSpeakMessage = { text, id -> speakText(text, id) },
                        onStopSpeaking = { stopSpeaking() },
                        onOpenPreview = { invoiceId -> onNavigateToInvoicePreview(invoiceId) },
                        onOpenEdit = { invoiceId -> onNavigateToInvoiceEdit(invoiceId) },
                        onNavigateToDashboard = onNavigateToDashboard,
                        onConfirmCommand = { commandId ->
                            viewModel.confirmAiCommand(commandId) { invoiceId ->
                                onNavigateToInvoicePreview(invoiceId)
                            }
                        },
                        onUseClientForInvoice = { client ->
                            inputPrompt = "Generate invoice for ${client.name}, 10 hours of consulting at $100/hr"
                        }
                    )
                }

                // AI Thinking indicator
                if (isAiThinking) {
                    item {
                        AiThinkingBubble()
                    }
                }
            }

            // Docked Voice Bar: Appears when AI is speaking response aloud natively
            AnimatedVisibility(
                visible = isSpeaking,
                enter = fadeIn(),
                exit = fadeOut()
            ) {
                Surface(
                    color = if (isDark) Color(0xFF1E293B) else Color(0xFFEFF6FF),
                    shape = RoundedCornerShape(topStart = 16.dp, topEnd = 16.dp),
                    border = androidx.compose.foundation.BorderStroke(
                        1.dp,
                        if (isDark) Color(0xFF3B82F6).copy(alpha = 0.4f) else Color(0xFFBFDBFE)
                    ),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 14.dp, vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.weight(1f)
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(28.dp)
                                    .clip(CircleShape)
                                    .background(Color(0xFF2563EB)),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(
                                    imageVector = Icons.Default.GraphicEq,
                                    contentDescription = null,
                                    tint = Color.White,
                                    modifier = Modifier.size(16.dp)
                                )
                            }
                            Spacer(modifier = Modifier.width(10.dp))
                            Column {
                                Text(
                                    text = "🔊 AI Employee is speaking response...",
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = if (isDark) Color.White else PrimaryNavy
                                )
                                Text(
                                    text = "Native speech audio playing",
                                    fontSize = 10.sp,
                                    color = if (isDark) Color(0xFF94A3B8) else Color(0xFF64748B)
                                )
                            }
                        }

                        IconButton(
                            onClick = { stopSpeaking() },
                            modifier = Modifier.size(32.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.Stop,
                                contentDescription = "Stop",
                                tint = Color(0xFFEF4444),
                                modifier = Modifier.size(20.dp)
                            )
                        }
                    }
                }
            }

            // Bottom Input Bar
            Surface(
                color = if (isDark) Color(0xEE0F172A) else Color(0xF2FFFFFF),
                shadowElevation = 8.dp,
                border = androidx.compose.foundation.BorderStroke(1.dp, if (isDark) Color.White.copy(alpha = 0.12f) else Color(0xFF0F172A).copy(alpha = 0.08f))
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 12.dp, vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    // Voice Input Trigger (Speech-to-Text)
                    VoiceInputButton(
                        onClick = {
                            recordAudioPermissionLauncher.launch(android.Manifest.permission.RECORD_AUDIO)
                        }
                    )

                    // Text Field with 100% visibility
                    OutlinedTextField(
                        value = inputPrompt,
                        onValueChange = { inputPrompt = it },
                        placeholder = {
                            Text("Ask anything, make bill, talk in Hindi/English...", fontSize = 13.sp, color = if (isDark) Color(0xFF94A3B8) else Color(0xFF64748B))
                        },
                        modifier = Modifier
                            .weight(1f)
                            .testTag("ai_chat_text_input"),
                        shape = RoundedCornerShape(24.dp),
                        colors = glassTextFieldColors(),
                        singleLine = false,
                        maxLines = 3,
                        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Send),
                        keyboardActions = KeyboardActions(
                            onSend = {
                                if (inputPrompt.isNotBlank() && !isAiThinking) {
                                    val promptToSend = inputPrompt
                                    val wasVoiceInput = pendingVoiceInput
                                    inputPrompt = ""
                                    pendingVoiceInput = false
                                    latestUserTranscript = promptToSend
                                    stopSpeaking()
                                    viewModel.sendAiChatMessage(promptToSend, isVoiceInput = wasVoiceInput)
                                }
                            }
                        ),
                        label = if (pendingVoiceInput) {
                            { Text("Review transcript · voice assistant is read-only") }
                        } else {
                            null
                        }
                    )

                    // Send Button
                    IconButton(
                        onClick = {
                            if (inputPrompt.isNotBlank() && !isAiThinking) {
                                val promptToSend = inputPrompt
                                val wasVoiceInput = pendingVoiceInput
                                inputPrompt = ""
                                pendingVoiceInput = false
                                latestUserTranscript = promptToSend
                                stopSpeaking()
                                viewModel.sendAiChatMessage(promptToSend, isVoiceInput = wasVoiceInput)
                            }
                        },
                        enabled = inputPrompt.isNotBlank() && !isAiThinking,
                        modifier = Modifier
                            .size(44.dp)
                            .clip(CircleShape)
                            .background(
                                if (inputPrompt.isNotBlank() && !isAiThinking) Color(0xFF2563EB) else Color(0xFFE2E8F0)
                            )
                            .testTag("send_ai_prompt_button")
                    ) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.Send,
                            contentDescription = "Send",
                            tint = if (inputPrompt.isNotBlank() && !isAiThinking) Color.White else Color.Gray,
                            modifier = Modifier.size(18.dp)
                        )
                    }
                }
            }
        }
    }
}
}
}

/**
 * Triggers the speech recognizer intent
 */
private fun launchVoiceInput(context: Context, launcher: androidx.activity.result.ActivityResultLauncher<Intent>) {
    try {
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault())
            putExtra(RecognizerIntent.EXTRA_PROMPT, "Talk to Gemini about your data or anything...")
        }
        launcher.launch(intent)
    } catch (_: Exception) {
        Toast.makeText(context, "Voice speech recognition is not supported on this device", Toast.LENGTH_SHORT).show()
    }
}

@Composable
fun VoiceInputButton(
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val infiniteTransition = rememberInfiniteTransition(label = "pulse")
    val pulseScale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.08f,
        animationSpec = infiniteRepeatable(
            animation = tween(1200, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "pulse_scale"
    )

    IconButton(
        onClick = onClick,
        modifier = modifier
            .size(44.dp)
            .scale(pulseScale)
            .clip(CircleShape)
            .background(Color(0xFFEEF2FF))
            .border(1.dp, Color(0xFFC7D2FE), CircleShape)
            .testTag("voice_chat_button")
    ) {
        Icon(
            imageVector = Icons.Default.Mic,
            contentDescription = "Voice Chat",
            tint = Color(0xFF4F46E5),
            modifier = Modifier.size(22.dp)
        )
    }
}

/**
 * Builds rich styled annotated text supporting **bold**, *italic*, and code snippets
 */
fun buildAnnotatedMarkdown(rawText: String, isDark: Boolean): AnnotatedString {
    return buildAnnotatedString {
        val boldParts = rawText.split("**")
        var isBold = false
        boldParts.forEach { part ->
            if (isBold) {
                withStyle(
                    SpanStyle(
                        fontWeight = FontWeight.Bold,
                        color = if (isDark) Color(0xFFF8FAFC) else Color(0xFF0F172A)
                    )
                ) {
                    append(part)
                }
            } else {
                val italicParts = part.split("*")
                var isItalic = false
                italicParts.forEach { itPart ->
                    if (isItalic) {
                        withStyle(
                            SpanStyle(
                                fontStyle = androidx.compose.ui.text.font.FontStyle.Italic,
                                color = if (isDark) Color(0xFF94A3B8) else Color(0xFF475569)
                            )
                        ) {
                            append(itPart)
                        }
                    } else {
                        val codeParts = itPart.split("`")
                        var isCode = false
                        codeParts.forEach { codePart ->
                            if (isCode) {
                                withStyle(
                                    SpanStyle(
                                        fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace,
                                        fontWeight = FontWeight.SemiBold,
                                        color = if (isDark) Color(0xFF67E8F9) else Color(0xFF0369A1)
                                    )
                                ) {
                                    append(codePart)
                                }
                            } else {
                                append(codePart)
                            }
                            isCode = !isCode
                        }
                    }
                    isItalic = !isItalic
                }
            }
            isBold = !isBold
        }
    }
}

/**
 * Formats AI responses into structured, elegant paragraphs and bullet data points (ChatGPT flow).
 */
@Composable
fun StructuredAiResponseView(
    text: String,
    isDark: Boolean,
    modifier: Modifier = Modifier
) {
    val paragraphs = remember(text) {
        text.split(Regex("\n+")).map { it.trim() }.filter { it.isNotBlank() }
    }

    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        paragraphs.forEach { paragraph ->
            val isBullet = paragraph.startsWith("•") ||
                    paragraph.startsWith("- ") ||
                    paragraph.startsWith("* ") ||
                    paragraph.matches(Regex("^\\d+\\..*"))

            if (isBullet) {
                val cleanLine = paragraph
                    .removePrefix("•")
                    .removePrefix("-")
                    .removePrefix("*")
                    .trim()

                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(start = 2.dp, end = 2.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.Top
                ) {
                    Box(
                        modifier = Modifier
                            .padding(top = 7.dp)
                            .size(6.dp)
                            .clip(CircleShape)
                            .background(
                                Brush.linearGradient(
                                    listOf(Color(0xFF3B82F6), Color(0xFF8B5CF6))
                                )
                            )
                    )
                    Text(
                        text = buildAnnotatedMarkdown(cleanLine, isDark),
                        fontSize = 13.5.sp,
                        color = if (isDark) Color(0xFFE2E8F0) else Color(0xFF1E293B),
                        lineHeight = 20.sp,
                        modifier = Modifier.weight(1f)
                    )
                }
            } else {
                Text(
                    text = buildAnnotatedMarkdown(paragraph, isDark),
                    fontSize = 14.sp,
                    color = if (isDark) Color(0xFFF1F5F9) else Color(0xFF0F172A),
                    lineHeight = 21.sp
                )
            }
        }
    }
}

/**
 * Welcome Hero shown in fresh chats to introduce the Employee Agent persona & quick actions
 */
@Composable
fun WelcomeEmployeeHero(
    onSelectPrompt: (String) -> Unit,
    onStartVoice: () -> Unit,
    isDark: Boolean
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (isDark) Color(0xFF1E293B).copy(alpha = 0.85f) else Color.White.copy(alpha = 0.95f)
        ),
        border = androidx.compose.foundation.BorderStroke(
            1.dp,
            if (isDark) Color.White.copy(alpha = 0.12f) else Color(0xFF3B82F6).copy(alpha = 0.15f)
        )
    ) {
        Column(
            modifier = Modifier.padding(18.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Box(
                modifier = Modifier
                    .size(54.dp)
                    .clip(CircleShape)
                    .background(
                        Brush.linearGradient(
                            listOf(Color(0xFF2563EB), Color(0xFF7C3AED))
                        )
                    ),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.AutoAwesome,
                    contentDescription = null,
                    tint = Color.White,
                    modifier = Modifier.size(28.dp)
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            Text(
                text = "Namaste & Welcome, Sir! 🙏",
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold,
                color = if (isDark) Color.White else PrimaryNavy,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(4.dp))

            Text(
                text = "I am your 24/7 Smart Business Employee Agent. I manage invoices, compute financial summaries, log expenses, and answer anything in English or Hindi (हिंदी).",
                fontSize = 13.sp,
                color = if (isDark) Color(0xFF94A3B8) else Color(0xFF475569),
                textAlign = TextAlign.Center,
                lineHeight = 19.sp
            )

            Spacer(modifier = Modifier.height(16.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Surface(
                    color = if (isDark) Color(0xFF0F172A) else Color(0xFFEFF6FF),
                    shape = RoundedCornerShape(12.dp),
                    border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFBFDBFE)),
                    modifier = Modifier
                        .weight(1f)
                        .clickable { onSelectPrompt("Acme Corp के लिए ₹5,000 का इनवॉइस बना दो 18% GST के साथ") }
                ) {
                    Column(modifier = Modifier.padding(10.dp)) {
                        Text("⚡ Create Bill", fontWeight = FontWeight.Bold, fontSize = 12.sp, color = Color(0xFF1D4ED8))
                        Text("GST & items", fontSize = 10.sp, color = Color(0xFF64748B))
                    }
                }

                Surface(
                    color = if (isDark) Color(0xFF0F172A) else Color(0xFFF0FDF4),
                    shape = RoundedCornerShape(12.dp),
                    border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFBBF7D0)),
                    modifier = Modifier
                        .weight(1f)
                        .clickable { onSelectPrompt("कितना पेमेंट अभी पेंडिंग है?") }
                ) {
                    Column(modifier = Modifier.padding(10.dp)) {
                        Text("💰 Pending Dues", fontWeight = FontWeight.Bold, fontSize = 12.sp, color = Color(0xFF15803D))
                        Text("Unpaid balance", fontSize = 10.sp, color = Color(0xFF64748B))
                    }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Surface(
                    color = if (isDark) Color(0xFF0F172A) else Color(0xFFFAF5FF),
                    shape = RoundedCornerShape(12.dp),
                    border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFE9D5FF)),
                    modifier = Modifier
                        .weight(1f)
                        .clickable { onSelectPrompt("Show my complete revenue, paid, and profit overview") }
                ) {
                    Column(modifier = Modifier.padding(10.dp)) {
                        Text("📊 Revenue Report", fontWeight = FontWeight.Bold, fontSize = 12.sp, color = Color(0xFF7E22CE))
                        Text("CFO summary", fontSize = 10.sp, color = Color(0xFF64748B))
                    }
                }

                Surface(
                    color = if (isDark) Color(0xFF0F172A) else Color(0xFFFEF2F2),
                    shape = RoundedCornerShape(12.dp),
                    border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFFECACA)),
                    modifier = Modifier
                        .weight(1f)
                        .clickable { onSelectPrompt("Record expense ₹650 for client lunch") }
                ) {
                    Column(modifier = Modifier.padding(10.dp)) {
                        Text("💸 Log Expense", fontWeight = FontWeight.Bold, fontSize = 12.sp, color = Color(0xFFB91C1C))
                        Text("Category tracking", fontSize = 10.sp, color = Color(0xFF64748B))
                    }
                }
            }

            Spacer(modifier = Modifier.height(14.dp))

            Button(
                onClick = onStartVoice,
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF2563EB)),
                shape = RoundedCornerShape(24.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Icon(Icons.Default.Mic, contentDescription = null, modifier = Modifier.size(18.dp))
                Spacer(modifier = Modifier.width(8.dp))
                Text("Tap to Talk in Hindi / English", fontSize = 13.sp, fontWeight = FontWeight.Bold)
            }
        }
    }
}

/**
 * Renders individual messages with interactive voice playback and data cards.
 */
@Composable
fun ChatMessageItem(
    message: ChatMessage,
    isSpeaking: Boolean,
    onSpeakMessage: (String, String) -> Unit,
    onStopSpeaking: () -> Unit,
    onOpenPreview: (Long) -> Unit,
    onOpenEdit: (Long) -> Unit,
    onNavigateToDashboard: () -> Unit,
    onConfirmCommand: (String) -> Unit,
    onUseClientForInvoice: (ClientEntity) -> Unit,
    modifier: Modifier = Modifier
) {
    val isDark = isSystemInDarkTheme()
    val context = LocalContext.current
    val clipboardManager = LocalClipboardManager.current

    if (message.isUser) {
        // User Message (Right-aligned)
        Row(
            modifier = modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.End
        ) {
            Box(
                modifier = Modifier
                    .clip(
                        RoundedCornerShape(
                            topStart = 16.dp,
                            topEnd = 4.dp,
                            bottomStart = 16.dp,
                            bottomEnd = 16.dp
                        )
                    )
                    .background(
                        Brush.linearGradient(
                            colors = listOf(Color(0xFF1D4ED8), Color(0xFF2563EB))
                        )
                    )
                    .border(
                        1.dp,
                        Color.White.copy(alpha = 0.3f),
                        RoundedCornerShape(topStart = 16.dp, topEnd = 4.dp, bottomStart = 16.dp, bottomEnd = 16.dp)
                    )
                    .padding(horizontal = 14.dp, vertical = 10.dp)
            ) {
                Text(
                    text = message.text,
                    fontSize = 14.sp,
                    color = Color.White,
                    lineHeight = 20.sp
                )
            }
        }
    } else {
        // AI Message (Left-aligned)
        Row(
            modifier = modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.Start,
            verticalAlignment = Alignment.Top
        ) {
            Box(
                modifier = Modifier
                    .size(34.dp)
                    .clip(CircleShape)
                    .background(
                        Brush.linearGradient(
                            colors = listOf(Color(0xFF2563EB), Color(0xFF7C3AED))
                        )
                    ),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.SmartToy,
                    contentDescription = "Invoicely AI",
                    tint = Color.White,
                    modifier = Modifier.size(19.dp)
                )
            }

            Spacer(modifier = Modifier.width(8.dp))

            Column(modifier = Modifier.weight(1f)) {
                Surface(
                    color = if (isDark) Color(0xEE1E293B) else Color(0xF8FFFFFF),
                    shape = RoundedCornerShape(
                        topStart = 4.dp,
                        topEnd = 16.dp,
                        bottomStart = 16.dp,
                        bottomEnd = 16.dp
                    ),
                    shadowElevation = 2.dp,
                    border = androidx.compose.foundation.BorderStroke(
                        1.dp,
                        if (isDark) Color.White.copy(alpha = 0.12f) else Color(0xFF0F172A).copy(alpha = 0.08f)
                    )
                ) {
                    Column(modifier = Modifier.padding(14.dp)) {
                        // AI Header: Name + Employee Agent Badge
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(
                                    text = "Invoicely AI",
                                    fontSize = 13.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = if (isDark) Color.White else PrimaryNavy
                                )
                                Spacer(modifier = Modifier.width(6.dp))
                                Surface(
                                    color = if (isDark) Color(0xFF1E3A8A).copy(alpha = 0.5f) else Color(0xFFEFF6FF),
                                    shape = RoundedCornerShape(8.dp),
                                    border = androidx.compose.foundation.BorderStroke(1.dp, if (isDark) Color(0xFF3B82F6).copy(alpha = 0.4f) else Color(0xFFBFDBFE))
                                ) {
                                    Text(
                                        text = "Employee Agent",
                                        fontSize = 9.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = if (isDark) Color(0xFF93C5FD) else Color(0xFF1D4ED8),
                                        modifier = Modifier.padding(horizontal = 5.dp, vertical = 1.5.dp)
                                    )
                                }
                            }

                            // Model pill
                            Text(
                                text = "Gemini 3.8",
                                fontSize = 10.sp,
                                color = if (isDark) Color(0xFF94A3B8) else Color(0xFF64748B),
                                fontWeight = FontWeight.Medium
                            )
                        }

                        Spacer(modifier = Modifier.height(8.dp))

                        // Structured AI Response rendering (Paragraphs + Bullet Data Points)
                        StructuredAiResponseView(
                            text = message.text,
                            isDark = isDark
                        )

                        if (message.pendingCommandId != null) {
                            Spacer(modifier = Modifier.height(10.dp))
                            Button(
                                onClick = { onConfirmCommand(message.pendingCommandId) },
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Icon(Icons.Default.CheckCircle, contentDescription = null)
                                Spacer(modifier = Modifier.width(8.dp))
                                Text("Confirm and save")
                            }
                            Text(
                                text = "This action will be saved to your business account. It will not be sent to a client.",
                                fontSize = 11.sp,
                                color = if (isDark) Color(0xFF94A3B8) else Color(0xFF64748B),
                                modifier = Modifier.padding(top = 4.dp)
                            )
                        }

                        // ChatGPT Style Actions Bar: Copy, Voice Speak, Share
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(top = 10.dp),
                            horizontalArrangement = Arrangement.spacedBy(4.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            IconButton(
                                onClick = {
                                    clipboardManager.setText(AnnotatedString(message.text))
                                    Toast.makeText(context, "Copied response to clipboard", Toast.LENGTH_SHORT).show()
                                },
                                modifier = Modifier.size(30.dp)
                            ) {
                                Icon(
                                    imageVector = Icons.Default.ContentCopy,
                                    contentDescription = "Copy response",
                                    tint = if (isDark) Color(0xFF94A3B8) else Color(0xFF64748B),
                                    modifier = Modifier.size(15.dp)
                                )
                            }

                            IconButton(
                                onClick = {
                                    if (isSpeaking) {
                                        onStopSpeaking()
                                    } else {
                                        onSpeakMessage(message.text, message.id)
                                    }
                                },
                                modifier = Modifier.size(30.dp)
                            ) {
                                Icon(
                                    imageVector = if (isSpeaking) Icons.Default.Stop else Icons.Default.VolumeUp,
                                    contentDescription = if (isSpeaking) "Stop voice" else "Speak message",
                                    tint = if (isSpeaking) Color(0xFFEF4444) else (if (isDark) Color(0xFF94A3B8) else Color(0xFF64748B)),
                                    modifier = Modifier.size(17.dp)
                                )
                            }

                            IconButton(
                                onClick = {
                                    val sendIntent = Intent().apply {
                                        action = Intent.ACTION_SEND
                                        putExtra(Intent.EXTRA_TEXT, message.text)
                                        type = "text/plain"
                                    }
                                    context.startActivity(Intent.createChooser(sendIntent, "Share AI Response"))
                                },
                                modifier = Modifier.size(30.dp)
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Share,
                                    contentDescription = "Share",
                                    tint = if (isDark) Color(0xFF94A3B8) else Color(0xFF64748B),
                                    modifier = Modifier.size(15.dp)
                                )
                            }
                        }

                        // -------------------------------------------------------------
                        // FINANCIAL SUMMARY DATA CARD (CUSTOMER DATA INSIGHT)
                        // -------------------------------------------------------------
                        if (message.financialSummary != null) {
                            Spacer(modifier = Modifier.height(10.dp))
                            FinancialSummaryCard(
                                summary = message.financialSummary,
                                onNavigateToDashboard = onNavigateToDashboard
                            )
                        }

                        // -------------------------------------------------------------
                        // MATCHED INVOICES LIST (CUSTOMER DATA MATCHES)
                        // -------------------------------------------------------------
                        if (!message.matchedInvoices.isNullOrEmpty()) {
                            Spacer(modifier = Modifier.height(10.dp))
                            Text(
                                text = "Matching Invoices in Database:",
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Bold,
                                color = PrimaryNavy
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            message.matchedInvoices.forEach { inv ->
                                MatchedInvoiceCard(
                                    invoice = inv,
                                    onOpenPreview = { onOpenPreview(inv.id) }
                                )
                                Spacer(modifier = Modifier.height(6.dp))
                            }
                        }

                        // -------------------------------------------------------------
                        // GENERATED INVOICE PREVIEW CARD
                        // -------------------------------------------------------------
                        if (message.generatedInvoice != null && message.generatedInvoiceId != null) {
                            Spacer(modifier = Modifier.height(10.dp))
                            GeneratedInvoicePreviewCard(
                                invoice = message.generatedInvoice,
                                invoiceId = message.generatedInvoiceId,
                                onOpenPreview = { onOpenPreview(message.generatedInvoiceId) },
                                onOpenEdit = { onOpenEdit(message.generatedInvoiceId) }
                            )
                        }

                        // -------------------------------------------------------------
                        // GENERATED CLIENT CARD
                        // -------------------------------------------------------------
                        if (message.generatedClient != null) {
                            Spacer(modifier = Modifier.height(10.dp))
                            SavedClientCard(
                                client = message.generatedClient,
                                onUseForInvoice = { onUseClientForInvoice(message.generatedClient) }
                            )
                        }

                        // -------------------------------------------------------------
                        // RECORDED EXPENSE CARD
                        // -------------------------------------------------------------
                        if (message.generatedExpense != null) {
                            Spacer(modifier = Modifier.height(10.dp))
                            SavedExpenseChatCard(expense = message.generatedExpense)
                        }
                    }
                }
            }
        }
    }
}

/**
 * Rich financial summary card showing customer's real database overview.
 */
@Composable
fun FinancialSummaryCard(
    summary: FinancialSummaryData,
    onNavigateToDashboard: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = Color(0xFFF8FAFC)),
        border = androidx.compose.foundation.BorderStroke(1.5.dp, Color(0xFFBFDBFE))
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Default.TrendingUp,
                        contentDescription = null,
                        tint = Color(0xFF2563EB),
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = "Business Financial Snapshot",
                        fontWeight = FontWeight.Bold,
                        fontSize = 13.sp,
                        color = PrimaryNavy
                    )
                }
                Surface(
                    color = Color(0xFFDCFCE7),
                    shape = RoundedCornerShape(8.dp)
                ) {
                    Text(
                        text = "${summary.clientCount} Clients",
                        fontSize = 10.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color(0xFF15803D),
                        modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(8.dp))
            HorizontalDivider(color = Color(0xFFE2E8F0))
            Spacer(modifier = Modifier.height(8.dp))

            // Metrics Grid
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text("Total Invoiced", fontSize = 10.sp, color = Color(0xFF64748B))
                    Text(
                        text = "${summary.currencySymbol}${String.format(Locale.US, "%,.2f", summary.totalRevenue)}",
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color(0xFF0F172A)
                    )
                }
                Column(modifier = Modifier.weight(1f)) {
                    Text("Collected (Paid)", fontSize = 10.sp, color = Color(0xFF64748B))
                    Text(
                        text = "${summary.currencySymbol}${String.format(Locale.US, "%,.2f", summary.paidAmount)}",
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Bold,
                        color = StatusPaidGreen
                    )
                }
                Column(modifier = Modifier.weight(1f)) {
                    Text("Pending Balance", fontSize = 10.sp, color = Color(0xFF64748B))
                    Text(
                        text = "${summary.currencySymbol}${String.format(Locale.US, "%,.2f", summary.pendingAmount)}",
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Bold,
                        color = if (summary.pendingAmount > 0) Color(0xFFDC2626) else StatusPaidGreen
                    )
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            // Net Profit & Expenses
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(8.dp))
                    .background(Color(0xFFEFF6FF))
                    .padding(8.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Tracked Expenses: ${summary.currencySymbol}${String.format(Locale.US, "%,.2f", summary.totalExpenses)}",
                    fontSize = 11.sp,
                    color = Color(0xFF1E3A8A)
                )
                Text(
                    text = "Net Profit: ${summary.currencySymbol}${String.format(Locale.US, "%,.2f", summary.netProfit)}",
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color(0xFF1E3A8A)
                )
            }

            Spacer(modifier = Modifier.height(10.dp))

            Button(
                onClick = onNavigateToDashboard,
                colors = ButtonDefaults.buttonColors(containerColor = PrimaryNavy),
                shape = RoundedCornerShape(8.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Icon(Icons.Default.AccountBalanceWallet, contentDescription = null, modifier = Modifier.size(16.dp))
                Spacer(modifier = Modifier.width(6.dp))
                Text("Open Full Financial Dashboard", fontSize = 12.sp, fontWeight = FontWeight.Bold)
            }
        }
    }
}

/**
 * Card showing a specific invoice from customer data.
 */
@Composable
fun MatchedInvoiceCard(
    invoice: InvoiceEntity,
    onOpenPreview: () -> Unit,
    modifier: Modifier = Modifier
) {
    val items = remember(invoice.itemsJson) {
        InvoiceUtils.deserializeInvoiceItems(invoice.itemsJson)
    }
    val calcs = remember(items, invoice) {
        InvoiceUtils.calculateInvoice(
            items = items,
            taxRate = invoice.taxRate,
            discountPercent = invoice.discountPercent,
            discountAmount = invoice.discountAmount,
            shippingFee = invoice.shippingFee,
            amountPaid = invoice.amountPaid
        )
    }

    Card(
        modifier = modifier
            .fillMaxWidth()
            .clickable { onOpenPreview() },
        shape = RoundedCornerShape(10.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFE2E8F0))
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(10.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = invoice.invoiceNumber,
                        fontWeight = FontWeight.Bold,
                        fontSize = 13.sp,
                        color = PrimaryNavy
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Surface(
                        color = when (invoice.status.lowercase(Locale.US)) {
                            "paid" -> Color(0xFFDCFCE7)
                            "overdue" -> Color(0xFFFEE2E2)
                            else -> Color(0xFFFEF3C7)
                        },
                        shape = RoundedCornerShape(6.dp)
                    ) {
                        Text(
                            text = invoice.status.uppercase(),
                            fontSize = 9.sp,
                            fontWeight = FontWeight.Bold,
                            color = when (invoice.status.lowercase(Locale.US)) {
                                "paid" -> Color(0xFF15803D)
                                "overdue" -> Color(0xFFB91C1C)
                                else -> Color(0xFFB45309)
                            },
                            modifier = Modifier.padding(horizontal = 4.dp, vertical = 2.dp)
                        )
                    }
                }
                Text(
                    text = "Client: ${invoice.clientName} • Due: ${invoice.dueDate}",
                    fontSize = 11.sp,
                    color = Color(0xFF64748B)
                )
            }

            Column(horizontalAlignment = Alignment.End) {
                Text(
                    text = "${invoice.currencySymbol}${String.format(Locale.US, "%,.2f", calcs.grandTotal)}",
                    fontWeight = FontWeight.ExtraBold,
                    fontSize = 14.sp,
                    color = Color(0xFF0F172A)
                )
                Text(
                    text = "View Preview →",
                    fontSize = 10.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color(0xFF2563EB)
                )
            }
        }
    }
}

/**
 * GEMINI LIVE TALK SYSTEM OVERLAY (USER REQUIREMENT)
 * Immersive, full-screen audio conversation interface with glowing animated pulsing orb.
 */
@Composable
fun GeminiLiveTalkModal(
    isThinking: Boolean,
    isSpeaking: Boolean,
    latestUserTranscript: String,
    latestAiSpokenReply: String,
    autoSpeakEnabled: Boolean,
    onToggleAutoSpeak: () -> Unit,
    onStartListening: () -> Unit,
    onStopSpeaking: () -> Unit,
    onSendPrompt: (String) -> Unit,
    onDropTalkToChat: () -> Unit = {},
    onDismiss: () -> Unit
) {
    // Pulse animation for the glowing Gemini orb
    val infiniteTransition = rememberInfiniteTransition(label = "gemini_orb_pulse")
    val pulseScale by infiniteTransition.animateFloat(
        initialValue = 1.0f,
        targetValue = if (isSpeaking) 1.25f else 1.12f,
        animationSpec = infiniteRepeatable(
            animation = tween(if (isSpeaking) 600 else 1400, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "gemini_orb_scale"
    )

    val waveRotation by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(
            animation = tween(8000, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "wave_rotation"
    )

    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false)
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.verticalGradient(
                        colors = listOf(Color(0xFF060913), Color(0xFF0F172A), Color(0xFF090D1A))
                    )
                )
                .padding(20.dp)
        ) {
            Column(
                modifier = Modifier.fillMaxSize(),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.SpaceBetween
            ) {
                // Top Header Row
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Surface(
                            color = Color(0xFF7C3AED).copy(alpha = 0.2f),
                            shape = CircleShape,
                            border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFF7C3AED))
                        ) {
                            Box(modifier = Modifier.padding(6.dp)) {
                                Icon(
                                    imageVector = Icons.Default.AutoAwesome,
                                    contentDescription = null,
                                    tint = Color(0xFFA78BFA),
                                    modifier = Modifier.size(16.dp)
                                )
                            }
                        }
                        Spacer(modifier = Modifier.width(10.dp))
                        Column {
                            Text(
                                text = "Invoicely AI Employee",
                                fontWeight = FontWeight.Bold,
                                color = Color.White,
                                fontSize = 16.sp
                            )
                            Text(
                                text = "Live Voice Talk • Speaks Hindi (हिंदी) & English",
                                color = Color(0xFF94A3B8),
                                fontSize = 11.sp
                            )
                        }
                    }

                    Row(verticalAlignment = Alignment.CenterVertically) {
                        // Drop Talk to Chat button (Minimizes talk overlay into chat)
                        IconButton(onClick = onDropTalkToChat) {
                            Icon(
                                imageVector = Icons.Default.KeyboardArrowDown,
                                contentDescription = "Drop to Chat",
                                tint = Color(0xFF60A5FA)
                            )
                        }

                        // Speaker mute toggle
                        IconButton(onClick = onToggleAutoSpeak) {
                            Icon(
                                imageVector = if (autoSpeakEnabled) Icons.Default.VolumeUp else Icons.Default.VolumeOff,
                                contentDescription = "Toggle Speaker",
                                tint = if (autoSpeakEnabled) Color(0xFF38BDF8) else Color.Gray
                            )
                        }
                        // Close modal
                        IconButton(onClick = onDismiss) {
                            Icon(
                                imageVector = Icons.Default.Close,
                                contentDescription = "Exit Talk Mode",
                                tint = Color.White
                            )
                        }
                    }
                }

                // Centerpiece: Glowing Animated Gemini Orb & Status
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center,
                    modifier = Modifier.weight(1f)
                ) {
                    // Pulsing Concentric Rings
                    Box(
                        modifier = Modifier
                            .size(240.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        // Outermost glowing aura
                        Box(
                            modifier = Modifier
                                .size(230.dp * pulseScale)
                                .clip(CircleShape)
                                .background(
                                    Brush.radialGradient(
                                        colors = listOf(
                                            (if (isSpeaking) Color(0xFF10B981) else Color(0xFF6366F1)).copy(alpha = 0.25f),
                                            Color.Transparent
                                        )
                                    )
                                )
                        )

                        // Mid ring
                        Box(
                            modifier = Modifier
                                .size(180.dp * pulseScale)
                                .clip(CircleShape)
                                .background(
                                    Brush.radialGradient(
                                        colors = listOf(
                                            (if (isSpeaking) Color(0xFF34D399) else Color(0xFF8B5CF6)).copy(alpha = 0.35f),
                                            Color.Transparent
                                        )
                                    )
                                )
                        )

                        // Core Glowing Orb
                        Box(
                            modifier = Modifier
                                .size(130.dp)
                                .clip(CircleShape)
                                .background(
                                    Brush.linearGradient(
                                        colors = if (isSpeaking) {
                                            listOf(Color(0xFF059669), Color(0xFF10B981), Color(0xFF065F46))
                                        } else {
                                            listOf(Color(0xFF3B82F6), Color(0xFF8B5CF6), Color(0xFF1E1B4B))
                                        }
                                    )
                                )
                                .border(
                                    2.dp,
                                    if (isSpeaking) Color(0xFF6EE7B7) else Color(0xFF93C5FD),
                                    CircleShape
                                ),
                            contentAlignment = Alignment.Center
                        ) {
                            if (isSpeaking) {
                                Icon(
                                    imageVector = Icons.Default.GraphicEq,
                                    contentDescription = null,
                                    tint = Color.White,
                                    modifier = Modifier.size(54.dp)
                                )
                            } else if (isThinking) {
                                CircularProgressIndicator(
                                    color = Color.White,
                                    strokeWidth = 3.dp,
                                    modifier = Modifier.size(46.dp)
                                )
                            } else {
                                Icon(
                                    imageVector = Icons.Default.AutoAwesome,
                                    contentDescription = null,
                                    tint = Color.White,
                                    modifier = Modifier.size(48.dp)
                                )
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    // Status Pill
                    Surface(
                        color = when {
                            isSpeaking -> Color(0xFF065F46)
                            isThinking -> Color(0xFF4C1D95)
                            else -> Color(0xFF1E293B)
                        },
                        shape = RoundedCornerShape(20.dp),
                        border = androidx.compose.foundation.BorderStroke(
                            1.dp,
                            when {
                                isSpeaking -> Color(0xFF10B981)
                                isThinking -> Color(0xFF8B5CF6)
                                else -> Color(0xFF334155)
                            }
                        )
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 14.dp, vertical = 6.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(8.dp)
                                    .clip(CircleShape)
                                    .background(
                                        when {
                                            isSpeaking -> Color(0xFF34D399)
                                            isThinking -> Color(0xFFA78BFA)
                                            else -> Color(0xFF38BDF8)
                                        }
                                    )
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = when {
                                    isSpeaking -> "AI Employee is speaking..."
                                    isThinking -> "Analyzing your business data..."
                                    else -> "Tap the microphone below to talk"
                                },
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color.White
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(18.dp))

                    // Transcript Cards
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(16.dp))
                            .background(Color(0xFF111827).copy(alpha = 0.8f))
                            .padding(14.dp)
                    ) {
                        if (latestUserTranscript.isNotBlank()) {
                            Text(
                                text = "You asked:",
                                fontSize = 11.sp,
                                color = Color(0xFF94A3B8),
                                fontWeight = FontWeight.SemiBold
                            )
                            Text(
                                text = "\"$latestUserTranscript\"",
                                fontSize = 13.sp,
                                color = Color.White,
                                fontStyle = androidx.compose.ui.text.font.FontStyle.Italic
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            HorizontalDivider(color = Color(0xFF1F2937))
                            Spacer(modifier = Modifier.height(8.dp))
                        }

                        Text(
                            text = "AI Employee says:",
                            fontSize = 11.sp,
                            color = Color(0xFF38BDF8),
                            fontWeight = FontWeight.SemiBold
                        )
                        Text(
                            text = latestAiSpokenReply.ifBlank {
                                "Namaste Sir! I am your business assistant. I can speak to you about invoices, pending money, clients, expenses, or talk about any business ideas. Just tap the mic below!"
                            },
                            fontSize = 13.sp,
                            color = Color(0xFFE2E8F0),
                            lineHeight = 19.sp,
                            maxLines = 5
                        )
                    }
                }

                // Bottom Controls: Drop to Chat Button + Quick Voice Prompts + Big Glowing Talk Button
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    // Option to Drop Talk to Chat & View full rich response
                    Button(
                        onClick = onDropTalkToChat,
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Color(0xFF1E293B)
                        ),
                        shape = RoundedCornerShape(20.dp),
                        border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFF3B82F6).copy(alpha = 0.6f)),
                        modifier = Modifier
                            .fillMaxWidth(0.85f)
                            .padding(bottom = 12.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.ArrowDownward,
                            contentDescription = "Drop Talk to Chat",
                            tint = Color(0xFF60A5FA),
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "Drop to Chat & View Response",
                            color = Color.White,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.SemiBold
                        )
                    }

                    // Quick Prompts Chips Carousel
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .horizontalScroll(rememberScrollState()),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        listOf(
                            "⚡ Acme ka bill banao ₹5,000",
                            "💰 कितना पेंडिंग पेमेंट बाकी है?",
                            "📊 Summarize my revenue",
                            "👥 Who owes me money?",
                            "💸 खर्चा लिखो ₹650 क्लाइंट लंच",
                            "💡 How to recover overdue dues?"
                        ).forEach { prompt ->
                            Surface(
                                color = Color(0xFF1E293B),
                                shape = RoundedCornerShape(14.dp),
                                border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFF334155)),
                                modifier = Modifier.clickable {
                                    onSendPrompt(prompt.substringAfter(" ").trim())
                                }
                            ) {
                                Text(
                                    text = prompt,
                                    fontSize = 11.sp,
                                    color = Color(0xFFE2E8F0),
                                    modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp)
                                )
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    // Big Central Talk / Mic Button
                    Box(
                        modifier = Modifier
                            .size(76.dp)
                            .clip(CircleShape)
                            .background(
                                Brush.linearGradient(
                                    colors = if (isSpeaking) {
                                        listOf(Color(0xFFEF4444), Color(0xFFDC2626))
                                    } else {
                                        listOf(Color(0xFF3B82F6), Color(0xFF8B5CF6))
                                    }
                                )
                            )
                            .clickable {
                                if (isSpeaking) {
                                    onStopSpeaking()
                                } else {
                                    onStartListening()
                                }
                            },
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = if (isSpeaking) Icons.Default.Stop else Icons.Default.Mic,
                            contentDescription = "Talk to Gemini",
                            tint = Color.White,
                            modifier = Modifier.size(36.dp)
                        )
                    }

                    Spacer(modifier = Modifier.height(10.dp))

                    Text(
                        text = if (isSpeaking) "Tap to Stop Voice" else "Tap to Speak to AI Employee",
                        color = Color(0xFF94A3B8),
                        fontSize = 11.sp
                    )
                }
            }
        }
    }
}

/**
 * Rich interactive preview card for invoices generated directly via chat.
 */
@Composable
fun GeneratedInvoicePreviewCard(
    invoice: InvoiceEntity,
    invoiceId: Long,
    onOpenPreview: () -> Unit,
    onOpenEdit: () -> Unit,
    modifier: Modifier = Modifier
) {
    val items = remember(invoice.itemsJson) {
        InvoiceUtils.deserializeInvoiceItems(invoice.itemsJson)
    }
    val calcs = remember(items, invoice) {
        InvoiceUtils.calculateInvoice(
            items = items,
            taxRate = invoice.taxRate,
            discountPercent = invoice.discountPercent,
            discountAmount = invoice.discountAmount,
            shippingFee = invoice.shippingFee,
            amountPaid = invoice.amountPaid
        )
    }

    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = Color(0xFFF8FAFC)),
        border = androidx.compose.foundation.BorderStroke(1.5.dp, Color(0xFFBFDBFE))
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            // Header: Invoice badge + status pill
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Default.ReceiptLong,
                        contentDescription = "Invoice",
                        tint = Color(0xFF2563EB),
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = invoice.invoiceNumber,
                        fontWeight = FontWeight.Bold,
                        fontSize = 14.sp,
                        color = PrimaryNavy
                    )
                }
                Surface(
                    color = Color(0xFFFEF3C7),
                    shape = RoundedCornerShape(8.dp)
                ) {
                    Text(
                        text = invoice.status.uppercase(),
                        fontSize = 10.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color(0xFFB45309),
                        modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(6.dp))

            // Client Name & Company
            Text(
                text = "Billed to: ${invoice.clientName} ${if (invoice.clientCompany.isNotBlank()) "(${invoice.clientCompany})" else ""}",
                fontSize = 13.sp,
                fontWeight = FontWeight.Medium,
                color = Color(0xFF334155)
            )

            // Items mini-table
            Spacer(modifier = Modifier.height(6.dp))
            HorizontalDivider(color = Color(0xFFE2E8F0), thickness = 1.dp)
            Spacer(modifier = Modifier.height(6.dp))

            items.take(3).forEach { item ->
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "• ${item.description.ifBlank { "Service" }} (${item.quantity} ${item.unit} @ ${invoice.currencySymbol}${item.unitPrice})",
                        fontSize = 12.sp,
                        color = Color(0xFF475569),
                        modifier = Modifier.weight(1f)
                    )
                    Text(
                        text = "${invoice.currencySymbol}${String.format(Locale.US, "%.2f", item.total)}",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = Color(0xFF1E293B)
                    )
                }
            }
            if (items.size > 3) {
                Text(
                    text = "+ ${items.size - 3} more line item(s)...",
                    fontSize = 11.sp,
                    color = Color.Gray
                )
            }

            Spacer(modifier = Modifier.height(6.dp))
            HorizontalDivider(color = Color(0xFFE2E8F0), thickness = 1.dp)
            Spacer(modifier = Modifier.height(6.dp))

            // Financial Summary Row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        text = "Tax (${invoice.taxRate}% ${invoice.taxLabel}): ${invoice.currencySymbol}${String.format(Locale.US, "%.2f", calcs.taxTotal)}",
                        fontSize = 11.sp,
                        color = Color.Gray
                    )
                    Text(
                        text = "Due: ${invoice.dueDate}",
                        fontSize = 11.sp,
                        color = Color.Gray
                    )
                }
                Column(horizontalAlignment = Alignment.End) {
                    Text(
                        text = "Total Due",
                        fontSize = 10.sp,
                        color = Color.Gray,
                        fontWeight = FontWeight.SemiBold
                    )
                    Text(
                        text = "${invoice.currencySymbol}${String.format(Locale.US, "%.2f", calcs.grandTotal)}",
                        fontSize = 16.sp,
                        fontWeight = FontWeight.ExtraBold,
                        color = StatusPaidGreen
                    )
                }
            }

            Spacer(modifier = Modifier.height(10.dp))

            // Action Buttons
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Button(
                    onClick = onOpenPreview,
                    modifier = Modifier
                        .weight(1f)
                        .testTag("open_invoice_preview_button"),
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF2563EB)),
                    shape = RoundedCornerShape(8.dp),
                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 6.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Visibility,
                        contentDescription = "Preview",
                        modifier = Modifier.size(16.dp)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = "Preview & DOCX",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold
                    )
                }

                OutlinedButton(
                    onClick = onOpenEdit,
                    modifier = Modifier.testTag("edit_generated_invoice_button"),
                    shape = RoundedCornerShape(8.dp),
                    contentPadding = PaddingValues(horizontal = 10.dp, vertical = 6.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Edit,
                        contentDescription = "Edit",
                        modifier = Modifier.size(15.dp),
                        tint = PrimaryNavy
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "Edit",
                        fontSize = 12.sp,
                        color = PrimaryNavy,
                        fontWeight = FontWeight.SemiBold
                    )
                }
            }
        }
    }
}

/**
 * Card showing client saved from chat
 */
@Composable
fun SavedClientCard(
    client: ClientEntity,
    onUseForInvoice: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = Color(0xFFF0FDF4)),
        border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFBBF7D0))
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        modifier = Modifier
                            .size(28.dp)
                            .clip(CircleShape)
                            .background(Color(0xFFDCFCE7)),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.Person,
                            contentDescription = "Client",
                            tint = Color(0xFF16A34A),
                            modifier = Modifier.size(16.dp)
                        )
                    }
                    Spacer(modifier = Modifier.width(8.dp))
                    Column {
                        Text(
                            text = client.name,
                            fontWeight = FontWeight.Bold,
                            fontSize = 14.sp,
                            color = Color(0xFF14532D)
                        )
                        if (client.companyName.isNotBlank()) {
                            Text(
                                text = client.companyName,
                                fontSize = 11.sp,
                                color = Color(0xFF15803D)
                            )
                        }
                    }
                }
                Icon(
                    imageVector = Icons.Default.CheckCircle,
                    contentDescription = "Saved",
                    tint = Color(0xFF16A34A),
                    modifier = Modifier.size(18.dp)
                )
            }

            if (client.email.isNotBlank() || client.phone.isNotBlank()) {
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "Email: ${client.email.ifBlank { "—" }} • Phone: ${client.phone.ifBlank { "—" }}",
                    fontSize = 11.sp,
                    color = Color(0xFF334155)
                )
            }

            Spacer(modifier = Modifier.height(8.dp))

            Button(
                onClick = onUseForInvoice,
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF16A34A)),
                shape = RoundedCornerShape(8.dp),
                contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    text = "Invoice This Client",
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}

/**
 * Card showing expense recorded from chat
 */
@Composable
fun SavedExpenseChatCard(
    expense: ExpenseEntity,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = Color(0xFFFEF2F2)),
        border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFFECACA))
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        modifier = Modifier
                            .size(28.dp)
                            .clip(CircleShape)
                            .background(Color(0xFFFEE2E2)),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.Receipt,
                            contentDescription = "Expense",
                            tint = Color(0xFFDC2626),
                            modifier = Modifier.size(16.dp)
                        )
                    }
                    Spacer(modifier = Modifier.width(8.dp))
                    Column {
                        Text(
                            text = expense.title,
                            fontWeight = FontWeight.Bold,
                            fontSize = 14.sp,
                            color = Color(0xFF991B1B)
                        )
                        Text(
                            text = "${expense.category} • ${expense.paymentMethod}",
                            fontSize = 11.sp,
                            color = Color(0xFFB91C1C)
                        )
                    }
                }
                Text(
                    text = "${expense.currencySymbol}${String.format(Locale.US, "%.2f", expense.amount)}",
                    fontWeight = FontWeight.ExtraBold,
                    fontSize = 16.sp,
                    color = Color(0xFFDC2626)
                )
            }
            if (expense.vendor.isNotBlank()) {
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "Vendor: ${expense.vendor} • Recorded to Expenses",
                    fontSize = 11.sp,
                    color = Color(0xFF475569)
                )
            }
        }
    }
}

@Composable
fun AiThinkingBubble() {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.Start,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(32.dp)
                .clip(CircleShape)
                .background(
                    Brush.linearGradient(
                        colors = listOf(Color(0xFF3B82F6), Color(0xFF8B5CF6))
                    )
                ),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Default.SmartToy,
                contentDescription = "Gemini",
                tint = Color.White,
                modifier = Modifier.size(18.dp)
            )
        }

        Spacer(modifier = Modifier.width(8.dp))

        Surface(
            color = Color.White,
            shape = RoundedCornerShape(16.dp),
            border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFE2E8F0)),
            shadowElevation = 1.dp
        ) {
            Row(
                modifier = Modifier.padding(horizontal = 14.dp, vertical = 10.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                CircularProgressIndicator(
                    modifier = Modifier.size(16.dp),
                    strokeWidth = 2.dp,
                    color = Color(0xFF3B82F6)
                )
                Text(
                    text = "Gemini is thinking...",
                    fontSize = 13.sp,
                    color = Color.Gray,
                    fontStyle = androidx.compose.ui.text.font.FontStyle.Italic
                )
            }
        }
    }
}
