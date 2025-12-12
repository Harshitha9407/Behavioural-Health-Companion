import 'package:flutter/material.dart';
import '../services/ml_analysis_service.dart';
import '../models/ml_analysis_model.dart';

class RecentMetricsScreen extends StatefulWidget {
  const RecentMetricsScreen({super.key});

  @override
  State<RecentMetricsScreen> createState() => _RecentMetricsScreenState();
}

class _RecentMetricsScreenState extends State<RecentMetricsScreen> {
  final MLAnalysisService _mlService = MLAnalysisService();
  MLAnalysisOverview? _analysisOverview;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAnalyses();
  }

  Future<void> _fetchAnalyses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _mlService.getAllAnalyses();

      setState(() {
        _analysisOverview = MLAnalysisOverview(
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
          normalRange: results['normalRange'] != null
              ? MLAnalysisResult.fromJson(results['normalRange']!)
              : null,
          anomaly: results['anomaly'] != null
              ? MLAnalysisResult.fromJson(results['anomaly']!)
              : null,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load health metrics: $e';
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
          'Recent Metrics',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchAnalyses,
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
              : _analysisOverview == null || !_analysisOverview!.hasAnyData
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      color: const Color(0xFF2E8B82),
                      onRefresh: _fetchAnalyses,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeaderCard(),
                            const SizedBox(height: 24),
                            _buildMetricsGrid(),
                            const SizedBox(height: 24),
                            _buildDetailedAnalysis(),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2E8B82),
            const Color(0xFF2E8B82).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E8B82).withOpacity(0.3),
            spreadRadius: 0,
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
              Icon(Icons.timeline, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Health Analysis',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Last updated: ${_getTimeAgo(_analysisOverview!.fetchedAt)}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Current Status',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A5A54),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            _buildMetricCard(
              'Stress Level',
              _analysisOverview!.stressLevel,
              _getStressIcon(),
              _getStressColor(),
            ),
            _buildMetricCard(
              'Mood',
              _analysisOverview!.moodState,
              _getMoodIcon(),
              _getMoodColor(),
            ),
            _buildMetricCard(
              'Anxiety',
              _analysisOverview!.anxietyLevel,
              Icons.psychology_outlined,
              _getAnxietyColor(),
            ),
            _buildMetricCard(
              'Sleep Quality',
              _analysisOverview!.sleepQualityLabel,
              Icons.bedtime_outlined,
              _getSleepColor(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detailed Analysis',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A5A54),
          ),
        ),
        const SizedBox(height: 16),
        if (_analysisOverview!.stress?.isValid ?? false)
          _buildAnalysisCard(
            'Stress Analysis',
            _analysisOverview!.stressLevel,
            _getStressDescription(),
            _getStressColor(),
            _analysisOverview!.stress!.probabilities,
          ),
        if (_analysisOverview!.mood?.isValid ?? false)
          _buildAnalysisCard(
            'Mood Analysis',
            _analysisOverview!.moodState,
            _getMoodDescription(),
            _getMoodColor(),
            _analysisOverview!.mood!.probabilities,
          ),
        if (_analysisOverview!.anxiety?.isValid ?? false)
          _buildAnalysisCard(
            'Anxiety Analysis',
            _analysisOverview!.anxietyLevel,
            _getAnxietyDescription(),
            _getAnxietyColor(),
            _analysisOverview!.anxiety!.probabilities,
          ),
        if (_analysisOverview!.sleep?.isValid ?? false)
          _buildSleepAnalysisCard(),
      ],
    );
  }

  Widget _buildAnalysisCard(
    String title,
    String value,
    String description,
    Color color,
    List<List<double>>? probabilities,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A5A54),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
            _buildProbabilityBars(probabilities[0]),
          ],
        ],
      ),
    );
  }

  Widget _buildSleepAnalysisCard() {
    final score = _analysisOverview!.sleepQualityScore;
    final label = _analysisOverview!.sleepQualityLabel;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sleep Quality',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A5A54),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getSleepColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$score/10',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _getSleepColor(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _getSleepColor(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getSleepDescription(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProbabilityBars(List<double> probabilities) {
    final labels = ['Low', 'Moderate', 'High'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confidence Levels:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A5A54),
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(probabilities.length, (index) {
          final probability = probabilities[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: probability,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(
                        _getColorForProbability(probability),
                      ),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 45,
                  child: Text(
                    '${(probability * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E8B82),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(
              'No Metrics Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start tracking your health metrics to see analysis',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchAnalyses,
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
              'Error Loading Metrics',
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
              onPressed: _fetchAnalyses,
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

  // Helper methods for colors and icons
  IconData _getStressIcon() {
    final level = _analysisOverview!.stressLevel;
    if (level == 'Low') return Icons.sentiment_very_satisfied;
    if (level == 'Moderate') return Icons.sentiment_neutral;
    return Icons.sentiment_very_dissatisfied;
  }

  Color _getStressColor() {
    final level = _analysisOverview!.stressLevel;
    if (level == 'Low') return Colors.green;
    if (level == 'Moderate') return Colors.orange;
    return Colors.red;
  }

  IconData _getMoodIcon() {
    final mood = _analysisOverview!.moodState;
    if (mood == 'Positive') return Icons.sentiment_satisfied;
    if (mood == 'Neutral') return Icons.sentiment_neutral;
    return Icons.sentiment_dissatisfied;
  }

  Color _getMoodColor() {
    final mood = _analysisOverview!.moodState;
    if (mood == 'Positive') return const Color(0xFF2E8B82);
    if (mood == 'Neutral') return Colors.grey;
    return Colors.redAccent;
  }

  Color _getAnxietyColor() {
    final level = _analysisOverview!.anxietyLevel;
    if (level == 'Low') return Colors.blue;
    if (level == 'Moderate') return Colors.amber;
    return Colors.deepOrange;
  }

  Color _getSleepColor() {
    final label = _analysisOverview!.sleepQualityLabel;
    if (label == 'Excellent' || label == 'Good') return Colors.purple;
    if (label == 'Fair') return Colors.orange;
    return Colors.red;
  }

  Color _getColorForProbability(double probability) {
    if (probability >= 0.7) return Colors.green;
    if (probability >= 0.4) return Colors.orange;
    return Colors.red;
  }

  String _getStressDescription() {
    final level = _analysisOverview!.stressLevel;
    if (level == 'Low') {
      return 'Your stress levels are well-managed. Keep up with your healthy habits!';
    } else if (level == 'Moderate') {
      return 'You\'re experiencing moderate stress. Consider relaxation techniques or taking breaks.';
    } else {
      return 'High stress detected. Please prioritize self-care and consider reaching out for support.';
    }
  }

  String _getMoodDescription() {
    final mood = _analysisOverview!.moodState;
    if (mood == 'Positive') {
      return 'You\'re in a positive emotional state. Great job maintaining your mental wellness!';
    } else if (mood == 'Neutral') {
      return 'Your mood is balanced. Focus on activities that bring you joy.';
    } else {
      return 'Your mood needs attention. Try engaging in mood-boosting activities.';
    }
  }

  String _getAnxietyDescription() {
    final level = _analysisOverview!.anxietyLevel;
    if (level == 'Low') {
      return 'Your anxiety levels are low. You\'re managing well!';
    } else if (level == 'Moderate') {
      return 'Moderate anxiety detected. Practice mindfulness and deep breathing exercises.';
    } else {
      return 'High anxiety levels. Consider speaking with a mental health professional.';
    }
  }

  String _getSleepDescription() {
    final label = _analysisOverview!.sleepQualityLabel;
    if (label == 'Excellent') {
      return 'Your sleep quality is excellent! Keep maintaining your sleep routine.';
    } else if (label == 'Good') {
      return 'Good sleep quality. Small improvements can make it even better.';
    } else if (label == 'Fair') {
      return 'Fair sleep quality. Try improving your sleep hygiene and bedtime routine.';
    } else {
      return 'Poor sleep quality detected. Focus on creating a better sleep environment.';
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}