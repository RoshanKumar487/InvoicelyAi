import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../shared/widgets/app_card.dart';
import '../data/ai_assistant_models.dart';
import '../data/ai_assistant_repository.dart';

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
    'Summarize my recent invoices',
    'What expenses were recorded recently?',
    'Which invoices are overdue?',
    'What is our total collected revenue?',
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
    // Strip markdown formatting characters for clean spoken speech
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
      final saved = await _historyStorage.readValue(_historyKey);
      if (saved == null) {
        if (mounted) setState(() => _historyReady = true);
        return;
      }
      final decoded = jsonDecode(saved);
      if (decoded is! List<Object?>) {
        throw const FormatException('Saved AI chat history is invalid.');
      }
      final restored = <_ChatEntry>[];
      for (final value in decoded.take(100)) {
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
              _errorMessage = 'Voice input failed: ${error.errorMsg}';
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
        setState(() => _errorMessage = 'Voice input is unavailable: $error');
      }
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
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
      });
      await _speech.listen(
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(minutes: 1),
          pauseFor: const Duration(seconds: 5),
        ),
        onResult: (result) {
          if (!mounted) return;
          setState(() {
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
          _errorMessage = 'Could not start voice input: $error';
        });
      }
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

    final makeInvoiceDraft = _invoiceDraftMode;
    setState(() {
      _errorMessage = null;
      _isLoading = true;
      _invoiceDraftMode = false;
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
    if (_isLoading ||
        _confirmingCommandId != null ||
        _confirmedCommands.contains(commandId)) {
      return;
    }
    setState(() {
      _confirmingCommandId = commandId;
      _errorMessage = null;
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
      _scrollToLatest();
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = _errorText(error));
      }
    } finally {
      if (mounted) {
        setState(() => _confirmingCommandId = null);
      }
    }
  }

  Future<void> _clearChat() async {
    if (_isLoading || _confirmingCommandId != null) return;
    setState(() {
      _messages.clear();
      _confirmedCommands.clear();
      _errorMessage = null;
      _invoiceDraftMode = false;
    });
    try {
      await _historyStorage.deleteValue(_historyKey);
    } catch (error) {
      if (mounted) {
        setState(() =>
            _errorMessage = 'Could not delete saved chat history: $error');
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

  static IconData _getSuggestionIcon(String suggestion) {
    final lower = suggestion.toLowerCase();
    if (lower.contains('revenue') || lower.contains('collected')) {
      return Icons.trending_up_rounded;
    }
    if (lower.contains('overdue')) {
      return Icons.warning_amber_rounded;
    }
    if (lower.contains('expense')) {
      return Icons.receipt_long_rounded;
    }
    return Icons.description_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10A37F), Color(0xFF0D8A6C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Invoicely AI',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10A37F),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _isSpeaking
                          ? 'Speaking…'
                          : _isListening
                              ? 'Listening…'
                              : 'Online · Enterprise CFO',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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
              color: _autoSpeak ? const Color(0xFF10A37F) : null,
            ),
          ),
          if (_isSpeaking)
            IconButton(
              tooltip: 'Stop speaking',
              onPressed: _stopSpeaking,
              icon: const Icon(Icons.stop_circle_outlined, color: Colors.redAccent),
            ),
          IconButton(
            tooltip: 'Clear chat',
            onPressed:
                _isLoading || _confirmingCommandId != null ? null : _clearChat,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome, color: colors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Your business, in context',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ask about business records you can access. Answers show their grounded sources and are read-only unless you review and confirm a proposed action.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Chat history is stored securely on this account. Confirmations are not restored when reopening chat.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (_messages.isEmpty) ...[
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF10A37F), Color(0xFF0E7A60)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10A37F).withValues(alpha: 0.3),
                                  offset: const Offset(0, 4),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'How can I help you today?',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ask about invoices, expenses, revenue, or propose actions.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Suggested prompts',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 10),
                    for (final suggestion in _suggestions) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: _isLoading || _confirmingCommandId != null
                              ? null
                              : () => _submit(prompt: suggestion),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _getSuggestionIcon(suggestion),
                                  size: 16,
                                  color: const Color(0xFF10A37F),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    suggestion,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: colors.onSurface,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 12,
                                  color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                  for (final message in _messages) ...[
                    const SizedBox(height: 12),
                    _MessageBubble(
                      entry: message,
                      confirmingCommandId: _confirmingCommandId,
                      confirmedCommands: _confirmedCommands,
                      onConfirm: _confirmCommand,
                      onSpeak: _speakText,
                    ),
                  ],
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AppCard(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Thinking…'),
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
  });

  final _ChatEntry entry;
  final String? confirmingCommandId;
  final Set<String> confirmedCommands;
  final ValueChanged<String> onConfirm;
  final ValueChanged<String>? onSpeak;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final response = entry.chatResponse;
    final content = <Widget>[];
    if (!entry.isUser && response != null) {
      content.add(_responseMetadata(response));
    }
    content.add(SelectableText(entry.text));
    if (response != null && response.groundedSources.isNotEmpty) {
      content.add(
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: _GroundedSources(sources: response.groundedSources),
        ),
      );
    }
    final pendingId = response?.pendingCommandId;
    if (pendingId != null) {
      content.add(_pendingAction(context, pendingId));
    }
    final draft = entry.invoiceDraft;
    if (draft != null) {
      content.add(
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: _InvoiceDraftCard(response: draft),
        ),
      );
    }

    Widget bubbleCard = Container(
      decoration: BoxDecoration(
        color: entry.isUser
            ? const Color(0xFF2563EB)
            : (Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E293B)
                : Colors.white),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(entry.isUser ? 18 : 4),
          bottomRight: Radius.circular(entry.isUser ? 4 : 18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
        border: Border.all(
          color: entry.isUser
              ? Colors.transparent
              : (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0)),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...content,
          if (!entry.isUser)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                    icon: Icon(
                      Icons.copy_rounded,
                      color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  if (onSpeak != null)
                    IconButton(
                      iconSize: 16,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      tooltip: 'Read aloud',
                      onPressed: () => onSpeak!(entry.text),
                      icon: Icon(
                        Icons.volume_up_outlined,
                        color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            entry.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!entry.isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8, top: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10A37F), Color(0xFF0E7A60)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10A37F).withValues(alpha: 0.25),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.78,
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  textTheme: Theme.of(context).textTheme.copyWith(
                        bodyMedium: TextStyle(
                          color: entry.isUser ? Colors.white : null,
                          fontSize: 14.5,
                          height: 1.45,
                        ),
                      ),
                ),
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: entry.isUser
                        ? Colors.white
                        : Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 14.5,
                    height: 1.45,
                  ),
                  child: bubbleCard,
                ),
              ),
            ),
          ),
          if (entry.isUser) ...[
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(left: 8, top: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2B3548),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    offset: const Offset(0, 1.5),
                    blurRadius: 3,
                  ),
                ],
              ),
              child: const Icon(
                Icons.person,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _responseMetadata(AiChatResponse response) {
    final String status;
    final IconData icon;
    if (response.resourceId != null) {
      status = 'Action complete';
      icon = Icons.check_circle_outline;
    } else if (response.readOnly) {
      status = 'Read-only answer';
      icon = Icons.visibility_outlined;
    } else {
      status = 'Action proposal';
      icon = Icons.edit_note_outlined;
    }

    final badges = <Widget>[_InfoBadge(icon: icon, label: status)];
    final actionType = response.actionType;
    if (actionType != null) {
      badges.add(
        _InfoBadge(
          icon: Icons.bolt_outlined,
          label: _formatAction(actionType),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: badges,
      ),
    );
  }

  Widget _pendingAction(BuildContext context, String commandId) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nothing is saved until you confirm this action.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          confirmedCommands.contains(commandId)
              ? const _InfoBadge(
                  icon: Icons.check_circle_outline,
                  label: 'Confirmed',
                )
              : FilledButton.tonalIcon(
                  onPressed: confirmingCommandId == null
                      ? () => onConfirm(commandId)
                      : null,
                  icon: confirmingCommandId == commandId
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                    confirmingCommandId == commandId
                        ? 'Confirming…'
                        : 'Confirm action',
                  ),
                ),
        ],
      ),
    );
  }

  static String _formatAction(String action) {
    return action
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}

