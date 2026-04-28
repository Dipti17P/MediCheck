import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_service.dart';
import 'notification_service.dart';
import '../config/env_config.dart';

class ApiService {
  static String get baseUrl => EnvConfig.current.baseUrl;
  static Function()? onTokenExpired;

  // ── Auth header helper ────────────────────────────
  static Future<Map<String, String>> _headers() async {
    final token = await TokenService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Centralized response handler ──────────────────
  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw TokenExpiredException('Session expired.');
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? body['error'] ?? 'Something went wrong.');
    }
  }

  // ── Token Refresh Logic ───────────────────────────
  static Future<bool> refreshToken() async {
    final refreshTok = await TokenService.getRefreshToken();
    if (refreshTok == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshTok}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          await TokenService.saveToken(data['token']);
        }
        if (data['refreshToken'] != null) {
          await TokenService.saveRefreshToken(data['refreshToken']);
        }
        return true;
      }
    } catch (e) {
      print('Token refresh failed: $e');
    }
    return false;
  }

  // ── Base Request with Auto-Refresh ────────────────
  static Future<dynamic> _safeRequest(
    Future<http.Response> Function() requestFn,
  ) async {
    var response = await requestFn();

    if (response.statusCode == 401) {
      final success = await refreshToken();
      if (success) {
        // Retry the request once
        response = await requestFn();
      } else {
        // Permanent failure
        onTokenExpired?.call();
      }
    }

    return _handleResponse(response);
  }

  // ── Login ─────────────────────────────────────────
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = _handleResponse(response);
    if (data['token'] != null) {
      await TokenService.saveToken(data['token']);
    }
    if (data['refreshToken'] != null) {
      await TokenService.saveRefreshToken(data['refreshToken']);
    }
    if (data['user'] != null && data['user']['id'] != null) {
      await TokenService.saveUserId(data['user']['id']);
    }
    return data;
  }

  // ── Signup ────────────────────────────────────────
  static Future<Map<String, dynamic>> signup(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    final data = _handleResponse(response);
    if (data['token'] != null) {
      await TokenService.saveToken(data['token']);
    }
    if (data['refreshToken'] != null) {
      await TokenService.saveRefreshToken(data['refreshToken']);
    }
    return data;
  }

  // ── Logout ────────────────────────────────────────
  static Future<void> logout() async {
    await TokenService.clearAll();
    await NotificationService().cancelAll();
  }

  // ── Medicine Methods ──────────────────────────────
  static Future<Map<String, dynamic>> addMedicine({
    required String name,
    required String uses,
    required String sideEffects,
  }) async {
    final data = await _safeRequest(() async => http.post(
      Uri.parse('$baseUrl/add-medicine'),
      headers: await _headers(),
      body: jsonEncode({
        'name': name,
        'uses': uses,
        'sideEffects': sideEffects.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      }),
    ));
    return data['medicine'] ?? data;
  }

  static Future<List<dynamic>> getMedicines() async {
    final data = await _safeRequest(() async => http.get(
      Uri.parse('$baseUrl/medicines'),
      headers: await _headers(),
    ));
    return data['medicines'] ?? [];
  }

  static Future<Map<String, dynamic>> checkInteractions(List<String> medicines) async {
    return await _safeRequest(() async => http.post(
      Uri.parse('$baseUrl/check-interaction'),
      headers: await _headers(),
      body: jsonEncode({'medicines': medicines}),
    ));
  }

  // ── Reminder Methods ──────────────────────────────
  static Future<Map<String, dynamic>> addReminder(Map<String, dynamic> reminder) async {
    final data = await _safeRequest(() async => http.post(
      Uri.parse('$baseUrl/add-reminder'),
      headers: await _headers(),
      body: jsonEncode(reminder),
    ));
    return data['reminder'] ?? data;
  }

  static Future<List<dynamic>> getReminders() async {
    final data = await _safeRequest(() async => http.get(
      Uri.parse('$baseUrl/reminders'),
      headers: await _headers(),
    ));
    return data['reminders'] ?? [];
  }

  static Future<void> deleteReminder(String id) async {
    await _safeRequest(() async => http.delete(
      Uri.parse('$baseUrl/reminders/$id'),
      headers: await _headers(),
    ));
  }

  // ── FCM & Profile ────────────────────────────────
  static Future<void> saveFcmToken(String token) async {
    try {
      await _safeRequest(() async => http.post(
        Uri.parse('$baseUrl/fcm-token'),
        headers: await _headers(),
        body: jsonEncode({'fcmToken': token}),
      ));
    } catch (e) {
      print('Failed to save FCM token: $e');
    }
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final data = await _safeRequest(() async => http.get(
      Uri.parse('$baseUrl/profile'),
      headers: await _headers(),
    ));
    return data['user'] ?? {};
  }

  static Future<Map<String, dynamic>> updateProfile({
    List<String>? allergies,
    String? medicalHistory,
  }) async {
    return await _safeRequest(() async => http.put(
      Uri.parse('$baseUrl/profile'),
      headers: await _headers(),
      body: jsonEncode({
        if (allergies != null) 'allergies': allergies,
        if (medicalHistory != null) 'medicalHistory': medicalHistory,
      }),
    ));
  }

  static Future<Map<String, dynamic>> analyzeSymptoms(String symptoms) async {
    return await _safeRequest(() async => http.post(
      Uri.parse('$baseUrl/analyze-symptoms'),
      headers: await _headers(),
      body: jsonEncode({'symptoms': symptoms}),
    ));
  }

  static Future<Map<String, dynamic>> exportData() async {
    return await _safeRequest(() async => http.get(
      Uri.parse('$baseUrl/export-data'),
      headers: await _headers(),
    ));
  }

  static Future<void> deleteAccount() async {
    await _safeRequest(() async => http.delete(
      Uri.parse('$baseUrl/account'),
      headers: await _headers(),
    ));
    await TokenService.clearAll();
  }
}

// Custom exception for expired tokens
class TokenExpiredException implements Exception {
  final String message;
  TokenExpiredException(this.message);
  @override
  String toString() => message;
}
