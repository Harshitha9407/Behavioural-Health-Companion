import 'package:flutter/material.dart';
import '../services/ml_analysis_service.dart';
import '../models/ml_analysis_model.dart';

// Placeholder definitions for the purpose of running this code snippet
// class MLAnalysisResult { final dynamic prediction; final bool isValid; MLAnalysisResult({this.prediction, required this.isValid}); factory MLAnalysisResult.fromJson(Map<String, dynamic> json) => MLAnalysisResult(prediction: json['prediction'], isValid: true); }
// class MLAnalysisOverview { final MLAnalysisResult? stress, mood, anxiety, sleep; MLAnalysisOverview({this.stress, this.mood, this.anxiety, this.sleep}); bool get hasAnyData => stress != null || mood != null || anxiety != null || sleep != null; String get stressLevel => stress?.prediction is List ? stress!.prediction[0] == 1 ? 'Moderate' : 'Low' : 'Low'; String get moodState => mood?.prediction is List ? mood!.prediction[0] == 1 ? 'Positive' : 'Neutral' : 'Neutral'; String get anxietyLevel => anxiety?.prediction is List ? anxiety!.prediction[0] == 0 ? 'Low' : 'Moderate' : 'Low'; String get sleepQualityLabel => sleep?.prediction is double && sleep!.prediction > 7.0 ? 'Good' : 'Fair'; }
// class MLAnalysisService { Future<Map<String, dynamic>> getAllAnalyses() async { await Future.delayed(const Duration(milliseconds: 500)); return { 'stress': {'prediction': [1]}, 'mood': {'prediction': [1]}, 'anxiety': {'prediction': [0]}, 'sleep': {'prediction': 7.5}}; } }

// --- Full Widget Implementation ---

class HealthInsightsScreen extends StatefulWidget {
  const HealthInsightsScreen({super.key});

  @override
  State<HealthInsightsScreen> createState() => _HealthInsightsScreenState();
}

