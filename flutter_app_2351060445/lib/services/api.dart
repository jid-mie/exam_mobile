import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  ApiClient({required this.baseUrl});

  final String baseUrl;

  static const _tokenKey = 'auth_token';
  static const _roleKey = 'auth_role';
  static const _userIdKey = 'auth_user_id';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  Future<void> setAuth({required String token, required String role, int? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_roleKey, role);
    if (userId != null) {
      await prefs.setInt(_userIdKey, userId);
    } else {
      await prefs.remove(_userIdKey);
    }
  }

  Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_userIdKey);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, String>? headers,
    Object? body,
    bool auth = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final h = <String, String>{
      'Content-Type': 'application/json',
      if (headers != null) ...headers,
    };
    if (auth) {
      final token = await getToken();
      if (token != null) h['Authorization'] = 'Bearer $token';
    }
    final resp = await http.post(uri, headers: h, body: jsonEncode(body ?? {}));
    return _decode(resp);
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? headers,
    bool auth = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final h = <String, String>{
      if (headers != null) ...headers,
    };
    if (auth) {
      final token = await getToken();
      if (token != null) h['Authorization'] = 'Bearer $token';
    }
    final resp = await http.get(uri, headers: h);
    return _decode(resp);
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    Map<String, String>? headers,
    Object? body,
    bool auth = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final h = <String, String>{
      'Content-Type': 'application/json',
      if (headers != null) ...headers,
    };
    if (auth) {
      final token = await getToken();
      if (token != null) h['Authorization'] = 'Bearer $token';
    }
    final resp = await http.put(uri, headers: h, body: jsonEncode(body ?? {}));
    return _decode(resp);
  }

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    Map<String, String>? headers,
    bool auth = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final h = <String, String>{
      if (headers != null) ...headers,
    };
    if (auth) {
      final token = await getToken();
      if (token != null) h['Authorization'] = 'Bearer $token';
    }
    final resp = await http.delete(uri, headers: h);
    return _decode(resp);
  }

  Map<String, dynamic> _decode(http.Response resp) {
    final jsonBody = resp.body.isEmpty ? <String, dynamic>{} : jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode >= 200 && resp.statusCode < 300) return jsonBody;
    String message = (jsonBody['message'] as String?) ?? 'Request failed';
    final errors = jsonBody['errors'];
    if (message == 'Validation error' && errors is List) {
      final parts = errors
          .map((e) => '${e['path'] ?? 'field'}: ${e['message'] ?? 'invalid'}')
          .toList();
      if (parts.isNotEmpty) message = parts.join(', ');
    }
    throw ApiException(
      statusCode: resp.statusCode,
      message: message,
      raw: jsonBody,
    );
  }
}

class ApiException implements Exception {
  ApiException({required this.statusCode, required this.message, required this.raw});

  final int statusCode;
  final String message;
  final Map<String, dynamic> raw;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
