import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/ai_service.dart';

class StudentChatScreen extends StatefulWidget {
  final String? initialQuery; // ← ADD THIS
  
  const StudentChatScreen({Key? key, this.initialQuery}) : super(key: key);

  @override
  State<StudentChatScreen> createState() => _StudentChatScreenState();
}

class _StudentChatScreenState extends State<StudentChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  String? _currentUserId;
  String? _currentUserEmail;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _currentUserId = user?.uid;
    _currentUserEmail = user?.email;
    _addWelcomeMessage();
    
    // ← ADD THIS: Auto-send initial query if provided
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleUserQuestion(widget.initialQuery!);
      });
    }
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add({
        'text': '👋 Hello! I\'m your IIT Bhilai AI Assistant.\n\nAsk me about:\n• Mess menu\n• Exam schedules\n• Faculty info\n• Forms & documents\n• Campus events\n• And more!',
        'isUser': false,
        'timestamp': DateTime.now(),
      });
    });
  }

  Future<void> _handleUserQuestion(String question) async {
    if (question.trim().isEmpty) return;

    // Add user message
    setState(() {
      _messages.add({
        'text': question,
        'isUser': true,
        'timestamp': DateTime.now(),
      });
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await AiService.getSmartAnswer(
        question,
        userId: _currentUserId,
      );

      // Safe type conversion
      final answerText = _safeString(response['answer']);
      final confidence = _safeString(response['confidence']) ?? 'unverified';
      final source = _safeString(response['source']);
      final fromCache = response['from_cache'] == true;

      setState(() {
        _messages.add({
          'text': answerText,
          'isUser': false,
          'confidence': confidence,
          'source': source,
          'fromCache': fromCache,
          'timestamp': DateTime.now(),
        });
        _isLoading = false;
      });

      // Save to admin dashboard if unverified
      if (confidence == 'unverified' || response['needs_manual_check'] == true) {
        await _flagForAdmin(question, answerText);
      }

      _scrollToBottom();
    } catch (e) {
      debugPrint('Error in chat: $e');
      setState(() {
        _messages.add({
          'text': 'Sorry, something went wrong. Please try again.',
          'isUser': false,
          'isError': true,
          'timestamp': DateTime.now(),
        });
        _isLoading = false;
      });
    }
  }

  // Type-safe string extractor
  String _safeString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  Future<void> _flagForAdmin(String question, String aiAnswer) async {
    try {
      await FirebaseFirestore.instance.collection('questions').add({
        'question': question,
        'aiSuggestion': aiAnswer,
        'studentEmail': _currentUserEmail ?? 'anonymous',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to flag for admin: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IIT Bhilai AI Assistant'),
        backgroundColor: const Color(0xFF2563EB),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AI is thinking...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

          // Input area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['isUser'] as bool? ?? false;
    final text = _safeString(message['text']);
    final confidence = _safeString(message['confidence']);
    final source = _safeString(message['source']);
    final fromCache = message['fromCache'] as bool? ?? false;
    final isError = message['isError'] as bool? ?? false;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF2563EB)
              : isError
                  ? Colors.red[100]
                  : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            if (!isUser && confidence.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    confidence == 'verified' ? Icons.verified : Icons.info_outline,
                    size: 14,
                    color: confidence == 'verified' ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    confidence == 'verified' ? 'Verified' : 'Unverified',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (fromCache) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.cached, size: 14, color: Colors.grey[600]),
                  ],
                ],
              ),
            ],
            if (source.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Source: $source',
                style: TextStyle(
                  fontSize: 10,
                  color: isUser ? Colors.white70 : Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ask about IIT Bhilai...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (value) => _handleUserQuestion(value),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFF2563EB),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () => _handleUserQuestion(_messageController.text),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}