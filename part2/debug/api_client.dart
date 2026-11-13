// Fixed reference implementation for Part 2.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/shift.dart';

class ApiClient {
  ApiClient(this.baseUrl, this.client, this.secureStorage);
  final String baseUrl;
  final http.Client client;
  final FlutterSecureStorage secureStorage;

  Future<void> saveSession(String token, String email) async {
    await secureStorage.write(key: 'token', value: token);
    await secureStorage.write(key: 'email', value: email);
    // Never persist the user's password.
  }

  Future<Map<String, dynamic>> get(String path, Map<String, String> query) async {
    final token = await secureStorage.read(key: 'token');
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final response = await client.get(uri, headers: {
      if (token != null) 'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Request failed (${response.statusCode}). Please try again.');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // Return only the first page here; pagination belongs in the repository/list controller.
  Future<List<Shift>> firstOpenShiftPage(String department) async {
    final data = await get('/shifts/open', {'department': department, 'limit': '20'});
    return (data['items'] as List).map((item) => Shift.fromJson(item)).toList();
  }
}
