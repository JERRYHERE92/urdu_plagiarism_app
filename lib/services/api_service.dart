import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;


class ApiService {
  // TODO: replace with your actual backend URL
  //static const String baseUrl = 'http://192.168.100.72:8000';
  static const String baseUrl = 'http://192.168.1.105:8000';
  //flutter build apk

  /// Signup: name, email, password
  static Future<http.Response> signup({
    required String name,
    required String email,
    required String password,
  }) {
    final uri = Uri.parse('$baseUrl/signup/');
    return http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
  }

  /// Login: email, password
  static Future<http.Response> login({
    required String email,
    required String password,
  }) {
    final uri = Uri.parse('$baseUrl/login/');
    return http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
  }

  /// Forgot Password: email, new_password
  static Future<http.Response> forgotPassword({
    required String email,
    required String newPassword,
  }) {
    final uri = Uri.parse('$baseUrl/forget-password/');
    return http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'new_password': newPassword}),
    );
  }

  /// (Optional) Change Password: old_password, new_password
  static Future<http.Response> changePassword({
    required String token,
    required String oldPassword,
    required String newPassword,
  }) {
    final uri = Uri.parse('$baseUrl/change-password/');
    return http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'old_password': oldPassword,
        'new_password': newPassword,
      }),
    );
  }

  /// (Optional) Get Profile
  static Future<http.Response> getProfile({required String token}) {
    final uri = Uri.parse('$baseUrl/profile/');
    return http.get(uri, headers: {'Authorization': 'Bearer $token'});
  }

  static Future<http.Response> getHistory({required String token}) {
    final uri = Uri.parse('$baseUrl/history/');
    return http.get(uri, headers: {'Authorization': 'Bearer $token'});
  }

   static Future<http.Response> checkPlagiarism({
  required File file,
  required String token,
}) async {
  final uri = Uri.parse('$baseUrl/check-plagiarism/');
  final request = http.MultipartRequest('POST', uri)
    ..headers['Authorization'] = 'Bearer $token'
    ..files.add(await http.MultipartFile.fromPath('file', file.path));
  final streamedResponse = await request.send();
  return http.Response.fromStream(streamedResponse);
}

}
