import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'services/fraud_detection_service.dart';
import 'utils/currency_formatter.dart';
import 'models/fraud_alert_model.dart';
import 'models/transaction_model.dart';
import 'models/risk_assessment_model.dart';

class ReportingPage extends StatefulWidget {
  const ReportingPage({super.key});

  @override
  State<ReportingPage> createState() => _ReportingPageState();
}

class _ReportingPageState extends State<ReportingPage> with TickerProviderStateMixin {
  final FraudDetectionService _fraudService = FraudDetectionService();
  
  String _selectedReportType = 'Security Summary';
  String _selectedPeriod = 'Last 30 Days';
  bool _isLoading = true;
  bool _isGeneratingReport = false;
  
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  
  final List<String> _reportTypes = [
    'Security Summary',
    'Fraud Detection Report',
    'Platform Security Analysis',
    'Risk Assessment Report',
    'Transaction Audit',
    'ML Performance Report',
  ];
  
  final List<String> _periods = [
    'Last 7 Days',
    'Last 30 Days', 
    'Last 3 Months',
    'Last Year',
    'Custom Range',
  ];

  // Report data
  Map<String, dynamic> _securityData = {};
  List<FraudAlert> _fraudAlerts = [];
  Map<String, dynamic> _platformStats = {};
  List<Map<String, dynamic>> _riskTrends = [];
  Map<String, dynamic> _mlPerformance = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _initializeReporting();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeReporting() async {
    setState(() => _isLoading = true);
    
    try {
      // Initialize fraud detection service
      await _fraudService.initialize();
      
      // Generate sample security data
      await _generateSecurityData();
      
      _animationController.forward();
    } catch (e) {
      debugPrint('Error initializing reporting: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _generateSecurityData() async {
    // Generate security statistics
    _securityData = {
      'totalTransactions': 1247,
      'secureTransactions': 1203,
      'suspiciousTransactions': 31,
      'blockedTransactions': 13,
      'fraudRate': 0.035,
      'avgRiskScore': 0.18,
      'volumeSecured': 18750000.0, // TShs 18.75M
      'fraudPrevented': 2150000.0, // TShs 2.15M
    };
    
    // Generate fraud alerts
    _fraudAlerts = _fraudService.getRecentAlerts();
    
    // Generate platform statistics
    _platformStats = {
      'M-Pesa': {
        'transactions': 456,
        'fraudRate': 0.028,
        'volume': 8450000.0,
        'avgRisk': 0.15,
      },
      'Airtel Money': {
        'transactions': 298,
        'fraudRate': 0.041,
        'volume': 5670000.0,
        'avgRisk': 0.22,
      },
      'HaloPesa': {
        'transactions': 267,
        'fraudRate': 0.089,
        'volume': 2950000.0,
        'avgRisk': 0.45,
      },
      'Tigo Pesa': {
        'transactions': 226,
        'fraudRate': 0.067,
        'volume': 1680000.0,
        'avgRisk': 0.33,
      },
    };
    
    // Generate risk trends
    _riskTrends = [
      {'day': 'Mon', 'lowRisk': 45, 'mediumRisk': 12, 'highRisk': 3, 'critical': 1},
      {'day': 'Tue', 'lowRisk': 52, 'mediumRisk': 18, 'highRisk': 5, 'critical': 2},
      {'day': 'Wed', 'lowRisk': 38, 'mediumRisk': 22, 'highRisk': 8, 'critical': 4},
      {'day': 'Thu', 'lowRisk': 47, 'mediumRisk': 15, 'highRisk': 6, 'critical': 2},
      {'day': 'Fri', 'lowRisk': 65, 'mediumRisk': 28, 'highRisk': 12, 'critical': 7},
      {'day': 'Sat', 'lowRisk': 33, 'mediumRisk': 35, 'highRisk': 18, 'critical': 9},
      {'day': 'Sun', 'lowRisk': 29, 'mediumRisk': 25, 'highRisk': 11, 'critical': 5},
    ];
    
    // Generate ML performance data
    _mlPerformance = {
      'accuracy': 0.94,
      'precision': 0.89,
      'recall': 0.92,
      'f1Score': 0.905,
      'falsePositiveRate': 0.06,
      'falseNegativeRate': 0.08,
      'processingTime': 0.15, // seconds
      'modelsDeployed': 3,
      'lastUpdated': DateTime.now().subtract(const Duration(hours: 2)),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Security Reports & Analytics',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
          ),
          PopupMenuButton<String>(
            onSelected: (period) => setState(() => _selectedPeriod = period),
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
          tabs: const [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.dashboard),
                  SizedBox(width: 8),
                  Text('Reports'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.file_download),
                  SizedBox(width: 8),
                  Text('Export'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SlideTransition(
              position: _slideAnimation,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildReportsTab(),
                  _buildExportTab(),
                ],
              ),
            ),
    );
  }

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReportTypeSelector(),
          const SizedBox(height: 20),
          _buildReportContent(),
        ],
      ),
    );
  }

  Widget _buildReportTypeSelector() {
    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _reportTypes.length,
        itemBuilder: (context, index) {
          final reportType = _reportTypes[index];
          final isSelected = _selectedReportType == reportType;
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(
                reportType,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
              selectedColor: Colors.deepPurple,
              checkmarkColor: Colors.white,
              onSelected: (selected) {
                setState(() {
                  _selectedReportType = reportType;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildReportContent() {
    switch (_selectedReportType) {
      case 'Security Summary':
        return _buildSecuritySummaryReport();
      case 'Fraud Detection Report':
        return _buildFraudDetectionReport();
      case 'Platform Security Analysis':
        return _buildPlatformSecurityReport();
      case 'Risk Assessment Report':
        return _buildRiskAssessmentReport();
      case 'Transaction Audit':
        return _buildTransactionAuditReport();
      case 'ML Performance Report':
        return _buildMLPerformanceReport();
      default:
        return _buildSecuritySummaryReport();
    }
  }

  Widget _buildSecuritySummaryReport() {
    return Column(
      children: [
        // Security Overview Cards
        Row(
          children: [
            Expanded(
              child: _buildSecurityMetricCard(
                'Secure Transactions',
                '${_securityData['secureTransactions']}',
                '${((_securityData['secureTransactions'] / _securityData['totalTransactions']) * 100).toStringAsFixed(1)}%',
                Icons.shield_outlined,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSecurityMetricCard(
                'Fraud Prevented',
                CurrencyFormatter.formatAmount(_securityData['fraudPrevented']),
                'Protected',
                Icons.security,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSecurityMetricCard(
                'Risk Score',
                '${(_securityData['avgRiskScore'] * 100).toStringAsFixed(1)}%',
                'Average',
                Icons.warning_amber_outlined,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSecurityMetricCard(
                'Blocked Threats',
                '${_securityData['blockedTransactions']}',
                'Today',
                Icons.block,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Risk Trend Chart
        _buildRiskTrendChart(),
        const SizedBox(height: 20),
        
        // Recent Alerts
        _buildRecentAlertsSection(),
      ],
    );
  }

  Widget _buildFraudDetectionReport() {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fraud Detection Performance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildDetectionMetric('Detection Rate', '${(_mlPerformance['accuracy'] * 100).toStringAsFixed(1)}%'),
                _buildDetectionMetric('False Positives', '${(_mlPerformance['falsePositiveRate'] * 100).toStringAsFixed(1)}%'),
                _buildDetectionMetric('Processing Time', '${_mlPerformance['processingTime']}s avg'),
                _buildDetectionMetric('Models Active', '${_mlPerformance['modelsDeployed']}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Fraud Alerts List
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Fraud Alerts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ..._fraudAlerts.take(5).map((alert) => _buildAlertItem(alert)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlatformSecurityReport() {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Platform Security Analysis',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ..._platformStats.entries.map((entry) => _buildPlatformItem(entry.key, entry.value)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRiskAssessmentReport() {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Risk Assessment Overview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 100,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                              if (value.toInt() < days.length) {
                                return Text(days[value.toInt()], style: const TextStyle(fontSize: 10));
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: _riskTrends.asMap().entries.map((entry) {
                        final index = entry.key;
                        final data = entry.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: data['lowRisk'].toDouble(),
                              color: Colors.green,
                              width: 8,
                            ),
                            BarChartRodData(
                              toY: data['mediumRisk'].toDouble(),
                              color: Colors.orange,
                              width: 8,
                            ),
                            BarChartRodData(
                              toY: data['highRisk'].toDouble(),
                              color: Colors.red,
                              width: 8,
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionAuditReport() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transaction Audit Trail',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildAuditItem('High-Risk Transaction Blocked', '254XXXXX → 255XXXXX', CurrencyFormatter.formatAmount(850000), Colors.red),
            _buildAuditItem('Suspicious Pattern Detected', 'Rapid transfers detected', 'Multiple accounts', Colors.orange),
            _buildAuditItem('AI Model Alert', 'Unusual location access', 'Dodoma → Dar es Salaam', Colors.yellow[700]!),
            _buildAuditItem('Transaction Verified', 'Identity confirmed via USSD', CurrencyFormatter.formatAmount(25000), Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildMLPerformanceReport() {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI/ML Model Performance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMLMetricCard('Accuracy', '${(_mlPerformance['accuracy'] * 100).toStringAsFixed(1)}%', Colors.green),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMLMetricCard('Precision', '${(_mlPerformance['precision'] * 100).toStringAsFixed(1)}%', Colors.blue),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMLMetricCard('Recall', '${(_mlPerformance['recall'] * 100).toStringAsFixed(1)}%', Colors.purple),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMLMetricCard('F1-Score', '${(_mlPerformance['f1Score'] * 100).toStringAsFixed(1)}%', Colors.orange),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Model Status',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildModelStatusItem('Transaction Classifier', 'Active', 'v2.1.3', Colors.green),
                _buildModelStatusItem('Risk Scorer', 'Active', 'v1.8.7', Colors.green),
                _buildModelStatusItem('Pattern Detector', 'Training', 'v3.0.1', Colors.orange),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildExportOptions(),
          const SizedBox(height: 20),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Export History',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildExportHistoryItem('Security Summary - Dec 2024', 'PDF', '2.1 MB'),
                  _buildExportHistoryItem('Fraud Detection Report - Nov 2024', 'Excel', '1.8 MB'),
                  _buildExportHistoryItem('Platform Analysis - Nov 2024', 'PDF', '3.2 MB'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widgets
  Widget _buildSecurityMetricCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskTrendChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Risk Trends',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              height: 150,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          if (value.toInt() < days.length) {
                            return Text(days[value.toInt()], style: const TextStyle(fontSize: 10));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _riskTrends.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value['highRisk'].toDouble());
                      }).toList(),
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: _riskTrends.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value['mediumRisk'].toDouble());
                      }).toList(),
                      isCurved: true,
                      color: Colors.orange,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAlertsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Security Alerts',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._fraudAlerts.take(3).map((alert) => _buildAlertItem(alert)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionMetric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAlertItem(FraudAlert alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getAlertColor(alert.severity).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getAlertColor(alert.severity).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _getAlertIcon(alert.alertType),
            color: _getAlertColor(alert.severity),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.alertType,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
                Text(
                  alert.description,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            alert.severity.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _getAlertColor(alert.severity),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformItem(String platform, Map<String, dynamic> stats) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                platform,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${(stats['fraudRate'] * 100).toStringAsFixed(1)}% fraud rate',
                style: TextStyle(
                  color: stats['fraudRate'] > 0.05 ? Colors.red : Colors.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${stats['transactions']} transactions'),
              Text('${CurrencyFormatter.formatAmount(stats['volume'])} volume'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuditItem(String title, String description, String detail, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          Text(
            detail,
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMLMetricCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelStatusItem(String name, String status, String version, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                version,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportHistoryItem(String name, String format, String size) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            format == 'PDF' ? Icons.picture_as_pdf : Icons.table_chart,
            color: format == 'PDF' ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  '$format • $size',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.download, size: 20),
          ),
        ],
      ),
    );
  }

  Color _getAlertColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow[700]!;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getAlertIcon(String alertType) {
    switch (alertType.toLowerCase()) {
      case 'suspicious transaction':
        return Icons.warning;
      case 'high risk score':
        return Icons.error;
      case 'pattern anomaly':
        return Icons.analytics;
      case 'location mismatch':
        return Icons.location_off;
      default:
        return Icons.notification_important;
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await _generateSecurityData();
    setState(() => _isLoading = false);
  }

  Widget _buildExportOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export Options',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _exportToPDF,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Export PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _exportToExcel,
                    icon: const Icon(Icons.table_chart),
                    label: const Text('Export Excel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _shareReport,
                icon: const Icon(Icons.share),
                label: const Text('Share Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _exportToPDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting to PDF...')),
    );
  }

  void _exportToExcel() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting to Excel...')),
    );
  }

  void _shareReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening share options...')),
    );
  }
}
