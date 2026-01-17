import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  final String email;
  const AdminHomeScreen({super.key, required this.email});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("ADMIN COMMAND CENTER", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blueAccent,
          tabs: const [
            Tab(text: "PENDING (Human Action Required)"),
            Tab(text: "VERIFIED KNOWLEDGE"),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
          })
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuestionList('pending'),
          _buildQuestionList('answered'),
        ],
      ),
    );
  }

  Widget _buildQuestionList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('questions').where('status', isEqualTo: status).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return Center(child: Text("No $status queries found.", style: const TextStyle(color: Colors.grey)));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _buildQuestionCard(docs[i].id, data);
          },
        );
      },
    );
  }

  Widget _buildQuestionCard(String id, Map<String, dynamic> data) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(backgroundColor: Color(0xFFE2E8F0), child: Icon(Icons.person, size: 20, color: Colors.black54)),
                const SizedBox(width: 10),
                Text(data['studentEmail'] ?? "Unknown Student", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            Text(data['question'] ?? "", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const Divider(height: 30),
            if (data['status'] == 'pending')
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 45)),
                onPressed: () => _showAnswerDialog(id, data['question']),
                icon: const Icon(Icons.edit),
                label: const Text("PROVIDE OFFICIAL ANSWER"),
              )
            else
              Text("AI/Admin Answer: ${data['answer']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _showAnswerDialog(String id, String question) {
    final TextEditingController ansController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Train Knowledge Base"),
        content: TextField(controller: ansController, maxLines: 5, decoration: const InputDecoration(hintText: "Enter official response...")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('questions').doc(id).update({
                'answer': ansController.text,
                'status': 'answered',
              });
              // ALSO ADD TO THE TRAINING VAULT
              await FirebaseFirestore.instance.collection('official_data').add({
                'question': question,
                'answer': ansController.text,
                'verifiedAt': FieldValue.serverTimestamp(),
              });
              Navigator.pop(context);
            },
            child: const Text("Verify & Publish"),
          )
        ],
      ),
    );
  }
}