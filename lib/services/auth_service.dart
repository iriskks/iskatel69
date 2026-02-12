import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _usersKey = 'users';
  static const String _currentUserKey = 'current_user';

  Future<Map<String, String>> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_usersKey);
    if (jsonStr == null) return {};
    final Map<String, dynamic> map = json.decode(jsonStr);
    return map.map((k, v) => MapEntry(k, v as String));
  }

  Future<void> _saveUsers(Map<String, String> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersKey, json.encode(users));
  }

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> isLoginTaken(String login) async {
    final users = await _loadUsers();
    return users.containsKey(login);
  }

  /// Returns true if registration succeeded. Returns false if login already exists.
  Future<bool> register(String login, String password) async {
    if (login.isEmpty || password.isEmpty) return false;
    final users = await _loadUsers();
    if (users.containsKey(login)) return false;
    final hashed = hashPassword(password);
    users[login] = hashed;
    await _saveUsers(users);
    return true;
  }

  /// Returns true if login successful.
  Future<bool> login(String login, String password) async {
    final users = await _loadUsers();
    if (!users.containsKey(login)) return false;
    final hashed = hashPassword(password);
    if (users[login] == hashed) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserKey, login);
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  Future<String?> currentUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUserKey);
  }
}
