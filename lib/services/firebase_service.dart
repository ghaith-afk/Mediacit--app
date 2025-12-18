import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static bool _initialized = false;

  static Future<void> init() async {
    if (!_initialized) {
      try {
        await Firebase.initializeApp();
        _initialized = true;
        if (kDebugMode) print('✅ Firebase initialized');
      } catch (e) {
        if (kDebugMode) print('❌ Firebase init failed: $e');
      }
    }
  }
}
