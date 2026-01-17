import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AiService {
  static const String _apiKey = "AIzaSyBdjTsUde6fpfaRVP0osLufx5YD3puWwXo";
  static const String _model = "gemini-2.5-flash-preview-09-2025";

  static Future<String> getSmartAnswer(String question, {String? base64Image}) async {
    final url = Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey");

    final Map<String, dynamic> payload = {
      "contents": [{
        "parts": [
          {"text": "User Query: $question. Search iitbhilai.ac.in and polaris.iitbhilai.ac.in."}
        ]
      }],
      "tools": [{"google_search": {}}],
      "systemInstruction": {
        "parts": [{
          "text": """
          You are the IIT Bhilai Expert Assistant. 
          
          KNOWLEDGE MAP:
          - Use iitbhilai.ac.in for: B.Tech/M.Tech/PhD programs, Faculty, Admission Criteria, Academic Calendars, Fees, and Anti-Ragging Policies.
          - Use polaris.iitbhilai.ac.in for: Student Mentorship (SMP), Fee Waivers, CoSA, Cultural/SciTech Clubs, and Student Life.
          
          RULES:
          - If the user asks about grades or private results, explain that these are on AIMS/Student Portal, not here.
          - ALWAYS paraphrase and summarize. Never quote verbatim (to avoid recitation filters).
          - If information is missing from both sites, reply ONLY: ESC_ADMIN.
          """
        }]
      }
    };

    try {
      final response = await http.post(url, headers: {"Content-Type": "application/json"}, body: jsonEncode(payload));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidate = data['candidates']?[0];
        if (candidate?['finishReason'] == "RECITATION") return "I found the official document, but it's too long. In short: [Try asking about a specific policy].";
        return candidate?['content']?['parts']?[0]?['text']?.trim() ?? "ESC_ADMIN";
      }
    } catch (e) { debugPrint("AI Error: $e"); }
    return "ESC_ADMIN";
  }
}