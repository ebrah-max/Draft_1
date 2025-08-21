import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'services/fraud_detection_service.dart';
import 'models/transaction_model.dart';
import 'models/fraud_alert_model.dart';
import 'models/risk_assessment_model.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> with TickerProviderStateMixin {
  final FraudDetectionService _fraudService = FraudDetectionService();
  
  String _selectedPeriod = 'Last 30 Days';
  String _selectedTab = 'Overview';
  bool _isLoading = true;
  
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final List<String> _periods = ['Last 7 Days', 'Last 30 Days', 'Last 3 Months', 'Last Year'];
  final List<String> _tabs = ['Overview', 'Risk Trends', 'Platform Analytics', 'ML Insights'];
  
  // Fraud Analytics Data
  Map<String, dynamic> _fraudStats = {};
  List<FraudAlert> _recentAlerts = [];
  List<Map<String, dynamic>> _riskTrendData = [];
  Map<String, Map<String, dynamic>> _platformAnalytics = {};
  List<Map<String, dynamic>> _mlInsights = [];
  
  // Sample fraud trend data
  final List<Map<String, dynamic>> _sampleFraudTrends = [
    {'day': 'Mon', 'safe': 45, 'suspicious': 8, 'blocked': 2},
    {'day': 'Tue', 'safe': 52, 'suspicious': 12, 'blocked': 4},
    {'day': 'Wed', 'safe': 38, 'suspicious': 15, 'blocked': 6},
    {'day': 'Thu', 'safe': 47, 'suspicious': 9, 'blocked': 1},
    {'day': 'Fri', 'safe': 65, 'suspicious': 18, 'blocked': 8},
    {'day': 'Sat', 'safe': 33, 'suspicious': 22, 'blocked': 12},
    {'day': 'Sun', 'safe': 29, 'suspicious': 16, 'blocked': 5},
  ];
  
  // Sample platform data
  final Map<String, Map<String, dynamic>> _samplePlatformData = {
    'M-Pesa': {
      'transactions': 156,
      'volume': 2450000.0,
      'fraudRate': 0.032,
      'avgRisk': 0.24,
      'color': 0xFF00A651,
    },
    'Airtel Money': {
      'transactions': 98,
      'volume': 1650000.0,
      'fraudRate': 0.045,
      'avgRisk': 0.31,
      'color': 0xFFE20613,
    },
    'HaloPesa': {
      'transactions': 67,
      'volume': 980000.0,
      'fraudRate': 0.089,
      'avgRisk': 0.52,
      'color': 0xFF0066CC,
    },
    'Tigo Pesa': {
      'transactions': 43,
      'volume': 720000.0,
      'fraudRate': 0.067,
      'avgRisk': 0.38,
      'color': 0xFFFF6600,
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(_animationController);
    _initializeAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeAnalytics() async {
    setState(() => _isLoading = true);
    
    try {
      // Initialize fraud detection service
      await _fraudService.initialize();
      
      // Load fraud statistics
      _fraudStats = _fraudService.getFraudStats();
      _recentAlerts = _fraudService.getRecentAlerts();
      
      // Generate sample analytics data
      _riskTrendData = _sampleFraudTrends;
      _platformAnalytics = _samplePlatformData;
      _generateMLInsights();
      
      _animationController.forward();
    } catch (e) {
      debugPrint('Error initializing analytics: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _generateMLInsights() {
    _mlInsights = [
      {
        'title': 'High-Risk Time Pattern',
        'description': 'Fraudulent activities peak between 11 PM and 3 AM',
        'confidence': 0.87,
        'icon': Icons.access_time,
        'color': Colors.red,
        'recommendation': 'Increase security checks during late hours',
      },
      {
        'title': 'Platform Vulnerability',
        'description': 'HaloPesa shows 89% higher fraud rate than average',
        'confidence': 0.94,
        'icon': Icons.security,
        'color': Colors.orange,
        'recommendation': 'Implement stricter validation for HaloPesa transactions',
      },
      {
        'title': 'Device Pattern Anomaly',
        'description': 'Unknown devices associated with 73% of blocked transactions',
        'confidence': 0.82,
        'icon': Icons.devices,
        'color': Colors.amber,
        'recommendation': 'Require device registration for high-value transactions',
      },
      {
        'title': 'Amount Clustering',
        'description': 'Suspicious transactions cluster around TShs 850,000',
        'confidence': 0.76,
        'icon': Icons.analytics,
        'color': Colors.blue,
        'recommendation': 'Flag transactions near this amount for review',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Fraud Analytics & Insights',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _selectedPeriod = value),
            itemBuilder: (context) => _periods.map((period) {
              return PopupMenuItem(value: period, child: Text(period));
            }).toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedPeriod,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildRiskTrendsTab(),
                  _buildPlatformAnalyticsTab(),
                  _buildMLInsightsTab(),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSecurityMetrics(),
          const SizedBox(height: 24),
          _buildFraudTrendChart(),
          const SizedBox(height: 24),
          _buildRecentAlertsSection(),
        ],
      ),
    );
  }

  Widget _buildSecurityMetrics() {
    final totalTransactions = _fraudStats['total_transactions'] ?? 0;
    final blockedTransactions = _fraudStats['blocked_transactions'] ?? 0;
    final fraudRate = _fraudStats['fraud_rate'] ?? 0.0;
    final alertsGenerated = _fraudStats['alerts_generated'] ?? 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Security Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Transactions',
                totalTransactions.toString(),
                Colors.blue,
                Icons.mobile_friendly,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Blocked',
                blockedTransactions.toString(),
                Colors.red,
                Icons.block,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Fraud Rate',
                '${(fraudRate * 100).toStringAsFixed(2)}%',
                Colors.orange,
                Icons.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'AI Alerts',
                alertsGenerated.toString(),
                Colors.purple,
                Icons.psychology,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _selectedPeriod,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFraudTrendChart() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fraud Detection Trends',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < _riskTrendData.length) {
                          return Text(
                            _riskTrendData[value.toInt()]['day'],
                            style: const TextStyle(fontSize: 12),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!),
                    left: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                lineBarsData: [
                  // Safe transactions line
                  LineChartBarData(
                    spots: _riskTrendData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value['safe'].toDouble());
                    }).toList(),
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green.withOpacity(0.1),
                    ),
                  ),
                  // Suspicious transactions line
                  LineChartBarData(
                    spots: _riskTrendData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value['suspicious'].toDouble());
                    }).toList(),
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                  // Blocked transactions line
                  LineChartBarData(
                    spots: _riskTrendData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value['blocked'].toDouble());
                    }).toList(),
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                ],
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => Colors.black87,
                    tooltipRoundedRadius: 8,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildChartLegend('Safe', Colors.green),
              _buildChartLegend('Suspicious', Colors.orange),
              _buildChartLegend('Blocked', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentAlertsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Security Alerts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to full alerts page
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._buildSampleAlerts(),
        ],
      ),
    );
  }

  List<Widget> _buildSampleAlerts() {
    final sampleAlerts = [
      {
        'type': 'Critical',
        'message': 'High-value HaloPesa transaction blocked',
        'amount': 'TShs 850,000',
        'time': '2 min ago',
        'color': Colors.red,
      },
      {
        'type': 'Suspicious',
        'message': 'Unusual device detected for M-Pesa transfer',
        'amount': 'TShs 45,000',
        'time': '15 min ago',
        'color': Colors.orange,
      },
      {
        'type': 'Warning',
        'message': 'Frequency anomaly detected on Tigo Pesa',
        'amount': 'TShs 15,000',
        'time': '1 hour ago',
        'color': Colors.amber,
      },
    ];

    return sampleAlerts.map((alert) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: alert['color']!.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: alert['color']!.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: alert['color']!.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                alert['type'] == 'Critical'
                    ? Icons.error
                    : alert['type'] == 'Suspicious'
                        ? Icons.warning
                        : Icons.info,
                color: alert['color'],
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert['message']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        alert['amount']!,
                        style: TextStyle(
                          color: alert['color'],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Text(' • '),
                      Text(
                        alert['time']!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildRiskTrendsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRiskLevelDistribution(),
          const SizedBox(height: 24),
          _buildTimeBasedRiskAnalysis(),
          const SizedBox(height: 24),
          _buildAmountRiskCorrelation(),
        ],
      ),
    );
  }

  Widget _buildRiskLevelDistribution() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Risk Level Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: 68,
                    color: Colors.green,
                    title: 'Low\n68%',
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: 18,
                    color: Colors.orange,
                    title: 'Medium\n18%',
                    radius: 55,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: 10,
                    color: Colors.red,
                    title: 'High\n10%',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: 4,
                    color: Colors.purple,
                    title: 'Critical\n4%',
                    radius: 45,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBasedRiskAnalysis() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hourly Risk Pattern',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 20,
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const hours = ['0', '6', '12', '18', '24'];
                        if (value.toInt() < hours.length) {
                          return Text(
                            hours[value.toInt()],
                            style: const TextStyle(fontSize: 12),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 5, color: Colors.blue)]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 8, color: Colors.blue)]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 12, color: Colors.blue)]),
                  BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 18, color: Colors.red)]),
                  BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 3, color: Colors.blue)]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRiskCorrelation() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Risk Score vs Transaction Amount',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: ScatterChart(
              ScatterChartData(
                scatterSpots: [
                  ScatterSpot(5000, 0.2, color: Colors.green, radius: 4),
                  ScatterSpot(15000, 0.15, color: Colors.green, radius: 4),
                  ScatterSpot(25000, 0.3, color: Colors.green, radius: 4),
                  ScatterSpot(45000, 0.45, color: Colors.orange, radius: 6),
                  ScatterSpot(75000, 0.6, color: Colors.orange, radius: 6),
                  ScatterSpot(150000, 0.75, color: Colors.red, radius: 8),
                  ScatterSpot(850000, 0.95, color: Colors.purple, radius: 10),
                ],
                minX: 0,
                maxX: 1000000,
                minY: 0,
                maxY: 1,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${(value / 1000).toInt()}K',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: true),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlatformComparison(),
          const SizedBox(height: 24),
          _buildPlatformRiskMetrics(),
        ],
      ),
    );
  }

  Widget _buildPlatformComparison() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Platform Volume & Risk Comparison',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ..._platformAnalytics.entries.map((entry) {
            final platform = entry.key;
            final data = entry.value;
            final volume = data['volume'] as double;
            final fraudRate = data['fraudRate'] as double;
            final transactions = data['transactions'] as int;
            final color = Color(data['color'] as int);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            platform.substring(0, 1),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          platform,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: fraudRate > 0.05 ? Colors.red : Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${(fraudRate * 100).toStringAsFixed(1)}% Fraud',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TShs ${(volume / 1000000).toStringAsFixed(1)}M',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            const Text(
                              'Volume',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              transactions.toString(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Transactions',
                              style: TextStyle(
                                fontSize: 12,
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
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPlatformRiskMetrics() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Average Risk Score by Platform',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 1,
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final platforms = _platformAnalytics.keys.toList();
                        if (value.toInt() < platforms.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              platforms[value.toInt()].split(' ').first,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _platformAnalytics.entries.map((entry) {
                  final index = _platformAnalytics.keys.toList().indexOf(entry.key);
                  final avgRisk = entry.value['avgRisk'] as double;
                  final color = Color(entry.value['color'] as int);
                  
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: avgRisk,
                        color: color,
                        width: 20,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMLInsightsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI-Powered Insights',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 16),
          ..._mlInsights.map((insight) => _buildInsightCard(insight)),
        ],
      ),
    );
  }

  Widget _buildInsightCard(Map<String, dynamic> insight) {
    final confidence = insight['confidence'] as double;
    final color = insight['color'] as Color;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  insight['icon'] as IconData,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight['title'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      insight['description'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(confidence * 100).toInt()}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recommended Action:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight['recommendation'] as String,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: confidence,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          const SizedBox(height: 4),
          Text(
            'Confidence: ${(confidence * 100).toInt()}%',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
