import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String? _baseUrl;
  bool _loaded = false;

  Future<String> get baseUrl async {
    if (!_loaded) {
      await _loadSettings();
    }
    return _baseUrl ?? 'http://localhost:3000';
  }

  Future<void> _loadSettings() async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/config/settings.json');
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      _baseUrl = json['backend_url'] as String?;
      _loaded = true;
    } catch (e) {
      debugPrint('Failed to load settings: $e');
      _loaded = true;
    }
  }
}
