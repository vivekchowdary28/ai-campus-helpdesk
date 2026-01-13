import 'package:cloud_firestore/cloud_firestore.dart';

class AiAnswerService {
  static Future<String?> getAnswer(String question) async {
    final q = question.toLowerCase();

    final snapshot = await FirebaseFirestore.instance
        .collection('official_data')
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final keywords = List<String>.from(data['keywords'] ?? []);

      for (final k in keywords) {
        if (q.contains(k.toLowerCase())) {
          return data['answer'];
        }
      }
    }

    return null; // no match
  }
}