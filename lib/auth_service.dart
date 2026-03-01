import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:label_lensv2/user_profile.dart';
import 'package:intl/intl.dart';
import 'package:label_lensv2/scan_result.dart';


class AuthService {
  // TODO: Replace with your actual backend URL
  final String _apiBaseUrl = "https://nutrilens-015o.onrender.com";
  final _storage = const FlutterSecureStorage();

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/api/users/login'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['token'] != null) {
          await _storage.write(key: 'authToken', value: data['token']);
          return true;
        } else {
          throw Exception(data['message'] ?? 'Login failed: An unknown error occurred.');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to login. Status code: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'authToken');
  }

  Future<bool> register(String email, String password) async {
    try {
      // NOTE: The user-provided endpoint 'api/users/login' for signup seems incorrect.
      // Assuming a standard REST endpoint like '/register' on the auth service.
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/api/users/register'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['token'] != null) {
          await _storage.write(key: 'authToken', value: data['token']);
          return true;
        } else {
          throw Exception(data['message'] ?? 'Signup failed: An unknown error occurred.');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to sign up. Status code: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: 'authToken');
  }

  Future<UserProfile> getUserProfile() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Authentication token not found. Please log in again.');
    }

    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/api/users/profile'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['success'] == true && responseBody['profile'] != null) {
          return UserProfile.fromJson(responseBody['profile']);
        } else {
          throw Exception(responseBody['message'] ?? 'Failed to parse profile data.');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch profile. Status code: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateProfile({
    String? name,
    int? age,
    String? gender,
    String? diet,
    List<String>? allergies,
    List<String>? healthIssues,
    List<String>? likes,
    List<String>? dislikes,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Authentication token not found. Please log in again.');
    }

    final Map<String, dynamic> body = {
      'name': name,
      'age': age,
      'gender': gender?.toLowerCase(),
      'diet': diet?.toLowerCase(),
      'allergies': allergies,
      'healthIssues': healthIssues,
      'likes': likes,
      'avoid': dislikes, // Mapping dislikes from UI to 'avoid' in API
    };

    // Remove keys with null values to avoid sending them in the request body.
    body.removeWhere((key, value) {
      return value == null || (value is String && value.isEmpty) || (value is List && value.isEmpty);
    });

    try {
      final response = await http.put(
        Uri.parse('$_apiBaseUrl/api/users/profile'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update profile. Status code: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> saveScanForLater(String scanId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Authentication token not found. Please log in again.');
    }

    try {
      // Assuming an endpoint like this exists.
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/api/scan/save/$scanId'),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        return responseBody['success'] == true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to save scan. Status code: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

   Future<bool> isLoggedIn() async {
    final token = await _getToken();
    // For a more robust check, you could decode the JWT and check its expiration date.
    return token != null;
  }

  Future<ScanResult> scanIngredients(List<String> ingredients, {String? productName}) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Authentication token not found. Please log in again.');
    }

    final Map<String, dynamic> body = {
      'ingredients': ingredients,
    };

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/api/scan'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        return ScanResult.fromJson(responseBody, productName: productName ?? 'Scanned Product');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to scan. Status code: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ScanHistoryItem>> getScanHistory() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Authentication token not found. Please log in again.');
    }

    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/api/scan/history'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['success'] == true && responseBody['history'] != null) {
          final List<dynamic> historyList = responseBody['history'];
          return historyList
              .map((item) => ScanHistoryItem.fromJson(item))
              .toList();
        } else {
          throw Exception(responseBody['message'] ?? 'Failed to parse history data.');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch history. Status code: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}

class ScanHistoryItem {
  final ScanResult result;
  final String id;
  final DateTime createdAt;
  final String productName;

  ScanHistoryItem({
    required this.result,
    required this.id,
    required this.createdAt,
    required this.productName,
  });

  factory ScanHistoryItem.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.parse(json['createdAt']);
    final productName = 'Scan on ${DateFormat.yMMMd().format(createdAt.toLocal())}';

    return ScanHistoryItem(
      id: json['_id'],
      result: ScanResult.fromJson(json['result'], productName: productName),
      createdAt: createdAt,
      productName: productName,
    );
  }
}
