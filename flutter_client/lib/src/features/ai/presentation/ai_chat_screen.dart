import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../data/ai_assistant_models.dart';
import '../data/ai_assistant_repository.dart';

// Premium White + Warm Cream + Classical Burgundy Design System
const Color _kCreamBg = Color(0xFFFBF8F2);
const Color _kCreamPill = Color(0xFFF4ECE1);
const Color _kCreamPillBorder = Color(0xFFE6DCCE);
const Color _kBurgundy = Color(0xFF6B1D2F);
const Color _kUserBubble = Color(0xFFF5EAE7);
const Color _kTextDark = Color(0xFF261A1D);
const Color _kTextMuted = Color(0xFF78716C);
const Color _kCardBorder = Color(0xFFEBE4DA);
const Color _kGreenIcon = Color(0xFF16A34A);
const Color _kAmberIcon = Color(0xFFD97706);
const Color _kBlueIcon = Color(0xFF2563EB);

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({
    required this.apiClient,
    required this.accountScope,
    super.key,
  });

  final ApiClient apiClient;
  final String accountScope;

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  static const _suggestions = <String>[
    'Overdue invoices',
    'Monthly profit',
    'Create invoice',
    'Summarize my recent invoices',
    'Collected revenue',
  ];

  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _confirmedCommands = <String>{};
  late final AiAssistantRepository _repository;
  late final String _historyKey;
  final _historyStorage = TokenStorage();
  final _speech = SpeechToText();
  final _tts = FlutterTts();
  final List<_ChatEntry> _messages = <_ChatEntry>[];
  String? _errorMessage;
  String? _confirmingCommandId;
  bool _isLoading = false;
  bool _invoiceDraftMode = false;
  bool _speechAvailable = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _autoSpeak = true;
  bool _historyReady = false;

  // Live Speech Capture state
  bool _showSpeechLivePanel = false;
  String _liveSpokenText = '';

  @override
  void initState() {
    super.initState();
    _repository = AiAssistantRepository(apiClient: widget.apiClient);
    _historyKey = 'invoicely_ai_chat_'
        '${sha256.convert(utf8.encode(widget.accountScope)).toString()}';
    unawaited(_restoreChatHistory());
    unawaited(_initializeSpeech());
    unawaited(_initializeTts());
  }

  @override
  void dispose() {
    unawaited(_speech.stop());
    unawaited(_tts.stop());
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _tts.setStartHandler(() {
        if (mounted) setState(() => _isSpeaking = true);
      });
      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
      _tts.setErrorHandler((dynamic msg) {
        if (mounted) setState(() => _isSpeaking = false);
      });
    } catch (_) {}
  }

  Future<void> _speakText(String text) async {
    if (_isSpeaking) {
      await _tts.stop();
      if (mounted) setState(() => _isSpeaking = false);
      return;
    }
    final clean = text
        .replaceAll(RegExp(r'[*_#`~\[\]]'), '')
        .replaceAll(RegExp(r'\{.*?\}'), '')
        .trim();
    if (clean.isNotEmpty) {
      await _tts.speak(clean);
    }
  }

  Future<void> _stopSpeaking() async {
    await _tts.stop();
    if (mounted) setState(() => _isSpeaking = false);
  }

  Future<void> _restoreChatHistory() async {
    try {
      final savedJson = await _historyStorage.readValue(_historyKey);
      if (savedJson == null || savedJson.trim().isEmpty) {
        if (mounted) setState(() => _historyReady = true);
        return;
      }
      final Object? decoded = jsonDecode(savedJson);
      if (decoded is! List<Object?>) {
        throw const FormatException('Saved AI chat history is not a list.');
      }
      final restored = <_ChatEntry>[];
      for (final Object? value in decoded) {
        if (value is! Map<String, dynamic> ||
            value['text'] is! String ||
            value['isUser'] is! bool) {
          throw const FormatException('Saved AI chat history is invalid.');
        }
        restored.add(_ChatEntry(
          text: value['text'] as String,
          isUser: value['isUser'] as bool,
        ));
      }
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(restored);
        _historyReady = true;
      });
      _scrollToLatest();
    } catch (error) {
      if (mounted) {
        setState(() {
          _historyReady = true;
          _errorMessage = 'Could not restore saved chat history: $error';
        });
      }
      try {
        await _historyStorage.deleteValue(_historyKey);
      } catch (deleteError) {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Could not restore saved chat history: $error. Could not remove invalid history: $deleteError';
          });
        }
      }
    }
  }

  Future<void> _persistChatHistory() async {
    final recent = _messages.length <= 100
        ? _messages
        : _messages.sublist(_messages.length - 100);
    try {
      await _historyStorage.writeValue(
        _historyKey,
        jsonEncode([
          for (final entry in recent)
            {'text': entry.text, 'isUser': entry.isUser},
        ]),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not save chat history: $error');
      }
    }
  }

  Future<void> _initializeSpeech() async {
    try {
      final available = await _speech.initialize(
        onError: (error) {
          if (mounted) {
            setState(() {
              _isListening = false;
              _showSpeechLivePanel = false;
              _errorMessage = 'Voice input failed: ${error.errorMsg}';
            });
          }
        },
        onStatus: (status) {
          if (mounted && status != 'listening' && _isListening) {
            setState(() {
              _isListening = false;
            });
          }
        },
      );
      if (mounted) setState(() => _speechAvailable = available);
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = 'Voice input is unavailable: $error');
      }
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
      return;
    }
    try {
      if (!_speechAvailable) {
        await _initializeSpeech();
      }
      if (!_speechAvailable) {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Voice input is unavailable. Check microphone permission and speech recognition support.';
          });
        }
        return;
      }
      setState(() {
        _errorMessage = null;
        _isListening = true;
        _showSpeechLivePanel = true;
        _liveSpokenText = _inputController.text;
      });
      await _speech.listen(
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(minutes: 1),
          pauseFor: const Duration(seconds: 4),
        ),
        onResult: (result) {
          if (!mounted) return;
          setState(() {
            _liveSpokenText = result.recognizedWords;
            _inputController.value = TextEditingValue(
              text: result.recognizedWords,
              selection: TextSelection.collapsed(
                offset: result.recognizedWords.length,
              ),
            );
          });
        },
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _isListening = false;
          _showSpeechLivePanel = false;
          _errorMessage = 'Could not start voice input: $error';
        });
      }
    }
  }

  String _refineSpeechForAi(String spoken) {
    var text = spoken.trim();
    if (text.isEmpty) return text;

    final fillers = [
      RegExp(r'\b(um|uh|er|ah|like|you know|basically|actually)\b', caseSensitive: false),
      RegExp(r'\s+', caseSensitive: false),
    ];
    for (final filler in fillers) {
      text = text.replaceAll(filler, ' ');
    }

    final replacements = <Pattern, String>{
      RegExp(r'\bshow me (the )?overdue\b', caseSensitive: false): 'Which invoices are overdue?',
      RegExp(r'\bhow much (money )?did we (make|collect|get)\b', caseSensitive: false): 'What is our total collected revenue?',
      RegExp(r'\bwhat are (the )?expenses\b', caseSensitive: false): 'What expenses were recorded recently?',
      RegExp(r'\bmake (a )?new invoice\b', caseSensitive: false): 'Create a draft invoice',
      RegExp(r'\bshow my invoice updates\b', caseSensitive: false): 'Show my invoice updates and overdue payments this week',
    };

    for (final entry in replacements.entries) {
      if (entry.key.allMatches(text).isNotEmpty) {
        text = text.replaceAll(entry.key, entry.value);
      }
    }

    text = text.trim();
    if (text.isNotEmpty) {
      text = text[0].toUpperCase() + text.substring(1);
    }
    return text;
  }

  Future<void> _submit({String? prompt}) async {
    if (_isLoading || _confirmingCommandId != null || !_historyReady) return;
    final text = (prompt ?? _inputController.text).trim();
    if (text.isEmpty) return;
    if (text.length > 2000) {
      setState(() =>
          _errorMessage = 'Messages can contain at most 2,000 characters.');
      return;
    }

    if (_isListening) {
      await _speech.stop();
    }

    final makeInvoiceDraft = _invoiceDraftMode;
    setState(() {
      _errorMessage = null;
      _isLoading = true;
      _invoiceDraftMode = false;
      _showSpeechLivePanel = false;
      _isListening = false;
      _liveSpokenText = '';
      _inputController.clear();
      _messages.add(_ChatEntry(
        text: text,
        isUser: true,
      ));
    });
    unawaited(_persistChatHistory());
    _scrollToLatest();

    try {
      if (makeInvoiceDraft) {
        final response = await _repository.prepareInvoiceDraft(text);
        if (!mounted) return;
        setState(() {
          _messages.add(_ChatEntry(
            text: response.message,
            isUser: false,
            invoiceDraft: response,
          ));
        });
        unawaited(_persistChatHistory());
      } else {
        final response = await _repository.sendMessage(text);
        if (!mounted) return;
        setState(() {
          _messages.add(_ChatEntry(
            text: response.answer,
            isUser: false,
            chatResponse: response,
          ));
        });
        unawaited(_persistChatHistory());
        if (_autoSpeak) {
          unawaited(_speakText(response.answer));
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = _errorText(error));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToLatest();
      }
    }
  }

  Future<void> _confirmCommand(String commandId) async {
    if (_isLoading || _confirmingCommandId != null || !_historyReady) return;
    setState(() {
      _errorMessage = null;
      _confirmingCommandId = commandId;
    });

    try {
      final response = await _repository.confirmCommand(commandId);
      if (!mounted) return;
      setState(() {
        _confirmedCommands.add(commandId);
        _messages.add(_ChatEntry(
          text: response.answer,
          isUser: false,
          chatResponse: response,
        ));
      });
      unawaited(_persistChatHistory());
      if (_autoSpeak) {
        unawaited(_speakText(response.answer));
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = _errorText(error));
      }
    } finally {
      if (mounted) {
        setState(() => _confirmingCommandId = null);
        _scrollToLatest();
      }
    }
  }

  Future<void> _clearChat() async {
    if (_isLoading || _confirmingCommandId != null) return;
    if (_isSpeaking) _stopSpeaking();
    setState(() {
      _messages.clear();
      _confirmedCommands.clear();
      _errorMessage = null;
      _showSpeechLivePanel = false;
      _liveSpokenText = '';
    });
    try {
      await _historyStorage.deleteValue(_historyKey);
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not clear chat history: $error');
      }
    }
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  String _errorText(Object error) => error.toString();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kCreamBg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _kCreamBg,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _kBurgundy,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: _kBurgundy.withValues(alpha: 0.25),
                    offset: const Offset(0, 2),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'AI Business Assistant',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: _kTextDark,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  _isSpeaking
                      ? 'Speaking answer…'
                      : _isListening
                          ? 'Listening to your voice…'
                          : 'Your business data, explained simply',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isSpeaking || _isListening
                        ? _kBurgundy
                        : _kTextMuted,
                    fontWeight: _isSpeaking || _isListening
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _autoSpeak ? 'Mute voice answers' : 'Enable voice answers',
            onPressed: () {
              if (_isSpeaking) _stopSpeaking();
              setState(() => _autoSpeak = !_autoSpeak);
            },
            icon: Icon(
              _autoSpeak ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: _autoSpeak ? _kBurgundy : _kTextMuted,
            ),
          ),
          if (_isSpeaking)
            IconButton(
              tooltip: 'Stop speaking',
              onPressed: _stopSpeaking,
              icon: const Icon(Icons.stop_circle_outlined, color: Colors.redAccent),
            ),
          PopupMenuButton<String>(
            tooltip: 'Options',
            icon: const Icon(Icons.more_horiz_rounded, color: _kTextDark),
            onSelected: (value) {
              if (value == 'clear') _clearChat();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_outlined, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear conversation'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // SUGGESTED QUESTIONS bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              color: _kCreamBg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'SUGGESTED QUESTIONS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8C827A),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final suggestion in _suggestions)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: _isLoading || _confirmingCommandId != null
                                  ? null
                                  : () => _submit(prompt: suggestion),
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: _kCreamPill,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: _kCreamPillBorder,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  suggestion,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF362B2D),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: _kCardBorder),
            // Chat history stream
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  for (final message in _messages) ...[
                    const SizedBox(height: 14),
                    _MessageBubble(
                      entry: message,
                      confirmingCommandId: _confirmingCommandId,
                      confirmedCommands: _confirmedCommands,
                      onConfirm: _confirmCommand,
                      onSpeak: _speakText,
                      onSuggestionTap: (prompt) => _submit(prompt: prompt),
                    ),
                  ],
                  if (_isLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _kCardBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _kBurgundy,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Analyzing business records…',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: _kTextDark,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    _ErrorCard(
                      message: _errorMessage!,
                      onDismiss: () => setState(() => _errorMessage = null),
                    ),
                  ],
                ],
              ),
            ),

            // Live Speech Capture & Prompt Correction Floating Panel
            if (_showSpeechLivePanel)
              Container(
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kBurgundy.withValues(alpha: 0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: _kBurgundy.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _isListening ? Colors.red : _kBurgundy,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isListening
                              ? 'Live speech capturing… speak naturally'
                              : 'Speech captured',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _isListening ? Colors.red : _kBurgundy,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            if (_isListening) _speech.stop();
                            setState(() {
                              _showSpeechLivePanel = false;
                              _isListening = false;
                            });
                          },
                          child: const Icon(Icons.close, size: 16, color: _kTextMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: _kCreamBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _kCardBorder),
                      ),
                      child: Text(
                        _liveSpokenText.isEmpty
                            ? 'Listening… your speech will appear here'
                            : _liveSpokenText,
                        style: TextStyle(
                          fontSize: 14,
                          color: _liveSpokenText.isEmpty ? _kTextMuted : _kTextDark,
                          fontStyle: _liveSpokenText.isEmpty
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Refine / Polish Prompt button
                        OutlinedButton.icon(
                          onPressed: _liveSpokenText.trim().isEmpty
                              ? null
                              : () {
                                  final polished = _refineSpeechForAi(_liveSpokenText);
                                  setState(() {
                                    _liveSpokenText = polished;
                                    _inputController.text = polished;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Prompt refined for AI business query'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.auto_fix_high, size: 14, color: _kBurgundy),
                          label: const Text(
                            'Refine prompt',
                            style: TextStyle(fontSize: 12, color: _kBurgundy),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _kBurgundy),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        const Spacer(),
                        // Send prompt to AI button
                        FilledButton(
                          onPressed: _liveSpokenText.trim().isEmpty
                              ? null
                              : () => _submit(prompt: _liveSpokenText),
                          style: FilledButton.styleFrom(
                            backgroundColor: _kBurgundy,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Send to AI →',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Bottom Composer with voice icon positioned AFTER the send button arrow
            _Composer(
              controller: _inputController,
              isLoading:
                  _isLoading || _confirmingCommandId != null || !_historyReady,
              invoiceDraftMode: _invoiceDraftMode,
              isListening: _isListening,
              speechAvailable: _speechAvailable,
              onInvoiceDraftModeChanged: (enabled) =>
                  setState(() => _invoiceDraftMode = enabled),
              onToggleListening: _toggleListening,
              onSubmit: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatEntry {
  const _ChatEntry({
    required this.text,
    required this.isUser,
    this.chatResponse,
    this.invoiceDraft,
  });

  final String text;
  final bool isUser;
  final AiChatResponse? chatResponse;
  final AiInvoiceDraftResponse? invoiceDraft;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.entry,
    required this.confirmingCommandId,
    required this.confirmedCommands,
    required this.onConfirm,
    this.onSpeak,
    this.onSuggestionTap,
  });

  final _ChatEntry entry;
  final String? confirmingCommandId;
  final Set<String> confirmedCommands;
  final ValueChanged<String> onConfirm;
  final ValueChanged<String>? onSpeak;
  final ValueChanged<String>? onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    if (entry.isUser) {
      // User bubble: warm cream-rose tinted bubble on the right
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.85,
          ),
          decoration: BoxDecoration(
            color: _kUserBubble,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
            border: Border.all(
              color: const Color(0xFFEADBCE),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SelectableText(
            entry.text,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: _kTextDark,
              height: 1.4,
            ),
          ),
        ),
      );
    }

    // AI message: header + dynamic smart cards + insights + actions
    final response = entry.chatResponse;
    final summaryCards = response?.summaryCards ?? [];
    final insight = response?.insightCard;
    final recordCards = response?.recordCards ?? [];
    final pendingId = response?.pendingCommandId;
    final draft = entry.invoiceDraft;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.95,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Header row: Burgundy square icon + title + subtitle
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _kBurgundy,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 17,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Here is your business update',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: _kTextDark,
                        ),
                      ),
                      Text(
                        'Based on the latest records available in your workspace.',
                        style: TextStyle(
                          fontSize: 12,
                          color: _kTextMuted.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 1. Dynamic Summary Cards (2x2 Grid)
            if (summaryCards.isNotEmpty) ...[
              _buildSummaryCardsGrid(context, summaryCards),
              const SizedBox(height: 12),
            ],

            // 2. "Needs your attention" Alert / Insight Card
            if (insight != null) ...[
              _buildInsightCard(context, insight),
              const SizedBox(height: 12),
            ],

            // 3. Record Cards (if invoices / records were requested)
            if (recordCards.isNotEmpty) ...[
              _buildRecordCards(context, recordCards),
              const SizedBox(height: 12),
            ],

            // 4. Action Confirmation Card (if pending action)
            if (pendingId != null) ...[
              _buildPendingAction(context, pendingId),
              const SizedBox(height: 12),
            ],

            // 5. Invoice Draft Card (if invoice draft mode)
            if (draft != null) ...[
              _InvoiceDraftCard(response: draft),
              const SizedBox(height: 12),
            ],

            // 6. Conversational explanation / Text Answer card
            if (entry.text.isNotEmpty && summaryCards.isEmpty && recordCards.isEmpty && draft == null) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kCardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: SelectableText(
                  entry.text,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.45,
                    color: _kTextDark,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Grounded sources tags & Action buttons (Copy & Speak)
            Row(
              children: [
                if (response != null && response.groundedSources.isNotEmpty)
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final src in response.groundedSources)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _kCreamPill,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _kCreamPillBorder),
                            ),
                            child: Text(
                              src,
                              style: const TextStyle(
                                fontSize: 11,
                                color: _kTextMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                IconButton(
                  iconSize: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  tooltip: 'Copy answer',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: entry.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, color: _kTextMuted),
                ),
                if (onSpeak != null)
                  IconButton(
                    iconSize: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    tooltip: 'Read aloud',
                    onPressed: () => onSpeak!(entry.text),
                    icon: const Icon(Icons.volume_up_outlined, color: _kTextMuted),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 2x2 Grid of Pure White Summary Cards
  Widget _buildSummaryCardsGrid(BuildContext context, List<SummaryCardDto> cards) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final card in cards)
              Container(
                width: cardWidth,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kCardBorder, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _getCardIcon(card.icon),
                      size: 20,
                      color: _getCardColor(card.color),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      card.value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _kTextDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      card.title,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _kTextMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  // Pure White "Needs your attention" Alert Card with Classical Burgundy CTA
  Widget _buildInsightCard(BuildContext context, InsightCardDto insight) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kCardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 18,
                color: _kAmberIcon,
              ),
              const SizedBox(width: 8),
              Text(
                insight.title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: _kTextDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            insight.message,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF57534E),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                if (onSuggestionTap != null) {
                  onSuggestionTap!('Show overdue invoices');
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: _kBurgundy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                insight.actionLabel,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Record cards list
  Widget _buildRecordCards(BuildContext context, List<RecordCardDto> records) {
    return Column(
      children: [
        for (final rec in records)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kCardBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kCreamPill,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.receipt_outlined,
                    size: 18,
                    color: _kBurgundy,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rec.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _kTextDark,
                        ),
                      ),
                      Text(
                        rec.subtitle,
                        style: const TextStyle(fontSize: 12, color: _kTextMuted),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      rec.amount,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _kTextDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: rec.status.toLowerCase() == 'paid'
                            ? const Color(0xFFDCFCE7)
                            : (rec.status.toLowerCase() == 'overdue'
                                ? const Color(0xFFFEF3C7)
                                : const Color(0xFFDBEAFE)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        rec.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: rec.status.toLowerCase() == 'paid'
                              ? const Color(0xFF15803D)
                              : (rec.status.toLowerCase() == 'overdue'
                                  ? const Color(0xFFB45309)
                                  : const Color(0xFF1D4ED8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Pending action draft confirmation
  Widget _buildPendingAction(BuildContext context, String commandId) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBurgundy.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Action proposal ready for your approval:',
            style: TextStyle(fontSize: 12.5, color: _kTextMuted),
          ),
          const SizedBox(height: 10),
          confirmedCommands.contains(commandId)
              ? const Row(
                  children: [
                    Icon(Icons.check_circle, color: _kGreenIcon, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Action Confirmed & Executed',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _kGreenIcon,
                      ),
                    ),
                  ],
                )
              : SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: confirmingCommandId == null
                        ? () => onConfirm(commandId)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: _kBurgundy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      confirmingCommandId == commandId
                          ? 'Confirming…'
                          : 'Confirm and execute action →',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  static IconData _getCardIcon(String icon) {
    return switch (icon.toLowerCase()) {
      'wallet' => Icons.account_balance_wallet_outlined,
      'clock' => Icons.access_time_rounded,
      'users' => Icons.people_outline_rounded,
      _ => Icons.description_outlined,
    };
  }

  static Color _getCardColor(String color) {
    return switch (color.toLowerCase()) {
      'green' => _kGreenIcon,
      'amber' => _kAmberIcon,
      'blue' => _kBlueIcon,
      _ => _kBurgundy,
    };
  }
}

class _InvoiceDraftCard extends StatelessWidget {
  const _InvoiceDraftCard({required this.response});

  final AiInvoiceDraftResponse response;

  @override
  Widget build(BuildContext context) {
    final invoice = response.invoice;
    if (invoice == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kCardBorder),
        ),
        child: SelectableText(response.message),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: _kBurgundy, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Draft Invoice Preview',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _kTextDark,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  invoice.status,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _draftRow('Client', invoice.clientName),
          _draftRow('Currency', invoice.currencyCode),
          _draftRow('Dates', '${_orUnset(invoice.issueDate)} → ${_orUnset(invoice.dueDate)}'),
          if (invoice.taxRate != 0) _draftRow('Tax', '${invoice.taxRate}%'),
          if (invoice.notes.isNotEmpty) _draftRow('Notes', invoice.notes),
        ],
      ),
    );
  }

  Widget _draftRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: _kTextMuted),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _kTextDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _orUnset(String value) => value.isEmpty ? 'Not set' : value;
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, this.onDismiss});

  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
            ),
          ),
          if (onDismiss != null)
            InkWell(
              onTap: onDismiss,
              child: const Icon(Icons.close, size: 16, color: Color(0xFFDC2626)),
            ),
        ],
      ),
    );
  }
}

