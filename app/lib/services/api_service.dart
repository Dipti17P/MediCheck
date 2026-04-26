import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_service.dart';
import 'notification_service.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api';

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
      // Token expired — throw so the app can redirect to login
      throw TokenExpiredException('Session expired. Please log in again.');
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? body['error'] ?? 'Something went wrong.');
    }
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
    final response = await http.post(
      Uri.parse('$baseUrl/add-medicine'),
      headers: await _headers(),
      body: jsonEncode({
        'name': name,
        'uses': uses,
        'sideEffects': sideEffects.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      }),
    );
    return _handleResponse(response);
  }

  static Future<List<dynamic>> getMedicines() async {
    final response = await http.get(
      Uri.parse('$baseUrl/medicines'),
      headers: await _headers(),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> checkInteractions(List<String> medicines) async {
    final response = await http.post(
      Uri.parse('$baseUrl/check-interaction'),
      headers: await _headers(),
      body: jsonEncode({'medicines': medicines}),
    );
    return _handleResponse(response);
  }

  // ── Reminder Methods ──────────────────────────────
  static Future<Map<String, dynamic>> addReminder(Map<String, dynamic> reminder) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add-reminder'),
      headers: await _headers(),
      body: jsonEncode(reminder),
    );
    return _handleResponse(response);
  }

  static Future<List<dynamic>> getReminders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/reminders'),
      headers: await _headers(),
    );
    return _handleResponse(response);
  }

  static Future<void> deleteReminder(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/reminders/$id'),
      headers: await _headers(),
    );
    _handleResponse(response);
  }

  // ── FCM & Profile ────────────────────────────────
  static Future<void> saveFcmToken(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/fcm-token'),
        headers: await _headers(),
        body: jsonEncode({'fcmToken': token}),
      );
      _handleResponse(response);
    } catch (e) {
      print('Failed to save FCM token: $e');
    }
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: await _headers(),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateProfile({
    List<String>? allergies,
    String? medicalHistory,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: await _headers(),
      body: jsonEncode({
        if (allergies != null) 'allergies': allergies,
        if (medicalHistory != null) 'medicalHistory': medicalHistory,
      }),
    );
    return _handleResponse(response);
  }
}

// Custom exception for expired tokens
class TokenExpiredException implements Exception {
  final String message;
  TokenExpiredException(this.message);
  @override
  String toString() => message;
}
