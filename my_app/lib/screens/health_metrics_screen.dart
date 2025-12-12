import 'package:flutter/material.dart';

class HealthMetricsScreen extends StatefulWidget {
  const HealthMetricsScreen({super.key});

  @override
  State<HealthMetricsScreen> createState() => _HealthMetricsScreenState();
}

class _HealthMetricsScreenState extends State<HealthMetricsScreen> {
  // A list to hold the health metrics. This will be populated from the backend.
  List<Map<String, dynamic>> _metrics = [];
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
    // TODO: Replace with actual API call to your backend.
    // This is a placeholder to simulate data fetching.
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _metrics = [
        {'type': 'Heart Rate', 'value': 72.0, 'time': 'Today, 9:30 AM', 'icon': Icons.favorite, 'color': Colors.red},
        {'type': 'Blood Pressure', 'value': 120.0, 'time': 'Yesterday, 8:15 PM', 'icon': Icons.water_drop, 'color': Colors.blue},
        {'type': 'Weight', 'value': 70.5, 'time': '2 days ago', 'icon': Icons.monitor_weight, 'color': Colors.green},
      ];
    });
  }

  Future<void> _addMetric() async {
    if (_selectedMetricType == null || _metricValueController.text.isEmpty) {
      // Basic validation
      return;
    }

    final newMetric = {
      'type': _selectedMetricType,
      'value': double.parse(_metricValueController.text),
      'time': 'Just now',
      'source': 'manual',
    };

    // TODO: Replace with actual POST request to your backend
    // For example:
    // final response = await http.post(...);
    // if (response.statusCode == 201) {
    //   _fetchMetrics(); // Fetch the updated list
    // }

    setState(() {
      _metrics.insert(0, newMetric);
    });

    Navigator.of(context).pop();
  }

  void _showAddMetricDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              title: const Text('Add Health Metric'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Metric Type'),
                      initialValue: _selectedMetricType,
                      items: _metricTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setStateSB(() {
                          _selectedMetricType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _metricValueController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Value'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                ),
                TextButton(
                  onPressed: _addMetric,
                  child: const Text('Add', style: TextStyle(color: Color(0xFF2E8B82))),
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
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showAddMetricDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Padding(
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
                            Text(
                              'Track Your Health',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A5A54),
                              ),
                            ),
                            Text(
                              'Monitor vital signs and health data',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Metrics Categories
            const Text(
              'Health Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A5A54),
              ),
            ),
            const SizedBox(height: 16),
            // Grid of Metric Cards (Static placeholders, can be made dynamic later)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildMetricCard(
                  title: 'Heart Rate',
                  icon: Icons.favorite,
                  color: Colors.red,
                  value: '72 BPM',
                  subtitle: 'Normal',
                ),
                _buildMetricCard(
                  title: 'Blood Pressure',
                  icon: Icons.water_drop,
                  color: Colors.blue,
                  value: '120/80',
                  subtitle: 'Good',
                ),
                _buildMetricCard(
                  title: 'Weight',
                  icon: Icons.monitor_weight,
                  color: Colors.green,
                  value: '70 kg',
                  subtitle: 'Stable',
                ),
                _buildMetricCard(
                  title: 'Temperature',
                  icon: Icons.thermostat,
                  color: Colors.orange,
                  value: '36.5°C',
                  subtitle: 'Normal',
                ),
              ],
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
                children: [
                  for (var metric in _metrics)
                    _buildRecordItem(
                      metric['type'],
                      '${metric['value']}',
                      metric['time'],
                      metric['icon'],
                      metric['color'],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMetricDialog(context),
        backgroundColor: const Color(0xFF2E8B82),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required IconData icon,
    required Color color,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const Icon(
                Icons.trending_up,
                color: Colors.green,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A5A54),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A5A54),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordItem(String title, String value, String time, IconData icon, Color color) {
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
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A5A54),
        ),
      ),
      subtitle: Text(
        time,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
      trailing: Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A5A54),
        ),
      ),
    );
  }
}