// Bottom Composer with Voice Icon Positioned AFTER the Send Button Arrow
class _Composer extends StatefulWidget {
  const _Composer({
    required this.controller,
    required this.isLoading,
    required this.invoiceDraftMode,
    required this.isListening,
    required this.speechAvailable,
    required this.onInvoiceDraftModeChanged,
    required this.onToggleListening,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isLoading;
  final bool invoiceDraftMode;
  final bool isListening;
  final bool speechAvailable;
  final ValueChanged<bool> onInvoiceDraftModeChanged;
  final Future<void> Function() onToggleListening;
  final Future<void> Function() onSubmit;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.trim().isNotEmpty;
    widget.controller.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChange);
    super.dispose();
  }

  void _handleTextChange() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kCreamBg,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: widget.invoiceDraftMode
                    ? _kBurgundy
                    : const Color(0xFFE5DDD1),
                width: widget.invoiceDraftMode ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: Attachment / Invoice draft toggle icon
                IconButton(
                  tooltip: widget.invoiceDraftMode
                      ? 'Exit draft mode'
                      : 'Prepare invoice draft mode',
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: widget.isLoading
                      ? null
                      : () => widget.onInvoiceDraftModeChanged(!widget.invoiceDraftMode),
                  icon: Icon(
                    Icons.attach_file_rounded,
                    size: 20,
                    color: widget.invoiceDraftMode
                        ? _kBurgundy
                        : const Color(0xFF8C827A),
                  ),
                ),