class _HealthInsightsScreenState extends State<HealthInsightsScreen> {
  final MLAnalysisService _mlService = MLAnalysisService();
  MLAnalysisOverview? _analysis;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchInsights();
  }

  Future<void> _fetchInsights() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _mlService.getAllAnalyses();

      setState(() {
        _analysis = MLAnalysisOverview(
          stress: results['stress'] != null
              ? MLAnalysisResult.fromJson(results['stress']!)
              : null,
          mood: results['mood'] != null
              ? MLAnalysisResult.fromJson(results['mood']!)
              : null,
          anxiety: results['anxiety'] != null
              ? MLAnalysisResult.fromJson(results['anxiety']!)
              : null,
          sleep: results['sleep'] != null
              ? MLAnalysisResult.fromJson(results['sleep']!)
              : null,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load insights: $e';
        _isLoading = false;
      });
    }
  }

  // --- UI Builder Methods ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E8B82),
        elevation: 0,
        title: const Text(
          'Health Insights',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchInsights,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2E8B82),
              ),
            )
          : _errorMessage != null
              ? _buildErrorState()
              : _analysis == null || !_analysis!.hasAnyData
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      color: const Color(0xFF2E8B82),
                      onRefresh: _fetchInsights,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildWelcomeCard(),
                            const SizedBox(height: 24),
                            _buildHealthScoreCard(),
                            const SizedBox(height: 24),
                            _buildRecommendationsSection(),
                            const SizedBox(height: 24),
                            _buildQuickTipsSection(),
                            const SizedBox(height: 24),
                            _buildGoalsSection(),
                            const SizedBox(height: 100), // Add padding for scrolling
                          ],
                        ),
                      ),
                    ),
    );
  }

  // *** FIX APPLIED HERE: Wrapped the Text widget in Expanded ***
  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2E8B82),
            const Color(0xFF2E8B82).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E8B82).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 32),
              SizedBox(width: 12),
              // FIX: Wrap the text in Expanded
              Expanded( 
                child: Text(
                  'Your Personalized Insights',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Based on your health data and patterns',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScoreCard() {
    final overallScore = _calculateOverallHealthScore();
    final scoreColor = _getScoreColor(overallScore);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Overall Health Score',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A5A54),
            ),
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: overallScore / 100,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(scoreColor),
                ),
              ),
              Column(
                children: [
                  Text(
                    '${overallScore.toInt()}',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                  Text(
                    _getScoreLabel(overallScore),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildScoreBreakdown(),
        ],
      ),
    );
  }

  Widget _buildScoreBreakdown() {
    return Column(
      children: [
        // Mental Health combines Mood and Anxiety
        _buildScoreItem('Mental Health', _getMentalHealthScore(), Icons.spa_outlined),
        _buildScoreItem('Sleep Quality', _getSleepScore(), Icons.dark_mode),
        // Stress uses the Stress score directly, but with a different icon for visual distinction
        _buildScoreItem('Stress Level', _getStressScore(), Icons.favorite), 
      ],
    );
  }

  Widget _buildScoreItem(String label, double score, IconData icon) {
    // Determine the color based on the score threshold
    final color = _getScoreColor(score);
    final displayScore = score; 

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Vertically center alignment
        children: [
          // 1. Icon (Fixed width)
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          
          // 2. Label (Set to a fixed width or expanded, fixed width is better for alignment)
          SizedBox(
            width: 100, 
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 3. Progress Bar (MUST BE EXPANDED)
          Expanded( 
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: displayScore / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 8,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 4. Percentage Text (Fixed width)
          Text(
            '${displayScore.toInt()}%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    final recommendations = _getPersonalizedRecommendations();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personalized Recommendations',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A5A54),
          ),
        ),
        const SizedBox(height: 16),
        ...recommendations.map((rec) => _buildRecommendationCard(rec)),
      ],
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (recommendation['color'] as Color).withOpacity(0.1),
            (recommendation['color'] as Color).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (recommendation['color'] as Color).withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align icon and text at the top
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: recommendation['color'],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              recommendation['icon'] as IconData,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded( // Expanded here to prevent overflow in the inner row
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start, // Important for inner row
                  children: [
                    Expanded(
                      child: Text(
                        recommendation['title'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: recommendation['color'],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8), // Small gap between title and priority tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: recommendation['color'],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        recommendation['priority'] as String,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  recommendation['description'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTipsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Tips for Today',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A5A54),
          ),
        ),
        const SizedBox(height: 16),
        _buildTipCard(
          '💧 Stay Hydrated',
          'Drink 8 glasses of water throughout the day',
          Colors.blue,
        ),
        _buildTipCard(
          '🚶 Take Breaks',
          'Walk for 5 minutes every hour',
          Colors.orange,
        ),
        _buildTipCard(
          '🧘 Practice Mindfulness',
          '10 minutes of meditation before bed',
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildTipCard(String title, String description, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2E8B82).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎯 Your Health Goals',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A5A54),
            ),
          ),
          const SizedBox(height: 16),
          _buildGoalItem('Reduce stress levels', 0.7),
          _buildGoalItem('Improve sleep quality', 0.6),
          _buildGoalItem('Increase daily activity', 0.8),
        ],
      ),
    );
  }

  Widget _buildGoalItem(String goal, double progress) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                goal,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E8B82),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF2E8B82)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insights_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(
              'No Health Data Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start tracking your health metrics to get personalized insights',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
            const SizedBox(height: 24),
            Text(
              'Error Loading Insights',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Unknown error',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchInsights,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E8B82),
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper methods (Data Processing) ---

  double _calculateOverallHealthScore() {
    double total = 0;
    int count = 0;

    if (_analysis?.mood?.isValid ?? false) {
      total += _getMoodScore();
      count++;
    }
    if (_analysis?.stress?.isValid ?? false) {
      total += _getStressScore(); 
      count++;
    }
    if (_analysis?.anxiety?.isValid ?? false) {
      total += _getAnxietyScore();
      count++;
    }
    if (_analysis?.sleep?.isValid ?? false) {
      total += _getSleepScore();
      count++;
    }

    // Average the scores
    return count > 0 ? total / count : 75.0;
  }

  double _getMentalHealthScore() {
    double moodScore = _getMoodScore();
    double anxietyScore = _getAnxietyScore();
    // Only average if both are valid, otherwise return the average of what's available
    int count = (_analysis?.mood?.isValid ?? false ? 1 : 0) + 
                (_analysis?.anxiety?.isValid ?? false ? 1 : 0);
    if (count == 0) return 75.0; 
    return (moodScore + anxietyScore) / count;
  }

  double _getMoodScore() {
    final mood = _analysis?.moodState;
    if (mood == 'Positive') return 90.0;
    if (mood == 'Neutral') return 70.0;
    return 50.0;
  }

  // Returns score out of 100 where 100 is best (low stress)
  double _getStressScore() {
    final stress = _analysis?.stressLevel;
    if (stress == 'Low') return 90.0;
    if (stress == 'Moderate') return 65.0;
    return 40.0;
  }

  // Returns score out of 100 where 100 is best (low anxiety)
  double _getAnxietyScore() {
    final anxiety = _analysis?.anxietyLevel;
    if (anxiety == 'Low') return 90.0;
    if (anxiety == 'Moderate') return 65.0;
    return 40.0;
  }

  double _getSleepScore() {
    final label = _analysis?.sleepQualityLabel;
    if (label == 'Excellent') return 95.0;
    if (label == 'Good') return 80.0;
    if (label == 'Fair') return 60.0;
    return 40.0;
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return const Color(0xFF2E8B82); // Greenish color
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getScoreLabel(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    return 'Needs Attention';
  }

  List<Map<String, dynamic>> _getPersonalizedRecommendations() {
    final recommendations = <Map<String, dynamic>>[];

    // Stress-based
    if (_analysis!.stressLevel == 'Moderate' || _analysis!.stressLevel == 'High') {
      recommendations.add({
        'icon': Icons.spa,
        'title': 'Manage Your Stress',
        'description': 'Try deep breathing exercises for 10 minutes daily. Consider yoga or meditation.',
        'color': Colors.red,
        'priority': 'HIGH',
      });
    }

    // Mood-based
    if (_analysis!.moodState == 'Negative') {
      recommendations.add({
        'icon': Icons.wb_sunny,
        'title': 'Boost Your Mood',
        'description': 'Spend 20 minutes outdoors in sunlight. Connect with friends or family.',
        'color': Colors.orange,
        'priority': 'MEDIUM',
      });
    }

    // Sleep-based
    if (_analysis!.sleepQualityLabel == 'Poor' || _analysis!.sleepQualityLabel == 'Fair') {
      recommendations.add({
        'icon': Icons.bedtime,
        'title': 'Improve Sleep Quality',
        'description': 'Maintain consistent sleep schedule. Avoid screens 1 hour before bed.',
        'color': Colors.indigo,
        'priority': 'HIGH',
      });
    }

    // Positive recommendations
    if (recommendations.isEmpty) {
      recommendations.add({
        'icon': Icons.celebration,
        'title': 'Keep Up the Great Work!',
        'description': 'Your health metrics are looking good. Continue your healthy habits.',
        'color': const Color(0xFF2E8B82),
        'priority': 'INFO',
      });
    }

    return recommendations;
  }
}