import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';

class AiService {
  static const String _apiKey = "AIzaSyBdjTsUde6fpfaRVP0osLufx5YD3puWwXo";
  static const String _model = "gemini-2.0-flash-exp";
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // ==================== MAIN ENTRY POINT ====================
  static Future<Map<String, dynamic>> getSmartAnswer(
    String question, {
    String? userId,
    String? base64Image,
  }) async {
    try {
      // Step 1: Check smart cache first
      final cachedResponse = await _checkCache(question);
      if (cachedResponse != null) {
        await _logQuery(question, cachedResponse, userId, fromCache: true);
        return cachedResponse;
      }

      // Step 2: Classify intent
      final intent = await _classifyIntent(question);
      
      // Step 3: Get relevant data (scrape + firestore)
      final contextData = await _gatherContext(question, intent);
      
      // Step 4: Generate answer with Gemini
      final answer = await _generateAnswer(question, contextData, intent);
      
      // Step 5: Verify answer quality
      final verified = await _verifyAnswer(question, answer, contextData);
      
      // Step 6: Cache if high confidence
      if (verified['confidence'] >= 0.85) {
        await _cacheResponse(question, verified, intent);
      }
      
      // Step 7: Log analytics
      await _logQuery(question, verified, userId);
      
      return verified;
      
    } catch (e) {
      debugPrint("❌ AI Service Error: $e");
      return _fallbackResponse(question);
    }
  }

