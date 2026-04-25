import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator to access localhost.
  // If you are using an iOS simulator, change this to 127.0.0.1 or localhost.
  // If you are testing on a physical device, use your computer's local IP address.
  static const String baseUrl = 'http://localhost:5000/api';

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

  static Future<List<Map<String, dynamic>>> checkInteractions(List<String> medicines) async {
    final url = Uri.parse('$baseUrl/check-interaction');
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
        body: jsonEncode({'medicines': medicines}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['interactions']);
      } else if (response.statusCode == 404) {
        throw Exception('One or more medicines not recognised by RxNorm.');
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? 'Interaction check failed.');
      }
    } catch (e) {
      throw Exception('Network error or server unavailable: $e');
    }
  }
  /// Add Reminder API
  ///
  /// Endpoint: POST /add-reminder
  static Future<Map<String, dynamic>> addReminder({
    required String medicineName,
    required String time,
    String frequency = 'daily',
  }) async {
    final url = Uri.parse('$baseUrl/add-reminder');
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
          'medicineName': medicineName,
          'time': time,
          'frequency': frequency,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to add reminder');
      }
    } catch (e) {
      throw Exception('Network error or server unavailable: $e');
    }
  }

  /// Update Reminder Status API
  ///
  /// Endpoint: PUT /update-reminder/:id
  static Future<Map<String, dynamic>> updateReminderStatus(String id, bool isTaken) async {
    final url = Uri.parse('$baseUrl/update-reminder/$id');
    final token = await getToken();

    if (token == null) {
      throw Exception('Not authenticated. Please log in again.');
    }

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'isTaken': isTaken,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to update reminder');
      }
    } catch (e) {
      throw Exception('Network error or server unavailable: $e');
    }
  }

  /// Get Reminders API
  ///
  /// Endpoint: GET /reminders
  static Future<List<dynamic>> getReminders() async {
    final url = Uri.parse('$baseUrl/reminders');
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
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to fetch reminders');
      }
    } catch (e) {
      throw Exception('Network error or server unavailable: $e');
    }
  }

  /// Get Profile API
  ///
  /// Endpoint: GET /profile
  static Future<Map<String, dynamic>> getProfile() async {
    final url = Uri.parse('$baseUrl/profile');
    final token = await getToken();

    if (token == null) {
      throw Exception('Not authenticated.');
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
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to load profile');
      }
    } catch (e) {
      throw Exception('Network error or server unavailable: $e');
    }
  }

  /// Update Profile API
  ///
  /// Endpoint: PUT /profile
  static Future<Map<String, dynamic>> updateProfile({
    List<String>? allergies,
    String? medicalHistory,
  }) async {
    final url = Uri.parse('$baseUrl/profile');
    final token = await getToken();

    if (token == null) {
      throw Exception('Not authenticated.');
    }

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (allergies != null) 'allergies': allergies,
          if (medicalHistory != null) 'medicalHistory': medicalHistory,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      throw Exception('Network error or server unavailable: $e');
    }
  }
}

