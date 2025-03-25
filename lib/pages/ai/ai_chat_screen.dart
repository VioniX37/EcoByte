import 'dart:io';
import 'package:e_waste/pages/ai/api_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_speech/flutter_speech.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _chatMessages = [];
  bool _isLoading = false;
  final Color _primaryColor = const Color(0xFF1A5269);
  final Color _backgroundColor = const Color(0xFFE5F5F0);

  // Speech recognition variables
  SpeechRecognition? _speech;
  bool _speechRecognitionAvailable = false;
  bool _isListening = false;
  String _transcription = '';
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _initSpeechRecognizer();
  }

  // Initialize the speech recognizer
  void _initSpeechRecognizer() async {
    if (_isInitializing) return;

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

      _speech!.setRecognitionResultHandler(
        (String text) => setState(() {
          _transcription = text;
          _messageController.text = _transcription;
        }),
      );

      _speech!.setRecognitionCompleteHandler((String result) {
        setState(() {
          _isListening = false;
          if (result.isNotEmpty) {
            _transcription = result;
            _messageController.text = _transcription;
          }
        });
      });

      _speech!.setErrorHandler(() {
        print('Speech recognition error');
        _cleanupSpeechRecognition();
        // Auto-reinitialize on error
        Future.delayed(const Duration(milliseconds: 300), () {
          _initSpeechRecognizer();
        });
      });

      bool available = await _speech!.activate('en_US');
      setState(() {
        _speechRecognitionAvailable = available;
        _isInitializing = false;
      });

      print('Speech recognition initialized: $available');
    } catch (e) {
      print('Error initializing speech recognition: $e');
      setState(() {
        _isInitializing = false;
      });
      _cleanupSpeechRecognition();
      // Auto-reinitialize after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        _initSpeechRecognizer();
      });
    }
  }

  // Clean up speech recognition resources
  void _cleanupSpeechRecognition() {
    if (_speech != null) {
      if (_isListening) {
        _speech!.cancel().catchError((error) {
          print('Error cancelling speech recognition: $error');
        });
      }
      _speech = null;
    }

    setState(() {
      _isListening = false;
      _speechRecognitionAvailable = false;
    });
  }

  // Toggle speech recognition on/off
  void _toggleListening() {
    if (_isInitializing) return;

    if (_speech == null) {
      _initSpeechRecognizer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Initializing speech recognition...')),
      );
      return;
    }

    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  // Start speech recognition
  void _startListening() {
    if (_speech == null || !_speechRecognitionAvailable) {
      _initSpeechRecognizer();
      return;
    }

    setState(() => _transcription = '');
    _speech!.listen().then((result) {
      print('Speech recognition started');
    }).catchError((error) {
      print('Error starting speech recognition: $error');
      _cleanupSpeechRecognition();
      Future.delayed(const Duration(milliseconds: 300), () {
        _initSpeechRecognizer();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error with speech recognition. Please try again.')),
      );
    });
  }

  // Stop speech recognition
  void _stopListening() {
    if (_speech == null || !_isListening) return;

    _speech!.stop().then((result) {
      setState(() => _isListening = false);
      print('Speech recognition stopped');
    }).catchError((error) {
      print('Error stopping speech recognition: $error');
      _cleanupSpeechRecognition();
      Future.delayed(const Duration(milliseconds: 300), () {
        _initSpeechRecognizer();
      });
    });
  }

  // Cancel speech recognition and clear the text
  void _cancelListening() {
    if (_speech == null || !_isListening) return;

    _speech!.cancel().then((result) {
      setState(() {
        _isListening = false;
        _transcription = '';
        _messageController.clear();
      });
      print('Speech recognition cancelled');
    }).catchError((error) {
      print('Error cancelling speech recognition: $error');
      _cleanupSpeechRecognition();
      Future.delayed(const Duration(milliseconds: 300), () {
        _initSpeechRecognizer();
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _cleanupSpeechRecognition();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final String message = _messageController.text.trim();

    if (message.isEmpty) return;

    setState(() {
      _chatMessages.add({
        'isUser': true,
        'message': message,
      });
      _isLoading = true;
    });

    _messageController.clear();

    try {
      final String response = await ApiService.getAIResponse(message);

      setState(() {
        _chatMessages.add({
          'isUser': false,
          'message': response,
        });
      });
    } catch (e) {
      setState(() {
        _chatMessages.add({
          'isUser': false,
          'message':
              "Sorry, I couldn't process that request. Please try again later.",
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);

      if (image == null) return;

      setState(() {
        _chatMessages.add({
          'isUser': true,
          'message': "I'm sending an image of my device for recycling advice",
          'imageFile': File(image.path),
        });
        _isLoading = true;
      });

      final String response =
          await ApiService.getAIResponseWithImage(File(image.path));

      setState(() {
        _chatMessages.add({
          'isUser': false,
          'message': response,
        });
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _chatMessages.add({
          'isUser': false,
          'message':
              "Sorry, I couldn't process that image. Please try again or describe the device to me.",
        });
        _isLoading = false;
      });
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _backgroundColor,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_camera, color: _primaryColor),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: _primaryColor),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _primaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'EcoBot',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _chatMessages.isEmpty
                ? _buildWelcomeScreen()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _chatMessages.length,
                    reverse: false,
                    itemBuilder: (context, index) {
                      final message = _chatMessages[index];
                      return _buildMessageTile(message);
                    },
                  ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: LinearProgressIndicator(
                backgroundColor: _backgroundColor,
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              ),
            ),
          if (_isListening) _buildListeningIndicator(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildListeningIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.blue.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(
            Icons.mic,
            color: Colors.blue,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _transcription.isEmpty ? 'Listening...' : _transcription,
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.send,
              color: _primaryColor,
            ),
            onPressed: _stopListening,
            tooltip: 'Use Text',
          ),
          IconButton(
            icon: const Icon(
              Icons.cancel,
              color: Colors.grey,
            ),
            onPressed: _cancelListening,
            tooltip: 'Cancel',
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/ecobot.png',
              height: 110,
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to EcoByte',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: _primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Ask questions about electronic waste recycling, device repair, or take a photo of your device for specific advice. You can also use speech-to-text!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.black87,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Speech recognizer initialization button - shows only if needed
            if (!_speechRecognitionAvailable && !_isInitializing)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.mic),
                  label: const Text('Enable Speech Recognition'),
                  onPressed: _initSpeechRecognizer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            if (_isInitializing)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                ),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('How to recycle an old iPhone?'),
                _buildSuggestionChip('What are toxic components in laptops?'),
                _buildSuggestionChip('Where to dispose of batteries?'),
                _buildSuggestionChip('Can I repair my Samsung Galaxy screen?'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text),
      backgroundColor: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.3),
      avatar: Icon(Icons.help_outline, color: _primaryColor, size: 18),
      labelStyle: TextStyle(color: _primaryColor),
      elevation: 2,
      onPressed: () {
        _messageController.text = text;
        _sendMessage();
      },
    );
  }

  Widget _buildMessageTile(Map<String, dynamic> message) {
    final bool isUser = message['isUser'] as bool;
    final String messageText = message['message'] as String;
    final File? imageFile = message['imageFile'] as File?;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser
              ? const Color.fromARGB(255, 13, 71, 161)
              : const Color.fromRGBO(180, 245, 255, 1),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  imageFile,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            if (imageFile != null) const SizedBox(height: 8),
            if (isUser)
              Text(
                messageText,
                style: TextStyle(
                    fontSize: 16, color: isUser ? Colors.white : Colors.black),
              )
            else
              MarkdownBody(
                data: messageText,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(fontSize: 16),
                  strong: TextStyle(
                      color: _primaryColor, fontWeight: FontWeight.bold),
                  a: TextStyle(color: _primaryColor),
                  h1: TextStyle(
                      color: _primaryColor, fontWeight: FontWeight.bold),
                  h2: TextStyle(
                      color: _primaryColor, fontWeight: FontWeight.bold),
                  h3: TextStyle(
                      color: _primaryColor, fontWeight: FontWeight.bold),
                ),
                onTapLink: (text, href, title) {
                  if (href != null) _launchURL(href);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Camera button
            IconButton(
              icon: Icon(Icons.camera_alt, color: _primaryColor),
              onPressed:
                  _isLoading || _isListening ? null : _showImageSourceOptions,
              tooltip: 'Take Photo or Send Image',
            ),
            // Speech-to-text button - now a toggle button
            IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Icon(
                  _isListening ? Icons.mic : Icons.keyboard_voice,
                  key: ValueKey<bool>(_isListening),
                  color: _isListening
                      ? Colors.red
                      : (_isInitializing
                          ? Colors.grey
                          : _speechRecognitionAvailable
                              ? _primaryColor
                              : Colors.grey),
                ),
              ),
              onPressed:
                  _isLoading || _isInitializing ? null : _toggleListening,
              tooltip: _isListening
                  ? 'Stop Listening'
                  : (_speechRecognitionAvailable
                      ? 'Start Speech to Text'
                      : 'Initializing...'),
            ),
            // Text field
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Ask about e-waste recycling...',
                  border: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(24)),
                    borderSide:
                        BorderSide(color: _primaryColor.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(24)),
                    borderSide: BorderSide(color: _primaryColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  fillColor: _backgroundColor.withOpacity(0.5),
                  filled: true,
                ),
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                enabled: !_isLoading && !_isListening,
              ),
            ),
            // Send button
            IconButton(
              icon: Icon(Icons.send, color: _primaryColor),
              onPressed: _isLoading ||
                      _isListening ||
                      _messageController.text.trim().isEmpty
                  ? null
                  : _sendMessage,
              tooltip: 'Send Message',
            ),
          ],
        ),
      ),
    );
  }
}
