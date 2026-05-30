import 'dart:io';

import 'package:e_waste/app/widgets/premium_ui.dart';
import 'package:e_waste/app/widgets/theme_toggle_icon_button.dart';
import 'package:e_waste/pages/ai/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_speech/flutter_speech.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _chatMessages = [];

  SpeechRecognition? _speech;
  bool _speechRecognitionAvailable = false;
  bool _isListening = false;
  bool _isInitializing = false;
  bool _isLoading = false;
  bool _showInfoPanel = false;
  String _transcription = '';

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _cleanupSpeechRecognition();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _initSpeechRecognizer() async {
    if (_isInitializing) {
      return;
    }

    setState(() {
      _isInitializing = true;
    });

    try {
      _speech = SpeechRecognition();

      _speech!.setAvailabilityHandler(
        (bool result) => setState(() => _speechRecognitionAvailable = result),
      );

      _speech!.setRecognitionStartedHandler(
        () => setState(() => _isListening = true),
      );

      _speech!.setRecognitionResultHandler((String text) {
        setState(() {
          _transcription = text;
          _messageController.text = text;
        });
      });

      _speech!.setRecognitionCompleteHandler((String result) {
        setState(() {
          _isListening = false;
          if (result.isNotEmpty) {
            _transcription = result;
            _messageController.text = result;
          }
        });
      });

      _speech!.setErrorHandler(() {
        _cleanupSpeechRecognition();
      });

      final bool available = await _speech!.activate('en_US');
      if (!mounted) {
        return;
      }

      setState(() {
        _speechRecognitionAvailable = available;
        _isInitializing = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isInitializing = false;
      });
      _cleanupSpeechRecognition();
    }
  }

  void _cleanupSpeechRecognition() {
    final speech = _speech;
    _speech = null;

    if (speech != null && _isListening && !_isInitializing) {
      speech.cancel().catchError((_) {});
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isListening = false;
      _speechRecognitionAvailable = false;
      _isInitializing = false;
    });
  }

  void _toggleListening() {
    if (_isInitializing) {
      return;
    }

    if (_speech == null) {
      _initSpeechRecognizer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing voice input...')),
      );
      return;
    }

    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _startListening() {
    if (_speech == null || !_speechRecognitionAvailable) {
      _initSpeechRecognizer();
      return;
    }

    setState(() {
      _transcription = '';
    });

    _speech!.listen().catchError((_) {
      _cleanupSpeechRecognition();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice input is unavailable right now.')),
        );
      }
    });
  }

  void _stopListening() {
    if (_speech == null || !_isListening) {
      return;
    }

    _speech!.stop().catchError((_) {
      _cleanupSpeechRecognition();
    });
  }

  void _cancelListening() {
    if (_speech == null || !_isListening) {
      return;
    }

    _speech!.cancel().then((_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isListening = false;
        _transcription = '';
        _messageController.clear();
      });
    }).catchError((_) {
      _cleanupSpeechRecognition();
    });
  }

  Future<void> _sendMessage() async {
    final String message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) {
      return;
    }

    setState(() {
      _chatMessages.add({
        'isUser': true,
        'message': message,
      });
      _isLoading = true;
      _transcription = '';
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final String response = await ApiService.getAIResponse(message);
      if (!mounted) {
        return;
      }

      setState(() {
        _chatMessages.add({
          'isUser': false,
          'message': response,
        });
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _chatMessages.add({
          'isUser': false,
          'message': 'Sorry, I could not process that request. Please try again in a moment.',
        });
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);

      if (image == null) {
        return;
      }

      final File file = File(image.path);
      setState(() {
        _chatMessages.add({
          'isUser': true,
          'message': 'I am sending a device image for analysis.',
          'imageFile': file,
        });
        _isLoading = true;
      });
      _scrollToBottom();

      final String response = await ApiService.getAIResponseWithImage(file);
      if (!mounted) {
        return;
      }

      setState(() {
        _chatMessages.add({
          'isUser': false,
          'message': response,
        });
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _chatMessages.add({
          'isUser': false,
          'message': 'Sorry, I could not process that image. Please try again or describe the device instead.',
        });
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _showImageSourceOptions() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: PremiumSurface(
              borderRadius: 28,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attach a photo',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Send a device image for recycling, repair, or disposal guidance.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.photo_camera_outlined, color: scheme.primary),
                    title: const Text('Take a photo'),
                    subtitle: const Text('Use the camera for a live device shot.'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  const SizedBox(height: 6),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.photo_library_outlined, color: scheme.primary),
                    title: const Text('Choose from gallery'),
                    subtitle: const Text('Pick an existing photo from the device.'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  void _clearConversation() {
    setState(() {
      _chatMessages.clear();
      _messageController.clear();
      _transcription = '';
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _sendPrompt(String text) {
    _messageController.text = text;
    _sendMessage();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return PremiumShell(
      appBar: AppBar(
        title: const Text('EcoBot AI'),
        actions: [
          IconButton(
            tooltip: _showInfoPanel ? 'Hide info' : 'Show info',
            onPressed: () {
              setState(() {
                _showInfoPanel = !_showInfoPanel;
              });
            },
            icon: Icon(_showInfoPanel ? Icons.info : Icons.info_outline),
          ),
          const ThemeToggleIconButton(),
          IconButton(
            tooltip: 'Clear conversation',
            onPressed: _chatMessages.isEmpty ? null : _clearConversation,
            icon: const Icon(Icons.restart_alt, color: Colors.white),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth > 1100 ? 980 : constraints.maxWidth,
                      ),
                      child: ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: _showInfoPanel
                                ? Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: PremiumSurface(
                                      key: const ValueKey('info-panel'),
                                      borderRadius: 28,
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF123447), Color(0xFF2C8C6B)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                height: 54,
                                                width: 54,
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.14),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 28),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Text(
                                                  'EcoBot AI',
                                                  style: theme.textTheme.headlineSmall?.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 14),
                                          Text(
                                            'Ask about recycling, repair, or safe disposal. Use text, voice, or a photo.',
                                            style: theme.textTheme.bodyLarge?.copyWith(
                                              color: Colors.white.withValues(alpha: 0.92),
                                              height: 1.45,
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: const [
                                              _CapabilityChip(icon: Icons.mic_none_rounded, label: 'Voice input'),
                                              _CapabilityChip(icon: Icons.photo_camera_outlined, label: 'Photo check'),
                                              _CapabilityChip(icon: Icons.travel_explore_outlined, label: 'Web help'),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          PremiumSectionHeader(
                            title: 'Suggested prompts',
                            subtitle: 'Tap one to start a conversation fast.',
                            trailing: TextButton.icon(
                              onPressed: _chatMessages.isEmpty ? null : _clearConversation,
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Reset'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _PromptChip(
                                label: 'How should I recycle an old iPhone?',
                                onTap: () => _sendPrompt('How should I recycle an old iPhone?'),
                              ),
                              _PromptChip(
                                label: 'What parts of a laptop are hazardous?',
                                onTap: () => _sendPrompt('What parts of a laptop are hazardous?'),
                              ),
                              _PromptChip(
                                label: 'Can I repair a cracked phone screen?',
                                onTap: () => _sendPrompt('Can I repair a cracked phone screen?'),
                              ),
                              _PromptChip(
                                label: 'Where should I dispose of batteries?',
                                onTap: () => _sendPrompt('Where should I dispose of batteries?'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_chatMessages.isEmpty)
                            PremiumEmptyState(
                              icon: Icons.forum_outlined,
                              title: 'Start a premium chat session',
                              subtitle:
                                  'Ask a question, attach a device photo, or use voice input to get practical recycling and repair advice.',
                              compact: true,
                              action: Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  FilledButton.icon(
                                    onPressed: () => _sendPrompt('How do I recycle an old smartphone safely?'),
                                    icon: const Icon(Icons.play_arrow),
                                    label: const Text('Try a question'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: _speechRecognitionAvailable || _isInitializing ? _toggleListening : _initSpeechRecognizer,
                                    icon: Icon(_isListening ? Icons.mic_off : Icons.mic_none),
                                    label: Text(_isListening ? 'Stop voice' : 'Enable voice'),
                                  ),
                                ],
                              ),
                            )
                          else
                            ..._chatMessages.map(_buildMessageTile),
                          if (_isLoading) ...[
                            const SizedBox(height: 12),
                            PremiumSurface(
                              borderRadius: 20,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.3,
                                      valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'EcoBot is composing a context-aware answer...',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isListening) _buildListeningIndicator(),
            _buildComposer(context),
          ],
        ),
      ),
    );
  }

  Widget _buildListeningIndicator() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: PremiumSurface(
        borderRadius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        gradient: LinearGradient(
          colors: [
            Colors.red.withValues(alpha: 0.18),
            scheme.surfaceContainerHighest.withValues(alpha: 0.95),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic, color: Colors.redAccent, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _transcription.isEmpty ? 'Listening for your next question...' : _transcription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Stop voice input',
              onPressed: _stopListening,
              icon: const Icon(Icons.send_rounded),
            ),
            IconButton(
              tooltip: 'Cancel voice input',
              onPressed: _cancelListening,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageTile(Map<String, dynamic> message) {
    final bool isUser = message['isUser'] as bool? ?? false;
    final String messageText = message['message']?.toString() ?? '';
    final File? imageFile = message['imageFile'] as File?;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bubbleGradient = isUser
        ? LinearGradient(
            colors: [
              scheme.primary,
              scheme.primary.withValues(alpha: isDark ? 0.88 : 0.82),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [
              scheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.94 : 0.98),
              scheme.surfaceContainerLow.withValues(alpha: isDark ? 0.9 : 0.98),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PremiumSurface(
            borderRadius: 24,
            padding: const EdgeInsets.all(14),
            gradient: bubbleGradient,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 38,
                      width: 38,
                      decoration: BoxDecoration(
                        color: isUser ? Colors.white.withValues(alpha: 0.18) : scheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isUser ? Icons.person_outline : Icons.smart_toy_outlined,
                        color: isUser ? Colors.white : scheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isUser ? 'You' : 'EcoBot',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isUser ? Colors.white : scheme.onSurface,
                            ),
                          ),
                          Text(
                            isUser ? 'Your request' : 'AI guidance',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: isUser ? Colors.white.withValues(alpha: 0.85) : scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (imageFile != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.file(
                      imageFile,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                if (imageFile != null) const SizedBox(height: 12),
                if (isUser)
                  Text(
                    messageText,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      height: 1.45,
                    ),
                  )
                else
                  MarkdownBody(
                    data: messageText,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurface,
                        height: 1.45,
                      ),
                      strong: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                      em: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurface,
                        fontStyle: FontStyle.italic,
                      ),
                      a: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                      h1: theme.textTheme.titleLarge?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                      h2: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                      h3: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                      listBullet: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurface,
                        height: 1.45,
                      ),
                    ),
                    onTapLink: (text, href, title) {
                      if (href != null) {
                        _launchURL(href);
                      }
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComposer(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: PremiumSurface(
        borderRadius: 26,
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton.filledTonal(
              tooltip: 'Attach an image',
              onPressed: _isLoading || _isListening ? null : _showImageSourceOptions,
              icon: const Icon(Icons.photo_camera_outlined),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: _isListening ? 'Stop listening' : 'Use voice input',
              onPressed: _isLoading || _isInitializing ? null : _toggleListening,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                child: Icon(
                  _isListening ? Icons.mic : Icons.keyboard_voice_outlined,
                  key: ValueKey<bool>(_isListening),
                  color: _isListening ? Colors.redAccent : scheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                enabled: !_isLoading && !_isListening,
                style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Ask here',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: scheme.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: scheme.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: scheme.primary, width: 1.4),
                  ),
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.72),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _isLoading
                  ? SizedBox(
                      key: const ValueKey('loading'),
                      height: 52,
                      width: 52,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                        ),
                      ),
                    )
                  : FilledButton(
                      key: const ValueKey('send'),
                      onPressed: _isListening ? null : _sendMessage,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(52, 52),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Icon(Icons.send_rounded),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapabilityChip extends StatelessWidget {
  const _CapabilityChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  const _PromptChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ActionChip(
      onPressed: onTap,
      avatar: Icon(Icons.auto_awesome_outlined, size: 18, color: scheme.primary),
      label: Text(label),
      labelStyle: TextStyle(
        color: scheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: scheme.surfaceContainerHighest,
      side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.65)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}