import 'dart:convert';
import 'dart:typed_data';
import 'package:gnet_app/models/activity_model.dart';
import 'package:http/http.dart' as http;
import 'package:gnet_app/services/storage_service.dart';

class ApiService {
  static const String baseUrl = "http://10.2.11.13:8000/api/v1";

  // Helper method to get auth headers
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Helper method to get auth headers for non-JSON requests
  Future<Map<String, String>> _getAuthHeadersBasic() async {
    final token = await StorageService.getToken();
    return {'Authorization': 'Bearer $token'};
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Login failed: ${response.statusCode}');
    }
  }

  // Fetch All Activity
  Future<List<Activity>> getActivities({int page = 1}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/activity?page=$page'),
      headers: await _getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final activities = (jsonData['data']['data'] as List)
          .map((item) => Activity.fromJson(item))
          .toList();
      return activities;
    } else {
      throw Exception('Failed to load activities: ${response.statusCode}');
    }
  }

  // Get full image URL
  static String getFullImageUrl(String imagePath) {
    // Properly encode the image path and construct URL
    final encodedPath = Uri.encodeComponent(imagePath);
    return '$baseUrl/nextcloud/file/Activity/$encodedPath';
  }

  // Get image bytes directly
  Future<Uint8List> getImageBytes(String imagePath) async {
    final response = await http.get(
      Uri.parse(getFullImageUrl(imagePath)),
      headers: await _getAuthHeadersBasic(),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to load image: ${response.statusCode}');
    }
  }
}