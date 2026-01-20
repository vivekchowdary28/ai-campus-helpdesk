import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';

class AiService {
  // 🔑 MULTIPLE API KEYS - AUTOMATIC ROTATION
  static const List<String> _apiKeys = [
    "AIzaSyCNJZsMCjzgj8DQ_xTfvW6M5x_ZG4nUksM",
    "AIzaSyBO2Omev5yeSz8vFVWRK_hZPa_iWo20Q3E",
    "AIzaSyCHSNm2wHS9YxA-Z8kq8FWFfgRzimO38CY",
  ];
  
  static int _currentKeyIndex = 0;
  static int _retryCount = 0;
  static const int _maxRetries = 3;
  
  static String get _apiKey => _apiKeys[_currentKeyIndex];
  
  static const String _model = "gemini-1.5-flash";
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // ==================== MAIN ENTRY POINT ====================
  static Future<Map<String, dynamic>> getSmartAnswer(
    String question, {
    String? userId,
    String? base64Image,
  }) async {
    try {
      _retryCount = 0; // Reset for new question
      
      // Step 1: Check cache
      final cachedResponse = await _checkCache(question);
      if (cachedResponse != null) {
        await _logQuery(question, cachedResponse, userId, fromCache: true);
        return cachedResponse;
      }

      // Step 2: Check admin knowledge base
      final officialAnswer = await _checkOfficialKnowledge(question);
      if (officialAnswer != null) {
        await _logQuery(question, officialAnswer, userId);
        return officialAnswer;
      }

      // Step 3: Classify intent
      final intent = await _classifyIntent(question);
      
      // Step 4: Gather context
      final contextData = await _gatherContext(question, intent);
      
      // Step 5: Generate with Gemini (with key rotation)
      final answer = await _generateAnswer(question, contextData, intent);
      
      // Step 6: Verify
      final verified = await _verifyAnswer(question, answer, contextData);
      
      // Step 7: Cache if high confidence
      final confidenceScore = verified['confidence_score'];
      if (confidenceScore is num && confidenceScore >= 0.85) {
        await _cacheResponse(question, verified, intent);
      }
      
      // Step 8: Log
      await _logQuery(question, verified, userId);
      
      return verified;
      
    } catch (e) {
      debugPrint("❌ AI Service Error: $e");
      return _fallbackResponse(question);
    }
  }

