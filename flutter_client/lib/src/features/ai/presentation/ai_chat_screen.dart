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

// InvoicePro Business OS Design Tokens
const Color _kPrimary = Color(0xFF1D68F0);
const Color _kNavyDark = Color(0xFF0B1736);
const Color _kSlateBg = Color(0xFFF8FAFC);
const Color _kCardBorder = Color(0xFFE2E8F0);
const Color _kChipBg = Color(0xFFF1F5F9);
const Color _kChipBorder = Color(0xFFCBD5E1);
const Color _kTextDark = Color(0xFF0F172A);
const Color _kTextMuted = Color(0xFF64748B);
const Color _kGreen = Color(0xFF10B981);

class _CachedItem {
  _CachedItem({required this.response, required this.timestamp});
  final AiChatResponse response;
  final DateTime timestamp;
}

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

class _AiChatScreenState extends State<AiChatScreen>
    with SingleTickerProviderStateMixin {
  static const _suggestions = <Map<String, String>>[
    {'label': 'Overdue Invoices', 'icon': '📄', 'query': 'Which invoices are overdue?'},
    {'label': 'Monthly Profit', 'icon': '📈', 'query': 'What is our monthly profit and margin?'},
    {'label': 'Create Invoice', 'icon': '🧾', 'query': 'Create draft invoice'},
    {'label': 'Pending Payments', 'icon': '⏳', 'query': 'Summarize all unpaid customer invoices'},
    {'label': 'Aaj Ka Revenue', 'icon': '🇮🇳', 'query': 'Humara total collected revenue kitna hai?'},
    {'label': 'Recent Expenses', 'icon': '💳', 'query': 'What expenses were recorded recently?'},
  ];

  // In-memory token-saver query cache (10 min TTL)
  static final Map<String, _CachedItem> _clientQueryCache = {};

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

  // Live Speech & Silence auto-submit timer
  bool _showSpeechLivePanel = false;
  String _liveSpokenText = '';
  Timer? _silenceTimer;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _repository = AiAssistantRepository(apiClient: widget.apiClient);
    _historyKey = 'invoicely_ai_chat_'
        '${sha256.convert(utf8.encode(widget.accountScope)).toString()}';
    unawaited(_restoreChatHistory());
    unawaited(_initializeSpeech());
    unawaited(_initializeTts());
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _waveController.dispose();
    unawaited(_speech.stop());
    unawaited(_tts.stop());
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Natural Indian English & Hinglish TTS Setup (Pitch 1.08 = clear, crisp, not too deep)
  Future<void> _initializeTts() async {
    try {
      await _tts.setSpeechRate(0.50);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.08);

      // Default to Indian English if available
      try {
        await _tts.setLanguage('en-IN');
      } catch (_) {
        await _tts.setLanguage('en-US');
      }

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

  bool _isHinglishOrHindi(String text) {
    final devanagari = RegExp(r'[\u0900-\u097F]');
    if (devanagari.hasMatch(text)) return true;
    final hinglishWords = RegExp(
      r'\b(namaste|kaise|kya|hai|haan|nahi|kardo|batao|kitna|kitne|rupaye|kharcha|bhejo|aaya|diya|dekh|karein|chahiye|aapka|humara|shukriya|dhanyawad|bana|dekhna)\b',
      caseSensitive: false,
    );
    return hinglishWords.hasMatch(text);
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
        .replaceAll(RegExp(r'https?:\/\/\S+'), '')
        .replaceAll(RegExp(r'[^\w\s.,!?:;₹$%\-\u0900-\u097F]'), ' ')
        .trim();

    if (clean.isNotEmpty) {
      try {
        if (_isHinglishOrHindi(clean)) {
          // Use Hindi voice for Hinglish / Hindi queries
          await _tts.setLanguage('hi-IN');
          await _tts.setPitch(1.08);
          await _tts.setSpeechRate(0.50);
        } else {
          // Indian English accent voice
          await _tts.setLanguage('en-IN');
          await _tts.setPitch(1.08);
          await _tts.setSpeechRate(0.50);
        }
      } catch (_) {}
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
          isCached: (value['isCached'] as bool?) ?? false,
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
      } catch (_) {}
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
            {
              'text': entry.text,
              'isUser': entry.isUser,
              'isCached': entry.isCached,
            },
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
              _errorMessage = 'Voice input: ${error.errorMsg}';
            });
          }
        },
        onStatus: (status) {
          if (mounted && status != 'listening' && _isListening) {
            setState(() => _isListening = false);
          }
        },
      );
      if (mounted) setState(() => _speechAvailable = available);
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = 'Voice input unavailable: $error');
      }
    }
  }

  // Live Speech with auto-send on silence
  Future<void> _toggleListening() async {
    _silenceTimer?.cancel();
    if (_isListening) {
      await _speech.stop();
      if (mounted) {
        setState(() => _isListening = false);
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
                'Voice input is unavailable. Please check microphone permissions in your browser or device.';
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
          listenFor: const Duration(seconds: 45),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          cancelOnError: false,
        ),
        onResult: (result) {
          if (!mounted) return;
          final words = result.recognizedWords;
          setState(() {
            _liveSpokenText = words;
            _inputController.value = TextEditingValue(
              text: words,
              selection: TextSelection.collapsed(offset: words.length),
            );
          });

          // Automatic auto-send: if final result received or user pauses for 1650ms
          _silenceTimer?.cancel();
          if (words.trim().isNotEmpty) {
            if (result.finalResult) {
              _autoSubmitSpokenText(words);
            } else {
              // Debounced silence timer: sends automatically once user finishes talking!
              _silenceTimer = Timer(const Duration(milliseconds: 1650), () {
                if (_isListening && _liveSpokenText.trim().isNotEmpty) {
                  _autoSubmitSpokenText(_liveSpokenText);
                }
              });
            }
          }
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

  void _autoSubmitSpokenText(String rawText) {
    _silenceTimer?.cancel();
    unawaited(_speech.stop());
    final polished = _refineSpeechForAi(rawText);
    if (mounted) {
      setState(() {
        _isListening = false;
        _showSpeechLivePanel = false;
      });
      _submit(prompt: polished);
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

  // Zero-Token Instant Greeting Engine (minimizes AI token over-utilization)
  String? _resolveInstantGreeting(String rawQuery) {
    final q = rawQuery.toLowerCase().trim();
    final isHindi = _isHinglishOrHindi(q);

    final greetingPatterns = [
      'hi', 'hello', 'hey', 'namaste', 'kaise ho', 'kya haal hai', 'kem cho',
      'good morning', 'good afternoon', 'good evening', 'who are you', 'kya kar sakte ho'
    ];

    final isGreeting = greetingPatterns.any((p) => q == p || q.startsWith('$p '));
    if (!isGreeting) return null;

    if (isHindi || q.contains('namaste') || q.contains('kaise')) {
      return 'Namaste! 🙏 Main aapka Invoicely AI Assistant hoon.\n\n'
          'Main aapke business ke invoices, pending payments, expenses aur revenue calculate karne me help kar sakta hoon.\n\n'
          '• **Aap Hindi ya English** kisi me bhi pooch sakte hain.\n'
          '• **Suggestions**: "Overdue invoices batao", "Kitna profit hua?", "New invoice draft banao".\n\n'
          'Bataiye, aaj aapko kya check karna hai?';
    } else {
      return 'Hello! 👋 I am your Invoicely AI Business Assistant.\n\n'
          'I can help you monitor cash flow, track overdue invoices, record expenses, and draft new client billings instantly.\n\n'
          '• You can speak or type in **English** or **Hinglish**.\n'
          '• Voice answers are enabled with Indian pronunciation.\n\n'
          'How can I assist your business today?';
    }
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

    _silenceTimer?.cancel();
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

    // 1. Instant Token-Free Greeting Check (0 tokens consumed!)
    final instantGreeting = _resolveInstantGreeting(text);
    if (instantGreeting != null) {
      await Future<void>.delayed(const Duration(milliseconds: 180));
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _messages.add(_ChatEntry(
          text: instantGreeting,
          isUser: false,
          isCached: true,
          chatResponse: AiChatResponse(
            answer: instantGreeting,
            groundedSources: const ['Instant Engine (0 Tokens)'],
            readOnly: true,
          ),
        ));
      });
      unawaited(_persistChatHistory());
      if (_autoSpeak) {
        unawaited(_speakText(instantGreeting));
      }
      _scrollToLatest();
      return;
    }

    // 2. Client-Side Token Cache Check (TTL: 10 minutes)
    final cacheKey = text.toLowerCase().trim();
    final cached = _clientQueryCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) < const Duration(minutes: 10) &&
        !makeInvoiceDraft) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _messages.add(_ChatEntry(
          text: cached.response.answer,
          isUser: false,
          isCached: true,
          chatResponse: cached.response,
        ));
      });
      unawaited(_persistChatHistory());
      if (_autoSpeak) {
        unawaited(_speakText(cached.response.answer));
      }
      _scrollToLatest();
      return;
    }

    // 3. Backend Call (with server-side token cache enabled)
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
        if (_autoSpeak) {
          unawaited(_speakText(response.message));
        }
      } else {
        final response = await _repository.sendMessage(text);
        // Cache read-only queries client-side to save tokens on repeat questions
        if (response.readOnly && response.pendingCommandId == null) {
          _clientQueryCache[cacheKey] = _CachedItem(
            response: response,
            timestamp: DateTime.now(),
          );
        }
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
      // Invalidate query cache when a modifying action is executed
      _clientQueryCache.clear();

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
    _clientQueryCache.clear();
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
      backgroundColor: _kSlateBg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: Colors.white,
        shadowColor: Colors.black12,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kPrimary, _kNavyDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _kPrimary.withValues(alpha: 0.3),
                    offset: const Offset(0, 3),
                    blurRadius: 8,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Invoicely AI Assistant',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _kTextDark,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Cache & Engine Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _kGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _kGreen.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt_rounded, size: 11, color: _kGreen),
                            SizedBox(width: 2),
                            Text(
                              'Cache Active',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _kGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _isSpeaking
                        ? 'Speaking with natural voice…'
                        : _isListening
                            ? 'Listening live… auto-sends on pause'
                            : 'Indian English & Hinglish • Zero-token cache',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isSpeaking
                          ? _kPrimary
                          : _isListening
                              ? Colors.red
                              : _kTextMuted,
                      fontWeight: _isSpeaking || _isListening
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Voice Toggle
          IconButton(
            tooltip: _autoSpeak ? 'Mute voice answers' : 'Enable voice answers',
            onPressed: () {
              if (_isSpeaking) _stopSpeaking();
              setState(() => _autoSpeak = !_autoSpeak);
            },
            icon: Icon(
              _autoSpeak ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: _autoSpeak ? _kPrimary : _kTextMuted,
            ),
          ),
          if (_isSpeaking)
            IconButton(
              tooltip: 'Stop speaking',
              onPressed: _stopSpeaking,
              icon: const Icon(Icons.stop_circle_rounded, color: Colors.redAccent),
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
                    Text('Clear conversation & cache'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Quick Suggestion Chips Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final s in _suggestions)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: _isLoading || _confirmingCommandId != null
                                  ? null
                                  : () => _submit(prompt: s['query']),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _kChipBg,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _kChipBorder, width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(s['icon']!, style: const TextStyle(fontSize: 12)),
                                    const SizedBox(width: 6),
                                    Text(
                                      s['label']!,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: _kTextDark,
                                      ),
                                    ),
                                  ],
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

            // Chat Messages Stream
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _kCardBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
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
                                  color: _kPrimary,
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

            // Live Voice Panel with Audio Waveform & Auto-Submit Indicator
            if (_showSpeechLivePanel)
              Container(
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _isListening ? Colors.red.shade300 : _kCardBorder,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isListening
                          ? Colors.red.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Animated pulsing mic indicator
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _isListening ? Colors.red : _kPrimary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isListening
                              ? 'Live Voice Listening…'
                              : 'Speech Captured',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _isListening ? Colors.red : _kNavyDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _kPrimary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '⚡ Auto-sends on pause',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _kPrimary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            _silenceTimer?.cancel();
                            if (_isListening) _speech.stop();
                            setState(() {
                              _showSpeechLivePanel = false;
                              _isListening = false;
                            });
                          },
                          child: const Icon(Icons.close, size: 18, color: _kTextMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Live spoken text container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: _kSlateBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kCardBorder),
                      ),
                      child: Text(
                        _liveSpokenText.isEmpty
                            ? 'Speak now in Hindi or English… I will transcribe and send automatically.'
                            : _liveSpokenText,
                        style: TextStyle(
                          fontSize: 14,
                          color: _liveSpokenText.isEmpty ? _kTextMuted : _kTextDark,
                          fontStyle: _liveSpokenText.isEmpty
                              ? FontStyle.italic
                              : FontStyle.normal,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Polish prompt button
                        OutlinedButton.icon(
                          onPressed: _liveSpokenText.trim().isEmpty
                              ? null
                              : () {
                                  final polished = _refineSpeechForAi(_liveSpokenText);
                                  setState(() {
                                    _liveSpokenText = polished;
                                    _inputController.text = polished;
                                  });
                                },
                          icon: const Icon(Icons.auto_fix_high, size: 14, color: _kPrimary),
                          label: const Text(
                            'Refine Prompt',
                            style: TextStyle(fontSize: 12, color: _kPrimary, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _kPrimary),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const Spacer(),
                        // Send immediately button
                        FilledButton(
                          onPressed: _liveSpokenText.trim().isEmpty
                              ? null
                              : () => _autoSubmitSpokenText(_liveSpokenText),
                          style: FilledButton.styleFrom(
                            backgroundColor: _kPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Send Now →',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Modern Bottom Composer with Invoice Draft toggle, text field, Send button, Voice mic
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
    this.isCached = false,
    this.chatResponse,
    this.invoiceDraft,
  });

  final String text;
  final bool isUser;
  final bool isCached;
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
      // Sleek royal blue user bubble with modern curvature
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.85,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kPrimary, Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withValues(alpha: 0.2),
                offset: const Offset(0, 3),
                blurRadius: 8,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SelectableText(
            entry.text,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ),
      );
    }

    // AI message: Modern white card with Navy header, cached token badge, action button, etc.
    final response = entry.chatResponse;
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
            // AI Header row
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _kNavyDark,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: _kNavyDark.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Business Insights & Action',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: _kTextDark,
                            ),
                          ),
                          if (entry.isCached) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _kGreen.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: _kGreen.withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bolt_rounded, size: 11, color: _kGreen),
                                  SizedBox(width: 2),
                                  Text(
                                    'Instant (0 Tokens)',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: _kGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        'Verified from real-time workspace records',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: _kTextMuted.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Formatted AI Response Body
            if (entry.text.isNotEmpty) ...[
              _FormattedAiMessage(text: entry.text),
              const SizedBox(height: 10),
            ],

            // Pending Action Confirmation Card
            if (pendingId != null) ...[
              _buildPendingAction(context, pendingId),
              const SizedBox(height: 10),
            ],

            // Invoice Draft Card
            if (draft != null) ...[
              _InvoiceDraftCard(response: draft),
              const SizedBox(height: 10),
            ],

            // Grounded sources tags & Action buttons
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
                              color: _kChipBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _kChipBorder, width: 0.8),
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
                    tooltip: 'Read aloud (Indian Accent / Hinglish)',
                    onPressed: () => onSpeak!(entry.text),
                    icon: const Icon(Icons.volume_up_outlined, color: _kPrimary),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingAction(BuildContext context, String commandId) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
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
                    Icon(Icons.check_circle_rounded, color: _kGreen, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Action Confirmed & Executed Successfully',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _kGreen,
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
                      backgroundColor: _kPrimary,
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
}

