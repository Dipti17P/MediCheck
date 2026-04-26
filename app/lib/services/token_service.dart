import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  // Use FlutterSecureStorage for mobile (Android/iOS)
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _tokenKey = 'jwt_token';
  static const _refreshKey = 'refresh_token';
  static const _userIdKey = 'user_id';

  // ── Save ──────────────────────────────────────────
  static Future<void> saveToken(String token) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } else {
      await _secureStorage.write(key: _tokenKey, value: token);
    }
  }

  static Future<void> saveRefreshToken(String token) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_refreshKey, token);
    } else {
      await _secureStorage.write(key: _refreshKey, value: token);
    }
  }

  static Future<void> saveUserId(String userId) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, userId);
    } else {
      await _secureStorage.write(key: _userIdKey, value: userId);
    }
  }

  // ── Read ──────────────────────────────────────────
  static Future<String?> getToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    }
    return await _secureStorage.read(key: _tokenKey);
  }

  static Future<String?> getRefreshToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshKey);
    }
    return await _secureStorage.read(key: _refreshKey);
  }

  static Future<String?> getUserId() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userIdKey);
    }
    return await _secureStorage.read(key: _userIdKey);
  }

  // ── Check ─────────────────────────────────────────
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ── Clear (logout) ────────────────────────────────
  static Future<void> clearAll() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_refreshKey);
      await prefs.remove(_userIdKey);
    } else {
      await _secureStorage.deleteAll();
    }
  }
}
