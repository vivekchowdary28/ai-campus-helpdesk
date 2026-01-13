import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  // ================= LOGOUT =================
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('signed_in_email');
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  // ================= FLAGGED / PENDING =================
  Widget _buildPendingQueries() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('questions')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text('No pending questions'));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return ListTile(
              title: Text(data['question'] ?? ''),
              subtitle: Text('From: ${data['studentEmail'] ?? ''}'),
              trailing: ElevatedButton(
                onPressed: () => _showAnswerDialog(doc),
                child: const Text('Answer'),
              ),
            );
          },
        );
      },
    );
  }

  // ================= ANSWER DIALOG =================
  void _showAnswerDialog(DocumentSnapshot doc) {
    final answerController = TextEditingController();
    String category = 'FAQ';
    final data = doc.data() as Map<String, dynamic>;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Answer Question'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              Text(data['question'] ?? ''),
              const SizedBox(height: 12),
              TextField(
                controller: answerController,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Official Answer',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: category,
                isExpanded: true,
                items: const ['Rule', 'Policy', 'Notice', 'FAQ']
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ),
                    )
                    .toList(),
                onChanged: (v) => category = v!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final answer = answerController.text.trim();
              if (answer.isEmpty) return;

              // update question
              await FirebaseFirestore.instance
                  .collection('questions')
                  .doc(doc.id)
                  .update({
                'answer': answer,
                'status': 'answered',
                'answeredAt': FieldValue.serverTimestamp(),
              });

              // add to official data
              await FirebaseFirestore.instance
                  .collection('official_data')
                  .add({
                'question': data['question'],
                'answer': answer,
                'category': category,
                'createdAt': FieldValue.serverTimestamp(),
              });

              if (mounted) Navigator.pop(context);
            },
            child: const Text('Publish'),
          ),
        ],
      ),
    );
  }

  // ================= ANSWERED =================
  Widget _buildAnsweredQueries() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('questions')
          .where('status', isEqualTo: 'answered')
          .orderBy('answeredAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text('No answered questions'));
        }

        return ListView(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ListTile(
              title: Text(data['question'] ?? ''),
              subtitle: Text(data['answer'] ?? ''),
            );
          }).toList(),
        );
      },
    );
  }

  // ================= OFFICIAL DATA =================
  Widget _buildOfficialData() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('official_data')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text('No official data'));
        }

        return ListView(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ListTile(
              title: Text(data['question'] ?? ''),
              subtitle: Text(data['answer'] ?? ''),
            );
          }).toList(),
        );
      },
    );
  }

  // ================= ADD OFFICIAL DATA =================
  void _addOfficialDataManually() {
    final q = TextEditingController();
    final a = TextEditingController();
    String category = 'FAQ';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Official Data'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: q,
                decoration: const InputDecoration(labelText: 'Question'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: a,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Answer'),
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: category,
                isExpanded: true,
                items: const ['Rule', 'Policy', 'Notice', 'FAQ']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => category = v!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (q.text.trim().isEmpty || a.text.trim().isEmpty) return;

              await FirebaseFirestore.instance
                  .collection('official_data')
                  .add({
                'question': q.text.trim(),
                'answer': a.text.trim(),
                'category': category,
                'createdAt': FieldValue.serverTimestamp(),
              });

              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),

      body: [
        _buildPendingQueries(),
        _buildAnsweredQueries(),
        _buildOfficialData(),
      ][_currentIndex],

      floatingActionButton: _currentIndex == 2
          ? FloatingActionButton(
              onPressed: _addOfficialDataManually,
              child: const Icon(Icons.add),
            )
          : null,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.flag), label: 'Pending'),
          BottomNavigationBarItem(icon: Icon(Icons.done), label: 'Answered'),
          BottomNavigationBarItem(icon: Icon(Icons.storage), label: 'Official'),
        ],
      ),
    );
  }
}