import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

// ---------------- INSTITUTIONAL DESIGN SYSTEM ----------------
class AdminTheme {
  static const Color primaryGreen = Color(0xFF1B7F5C);
  static const Color background = Color(0xFFF9F9F9);
  static const Color textPrimary = Color(0xFF1E1E1E);
  static const Color textMuted = Color(0xFF6B6B6B);
  static const Color flaggedRed = Color(0xFFD32F2F);
  static const Color white = Colors.white;
}

class AdminHomeScreen extends StatefulWidget {
  final String email;
  const AdminHomeScreen({super.key, required this.email});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  String _currentView = 'Flagged Queries';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AdminTheme.background,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: _buildMainContent(),
    );
  }

  // ---------------- APP BAR ----------------
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AdminTheme.white,
      elevation: 2,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: AdminTheme.textPrimary),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: const Text(
        "Campus Intelligence Center",
        style: TextStyle(
          color: AdminTheme.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey.shade200,
            child: Text(
              widget.email[0].toUpperCase(),
              style: const TextStyle(
                color: AdminTheme.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        )
      ],
    );
  }

  // ---------------- NAVIGATION DRAWER ----------------
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AdminTheme.white,
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: AdminTheme.background),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.security, color: AdminTheme.primaryGreen, size: 40),
                  SizedBox(height: 12),
                  Text(
                    "INSTITUTIONAL ADMIN",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: AdminTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _drawerItem(Icons.flag_outlined, "Flagged Queries", hasBadge: true),
          _drawerItem(Icons.check_circle_outline, "Answered Queries"),
          _drawerItem(Icons.library_books_outlined, "Official Knowledge Base"),
          _drawerItem(Icons.sensors, "System Status"),
          const Spacer(),
          const Divider(),
          _drawerItem(Icons.logout, "Logout", isLogout: true),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, {bool hasBadge = false, bool isLogout = false}) {
    final bool active = _currentView == title;
    return ListTile(
      leading: Icon(icon, color: active ? AdminTheme.primaryGreen : AdminTheme.textMuted),
      title: Text(
        title,
        style: TextStyle(
          color: active ? AdminTheme.primaryGreen : AdminTheme.textPrimary,
          fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      trailing: (hasBadge && title == "Flagged Queries") 
          ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: AdminTheme.flaggedRed, shape: BoxShape.circle)) 
          : null,
      onTap: () async {
        if (isLogout) {
          await FirebaseAuth.instance.signOut();
          (await SharedPreferences.getInstance()).clear();
          if (!mounted) return;
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
        } else {
          setState(() => _currentView = title);
          Navigator.pop(context);
        }
      },
      shape: active ? const Border(left: BorderSide(color: AdminTheme.primaryGreen, width: 4)) : null,
    );
  }

  // ---------------- MAIN CONTENT ROUTER ----------------
  Widget _buildMainContent() {
    switch (_currentView) {
      case 'Flagged Queries':
        return _buildQueryList('pending');
      case 'Answered Queries':
        return _buildQueryList('answered');
      case 'Official Knowledge Base':
        return _buildKnowledgeBase();
      case 'System Status':
        return _buildSystemStatus();
      default:
        return _buildQueryList('pending');
    }
  }

  // ---------------- QUERY LIST (IN-MEMORY SORTING) ----------------
  Widget _buildQueryList(String status) {
    return StreamBuilder<QuerySnapshot>(
      // We do not use .orderBy here to avoid Firestore Index requirement errors
      stream: FirebaseFirestore.instance
          .collection('questions')
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Connection Error: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AdminTheme.primaryGreen));

        final docs = snapshot.data!.docs.toList();
        
        // SORT BY TIMESTAMP (In-Memory)
        docs.sort((a, b) {
          final aTime = (a.data() as Map)['createdAt'] as Timestamp?;
          final bTime = (b.data() as Map)['createdAt'] as Timestamp?;
          return (bTime ?? Timestamp.now()).compareTo(aTime ?? Timestamp.now());
        });

        if (docs.isEmpty) return const Center(child: Text("No records found in this category."));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _buildQueryCard(docs[i].id, data, status == 'pending');
          },
        );
      },
    );
  }

  Widget _buildQueryCard(String id, Map<String, dynamic> data, bool isPending) {
    final String question = data['question'] ?? "Null Query Received";

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(data['studentEmail'] ?? "Anonymous Student", style: const TextStyle(color: AdminTheme.textMuted, fontSize: 11)),
                if (data['feedback'] != null)
                  Icon(data['feedback'] == 'positive' ? Icons.thumb_up : Icons.thumb_down, size: 14, color: AdminTheme.primaryGreen),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              question,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AdminTheme.textPrimary, height: 1.3),
            ),
            if (isPending) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.primaryGreen,
                    foregroundColor: AdminTheme.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _showAnswerModal(id, question),
                  child: const Text("PROVIDE OFFICIAL ANSWER", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
              ),
            ] else ...[
              const Divider(height: 30),
              const Text("OFFICIAL RESPONSE:", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AdminTheme.textMuted)),
              const SizedBox(height: 6),
              Text(data['answer'] ?? "", style: const TextStyle(color: AdminTheme.primaryGreen, fontSize: 14, height: 1.4)),
            ]
          ],
        ),
      ),
    );
  }

  // ---------------- ANSWER MODAL (BOTTOM SHEET) ----------------
  void _showAnswerModal(String id, String question) {
    final TextEditingController _ansController = TextEditingController();
    String category = 'FAQ';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AdminTheme.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("INSTITUTIONAL VERIFICATION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AdminTheme.textMuted)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: Text(question, style: const TextStyle(fontSize: 14, color: AdminTheme.textPrimary)),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _ansController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "Enter official institute response...",
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AdminTheme.primaryGreen)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: "Classification", border: OutlineInputBorder()),
                items: ['Rule', 'Policy', 'Notice', 'FAQ'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => category = v!,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primaryGreen, foregroundColor: AdminTheme.white),
                  onPressed: isSubmitting ? null : () async {
                    if (_ansController.text.trim().isEmpty) return;
                    setModalState(() => isSubmitting = true);
                    
                    try {
                      // Update Query
                      await FirebaseFirestore.instance.collection('questions').doc(id).update({
                        'answer': _ansController.text.trim(),
                        'status': 'answered',
                        'category': category,
                      });

                      // Add to Knowledge Vault (Consistent Field Name 'question')
                      await FirebaseFirestore.instance.collection('official_data').add({
                        'question': question,
                        'answer': _ansController.text.trim(),
                        'category': category,
                        'verifiedAt': FieldValue.serverTimestamp(),
                      });

                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      setModalState(() => isSubmitting = false);
                    }
                  },
                  child: isSubmitting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text("PUBLISH & TRAIN AI", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- OFFICIAL KNOWLEDGE BASE ----------------
  Widget _buildKnowledgeBase() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('official_data').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final aT = (a.data() as Map)['verifiedAt'] as Timestamp?;
          final bT = (b.data() as Map)['verifiedAt'] as Timestamp?;
          return (bT ?? Timestamp.now()).compareTo(aT ?? Timestamp.now());
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AdminTheme.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AdminTheme.primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(data['category'] ?? "General", style: const TextStyle(color: AdminTheme.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const Icon(Icons.verified, color: AdminTheme.primaryGreen, size: 16),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(data['question'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AdminTheme.textPrimary)),
                  const SizedBox(height: 8),
                  Text(data['answer'] ?? "", style: const TextStyle(color: AdminTheme.textMuted, fontSize: 13, height: 1.4)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ---------------- SYSTEM STATUS SCREEN ----------------
  Widget _buildSystemStatus() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _statusIndicator("AI Reasoning Engine", "Operational", Icons.check_circle, Colors.green),
          _statusIndicator("Search Grounding", "iitbhilai.ac.in (Live)", Icons.public, AdminTheme.primaryGreen),
          _statusIndicator("Database Sync", "Real-time", Icons.cloud_done, AdminTheme.primaryGreen),
          _statusIndicator("Security Protocol", "Domain Locked", Icons.lock, Colors.blue),
        ],
      ),
    );
  }

  Widget _statusIndicator(String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AdminTheme.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AdminTheme.textMuted)),
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            ],
          )
        ],
      ),
    );
  }
}