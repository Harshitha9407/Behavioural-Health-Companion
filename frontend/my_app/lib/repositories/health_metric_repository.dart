// lib/repositories/health_metric_repository.dart

import '../services/api_service.dart';
import '../models/health_metric.dart';

class HealthMetricRepository {
  final ApiService _api = ApiService();

  /// Save a new health metric
  Future<bool> saveHealthMetric(HealthMetric metric) async {
    try {
      print('📤 Saving health metric: ${metric.type} = ${metric.value}');
      
      final response = await _api.post('/health-metrics', metric.toJson());
      
      print('✅ Health metric saved: $response');
      return true;
    } catch (e) {
      print('❌ Error saving health metric: $e');
      return false;
    }
  }

  /// Get all health metrics for the current user
  Future<List<HealthMetric>> getAllHealthMetrics() async {
    try {
      print('📤 Fetching all health metrics...');
      
      final response = await _api.get('/health-metrics/user');
      
      if (response == null) {
        print('⚠️ No response from server');
        return [];
      }

      // The response structure from your Java DTO
      if (response is Map<String, dynamic> && response.containsKey('healthMetrics')) {
        final List<dynamic> metricsJson = response['healthMetrics'] as List<dynamic>;
        
        final metrics = metricsJson
            .map((json) => HealthMetric.fromJson(json as Map<String, dynamic>))
            .toList();
        
        print('✅ Loaded ${metrics.length} health metrics');
        return metrics;
      }
      
      print('⚠️ Unexpected response format: $response');
      return [];
      
    } catch (e) {
      print('❌ Error fetching health metrics: $e');
      rethrow; // Re-throw to handle in UI
    }
  }

  /// Get health metrics filtered by type
  Future<List<HealthMetric>> getHealthMetricsByType(String type) async {
    try {
      print('📤 Fetching health metrics for type: $type');
      
      final response = await _api.get('/health-metrics/$type');
      
      if (response == null) {
        print('⚠️ No response from server');
        return [];
      }

      if (response is Map<String, dynamic> && response.containsKey('healthMetrics')) {
        final List<dynamic> metricsJson = response['healthMetrics'] as List<dynamic>;
        
        final metrics = metricsJson
            .map((json) => HealthMetric.fromJson(json as Map<String, dynamic>))
            .toList();
        
        print('✅ Loaded ${metrics.length} metrics for type: $type');
        return metrics;
      }
      
      print('⚠️ Unexpected response format: $response');
      return [];
      
    } catch (e) {
      print('❌ Error fetching metrics by type: $e');
      rethrow;
    }
  }
}