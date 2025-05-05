import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class CreditService {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;




  static Future<int?> getCredits() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data()?['credits'] as int?;
    } catch (e) {
      debugPrint('Error getting credits: $e');
      return null;
    }

  }

  static Future<String?> getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    return await user?.getIdToken();
  }




  static Future<void> initializeCredits() async {
    final token = await getIdToken();
    if (token == null) return;

    final response = await http.post(
      Uri.parse('https://optima-livekit-token-server.onrender.com/credits/init'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint("[Credits Init] 📡 Response status: ${response.statusCode}");
    debugPrint("[Credits Init] 📝 Response body: ${response.body}");

    if (response.statusCode == 200) {
      debugPrint("[Credits Init] ✅ Credits initialized successfully.");
    } else {
      debugPrint("[Credits Init] ⚠️ Failed to initialize credits. Server responded with error.");
    }
  }

  static Future<void> deleteCredits() async {
    final token = await getIdToken();
    if (token == null) return;

    await http.post(
      Uri.parse('https://optima-livekit-token-server.onrender.com/credits/delete'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
  }

}
