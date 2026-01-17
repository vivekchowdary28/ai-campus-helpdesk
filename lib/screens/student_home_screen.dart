import 'package:flutter/material.dart';
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
    // Automatically close keyboard on send
    FocusScope.of(context).unfocus();
    
    setState(() => _isAITyping = true);

    try {
      final result = await AiService.getSmartAnswer(text, base64Image: base64Img);
      String status = result.contains("ESC_ADMIN") ? "pending" : "answered";

      await FirebaseFirestore.instance.collection('questions').add({
        'question': text,
        'studentEmail': widget.email.trim().toLowerCase(),
        'status': status,
        'answer': status == "answered" ? result : null,
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

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
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
      // CRITICAL: This allows the UI to resize when the keyboard appears
      resizeToAvoidBottomInset: true, 
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Campus Assist', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
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
          // THE CHAT AREA
          Expanded(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('questions')
                    .where('studentEmail', isEqualTo: widget.email.trim().toLowerCase())
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const Center(child: Text("Error loading messages"));
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  
                  final docs = snapshot.data!.docs;
                  
                  // Newest messages first at index 0
                  final sortedDocs = docs.toList()..sort((a, b) {
                    final aT = (a.data() as Map)['createdAt'] as Timestamp?;
                    final bT = (b.data() as Map)['createdAt'] as Timestamp?;
                    return (bT ?? Timestamp.now()).compareTo(aT ?? Timestamp.now());
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true, // index 0 is at the bottom
                    padding: const EdgeInsets.only(top: 20, bottom: 20, left: 12, right: 12),
                    // Force it to always be scrollable even if few messages
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    itemCount: sortedDocs.length,
                    itemBuilder: (context, i) {
                      final d = sortedDocs[i].data() as Map<String, dynamic>;
                      return _buildMessage(d);
                    },
                  );
                },
              ),
            ),
          ),

          // LOADING INDICATOR
          if (_isAITyping)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              width: double.infinity,
              color: Colors.white,
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),

          // INPUT BAR
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> data) {
    bool isPending = data['status'] == 'pending';
    String? answer = data['answer'];

    return Column(
      children: [
        // Student Question Bubble
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.only(left: 50, bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Text(data['question'] ?? "", style: const TextStyle(color: Colors.white)),
          ),
        ),
        
        // Response (AI or Status)
        if (answer != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(right: 50, bottom: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(4),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
              ),
              child: Text(answer),
            ),
          )
        else
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20, left: 8),
              child: Text(
                isPending ? "⏳ Sent to Admin" : "AI is writing...",
                style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12, 
        right: 12, 
        top: 8, 
        bottom: MediaQuery.of(context).padding.bottom + 8
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.blueGrey),
            onPressed: _isAITyping ? null : _pickImage,
          ),
          Expanded(
            child: TextField(
              controller: _queryController,
              enabled: !_isAITyping,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitQuery(),
              decoration: InputDecoration(
                hintText: "Ask anything...",
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isAITyping ? null : _submitQuery,
            child: const CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}