class _GroundedSources extends StatelessWidget {
  const _GroundedSources({required this.sources});

  final List<String> sources;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 20),
        Text(
          'Grounded sources',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        for (final source in sources)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.source_outlined, size: 15),
                ),
                const SizedBox(width: 6),
                Expanded(child: Text(source)),
              ],
            ),
          ),
      ],
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
      return const _InfoBadge(
        icon: Icons.info_outline,
        label: 'No invoice draft was returned',
      );
    }
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long_outlined, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('Invoice draft · not saved')),
            ],
          ),
          const SizedBox(height: 10),
          _DraftField(label: 'Client', value: invoice.clientName),
          if (invoice.clientCompany.isNotEmpty)
            _DraftField(label: 'Company', value: invoice.clientCompany),
          _DraftField(
            label: 'Invoice',
            value: invoice.invoiceNumber.isEmpty
                ? 'Not assigned'
                : invoice.invoiceNumber,
          ),
          _DraftField(
            label: 'Dates',
            value:
                '${_orUnset(invoice.issueDate)} → ${_orUnset(invoice.dueDate)}',
          ),
          _DraftField(
            label: 'Currency',
            value: invoice.currencyCode,
          ),
          if (invoice.itemsJson.isNotEmpty && invoice.itemsJson != '[]')
            _DraftField(label: 'Line items (JSON)', value: invoice.itemsJson),
          if (invoice.taxRate != 0)
            _DraftField(label: 'Tax rate', value: '${invoice.taxRate}%'),
          if (invoice.discountPercent != 0)
            _DraftField(
              label: 'Discount',
              value: '${invoice.discountPercent}%',
            ),
          if (invoice.shippingFee != 0)
            _DraftField(
              label: 'Shipping',
              value: '${invoice.currencyCode} ${invoice.shippingFee}',
            ),
          _DraftField(label: 'Status', value: invoice.status),
          if (invoice.notes.isNotEmpty)
            _DraftField(label: 'Notes', value: invoice.notes),
          if (invoice.terms.isNotEmpty)
            _DraftField(label: 'Terms', value: invoice.terms),
          const SizedBox(height: 4),
          Text(
            'Review these editable details in the invoice workflow before saving.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  static String _orUnset(String value) => value.isEmpty ? 'Not set' : value;
}