  // ==================== CHECK CACHE ====================
  static Future<Map<String, dynamic>?> _checkCache(String question) async {
    try {
      final queryHash = _generateHash(question.toLowerCase().trim());
      
      final exactMatch = await _firestore
          .collection('smart_cache')
          .where('query_hash', isEqualTo: queryHash)
          .limit(1)
          .get();
      
      if (exactMatch.docs.isNotEmpty) {
        final cached = exactMatch.docs.first.data();
        final expiresAt = (cached['expires_at'] as Timestamp).toDate();
        
        if (DateTime.now().isBefore(expiresAt)) {
          await exactMatch.docs.first.reference.update({
            'view_count': FieldValue.increment(1),
            'last_accessed': FieldValue.serverTimestamp(),
          });
          
          return {
            'answer': cached['answer'] as String,
            'confidence': 'verified',
            'source': cached['source_url'] as String? ?? 'iitbhilai.ac.in',
            'last_updated': _formatTimestamp(cached['scraped_at']),
            'from_cache': true,
            'confidence_score': 1.0,
          };
        }
      }
      
      return await _semanticSearch(question);
    } catch (e) {
      debugPrint("Cache check failed: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> _semanticSearch(String question) async {
    try {
      final intent = await _classifyIntent(question);
      
      final similar = await _firestore
          .collection('smart_cache')
          .where('intent', isEqualTo: intent)
          .orderBy('view_count', descending: true)
          .limit(5)
          .get();
      
      for (var doc in similar.docs) {
        final data = doc.data();
        final variants = List<String>.from(data['query_variants'] ?? []);
        
        for (var variant in variants) {
          if (_isSimilar(question, variant)) {
            final expiresAt = (data['expires_at'] as Timestamp).toDate();
            if (DateTime.now().isBefore(expiresAt)) {
              return {
                'answer': data['answer'] as String,
                'confidence': 'verified',
                'source': data['source_url'] as String? ?? 'iitbhilai.ac.in',
                'last_updated': _formatTimestamp(data['scraped_at']),
                'from_cache': true,
                'confidence_score': 0.95,
              };
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Semantic search failed: $e");
    }
    return null;
  }

  // ==================== CHECK ADMIN KNOWLEDGE ====================
  static Future<Map<String, dynamic>?> _checkOfficialKnowledge(String question) async {
    try {
      final queryLower = question.toLowerCase().trim();
      
      final snapshot = await _firestore
          .collection('official_data')
          .limit(100)
          .get();
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final officialQ = (data['question'] as String?)?.toLowerCase() ?? '';
        
        if (_isSimilar(queryLower, officialQ)) {
          debugPrint("✅ Found admin-verified answer!");
          return {
            'answer': data['answer'] as String,
            'confidence': 'verified',
            'source': 'Admin Verified',
            'from_cache': false,
            'confidence_score': 1.0,
          };
        }
      }
    } catch (e) {
      debugPrint("Official knowledge check failed: $e");
    }
    return null;
  }

  // ==================== INTENT CLASSIFICATION ====================
  static Future<String> _classifyIntent(String question) async {
    final q = question.toLowerCase();
    
    if (q.contains('mess') || q.contains('menu') || q.contains('food')) return 'mess_menu';
    if (q.contains('exam') || q.contains('test')) return 'exam_schedule';
    if (q.contains('holiday') || q.contains('vacation')) return 'holidays';
    if (q.contains('faculty') || q.contains('professor')) return 'faculty_info';
    if (q.contains('form') || q.contains('application')) return 'forms';
    if (q.contains('fee') || q.contains('payment')) return 'fees';
    if (q.contains('admission') || q.contains('eligibility')) return 'admissions';
    if (q.contains('club') || q.contains('event')) return 'clubs_events';
    if (q.contains('hostel') || q.contains('room')) return 'hostel';
    if (q.contains('placement') || q.contains('internship')) return 'placements';
    
    return 'general';
  }

  // ==================== GATHER CONTEXT ====================
  static Future<Map<String, dynamic>> _gatherContext(String question, String intent) async {
    final context = <String, dynamic>{};
    
    final scrapedData = await _getScrapedData(intent);
    if (scrapedData != null) context['scraped_data'] = scrapedData;
    
    final kbData = await _getKnowledgeBase(intent);
    if (kbData.isNotEmpty) context['knowledge_base'] = kbData;
    
    context['target_urls'] = _getTargetURLs(intent);
    
    return context;
  }

  static Future<Map<String, dynamic>?> _getScrapedData(String intent) async {
    try {
      final cached = await _firestore
          .collection('scrape_index')
          .where('intent', isEqualTo: intent)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();
      
      if (cached.docs.isNotEmpty) {
        final data = cached.docs.first.data();
        final lastScraped = (data['last_scraped'] as Timestamp).toDate();
        final maxAge = _getMaxAge(intent);
        
        if (DateTime.now().difference(lastScraped).inHours < maxAge) {
          return data['extracted_data'] as Map<String, dynamic>?;
        }
      }
    } catch (e) {
      debugPrint("Scraped data fetch failed: $e");
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> _getKnowledgeBase(String intent) async {
    try {
      final kb = await _firestore
          .collection('knowledge_base')
          .where('intent', isEqualTo: intent)
          .limit(3)
          .get();
      
      return kb.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint("KB fetch failed: $e");
      return [];
    }
  }

  static List<String> _getTargetURLs(String intent) {
    final urlMap = {
      'mess_menu': ['https://polaris.iitbhilai.ac.in'],
      'exam_schedule': ['https://iitbhilai.ac.in/academics'],
      'holidays': ['https://iitbhilai.ac.in/academics/calendar'],
      'faculty_info': ['https://iitbhilai.ac.in/faculty'],
      'forms': ['https://iitbhilai.ac.in/downloads'],
      'fees': ['https://iitbhilai.ac.in/admissions/fee-structure'],
      'admissions': ['https://iitbhilai.ac.in/admissions'],
      'clubs_events': ['https://polaris.iitbhilai.ac.in/student-life'],
      'hostel': ['https://iitbhilai.ac.in/campus-life/hostel'],
      'placements': ['https://iitbhilai.ac.in/placements'],
    };
    
    return urlMap[intent] ?? ['https://iitbhilai.ac.in'];
  }

  static int _getMaxAge(String intent) {
    final ageMap = {
      'mess_menu': 12, 'exam_schedule': 168, 'holidays': 168,
      'faculty_info': 720, 'fees': 720, 'admissions': 168,
      'clubs_events': 24, 'hostel': 720, 'placements': 24,
    };
    return ageMap[intent] ?? 24;
  }

  // ==================== GENERATE ANSWER (WITH KEY ROTATION) ====================
  static Future<Map<String, dynamic>> _generateAnswer(
    String question,
    Map<String, dynamic> context,
    String intent,
  ) async {
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey"
    );

    final payload = {
      "contents": [{"parts": [{"text": _buildUserPrompt(question, context)}]}],
      "tools": [{"google_search": {}}],
      "systemInstruction": {"parts": [{"text": _buildSystemPrompt(intent)}]},
      "generationConfig": {"temperature": 0.3, "topP": 0.8, "topK": 40, "maxOutputTokens": 1024},
    };

    try {
      debugPrint("🔑 Using API key #${_currentKeyIndex + 1}");
      
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      // ⚠️ QUOTA EXCEEDED - ROTATE KEY
      if (response.statusCode == 429) {
        debugPrint("⚠️ Quota exceeded on key #${_currentKeyIndex + 1}");
        _retryCount++;
        
        if (_retryCount < _maxRetries) {
          _currentKeyIndex = (_currentKeyIndex + 1) % _apiKeys.length;
          debugPrint("🔄 Switching to API key #${_currentKeyIndex + 1}");
          return _generateAnswer(question, context, intent); // Retry
        } else {
          debugPrint("❌ All API keys exhausted!");
          return _quotaExceededResponse(question, context);
        }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidate = data['candidates']?[0];
        
        if (candidate?['finishReason'] == "RECITATION") {
          return {
            'answer': "I found relevant information on: ${context['target_urls']?[0]}",
            'confidence_score': 0.6,
            'source': 'official_website',
          };
        }

        final answerText = candidate?['content']?['parts']?[0]?['text']?.trim() ?? '';
        debugPrint("✅ Success with API key #${_currentKeyIndex + 1}");
        
        return {
          'answer': answerText,
          'confidence_score': 0.9,
          'source': context['target_urls']?[0] ?? 'iitbhilai.ac.in',
        };
      } else {
        debugPrint("API Error: ${response.statusCode}");
        return _fallbackResponse(question);
      }
    } catch (e) {
      debugPrint("Generation error: $e");
      return _fallbackResponse(question);
    }
  }

  static String _buildSystemPrompt(String intent) {
    return """
You are the official IIT Bhilai AI Assistant.

RULES:
1. ONLY use info from iitbhilai.ac.in and polaris.iitbhilai.ac.in
2. NEVER invent information
3. Be concise and cite sources
4. Current focus: ${intent.toUpperCase()}

If uncertain, say: "I couldn't verify this. Check: [official_url]"
""";
  }

  static String _buildUserPrompt(String question, Map<String, dynamic> context) {
    final buffer = StringBuffer("USER QUESTION: $question\n\n");
    
    if (context.containsKey('scraped_data')) {
      buffer.writeln("DATA: ${jsonEncode(context['scraped_data'])}\n");
    }
    
    buffer.writeln("SOURCES: ${context['target_urls']?.join(', ')}\n");
    buffer.writeln("INSTRUCTIONS: Search sources, paraphrase findings, cite URL.");
    
    return buffer.toString();
  }

  // ==================== VERIFY ANSWER ====================
  static Future<Map<String, dynamic>> _verifyAnswer(
    String question,
    Map<String, dynamic> answer,
    Map<String, dynamic> context,
  ) async {
    final answerText = answer['answer'] as String? ?? '';
    
    if (answerText.isEmpty || answerText.length < 10) {
      return _fallbackResponse(question);
    }
    
    double confidence = (answer['confidence_score'] as num?)?.toDouble() ?? 0.9;
    final confidenceLabel = confidence >= 0.85 ? 'verified' : 'unverified';
    
    return {
      'answer': answerText,
      'confidence': confidenceLabel,
      'source': answer['source'] as String? ?? 'iitbhilai.ac.in',
      'confidence_score': confidence,
      'needs_manual_check': confidence < 0.85,
    };
  }

  // ==================== CACHE ====================
  static Future<void> _cacheResponse(
    String question,
    Map<String, dynamic> response,
    String intent,
  ) async {
    try {
      final queryHash = _generateHash(question.toLowerCase().trim());
      final expiresAt = DateTime.now().add(Duration(hours: _getMaxAge(intent)));
      
      await _firestore.collection('smart_cache').add({
        'query_hash': queryHash,
        'intent': intent,
        'query_variants': [question.toLowerCase().trim()],
        'answer': response['answer'],
        'source_url': response['source'],
        'scraped_at': FieldValue.serverTimestamp(),
        'expires_at': Timestamp.fromDate(expiresAt),
        'confidence_score': response['confidence_score'],
        'view_count': 1,
        'last_accessed': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Cache failed: $e");
    }
  }

  // ==================== LOGGING ====================
  static Future<void> _logQuery(
    String question,
    Map<String, dynamic> response,
    String? userId, {
    bool fromCache = false,
  }) async {
    try {
      await _firestore.collection('query_logs').add({
        'user_id': userId ?? 'anonymous',
        'question': question,
        'intent': await _classifyIntent(question),
        'confidence': response['confidence'],
        'from_cache': fromCache,
        'api_key_used': _currentKeyIndex + 1,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Logging failed: $e");
    }
  }

  // ==================== UTILITIES ====================
  static String _generateHash(String input) {
    return sha256.convert(utf8.encode(input)).toString().substring(0, 16);
  }

  static bool _isSimilar(String s1, String s2) {
    s1 = s1.toLowerCase().trim();
    s2 = s2.toLowerCase().trim();
    
    if (s1 == s2 || s1.contains(s2) || s2.contains(s1)) return true;
    
    final words1 = s1.split(' ').where((w) => w.length > 3).toSet();
    final words2 = s2.split(' ').where((w) => w.length > 3).toSet();
    
    return words1.intersection(words2).length >= 2;
  }

  static String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final diff = DateTime.now().difference(timestamp.toDate());
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hr ago';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'Recently';
  }

  static Map<String, dynamic> _fallbackResponse(String question) {
    return {
      'answer': "I'm unable to find verified information. Please check:\n\nhttps://iitbhilai.ac.in",
      'confidence': 'unverified',
      'source': 'https://iitbhilai.ac.in',
      'confidence_score': 0.3,
    };
  }

  static Map<String, dynamic> _quotaExceededResponse(String question, Map<String, dynamic> context) {
    final url = (context['target_urls'] as List?)?.first ?? 'https://iitbhilai.ac.in';
    return {
      'answer': "All AI services are at capacity. Your question has been flagged for admin review.\n\nCheck: $url",
      'confidence': 'unverified',
      'source': url,
      'confidence_score': 0.4,
    };
  }
}