                // Center: Text Input
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    enabled: !widget.isLoading,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 2000,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) {
                      if (!widget.isLoading) widget.onSubmit();
                    },
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 10,
                      ),
                      border: InputBorder.none,
                      counterText: '',
                      hintText: widget.invoiceDraftMode
                          ? 'Describe invoice to draft…'
                          : 'Ask about your business…',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF9E958C),
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: _kTextDark,
                    ),
                  ),
                ),

                // 1. Classical Burgundy Send Button Arrow
                GestureDetector(
                  onTap: (!widget.isLoading && _hasText)
                      ? () => widget.onSubmit()
                      : null,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _hasText && !widget.isLoading
                          ? _kBurgundy
                          : _kBurgundy.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: _kBurgundy.withValues(alpha: 0.25),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: widget.isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(9),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.arrow_upward_rounded,
                            size: 19,
                            color: Colors.white,
                          ),
                  ),
                ),
                const SizedBox(width: 6),

                // 2. Voice Mic Icon Placed AFTER the Send Button Arrow!
                IconButton(
                  tooltip: widget.isListening ? 'Stop voice input' : 'Voice input',
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: widget.isLoading ? null : () => widget.onToggleListening(),
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: widget.isListening
                          ? Colors.red
                          : _kCreamPill,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.isListening
                            ? Colors.red
                            : _kCreamPillBorder,
                      ),
                    ),
                    child: Icon(
                      widget.isListening ? Icons.mic : Icons.mic_none_rounded,
                      size: 18,
                      color: widget.isListening
                          ? Colors.white
                          : _kBurgundy,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
