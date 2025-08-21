import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home.dart';
import 'services/fraud_detection_service.dart';
import 'utils/currency_formatter.dart';
import 'models/fraud_alert_model.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with TickerProviderStateMixin {
  final FraudDetectionService _fraudService = FraudDetectionService();
  
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  
  bool _isLoading = false;
  bool _isSaving = false;
  
  // Risk Configuration
  double _criticalRiskThreshold = 0.8;
  double _highRiskThreshold = 0.6;
  double _mediumRiskThreshold = 0.4;
  double _maxTransactionAmount = 1000000.0; // TSh 1M
  bool _enableRealTimeScoring = true;
  bool _enableLocationVerification = true;
  
  // Alert Preferences
  bool _enablePushNotifications = true;
  bool _enableEmailAlerts = true;
  bool _enableSMSAlerts = true;
  bool _enableCriticalAlertSound = true;
  List<String> _selectedAlertTypes = ['High Risk Transaction', 'Suspicious Pattern', 'Location Mismatch'];
  
  // ML Model Settings
  String _selectedMLModel = 'Enhanced Detection v2.1';
  double _modelSensitivity = 0.75;
  bool _enableAutoRetraining = true;
  bool _enableAnomalyDetection = true;
  String _updateFrequency = 'Daily';
  
  // Security Agent Profile
  String _agentName = 'Agent Tanzania';
  String _agentRole = 'Senior Fraud Analyst';
  String _operatingRegion = 'Tanzania';
  List<String> _monitoredPlatforms = ['M-Pesa', 'Airtel Money', 'HaloPesa'];
  bool _enableAdvancedPrivileges = false;
  
  // Data & Backup
  bool _enableDataBackup = true;
  String _backupFrequency = 'Weekly';
  bool _enableDataEncryption = true;
  
  final List<String> _availableAlertTypes = [
    'High Risk Transaction',
    'Suspicious Pattern',
    'Location Mismatch',
    'Velocity Check Failed',
    'Device Fingerprint Mismatch',
    'Time-based Anomaly'
  ];
  
  final List<String> _availableMLModels = [
    'Enhanced Detection v2.1',
    'Basic Classification v1.8',
    'Advanced Pattern v3.0',
    'Hybrid ML/Rule Engine v2.5'
  ];
  
  final List<String> _platformOptions = [
    'M-Pesa',
    'Airtel Money',
    'HaloPesa',
    'Tigo Pesa',
    'Ezy Pesa'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _initializeSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeSettings() async {
    setState(() => _isLoading = true);
    
    try {
      await _fraudService.initialize();
      _animationController.forward();
    } catch (e) {
      debugPrint('Error initializing settings: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Fraud Detection Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _saveSettings,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _resetToDefaults,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.security, size: 16),
                  SizedBox(width: 4),
                  Text('Risk Config', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications, size: 16),
                  SizedBox(width: 4),
                  Text('Alerts', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.smart_toy, size: 16),
                  SizedBox(width: 4),
                  Text('AI/ML', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person, size: 16),
                  SizedBox(width: 4),
                  Text('Profile', style: TextStyle(fontSize: 12)),
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
                  _buildRiskConfigTab(),
                  _buildAlertsTab(),
                  _buildMLConfigTab(),
                  _buildProfileTab(),
                ],
              ),
            ),
    );
  }

  Widget _buildRiskConfigTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Risk Threshold Configuration
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.tune, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      const Text(
                        'Risk Thresholds',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildRiskSlider(
                    'Critical Risk Threshold',
                    _criticalRiskThreshold,
                    Colors.red,
                    (value) => setState(() => _criticalRiskThreshold = value),
                  ),
                  _buildRiskSlider(
                    'High Risk Threshold',
                    _highRiskThreshold,
                    Colors.orange,
                    (value) => setState(() => _highRiskThreshold = value),
                  ),
                  _buildRiskSlider(
                    'Medium Risk Threshold',
                    _mediumRiskThreshold,
                    Colors.yellow[700]!,
                    (value) => setState(() => _mediumRiskThreshold = value),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Transaction Limits
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      const Text(
                        'Transaction Limits',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Maximum Transaction Amount: ${CurrencyFormatter.formatAmount(_maxTransactionAmount)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _maxTransactionAmount,
                    min: 100000,
                    max: 5000000,
                    divisions: 49,
                    activeColor: Colors.deepPurple,
                    onChanged: (value) => setState(() => _maxTransactionAmount = value),
                  ),
                  Text(
                    'Range: ${CurrencyFormatter.formatAmount(100000)} - ${CurrencyFormatter.formatAmount(5000000)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Security Features
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      const Text(
                        'Security Features',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSwitchTile(
                    'Real-time Risk Scoring',
                    'Enable live risk assessment for each transaction',
                    _enableRealTimeScoring,
                    Icons.speed,
                    (value) => setState(() => _enableRealTimeScoring = value),
                  ),
                  _buildSwitchTile(
                    'Location Verification',
                    'Verify transaction locations against user patterns',
                    _enableLocationVerification,
                    Icons.location_on,
                    (value) => setState(() => _enableLocationVerification = value),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notification Channels
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_active, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      const Text(
                        'Notification Channels',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSwitchTile(
                    'Push Notifications',
                    'Receive instant app notifications',
                    _enablePushNotifications,
                    Icons.mobile_friendly,
                    (value) => setState(() => _enablePushNotifications = value),
                  ),
                  _buildSwitchTile(
                    'Email Alerts',
                    'Get fraud alerts via email',
                    _enableEmailAlerts,
                    Icons.email,
                    (value) => setState(() => _enableEmailAlerts = value),
                  ),
                  _buildSwitchTile(
                    'SMS Alerts',
                    'Receive SMS notifications for critical alerts',
                    _enableSMSAlerts,
                    Icons.sms,
                    (value) => setState(() => _enableSMSAlerts = value),
                  ),
                  _buildSwitchTile(
                    'Critical Alert Sound',
                    'Play sound for critical fraud alerts',
                    _enableCriticalAlertSound,
                    Icons.volume_up,
                    (value) => setState(() => _enableCriticalAlertSound = value),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Alert Types
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      const Text(
                        'Alert Types',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Text(
                    'Select which types of fraud alerts to receive',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ..._availableAlertTypes.map((alertType) {
                    final isSelected = _selectedAlertTypes.contains(alertType);
                    return CheckboxListTile(
                      title: Text(alertType),
                      subtitle: Text(_getAlertDescription(alertType)),
                      value: isSelected,
                      activeColor: Colors.deepPurple,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedAlertTypes.add(alertType);
                          } else {
                            _selectedAlertTypes.remove(alertType);
                          }
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMLConfigTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Model Selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.psychology, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      const Text(
                        'AI Model Configuration',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Active ML Model',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedMLModel,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _availableMLModels.map((model) {
                      return DropdownMenuItem(value: model, child: Text(model));
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedMLModel = value!),
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    'Model Sensitivity: ${(_modelSensitivity * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _modelSensitivity,
                    min: 0.1,
                    max: 1.0,
                    divisions: 9,
                    activeColor: Colors.deepPurple,
                    onChanged: (value) => setState(() => _modelSensitivity = value),
                  ),
                  Text(
                    'Higher sensitivity detects more fraud but may increase false positives',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Model Features
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      const Text(
                        'Model Features',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSwitchTile(
                    'Auto-Retraining',
                    'Automatically retrain models with new data',
                    _enableAutoRetraining,
                    Icons.refresh,
                    (value) => setState(() => _enableAutoRetraining = value),
                  ),
                  _buildSwitchTile(
                    'Anomaly Detection',
                    'Enable advanced pattern anomaly detection',
                    _enableAnomalyDetection,
                    Icons.insights,
                    (value) => setState(() => _enableAnomalyDetection = value),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Update Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.update, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      const Text(
                        'Update Frequency',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _updateFrequency,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: ['Hourly', 'Daily', 'Weekly', 'Monthly'].map((freq) {
                      return DropdownMenuItem(value: freq, child: Text(freq));
                    }).toList(),
                    onChanged: (value) => setState(() => _updateFrequency = value!),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widgets and methods
  Widget _buildRiskSlider(
    String title,
    double value,
    Color color,
    Function(double) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                '${(value * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Slider(
            value: value,
            min: 0.1,
            max: 1.0,
            divisions: 9,
            activeColor: color,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    IconData icon,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      value: value,
      activeColor: Colors.deepPurple,
      secondary: Icon(icon, color: Colors.deepPurple),
      onChanged: onChanged,
    );
  }

  String _getAlertDescription(String alertType) {
    switch (alertType) {
      case 'High Risk Transaction':
        return 'Transactions with elevated fraud risk scores';
      case 'Suspicious Pattern':
        return 'Unusual transaction patterns detected';
      case 'Location Mismatch':
        return 'Transactions from unexpected locations';
      case 'Velocity Check Failed':
        return 'Too many transactions in short time';
      case 'Device Fingerprint Mismatch':
        return 'Transaction from unknown device';
      case 'Time-based Anomaly':
        return 'Transactions at unusual times';
      default:
        return 'Fraud detection alert';
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    
    try {
      // Simulate saving settings to backend
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check, color: Colors.white),
                SizedBox(width: 8),
                Text('Settings saved successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Error saving settings: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text(
          'Are you sure you want to reset all settings to their default values? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performReset();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _performReset() {
    setState(() {
      // Risk Configuration
      _criticalRiskThreshold = 0.8;
      _highRiskThreshold = 0.6;
      _mediumRiskThreshold = 0.4;
      _maxTransactionAmount = 1000000.0;
      _enableRealTimeScoring = true;
      _enableLocationVerification = true;
      
      // Alert Preferences
      _enablePushNotifications = true;
      _enableEmailAlerts = true;
      _enableSMSAlerts = true;
      _enableCriticalAlertSound = true;
      _selectedAlertTypes = ['High Risk Transaction', 'Suspicious Pattern', 'Location Mismatch'];
      
      // ML Model Settings
      _selectedMLModel = 'Enhanced Detection v2.1';
      _modelSensitivity = 0.75;
      _enableAutoRetraining = true;
      _enableAnomalyDetection = true;
      _updateFrequency = 'Daily';
      
      // Security Agent Profile
      _agentName = 'Agent Tanzania';
      _agentRole = 'Senior Fraud Analyst';
      _operatingRegion = 'Tanzania';
      _monitoredPlatforms = ['M-Pesa', 'Airtel Money', 'HaloPesa'];
      _enableAdvancedPrivileges = false;
      
      // Data & Backup
      _enableDataBackup = true;
      _backupFrequency = 'Weekly';
      _enableDataEncryption = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.restore, color: Colors.white),
            SizedBox(width: 8),
            Text('Settings reset to defaults'),
          ],
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _exportConfiguration() async {
    try {
      final config = {
        'riskThresholds': {
          'critical': _criticalRiskThreshold,
          'high': _highRiskThreshold,
          'medium': _mediumRiskThreshold,
        },
        'transactionLimits': {
          'maxAmount': _maxTransactionAmount,
        },
        'securityFeatures': {
          'realTimeScoring': _enableRealTimeScoring,
          'locationVerification': _enableLocationVerification,
        },
        'alertPreferences': {
          'pushNotifications': _enablePushNotifications,
          'emailAlerts': _enableEmailAlerts,
          'smsAlerts': _enableSMSAlerts,
          'criticalAlertSound': _enableCriticalAlertSound,
          'selectedAlertTypes': _selectedAlertTypes,
        },
        'mlConfiguration': {
          'selectedModel': _selectedMLModel,
          'sensitivity': _modelSensitivity,
          'autoRetraining': _enableAutoRetraining,
          'anomalyDetection': _enableAnomalyDetection,
          'updateFrequency': _updateFrequency,
        },
        'agentProfile': {
          'name': _agentName,
          'role': _agentRole,
          'region': _operatingRegion,
          'monitoredPlatforms': _monitoredPlatforms,
          'advancedPrivileges': _enableAdvancedPrivileges,
        },
        'dataSettings': {
          'backup': _enableDataBackup,
          'backupFrequency': _backupFrequency,
          'encryption': _enableDataEncryption,
        },
      };
      
      // Simulate file export
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.download_done, color: Colors.white),
                SizedBox(width: 8),
                Text('Configuration exported successfully'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Export failed: $e'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearAllData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Clear All Data'),
          ],
        ),
        content: const Text(
          'This will permanently delete all fraud detection data, transaction history, and ML models. This action CANNOT be undone.\n\nAre you absolutely sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performDataClear();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _performDataClear() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Clearing all data...'),
            ],
          ),
        ),
      );
      
      // Simulate data clearing
      await Future.delayed(const Duration(seconds: 3));
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.delete_sweep, color: Colors.white),
                SizedBox(width: 8),
                Text('All data cleared successfully'),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Reset to defaults after clearing data
        _performReset();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Failed to clear data: $e'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Agent Profile
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      const Text(
                        'Security Agent Profile',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _agentName,
                    decoration: const InputDecoration(
                      labelText: 'Agent Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge),
                    ),
                    onChanged: (value) => _agentName = value,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _agentRole,
                    decoration: const InputDecoration(
                      labelText: 'Role/Position',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.work),
                    ),
                    onChanged: (value) => _agentRole = value,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _operatingRegion,
                    decoration: const InputDecoration(
                      labelText: 'Operating Region',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.public),
                    ),
                    onChanged: (value) => _operatingRegion = value,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Monitored Platforms
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.mobile_friendly, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      const Text(
                        'Monitored Platforms',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Text(
                    'Select which mobile money platforms to monitor',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ..._platformOptions.map((platform) {
                    final isSelected = _monitoredPlatforms.contains(platform);
                    return CheckboxListTile(
                      title: Text(platform),
                      subtitle: Text('Monitor $platform transactions'),
                      value: isSelected,
                      activeColor: Colors.deepPurple,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _monitoredPlatforms.add(platform);
                          } else {
                            _monitoredPlatforms.remove(platform);
                          }
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Security & Permissions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.security, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      const Text(
                        'Security & Data',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSwitchTile(
                    'Advanced Privileges',
                    'Enable advanced fraud investigation tools',
                    _enableAdvancedPrivileges,
                    Icons.admin_panel_settings,
                    (value) => setState(() => _enableAdvancedPrivileges = value),
                  ),
                  _buildSwitchTile(
                    'Data Backup',
                    'Automatically backup fraud detection data',
                    _enableDataBackup,
                    Icons.backup,
                    (value) => setState(() => _enableDataBackup = value),
                  ),
                  _buildSwitchTile(
                    'Data Encryption',
                    'Encrypt all stored fraud detection data',
                    _enableDataEncryption,
                    Icons.lock,
                    (value) => setState(() => _enableDataEncryption = value),
                  ),
                  if (_enableDataBackup) ..[
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _backupFrequency,
                      decoration: const InputDecoration(
                        labelText: 'Backup Frequency',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: ['Daily', 'Weekly', 'Monthly'].map((freq) {
                        return DropdownMenuItem(value: freq, child: Text(freq));
                      }).toList(),
                      onChanged: (value) => setState(() => _backupFrequency = value!),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Action Buttons
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.settings_applications, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      const Text(
                        'System Actions',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _exportConfiguration,
                      icon: const Icon(Icons.download),
                      label: const Text('Export Configuration'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _clearAllData,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Clear All Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

