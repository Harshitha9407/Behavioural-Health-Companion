import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/ml_analysis_service.dart';
import '../models/ml_analysis_model.dart';

class MoodTrackingScreen extends StatefulWidget {
  const MoodTrackingScreen({super.key});

  @override
  State<MoodTrackingScreen> createState() => _MoodTrackingScreenState();
}

class _MoodTrackingScreenState extends State<MoodTrackingScreen> {
  final MLAnalysisService _mlService = MLAnalysisService();
  MLAnalysisOverview? _currentAnalysis;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMoodAnalysis();
  }

  Future<void> _fetchMoodAnalysis() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _mlService.getAllAnalyses();

      setState(() {
        _currentAnalysis = MLAnalysisOverview(
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
        _errorMessage = 'Failed to load mood tracking: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E8B82),
        elevation: 0,
        title: const Text(
          'Mood Tracking',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchMoodAnalysis,
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
              : _currentAnalysis == null || !_currentAnalysis!.hasAnyData
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      color: const Color(0xFF2E8B82),
                      onRefresh: _fetchMoodAnalysis,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMoodHeaderCard(),
                            const SizedBox(height: 24),
                            _buildCurrentMoodSection(),
                            const SizedBox(height: 24),
                            _buildMoodFactorsSection(),
                            const SizedBox(height: 24),
                            _buildRecommendationsSection(),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildMoodHeaderCard() {
    final moodEmoji = _getMoodEmoji();
    final moodState = _currentAnalysis!.moodState;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getMoodGradientColor(),
            _getMoodGradientColor().withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getMoodGradientColor().withOpacity(0.3),
            spreadRadius: 0,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            moodEmoji,
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          const Text(
            'How are you feeling?',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            moodState,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Updated ${_getTimeAgo(_currentAnalysis!.fetchedAt)}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentMoodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Current Emotional State',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A5A54),
          ),
        ),
        const SizedBox(height: 16),
        _buildMoodMetricCard(
          'Overall Mood',
          _currentAnalysis!.moodState,
          Icons.sentiment_satisfied_alt,
          _getMoodColor(),
          _getMoodDescription(),
          _currentAnalysis!.mood?.probabilities,
        ),
      ],
    );
  }

  Widget _buildMoodFactorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mood Influencing Factors',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A5A54),
          ),
        ),
        const SizedBox(height: 16),
        _buildFactorCard(
          'Stress Level',
          _currentAnalysis!.stressLevel,
          Icons.trending_up,
          _getStressColor(),
          _getStressImpact(),
        ),
        const SizedBox(height: 12),
        _buildFactorCard(
          'Anxiety Level',
          _currentAnalysis!.anxietyLevel,
          Icons.psychology_outlined,
          _getAnxietyColor(),
          _getAnxietyImpact(),
        ),
        const SizedBox(height: 12),
        _buildFactorCard(
          'Sleep Quality',
          _currentAnalysis!.sleepQualityLabel,
          Icons.bedtime,
          _getSleepColor(),
          _getSleepImpact(),
        ),
      ],
    );
  }

  Widget _buildRecommendationsSection() {
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
        ..._getRecommendations().map((rec) => _buildRecommendationCard(rec)),
      ],
    );
  }

  Widget _buildMoodMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String description,
    List<List<double>>? probabilities,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A5A54),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          if (probabilities != null && probabilities.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            _buildMoodProbabilityBars(probabilities[0]),
          ],
        ],
      ),
    );
  }

  Widget _buildMoodProbabilityBars(List<double> probabilities) {
    final labels = ['Negative', 'Neutral', 'Positive'];
    final colors = [Colors.red, Colors.grey, const Color(0xFF2E8B82)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mood Probability Distribution:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A5A54),
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(probabilities.length, (index) {
          final probability = probabilities[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      labels[index],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '${(probability * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colors[index],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: probability,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(colors[index]),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFactorCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String impact,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  impact,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            _getImpactIcon(impact),
            color: color,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
        children: [
          Container(
            padding: const EdgeInsets.all(10),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation['title'] as String,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: recommendation['color'],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recommendation['description'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.3,
                  ),
                ),
              ],
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
            Icon(Icons.sentiment_neutral, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(
              'No Mood Data Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start tracking your health metrics to see mood analysis',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchMoodAnalysis,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E8B82),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
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
              'Error Loading Mood Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchMoodAnalysis,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E8B82),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  String _getMoodEmoji() {
    final mood = _currentAnalysis!.moodState;
    if (mood == 'Positive') return '😊';
    if (mood == 'Neutral') return '😐';
    return '😔';
  }

  Color _getMoodGradientColor() {
    final mood = _currentAnalysis!.moodState;
    if (mood == 'Positive') return const Color(0xFF2E8B82);
    if (mood == 'Neutral') return Colors.blueGrey;
    return Colors.deepOrange;
  }

  Color _getMoodColor() {
    final mood = _currentAnalysis!.moodState;
    if (mood == 'Positive') return const Color(0xFF2E8B82);
    if (mood == 'Neutral') return Colors.grey;
    return Colors.redAccent;
  }

  Color _getStressColor() {
    final level = _currentAnalysis!.stressLevel;
    if (level == 'Low') return Colors.green;
    if (level == 'Moderate') return Colors.orange;
    return Colors.red;
  }

  Color _getAnxietyColor() {
    final level = _currentAnalysis!.anxietyLevel;
    if (level == 'Low') return Colors.blue;
    if (level == 'Moderate') return Colors.amber;
    return Colors.deepOrange;
  }

  Color _getSleepColor() {
    final label = _currentAnalysis!.sleepQualityLabel;
    if (label == 'Excellent' || label == 'Good') return Colors.purple;
    if (label == 'Fair') return Colors.orange;
    return Colors.red;
  }

  String _getMoodDescription() {
    final mood = _currentAnalysis!.moodState;
    if (mood == 'Positive') {
      return 'You\'re experiencing positive emotions! Your mental state is healthy and balanced.';
    } else if (mood == 'Neutral') {
      return 'Your mood is neutral. Consider activities that bring joy and fulfillment.';
    } else {
      return 'You may be experiencing negative emotions. It\'s okay to feel this way. Consider self-care activities.';
    }
  }

  String _getStressImpact() {
    final level = _currentAnalysis!.stressLevel;
    if (level == 'High') return 'High impact on mood';
    if (level == 'Moderate') return 'Moderate impact';
    return 'Minimal impact';
  }

  String _getAnxietyImpact() {
    final level = _currentAnalysis!.anxietyLevel;
    if (level == 'High') return 'High impact on mood';
    if (level == 'Moderate') return 'Moderate impact';
    return 'Minimal impact';
  }

  String _getSleepImpact() {
    final label = _currentAnalysis!.sleepQualityLabel;
    if (label == 'Poor') return 'Negative impact';
    if (label == 'Fair') return 'Some impact';
    return 'Positive impact';
  }

  IconData _getImpactIcon(String impact) {
    if (impact.contains('High') || impact.contains('Negative')) {
      return Icons.arrow_upward;
    } else if (impact.contains('Moderate') || impact.contains('Some')) {
      return Icons.arrow_forward;
    }
    return Icons.arrow_downward;
  }

  List<Map<String, dynamic>> _getRecommendations() {
    final recommendations = <Map<String, dynamic>>[];
    
    // Mood-based recommendations
    if (_currentAnalysis!.moodState == 'Negative') {
      recommendations.add({
        'icon': Icons.self_improvement,
        'title': 'Practice Mindfulness',
        'description': 'Try 10 minutes of meditation to improve your emotional state',
        'color': const Color(0xFF2E8B82),
      });
    }

    // Stress-based recommendations
    if (_currentAnalysis!.stressLevel == 'High') {
      recommendations.add({
        'icon': Icons.spa,
        'title': 'Relaxation Exercises',
        'description': 'Deep breathing exercises can help reduce stress levels',
        'color': Colors.purple,
      });
    }

    // Anxiety-based recommendations
    if (_currentAnalysis!.anxietyLevel == 'High' || _currentAnalysis!.anxietyLevel == 'Moderate') {
      recommendations.add({
        'icon': Icons.nature_people,
        'title': 'Outdoor Activity',
        'description': 'Spend time in nature to reduce anxiety naturally',
        'color': Colors.green,
      });
    }

    // Sleep-based recommendations
    if (_currentAnalysis!.sleepQualityLabel == 'Poor' || _currentAnalysis!.sleepQualityLabel == 'Fair') {
      recommendations.add({
        'icon': Icons.nightlight_round,
        'title': 'Improve Sleep Hygiene',
        'description': 'Establish a consistent bedtime routine for better sleep',
        'color': Colors.indigo,
      });
    }

    // General positive recommendation
    if (recommendations.isEmpty) {
      recommendations.add({
        'icon': Icons.celebration,
        'title': 'Keep Up the Good Work!',
        'description': 'Your mental health metrics look great. Continue your healthy habits',
        'color': const Color(0xFF2E8B82),
      });
    }

    return recommendations;
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inMinutes < 1) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    return '${difference.inDays} days ago';
  }
}