  // ==================== STEP 1: SMART CACHE ====================
  static Future<Map<String, dynamic>?> _checkCache(String question) async {
    try {
      final queryHash = _generateHash(question.toLowerCase().trim());
      
      // Exact match search
      final exactMatch = await _firestore
          .collection('smart_cache')
          .where('query_hash', isEqualTo: queryHash)
          .limit(1)
          .get();
      
      if (exactMatch.docs.isNotEmpty) {
        final cached = exactMatch.docs.first.data();
        final expiresAt = (cached['expires_at'] as Timestamp).toDate();
        
        if (DateTime.now().isBefore(expiresAt)) {
          // Update access metrics
          await exactMatch.docs.first.reference.update({
            'view_count': FieldValue.increment(1),
            'last_accessed': FieldValue.serverTimestamp(),
          });
          
          return {
            'answer': cached['answer'],
            'confidence': 'verified',
            'source': cached['source_url'],
            'last_updated': _formatTimestamp(cached['scraped_at']),
            'from_cache': true,
          };
        }
      }
      
      // Semantic search (similar questions)
      final semanticMatch = await _semanticSearch(question);
      if (semanticMatch != null) return semanticMatch;
      
    } catch (e) {
      debugPrint("Cache check failed: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>?> _semanticSearch(String question) async {
    try {
      // Get recent queries with same intent
      final intent = await _quickIntentCheck(question);
      
      final similar = await _firestore
          .collection('smart_cache')
          .where('intent', isEqualTo: intent)
          .orderBy('view_count', descending: true)
          .limit(5)
          .get();
      
      for (var doc in similar.docs) {
        final data = doc.data();
        final variants = List<String>.from(data['query_variants'] ?? []);
        
        // Check if question matches any variant (fuzzy)
        for (var variant in variants) {
          if (_isSimilar(question, variant)) {
            final expiresAt = (data['expires_at'] as Timestamp).toDate();
            if (DateTime.now().isBefore(expiresAt)) {
              return {
                'answer': data['answer'],
                'confidence': 'verified',
                'source': data['source_url'],
                'last_updated': _formatTimestamp(data['scraped_at']),
                'from_cache': true,
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

  // ==================== STEP 2: INTENT CLASSIFICATION ====================
  static Future<String> _classifyIntent(String question) async {
    final q = question.toLowerCase();
    
    // Rule-based classification (fast)
    if (q.contains('mess') || q.contains('menu') || q.contains('food') || q.contains('breakfast') || q.contains('lunch') || q.contains('dinner')) {
      return 'mess_menu';
    }
    if (q.contains('exam') || q.contains('test') || q.contains('mid-sem') || q.contains('end-sem')) {
      return 'exam_schedule';
    }
    if (q.contains('holiday') || q.contains('vacation') || q.contains('break')) {
      return 'holidays';
    }
    if (q.contains('faculty') || q.contains('professor') || q.contains('teacher') || q.contains('hod')) {
      return 'faculty_info';
    }
    if (q.contains('form') || q.contains('application') || q.contains('document')) {
      return 'forms';
    }
    if (q.contains('fee') || q.contains('payment') || q.contains('dues')) {
      return 'fees';
    }
    if (q.contains('admission') || q.contains('eligibility') || q.contains('cutoff')) {
      return 'admissions';
    }
    if (q.contains('club') || q.contains('event') || q.contains('fest') || q.contains('cultural')) {
      return 'clubs_events';
    }
    if (q.contains('hostel') || q.contains('room') || q.contains('accommodation')) {
      return 'hostel';
    }
    if (q.contains('placement') || q.contains('internship') || q.contains('company')) {
      return 'placements';
    }
    
    return 'general';
  }

  static Future<String> _quickIntentCheck(String question) async {
    return await _classifyIntent(question);
  }

  // ==================== STEP 3: GATHER CONTEXT ====================
  static Future<Map<String, dynamic>> _gatherContext(String question, String intent) async {
    final context = <String, dynamic>{};
    
    // Check if we have recent scraped data for this intent
    final scrapedData = await _getScrapedData(intent);
    if (scrapedData != null) {
      context['scraped_data'] = scrapedData;
    }
    
    // Get relevant knowledge base entries
    final kbData = await _getKnowledgeBase(intent);
    if (kbData.isNotEmpty) {
      context['knowledge_base'] = kbData;
    }
    
    // Get official URLs for this intent
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
        
        // Check if data is fresh (< 24h for most intents)
        final maxAge = _getMaxAge(intent);
        if (DateTime.now().difference(lastScraped).inHours < maxAge) {
          return data['extracted_data'] as Map<String, dynamic>?;
        }
      }
    } catch (e) {
      debugPrint("Failed to get scraped data: $e");
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
      'mess_menu': ['https://polaris.iitbhilai.ac.in', 'https://iitbhilai.ac.in/hostel'],
      'exam_schedule': ['https://iitbhilai.ac.in/academics', 'https://polaris.iitbhilai.ac.in/academics'],
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
      'mess_menu': 12,      // 12 hours
      'exam_schedule': 168, // 7 days
      'holidays': 168,      // 7 days
      'faculty_info': 720,  // 30 days
      'fees': 720,          // 30 days
      'admissions': 168,    // 7 days
      'clubs_events': 24,   // 24 hours
      'hostel': 720,        // 30 days
      'placements': 24,     // 24 hours
    };
    
    return ageMap[intent] ?? 24;
  }

  // ==================== STEP 4: GENERATE ANSWER ====================
  static Future<Map<String, dynamic>> _generateAnswer(
    String question,
    Map<String, dynamic> context,
    String intent,
  ) async {
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey"
    );

    // Build enhanced prompt
    final systemPrompt = _buildSystemPrompt(intent);
    final userPrompt = _buildUserPrompt(question, context);

    final payload = {
      "contents": [
        {
          "parts": [{"text": userPrompt}]
        }
      ],
      "tools": [
        {"google_search": {}}
      ],
      "systemInstruction": {
        "parts": [{"text": systemPrompt}]
      },
      "generationConfig": {
        "temperature": 0.3,
        "topP": 0.8,
        "topK": 40,
        "maxOutputTokens": 1024,
      }
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidate = data['candidates']?[0];
        
        if (candidate?['finishReason'] == "RECITATION") {
          return {
            'answer': "I found relevant information on the official IIT Bhilai website. Please check: ${context['target_urls']?[0] ?? 'iitbhilai.ac.in'}",
            'confidence': 0.6,
            'source': 'official_website',
            'recitation_blocked': true,
          };
        }

        final answerText = candidate?['content']?['parts']?[0]?['text']?.trim() ?? '';
        
        // Extract groundingMetadata if available
        final groundingMetadata = candidate?['groundingMetadata'];
        final searchQueries = groundingMetadata?['searchEntryPoint']?['renderedContent'];
        final webSearchQueries = groundingMetadata?['webSearchQueries'];
        
        return {
          'answer': answerText,
          'confidence': 0.9,
          'source': context['target_urls']?[0] ?? 'iitbhilai.ac.in',
          'grounding_metadata': groundingMetadata,
          'search_queries': webSearchQueries,
        };
      } else {
        debugPrint("Gemini API Error: ${response.statusCode} - ${response.body}");
        return _fallbackResponse(question);
      }
    } catch (e) {
      debugPrint("Generation error: $e");
      return _fallbackResponse(question);
    }
  }

  static String _buildSystemPrompt(String intent) {
    return """
You are the official IIT Bhilai AI Assistant. Your role is to help students, faculty, and visitors find accurate information about IIT Bhilai.

CRITICAL RULES:
1. ONLY use information from:
   - iitbhilai.ac.in (official website)
   - polaris.iitbhilai.ac.in (student portal)
   - Provided context data

2. NEVER invent or assume information
3. If you don't find verified data, say: "I couldn't find verified information about this. Please check: [official_url]"
4. Always cite your source
5. Be concise and helpful
6. Use bullet points for lists
7. Include dates/deadlines when relevant

KNOWLEDGE DOMAINS:
- Academics: Courses, exams, calendar, grades
- Admissions: Eligibility, cutoffs, application process
- Campus Life: Hostels, mess, clubs, events
- Administration: Forms, fees, policies
- Faculty: Contact info, departments
- Placements: Companies, processes, statistics

CURRENT FOCUS: ${intent.toUpperCase()}

Response Format:
- Direct answer first
- Source citation at end
- Include relevant links if available
""";
  }

  static String _buildUserPrompt(String question, Map<String, dynamic> context) {
    final buffer = StringBuffer();
    
    buffer.writeln("USER QUESTION: $question");
    buffer.writeln();
    
    if (context.containsKey('scraped_data')) {
      buffer.writeln("AVAILABLE DATA FROM OFFICIAL WEBSITE:");
      buffer.writeln(jsonEncode(context['scraped_data']));
      buffer.writeln();
    }
    
    if (context.containsKey('knowledge_base') && (context['knowledge_base'] as List).isNotEmpty) {
      buffer.writeln("KNOWLEDGE BASE ENTRIES:");
      for (var entry in context['knowledge_base']) {
        buffer.writeln("- ${entry['answer']}");
      }
      buffer.writeln();
    }
    
    buffer.writeln("OFFICIAL SOURCES TO SEARCH:");
    for (var url in context['target_urls']) {
      buffer.writeln("- $url");
    }
    buffer.writeln();
    
    buffer.writeln("INSTRUCTIONS:");
    buffer.writeln("1. Search the provided official sources");
    buffer.writeln("2. If data is available, answer using that information");
    buffer.writeln("3. Paraphrase - never copy-paste verbatim");
    buffer.writeln("4. If no data found, say so clearly");
    buffer.writeln("5. Always mention the source URL");
    
    return buffer.toString();
  }

  // ==================== STEP 5: VERIFY ANSWER ====================
  static Future<Map<String, dynamic>> _verifyAnswer(
    String question,
    Map<String, dynamic> answer,
    Map<String, dynamic> context,
  ) async {
    // Basic validation
    final answerText = answer['answer'] as String;
    
    // Check for common issues
    if (answerText.isEmpty || answerText.length < 10) {
      return _fallbackResponse(question);
    }
    
    // Check if answer contains "ESC_ADMIN" or similar flags
    if (answerText.contains('ESC_ADMIN') || 
        answerText.contains("I don't know") ||
        answerText.contains("I couldn't find")) {
      return {
        'answer': "I couldn't find verified information about this on the official IIT Bhilai websites. Please contact the administration or check:\n\n${context['target_urls']?[0] ?? 'https://iitbhilai.ac.in'}",
        'confidence': 'unverified',
        'source': null,
        'needs_manual_check': true,
      };
    }
    
    // Calculate confidence score
    double confidence = answer['confidence'] ?? 0.9;
    
    // Reduce confidence if no grounding metadata
    if (answer['grounding_metadata'] == null) {
      confidence *= 0.9;
    }
    
    // High confidence = verified
    final confidenceLabel = confidence >= 0.85 ? 'verified' : 'unverified';
    
    return {
      'answer': answerText,
      'confidence': confidenceLabel,
      'source': answer['source'],
      'last_updated': 'Just now',
      'confidence_score': confidence,
      'needs_manual_check': confidence < 0.85,
    };
  }

  // ==================== STEP 6: CACHE RESPONSE ====================
  static Future<void> _cacheResponse(
    String question,
    Map<String, dynamic> response,
    String intent,
  ) async {
    try {
      final queryHash = _generateHash(question.toLowerCase().trim());
      final ttl = _getMaxAge(intent);
      final expiresAt = DateTime.now().add(Duration(hours: ttl));
      
      await _firestore.collection('smart_cache').add({
        'query_hash': queryHash,
        'intent': intent,
        'query_variants': [question.toLowerCase().trim()],
        'answer': response['answer'],
        'source_url': response['source'],
        'scraped_at': FieldValue.serverTimestamp(),
        'expires_at': Timestamp.fromDate(expiresAt),
        'confidence_score': response['confidence_score'] ?? 0.9,
        'view_count': 1,
        'last_accessed': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
      });
      
      debugPrint("✅ Cached response for: $question");
    } catch (e) {
      debugPrint("Cache storage failed: $e");
    }
  }

  // ==================== STEP 7: LOGGING & ANALYTICS ====================
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
        'response_type': response['confidence'],
        'source': response['source'],
        'from_cache': fromCache,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Logging failed: $e");
    }
  }

  // ==================== UTILITY FUNCTIONS ====================
  static String _generateHash(String input) {
    return sha256.convert(utf8.encode(input)).toString().substring(0, 16);
  }

  static bool _isSimilar(String s1, String s2) {
    s1 = s1.toLowerCase().trim();
    s2 = s2.toLowerCase().trim();
    
    // Exact match
    if (s1 == s2) return true;
    
    // Contains match
    if (s1.contains(s2) || s2.contains(s1)) return true;
    
    // Word overlap (simple)
    final words1 = s1.split(' ').where((w) => w.length > 3).toSet();
    final words2 = s2.split(' ').where((w) => w.length > 3).toSet();
    final overlap = words1.intersection(words2).length;
    
    return overlap >= 2; // At least 2 common words
  }

  static String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'Recently';
  }

  static Map<String, dynamic> _fallbackResponse(String question) {
    return {
      'answer': "I'm currently unable to find verified information about this. Please check the official IIT Bhilai website:\n\nhttps://iitbhilai.ac.in\n\nOr contact the administration office for accurate information.",
      'confidence': 'unverified',
      'source': 'https://iitbhilai.ac.in',
      'is_fallback': true,
    };
  }
}