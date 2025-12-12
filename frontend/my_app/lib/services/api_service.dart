import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  // ✅ CORRECT URL for Android Emulator
  static const String baseUrl = 'http://10.0.2.2:8081/api';
  
  // For iOS Simulator use: 'http://localhost:8080/api'
  // For Physical Device use: 'http://YOUR_PC_IP:8080/api'
  
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get Firebase ID Token (your backend expects this!)
  Future<String?> _getIdToken() async {
    User? user = _auth.currentUser;
    if (user != null) {
      String? token = await user.getIdToken();
      print('🔑 FULL FIREBASE TOKEN: Bearer $token');
      return token;
    }
    print('⚠️ No Firebase user found');
    return null;
  }
  

  // GET request
  Future<dynamic> get(String endpoint) async {
    try {
      final token = await _getIdToken();
      
      print('📤 GET: $baseUrl$endpoint');
      
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');
      
      return _handleResponse(response);
    } catch (e) {
      print('❌ GET Error: $e');
      rethrow;
    }
  }

  // POST request
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final token = await _getIdToken();
      
      print('📤 POST: $baseUrl$endpoint');
      print('📤 Data: ${json.encode(data)}');
      
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');
      
      return _handleResponse(response);
    } catch (e) {
      print('❌ POST Error: $e');
      rethrow;
    }
  }

  // PUT request
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final token = await _getIdToken();
      
      print('📤 PUT: $baseUrl$endpoint');
      print('📤 Data: ${json.encode(data)}');
      
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');
      
      return _handleResponse(response);
    } catch (e) {
      print('❌ PUT Error: $e');
      rethrow;
    }
  }

  // DELETE request
  Future<dynamic> delete(String endpoint) async {
    try {
      final token = await _getIdToken();
      
      print('📤 DELETE: $baseUrl$endpoint');
      
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print('📥 Response Status: ${response.statusCode}');
      
      return _handleResponse(response);
    } catch (e) {
      print('❌ DELETE Error: $e');
      rethrow;
    }
  }

  // Handle API responses
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {'success': true};
      try {
        return json.decode(response.body);
      } catch (e) {
        print('⚠️ Failed to decode JSON: ${response.body}');
        return {'data': response.body};
      }
    } else if (response.statusCode == 401) {
      throw Exception('❌ Unauthorized - Please login again');
    } else if (response.statusCode == 404) {
      throw Exception('❌ Not found');
    } else {
      throw Exception('❌ Error ${response.statusCode}: ${response.body}');
    }
    
  }
}