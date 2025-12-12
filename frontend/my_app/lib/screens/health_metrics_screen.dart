import 'package:flutter/material.dart';
import '../repositories/health_metric_repository.dart';
import '../models/health_metric.dart';

class HealthMetricsScreen extends StatefulWidget {
  const HealthMetricsScreen({super.key});

  @override
  State<HealthMetricsScreen> createState() => _HealthMetricsScreenState();
}

class _HealthMetricsScreenState extends State<HealthMetricsScreen> {
  final HealthMetricRepository _repository = HealthMetricRepository();
  List<HealthMetric> _metrics = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  final _metricValueController = TextEditingController();
  String? _selectedMetricType;

  final List<String> _metricTypes = [
    'Heart Rate',
    'Blood Pressure',
    'Weight',
    'Temperature',
    'Glucose Level',
    'Steps'
  ];

  // Icon mapping
  final Map<String, IconData> _metricIcons = {
    'Heart Rate': Icons.favorite,
    'Blood Pressure': Icons.water_drop,
    'Weight': Icons.monitor_weight,
    'Temperature': Icons.thermostat,
    'Glucose Level': Icons.bloodtype,
    'Steps': Icons.directions_walk,
  };

  // Color mapping
  final Map<String, Color> _metricColors = {
    'Heart Rate': Colors.red,
    'Blood Pressure': Colors.blue,
    'Weight': Colors.green,
    'Temperature': Colors.orange,
    'Glucose Level': Colors.purple,
    'Steps': Colors.teal,
  };

  @override
  void initState() {
    super.initState();
    _fetchMetrics();
  }

  @override
  void dispose() {
    _metricValueController.dispose();
    super.dispose();
  }

  Future<void> _fetchMetrics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final metrics = await _repository.getAllHealthMetrics();
      
      if (mounted) {
        setState(() {
          _metrics = metrics;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading metrics: $e');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load metrics: $e';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _addMetric() async {
    // Validate input
    if (_selectedMetricType == null || _metricValueController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select type and enter value'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Parse value
    final value = double.tryParse(_metricValueController.text);
    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create metric object
      final newMetric = HealthMetric(
        type: _selectedMetricType!,
        value: value,
        source: 'manual',
      );

      // Save to backend
      final success = await _repository.saveHealthMetric(newMetric);
      
      if (success) {
        print('✅ Metric saved successfully');
        
        // Close dialog
        if (mounted) {
          Navigator.of(context).pop();
        }
        
        // Refresh list
        await _fetchMetrics();
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Health metric saved!'),
              backgroundColor: Color(0xFF2E8B82),
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        // Clear form
        _metricValueController.clear();
        _selectedMetricType = null;
        
      } else {
        throw Exception('Failed to save metric');
      }
    } catch (e) {
      print('❌ Error saving metric: $e');
      
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving metric: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showAddMetricDialog(BuildContext context) {
    // Reset form state
    _metricValueController.clear();
    _selectedMetricType = null;
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Health Metric'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Metric Type Dropdown
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Metric Type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      value: _selectedMetricType,
                      items: _metricTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Row(
                            children: [
                              Icon(
                                _metricIcons[type],
                                size: 20,
                                color: _metricColors[type],
                              ),
                              const SizedBox(width: 8),
                              Text(type),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          _selectedMetricType = value;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Value Input
                    TextFormField(
                      controller: _metricValueController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Value',
                        hintText: 'Enter numeric value',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                TextButton(
                  onPressed: _isLoading ? null : _addMetric,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Add',
                          style: TextStyle(color: Color(0xFF2E8B82)),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E8B82),
        elevation: 0,
        title: const Text(
          'Health Metrics',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchMetrics,
          ),
        ],
      ),
      body: _isLoading && _metrics.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2E8B82),
              ),
            )
          : RefreshIndicator(
              color: const Color(0xFF2E8B82),
              onRefresh: _fetchMetrics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(right: 16.0),
                            child: Icon(
                              Icons.favorite_rounded,
                              color: Color(0xFF2E8B82),
                              size: 36,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Track Your Health',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A5A54),
                                  ),
                                ),
                                Text(
                                  '${_metrics.length} metrics tracked',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Recent Records Section
                    const Text(
                      'Recent Records',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A5A54),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Error message
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red[600]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red[800]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Metrics List
                    if (_metrics.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.favorite_border,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No health metrics yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to add your first metric',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: _metrics.asMap().entries.map((entry) {
                            final index = entry.key;
                            final metric = entry.value;
                            
                            return Column(
                              children: [
                                _buildRecordItem(metric),
                                if (index < _metrics.length - 1)
                                  const Divider(height: 1),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMetricDialog(context),
        backgroundColor: const Color(0xFF2E8B82),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildRecordItem(HealthMetric metric) {
    final icon = _metricIcons[metric.type] ?? Icons.health_and_safety;
    final color = _metricColors[metric.type] ?? Colors.grey;
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: color,
          size: 24,
        ),
      ),
      title: Text(
        metric.type,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A5A54),
        ),
      ),
      subtitle: Text(
        metric.timestamp != null
            ? _formatTimestamp(metric.timestamp!)
            : 'Just now',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
      trailing: Text(
        metric.value.toStringAsFixed(1),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A5A54),
          fontSize: 16,
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} min${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}