class _DraftField extends StatelessWidget {
  const _DraftField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, this.onDismiss});

  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: colors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.error),
            ),
          ),
          if (onDismiss != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: InkWell(
                onTap: onDismiss,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 18, color: colors.error),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isListening)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Listening to voice… speak now',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              // ChatGPT pill input container
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: widget.invoiceDraftMode
                        ? const Color(0xFF10A37F)
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                    width: widget.invoiceDraftMode ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                      offset: const Offset(0, 3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Invoice draft quick mode toggle
                    IconButton(
                      tooltip: widget.invoiceDraftMode
                          ? 'Exit invoice draft mode'
                          : 'Prepare invoice draft mode',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      onPressed: widget.isLoading
                          ? null
                          : () => widget.onInvoiceDraftModeChanged(!widget.invoiceDraftMode),
                      icon: Icon(
                        widget.invoiceDraftMode
                            ? Icons.receipt_long
                            : Icons.receipt_long_outlined,
                        size: 20,
                        color: widget.invoiceDraftMode
                            ? const Color(0xFF10A37F)
                            : colors.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                    // Text input
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
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
                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            counterText: '',
                            hintText: widget.invoiceDraftMode
                                ? 'Describe invoice to draft (e.g. Acme Corp 20 hours)…'
                                : 'Ask Invoicely AI or say a command…',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                          ),
                          style: const TextStyle(fontSize: 14.5),
                        ),
                      ),
                    ),
                    // Voice mic button
                    IconButton(
                      tooltip: widget.isListening ? 'Stop voice input' : 'Voice input',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      onPressed: widget.isLoading ? null : () => widget.onToggleListening(),
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: widget.isListening
                              ? Colors.red
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.isListening ? Icons.mic : Icons.mic_none_rounded,
                          size: 20,
                          color: widget.isListening
                              ? Colors.white
                              : (widget.speechAvailable
                                  ? colors.onSurfaceVariant.withValues(alpha: 0.8)
                                  : colors.onSurfaceVariant.withValues(alpha: 0.3)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // ChatGPT-style circular send button
                    GestureDetector(
                      onTap: (!widget.isLoading && _hasText)
                          ? () => widget.onSubmit()
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 34,
                        height: 34,
                        margin: const EdgeInsets.only(bottom: 2, right: 2),
                        decoration: BoxDecoration(
                          color: _hasText && !widget.isLoading
                              ? const Color(0xFF10A37F)
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          shape: BoxShape.circle,
                          boxShadow: _hasText && !widget.isLoading
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF10A37F).withValues(alpha: 0.35),
                                    offset: const Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                        child: widget.isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                Icons.arrow_upward_rounded,
                                size: 18,
                                color: _hasText
                                    ? Colors.white
                                    : (isDark
                                        ? const Color(0xFF64748B)
                                        : const Color(0xFF94A3B8)),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.invoiceDraftMode)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 13,
                        color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Invoice draft mode is active: Response will format as a complete draft.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