class _FormattedAiMessage extends StatelessWidget {
  const _FormattedAiMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final lines = text.trim().split('\n');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      if (line.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            line.substring(4).trim(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _kTextDark,
            ),
          ),
        ));
      } else if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Text(
            line.substring(3).trim(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _kNavyDark,
            ),
          ),
        ));
      } else if (line.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(
            line.substring(2).trim(),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: _kNavyDark,
            ),
          ),
        ));
      } else if (line.startsWith('• ') || line.startsWith('- ') || line.startsWith('* ')) {
        final bulletText = line.substring(2).trim();
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 4, top: 3, bottom: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 7, right: 8),
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: _kPrimary,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: _buildRichSpans(bulletText),
              ),
            ],
          ),
        ));
      } else if (RegExp(r'^\d+\.\s+').hasMatch(line)) {
        final match = RegExp(r'^\d+\.\s+').firstMatch(line)!;
        final numPrefix = line.substring(0, match.end).trim();
        final bodyText = line.substring(match.end).trim();
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 4, top: 3, bottom: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$numPrefix ',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _kPrimary,
                  fontSize: 14,
                ),
              ),
              Expanded(
                child: _buildRichSpans(bodyText),
              ),
            ],
          ),
        ));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: _buildRichSpans(line),
        ));
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kCardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets,
      ),
    );
  }

  static Widget _buildRichSpans(String text) {
    final spans = <TextSpan>[];
    final pattern = RegExp(r'(\*\*.*?\*\*|\*.*?\*|`.*?`)');
    int lastMatchEnd = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: const TextStyle(
            fontSize: 14.2,
            color: _kTextDark,
            height: 1.45,
          ),
        ));
      }
      final matchedText = match.group(0)!;
      if (matchedText.startsWith('**') && matchedText.endsWith('**')) {
        spans.add(TextSpan(
          text: matchedText.substring(2, matchedText.length - 2),
          style: const TextStyle(
            fontSize: 14.2,
            fontWeight: FontWeight.bold,
            color: _kTextDark,
            height: 1.45,
          ),
        ));
      } else if (matchedText.startsWith('*') && matchedText.endsWith('*')) {
        spans.add(TextSpan(
          text: matchedText.substring(1, matchedText.length - 1),
          style: const TextStyle(
            fontSize: 14.2,
            fontStyle: FontStyle.italic,
            color: _kTextDark,
            height: 1.45,
          ),
        ));
      } else if (matchedText.startsWith('`') && matchedText.endsWith('`')) {
        spans.add(TextSpan(
          text: matchedText.substring(1, matchedText.length - 1),
          style: const TextStyle(
            fontSize: 13.5,
            fontFamily: 'monospace',
            backgroundColor: Color(0xFFF1F5F9),
            color: _kPrimary,
            height: 1.45,
          ),
        ));
      }
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: const TextStyle(
          fontSize: 14.2,
          color: _kTextDark,
          height: 1.45,
        ),
      ));
    }

    return SelectableText.rich(
      TextSpan(children: spans),
    );
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
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kCardBorder),
        ),
        child: SelectableText(response.message),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded, color: _kPrimary, size: 20),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
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

