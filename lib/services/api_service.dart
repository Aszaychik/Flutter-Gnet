import 'dart:convert';
import 'dart:typed_data';
import 'package:gnet_app/models/activity_model.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:gnet_app/services/storage_service.dart';
import 'package:path/path.dart' as path;

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

  // Create new activity
  Future<bool> createActivity({
    required Uint8List imageBytes,
    required String imageName,
    required String title,
    required String description,
  }) async {
    final token = await StorageService.getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/activity/store'),
    );

    // Add authorization header
    request.headers['Authorization'] = 'Bearer $token';

    // Add image file
    final multipartFile = http.MultipartFile.fromBytes(
      'file',
      imageBytes,
      filename: imageName,
      contentType: MediaType('image', path.extension(imageName).replaceFirst('.', '')),
    );
    request.files.add(multipartFile);

    // Add text fields
    request.fields['title'] = title;
    request.fields['description'] = description;

    // Send request
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      final jsonResponse = jsonDecode(responseBody);
      return jsonResponse['success'] == true;
    } else {
      throw Exception('Failed to create activity: ${response.statusCode} - $responseBody');
    }
  }
}