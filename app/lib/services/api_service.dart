import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator to access localhost.
  // If you are using an iOS simulator, change this to 127.0.0.1 or localhost.
  // If you are testing on a physical device, use your computer's local IP address.
  static const String baseUrl = 'http://10.133.168.235:5000/api';

  /// Stores the JWT token in shared preferences
  static Future<void> _storeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  /// Retrieves the JWT token from shared preferences
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  /// Clears the JWT token on logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  /// Login API
  /// 
  /// Endpoint: POST /login
  /// Accepts [email] and [password].
  /// Returns the parsed JSON response or throws an Exception on failure.
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Assuming the backend returns a token field
        if (responseData['token'] != null) {
          await _storeToken(responseData['token']);
        }
        return responseData;
      } else {
        // Throw the error message from the backend, if available
        throw Exception(responseData['message'] ?? 'Failed to login');
      }
    } catch (e) {
      throw Exception('Network error or server unavailable: $e');
    }
  }

  /// Signup API
  /// 
  /// Endpoint: POST /signup
  /// Accepts [name], [email], and [password].
  /// Returns the parsed JSON response or throws an Exception on failure.
  static Future<Map<String, dynamic>> signup(String name, String email, String password) async {
    final url = Uri.parse('$baseUrl/signup');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Some backends might automatically log in the user upon signup
        if (responseData['token'] != null) {
          await _storeToken(responseData['token']);
        }
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to sign up');
      }
    } catch (e) {
      throw Exception('Network error or server unavailable: $e');
    }
  }

  /// Add Medicine API
  ///
  /// Endpoint: POST /add-medicine
  /// Requires [name], [uses], and [sideEffects].
  /// Sends the JWT token in the Authorization header.
  static Future<Map<String, dynamic>> addMedicine({
    required String name,
    required String uses,
    required String sideEffects,
  }) async {
    final url = Uri.parse('$baseUrl/add-medicine');
    final token = await getToken();

    if (token == null) {
      throw Exception('Not authenticated. Please log in again.');
    }

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'uses': uses,
          'sideEffects': sideEffects.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to add medicine');
      }
    } catch (e) {
      throw Exception('Network error or server unavailable: $e');
    }
  }

  /// Get Medicines API
  ///
  /// Endpoint: GET /medicines
  /// Fetches the list of medicines for the authenticated user.
  static Future<List<dynamic>> getMedicines() async {
    final url = Uri.parse('$baseUrl/medicines');
    final token = await getToken();

    if (token == null) {
      throw Exception('Not authenticated. Please log in again.');
    }

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Assuming the backend returns a list of medicines
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to fetch medicines');
      }
    } catch (e) {
      throw Exception('Network error or server unavailable: $e');
    }
  }
}
