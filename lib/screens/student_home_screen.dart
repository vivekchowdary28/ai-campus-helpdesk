import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../services/ai_service.dart';
import 'login_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  final String email;
  const StudentHomeScreen({super.key, required this.email});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  bool _isAITyping = false;

  void _submitQuery({String? base64Img, String? label}) async {
    final text = label ?? _queryController.text.trim();
    if (text.isEmpty && base64Img == null) return;

    _queryController.clear();
    FocusScope.of(context).unfocus();
    
    setState(() => _isAITyping = true);

    try {
      final result = await AiService.getSmartAnswer(text);
      // Check if the answer contains ESC_ADMIN (assuming answer is a String)
      String answerText = result['answer']?.toString() ?? '';
      String status = answerText.contains("ESC_ADMIN") ? "pending" : "answered";

      await FirebaseFirestore.instance.collection('questions').add({
        'question': text,
        'studentEmail': widget.email.trim().toLowerCase(),
        'status': status,
        'answer': status == "answered" ? result : null,
        'image': base64Img,
        'feedback': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) {
        setState(() => _isAITyping = false);
        _scrollToBottom();
      }
    }
  }

  void _saveFeedback(String docId, String type) async {
    await FirebaseFirestore.instance.collection('questions').doc(docId).update({
      'feedback': type,
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Feedback saved: $type"), duration: const Duration(seconds: 1)),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (image == null) return;
    final bytes = await image.readAsBytes();
    _submitQuery(base64Img: base64Encode(bytes), label: "Analyzed camera image");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Campus Assist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 22),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              (await SharedPreferences.getInstance()).clear();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // REMOVED orderBy here to fix the infinite loading (No Index Required)
              stream: FirebaseFirestore.instance
                  .collection('questions')
                  .where('studentEmail', isEqualTo: widget.email.trim().toLowerCase())
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                // SORT IN MEMORY INSTEAD
                final docs = snapshot.data!.docs.toList();
                docs.sort((a, b) {
                  final aTime = (a.data() as Map)['createdAt'] as Timestamp?;
                  final bTime = (b.data() as Map)['createdAt'] as Timestamp?;
                  return (bTime ?? Timestamp.now()).compareTo(aTime ?? Timestamp.now());
                });

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: docs.length + (_isAITyping ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (_isAITyping && i == 0) return _buildShimmerLoading();
                    final index = _isAITyping ? i - 1 : i;
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildMessageGroup(doc.id, data);
                  },
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20, right: 60),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: const [
              Icon(Icons.auto_awesome, size: 14, color: Colors.blueAccent),
              SizedBox(width: 8),
              Text("Gemini is thinking...", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            ]),
            const SizedBox(height: 12),
            Container(width: 150, height: 8, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4))),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageGroup(String docId, Map<String, dynamic> data) {
    return Column(
      children: [
        _buildStudentBubble(data['question'], data['image']),
        const SizedBox(height: 12),
        _buildAiResponse(docId, data),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStudentBubble(String? text, String? base64Img) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          color: Color(0xFFF1F5F9),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20), topRight: Radius.circular(20), bottomRight: Radius.circular(4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (base64Img != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(base64Decode(base64Img), width: 150, fit: BoxFit.cover),
              ),
            if (base64Img != null && text != null) const SizedBox(height: 8),
            if (text != null) Text(text, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _buildAiResponse(String docId, Map<String, dynamic> data) {
    bool isPending = data['status'] == 'pending';
    String? answer = data['answer'];

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(right: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.auto_awesome, size: 14, color: Colors.blueAccent),
                SizedBox(width: 8),
                Text("ASSISTANT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.1, color: Colors.blueAccent)),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: const BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20), topLeft: Radius.circular(4), bottomLeft: Radius.circular(20)),
              ),
              child: Text(
                answer ?? (isPending ? "⏳ Sent to Admin for verification." : "Thinking..."),
                style: const TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF334155)),
              ),
            ),
            if (answer != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    _feedbackBtn(docId, Icons.thumb_up_alt_outlined, "positive", data['feedback'] == "positive"),
                    _feedbackBtn(docId, Icons.thumb_down_alt_outlined, "negative", data['feedback'] == "negative"),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.grey),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: answer));
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _feedbackBtn(String docId, IconData icon, String type, bool isActive) {
    return IconButton(
      icon: Icon(icon, size: 16, color: isActive ? Colors.blueAccent : Colors.grey),
      onPressed: () => _saveFeedback(docId, type),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.camera_alt_rounded, color: Color(0xFF64748B)),
            onPressed: _isAITyping ? null : _pickImage,
          ),
          Expanded(
            child: TextField(
              controller: _queryController,
              enabled: !_isAITyping,
              decoration: InputDecoration(
                hintText: "Ask anything...",
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.send_rounded, color: _isAITyping ? Colors.grey : const Color(0xFF2563EB)),
            onPressed: _isAITyping ? null : () => _submitQuery(),
          ),
        ],
      ),
    );
  }
}