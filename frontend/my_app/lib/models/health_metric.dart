// lib/models/health_metric.dart

class HealthMetric {
  final int? id;
  final String type;
  final double value;
  final String? source;
  final DateTime? timestamp;

  HealthMetric({
    this.id,
    required this.type,
    required this.value,
    this.source,
    this.timestamp,
  });

  // Parse response from backend
  factory HealthMetric.fromJson(Map<String, dynamic> json) {
    return HealthMetric(
      id: json['id'],
      type: json['type'] as String,
      value: (json['value'] as num).toDouble(),
      source: json['source'] as String?,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }

  // Convert to JSON for sending to backend
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'value': value,
      if (source != null && source!.isNotEmpty) 'source': source,
    };
  }

  @override
  String toString() {
    return 'HealthMetric(type: $type, value: $value, source: $source, timestamp: $timestamp)';
  }
}