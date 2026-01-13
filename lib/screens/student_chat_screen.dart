import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentChatScreen extends StatefulWidget {
  final String email;
  const StudentChatScreen({super.key, required this.email});

  @override
  State<StudentChatScreen> createState() => _StudentChatScreenState();
}

class _StudentChatScreenState extends State<StudentChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Safe chat id
  String get chatId =>
      widget.email.replaceAll('@', '_').replaceAll('.', '_');

  // ---------------- SEND MESSAGE ----------------
Future<void> _sendMessage() async {
  print('🔥 sendMessage() CALLED');

  final text = _controller.text;
  print('📝 Raw text = "$text"');

  if (text.trim().isEmpty) {
    print('⛔ Text empty, returning');
    return;
  }

  try {
    print('🚀 Writing to Firestore...');

    await FirebaseFirestore.instance
        .collection('debug_test')
        .add({
      'text': text,
      'time': FieldValue.serverTimestamp(),
    });

    print('✅ Firestore write SUCCESS');

  } catch (e) {
    print('❌ Firestore ERROR: $e');
  }
}
  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Helpdesk'),
      ),
      body: Column(
        children: [
          // ---------------- MESSAGES ----------------
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('Start the conversation'),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data =
                        docs[index].data() as Map<String, dynamic>;
                    final isStudent =
                        data['sender'] == 'student';

                    return Align(
                      alignment: isStudent
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin:
                            const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        constraints:
                            const BoxConstraints(maxWidth: 280),
                        decoration: BoxDecoration(
                          color: isStudent
                              ? Colors.green.shade200
                              : Colors.grey.shade300,
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                        child: Text(
                          data['text'] ?? '',
                          style:
                              const TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ---------------- INPUT ----------------
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction:
                          TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Type your question...',
                        filled: true,
                        fillColor:
                            Colors.grey.shade200,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(
                                horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.green,
                    child: IconButton(
                      icon: const Icon(Icons.send,
                          color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}