class MLAnalysisResult {
  final List<dynamic>? prediction;
  final List<List<double>>? probabilities;
  final String? modelId;
  final String? modelName;
  final String? timestamp;
  final String? error;

  MLAnalysisResult({
    this.prediction,
    this.probabilities,
    this.modelId,
    this.modelName,
    this.timestamp,
    this.error,
  });

  factory MLAnalysisResult.fromJson(Map<String, dynamic> json) {
    return MLAnalysisResult(
      prediction: json['prediction'] as List<dynamic>?,
      probabilities: (json['probabilities'] as List<dynamic>?)
          ?.map((e) => (e as List<dynamic>).map((i) => (i as num).toDouble()).toList())
          .toList(),
      modelId: json['modelId'] as String?,
      modelName: json['modelName'] as String?,
      timestamp: json['timestamp'] as String?,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prediction': prediction,
      'probabilities': probabilities,
      'modelId': modelId,
      'modelName': modelName,
      'timestamp': timestamp,
      'error': error,
    };
  }

  bool get hasError => error != null && error!.isNotEmpty;
  bool get isValid => prediction != null && !hasError;
}

class MLAnalysisOverview {
  final MLAnalysisResult? stress;
  final MLAnalysisResult? mood;
  final MLAnalysisResult? anxiety;
  final MLAnalysisResult? sleep;
  final MLAnalysisResult? normalRange;
  final MLAnalysisResult? anomaly;
  final DateTime fetchedAt;

  MLAnalysisOverview({
    this.stress,
    this.mood,
    this.anxiety,
    this.sleep,
    this.normalRange,
    this.anomaly,
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  bool get hasAnyData =>
      (stress?.isValid ?? false) ||
      (mood?.isValid ?? false) ||
      (anxiety?.isValid ?? false) ||
      (sleep?.isValid ?? false);

  String get stressLevel {
    if (stress?.prediction == null || stress!.prediction!.isEmpty) {
      return 'Unknown';
    }
    final level = stress!.prediction![0];
    if (level == 0) return 'Low';
    if (level == 1) return 'Moderate';
    if (level == 2) return 'High';
    return 'Unknown';
  }

  String get moodState {
    if (mood?.prediction == null || mood!.prediction!.isEmpty) {
      return 'Unknown';
    }
    final state = mood!.prediction![0];
    if (state == 0) return 'Negative';
    if (state == 1) return 'Neutral';
    if (state == 2) return 'Positive';
    return 'Unknown';
  }

  String get anxietyLevel {
    if (anxiety?.prediction == null || anxiety!.prediction!.isEmpty) {
      return 'Unknown';
    }
    final level = anxiety!.prediction![0];
    if (level == 0) return 'Low';
    if (level == 1) return 'Moderate';
    if (level == 2) return 'High';
    return 'Unknown';
  }

  String get sleepQualityScore {
    if (sleep?.prediction == null || sleep!.prediction!.isEmpty) {
      return 'N/A';
    }
    try {
      final score = double.parse(sleep!.prediction![0].toString());
      return score.toStringAsFixed(1);
    } catch (e) {
      return 'N/A';
    }
  }

  String get sleepQualityLabel {
    if (sleep?.prediction == null || sleep!.prediction!.isEmpty) {
      return 'Unknown';
    }
    try {
      final score = double.parse(sleep!.prediction![0].toString());
      if (score >= 8) return 'Excellent';
      if (score >= 6) return 'Good';
      if (score >= 4) return 'Fair';
      return 'Poor';
    } catch (e) {
      return 'Unknown';
    }
  }
}