// Redesigned Modern Composer with Voice Mic after Send Arrow
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
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: widget.invoiceDraftMode ? _kPrimary : _kCardBorder,
                width: widget.invoiceDraftMode ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  offset: const Offset(0, 2),
                  blurRadius: 10,
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Invoice Draft Mode Toggle
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
                    color: widget.invoiceDraftMode ? _kPrimary : _kTextMuted,
                  ),
                ),

                // Text Field
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
                        horizontal: 8,
                        vertical: 10,
                      ),
                      border: InputBorder.none,
                      counterText: '',
                      hintText: widget.invoiceDraftMode
                          ? 'Describe invoice to draft (e.g. ₹50,000 for Acme)…'
                          : 'Ask anything in Hindi, Hinglish or English…',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: _kTextDark,
                    ),
                  ),
                ),

                // Send Button Arrow
                GestureDetector(
                  onTap: (!widget.isLoading && _hasText)
                      ? () => widget.onSubmit()
                      : null,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _hasText && !widget.isLoading
                          ? _kPrimary
                          : _kPrimary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: _kPrimary.withValues(alpha: 0.25),
                          offset: const Offset(0, 2),
                          blurRadius: 6,
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
                            size: 20,
                            color: Colors.white,
                          ),
                  ),
                ),
                const SizedBox(width: 6),

                // Voice Mic Icon Positioned AFTER Send Arrow
                IconButton(
                  tooltip: widget.isListening
                      ? 'Listening… tap to stop'
                      : 'Voice input (Hindi & English)',
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: widget.isLoading ? null : () => widget.onToggleListening(),
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: widget.isListening ? Colors.red : _kChipBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.isListening ? Colors.red : _kChipBorder,
                      ),
                    ),
                    child: Icon(
                      widget.isListening ? Icons.mic : Icons.mic_none_rounded,
                      size: 18,
                      color: widget.isListening ? Colors.white : _kNavyDark,
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
