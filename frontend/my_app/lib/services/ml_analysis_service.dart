import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class MLAnalysisService {
  static const String baseUrl = 'http://10.0.2.2:8081/api/analysis';
  
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get Firebase Auth Token
  Future<String?> _getAuthToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        print('🔑 ML Service Token obtained');
        return token;
      }
      print('❌ No authenticated user');
      return null;
    } catch (e) {
      print('❌ Error getting token: $e');
      return null;
    }
  }

  // Generic method to get analysis from any ML model
  Future<Map<String, dynamic>?> getAnalysis(String modelName) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      print('📤 GET ML Analysis: $baseUrl/$modelName');

      final response = await http.get(
        Uri.parse('$baseUrl/$modelName'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 ML Response Status: ${response.statusCode}');
      print('📥 ML Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ ML Analysis retrieved for model: $modelName');
        return data;
      } else {
        throw Exception('Failed to get analysis: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting ML analysis: $e');
      return null;
    }
  }

  // Specific analysis methods for each model
  
  // 1. Stress Level Analysis
  Future<Map<String, dynamic>?> getStressAnalysis() async {
    return await getAnalysis('stress_level_classifier');
  }

  // 2. Mood Prediction
  Future<Map<String, dynamic>?> getMoodPrediction() async {
    return await getAnalysis('mood_predictor');
  }

  // 3. Anxiety Level
  Future<Map<String, dynamic>?> getAnxietyAnalysis() async {
    return await getAnalysis('anxiety_level_classifier');
  }

  // 4. Sleep Quality
  Future<Map<String, dynamic>?> getSleepQualityAnalysis() async {
    return await getAnalysis('sleep_quality_predictor');
  }

  // 5. User Normal Range
  Future<Map<String, dynamic>?> getUserNormalRange() async {
    return await getAnalysis('user_normal_range_predictor');
  }

  // 6. Anomaly Detection
  Future<Map<String, dynamic>?> getAnomalyDetection() async {
    return await getAnalysis('anomaly_detector');
  }

  // Get all analyses at once
  Future<Map<String, Map<String, dynamic>?>> getAllAnalyses() async {
    try {
      print('📊 Fetching all ML analyses...');
      
      final results = await Future.wait([
        getStressAnalysis(),
        getMoodPrediction(),
        getAnxietyAnalysis(),
        getSleepQualityAnalysis(),
        getUserNormalRange(),
        getAnomalyDetection(),
      ]);

      return {
        'stress': results[0],
        'mood': results[1],
        'anxiety': results[2],
        'sleep': results[3],
        'normalRange': results[4],
        'anomaly': results[5],
      };
    } catch (e) {
      print('❌ Error fetching all analyses: $e');
      return {};
    }
  }

  // Helper method to interpret predictions
  String interpretStressLevel(List<dynamic>? prediction) {
    if (prediction == null || prediction.isEmpty) return 'Unknown';
    
    final level = prediction[0];
    if (level == 0) return 'Low Stress';
    if (level == 1) return 'Moderate Stress';
    if (level == 2) return 'High Stress';
    return 'Unknown';
  }

  String interpretMood(List<dynamic>? prediction) {
    if (prediction == null || prediction.isEmpty) return 'Unknown';
    
    final mood = prediction[0];
    if (mood == 0) return 'Negative';
    if (mood == 1) return 'Neutral';
    if (mood == 2) return 'Positive';
    return 'Unknown';
  }

  String interpretAnxietyLevel(List<dynamic>? prediction) {
    if (prediction == null || prediction.isEmpty) return 'Unknown';
    
    final level = prediction[0];
    if (level == 0) return 'Low Anxiety';
    if (level == 1) return 'Moderate Anxiety';
    if (level == 2) return 'High Anxiety';
    return 'Unknown';
  }

  String interpretSleepQuality(dynamic prediction) {
    if (prediction == null) return 'Unknown';
    
    try {
      final score = double.parse(prediction.toString());
      if (score >= 8) return 'Excellent Sleep';
      if (score >= 6) return 'Good Sleep';
      if (score >= 4) return 'Fair Sleep';
      return 'Poor Sleep';
    } catch (e) {
      return 'Unknown';
    }
  }
}