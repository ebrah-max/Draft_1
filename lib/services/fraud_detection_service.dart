import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/transaction_model.dart';
import '../models/fraud_alert_model.dart';
import '../models/risk_assessment_model.dart';
import '../utils/currency_formatter.dart';

class FraudDetectionService {
  static final FraudDetectionService _instance = FraudDetectionService._internal();
  factory FraudDetectionService() => _instance;
  FraudDetectionService._internal();

  final StreamController<FraudAlert> _fraudAlertsController = StreamController<FraudAlert>.broadcast();
  Stream<FraudAlert> get fraudAlerts => _fraudAlertsController.stream;

  final List<TransactionModel> _transactionHistory = [];
  final List<FraudAlert> _recentAlerts = [];
  
  // ML Model parameters (in production, these would be loaded from trained models)
  final Map<String, double> _riskWeights = {
    'amount_anomaly': 0.25,
    'time_anomaly': 0.20,
    'location_anomaly': 0.15,
    'frequency_anomaly': 0.15,
    'device_anomaly': 0.10,
    'network_anomaly': 0.10,
    'behavioral_anomaly': 0.05,
  };

  // Threshold values for different risk levels
  final Map<String, double> _riskThresholds = {
    'low': 0.3,
    'medium': 0.6,
    'high': 0.8,
    'critical': 0.95,
  };

  bool _isInitialized = false;
  String? _deviceFingerprint;
  Map<String, dynamic> _userBehaviorProfile = {};

  /// Initialize the fraud detection service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _generateDeviceFingerprint();
      await _loadUserBehaviorProfile();
      await _initializeMLModels();
      _isInitialized = true;
      debugPrint('Fraud Detection Service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Fraud Detection Service: $e');
    }
  }

  /// Generate unique device fingerprint for device anomaly detection
  Future<void> _generateDeviceFingerprint() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final connectivity = Connectivity();
      
      String fingerprint = '';
      
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        fingerprint = '${androidInfo.model}_${androidInfo.id}_${androidInfo.brand}';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        fingerprint = '${iosInfo.model}_${iosInfo.identifierForVendor}_${iosInfo.systemVersion}';
      } else {
        fingerprint = 'web_${DateTime.now().millisecondsSinceEpoch}';
      }

      final connectivityResult = await connectivity.checkConnectivity();
      fingerprint += '_${connectivityResult.first.name}';
      
      _deviceFingerprint = sha256.convert(utf8.encode(fingerprint)).toString();
    } catch (e) {
      _deviceFingerprint = 'unknown_device';
      debugPrint('Error generating device fingerprint: $e');
    }
  }

  /// Load user behavior profile from local storage
  Future<void> _loadUserBehaviorProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('user_behavior_profile');
      
      if (profileJson != null) {
        _userBehaviorProfile = json.decode(profileJson);
      } else {
        _userBehaviorProfile = {
          'average_transaction_amount': 0.0,
          'common_transaction_times': [],
          'preferred_platforms': {},
          'typical_frequency': 0,
          'location_patterns': [],
          'session_duration_avg': 0,
        };
      }
    } catch (e) {
      debugPrint('Error loading user behavior profile: $e');
      _userBehaviorProfile = {};
    }
  }

  /// Initialize ML models (placeholder for actual TensorFlow Lite models)
  Future<void> _initializeMLModels() async {
    // In production, this would load actual TensorFlow Lite models
    // For now, we'll simulate model initialization
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint('ML Models initialized (simulated)');
  }

  /// Analyze transaction for fraud risk
  Future<RiskAssessment> analyzeTransaction(TransactionModel transaction) async {
    if (!_isInitialized) {
      await initialize();
    }

    final riskFactors = <String, double>{};
    
    // Amount anomaly detection
    riskFactors['amount_anomaly'] = _calculateAmountAnomaly(transaction);
    
    // Time-based anomaly detection
    riskFactors['time_anomaly'] = _calculateTimeAnomaly(transaction);
    
    // Location anomaly detection
    riskFactors['location_anomaly'] = _calculateLocationAnomaly(transaction);
    
    // Frequency anomaly detection
    riskFactors['frequency_anomaly'] = _calculateFrequencyAnomaly(transaction);
    
    // Device anomaly detection
    riskFactors['device_anomaly'] = _calculateDeviceAnomaly(transaction);
    
    // Network anomaly detection
    riskFactors['network_anomaly'] = _calculateNetworkAnomaly(transaction);
    
    // Behavioral anomaly detection
    riskFactors['behavioral_anomaly'] = _calculateBehavioralAnomaly(transaction);

    // Calculate overall risk score using weighted sum
    double riskScore = 0.0;
    for (final entry in riskFactors.entries) {
      riskScore += entry.value * (_riskWeights[entry.key] ?? 0.0);
    }

    // Determine risk level
    RiskLevel riskLevel = _determineRiskLevel(riskScore);
    
    // Create risk assessment
    final assessment = RiskAssessment(
      transactionId: transaction.id,
      riskScore: riskScore,
      riskLevel: riskLevel,
      riskFactors: riskFactors,
      timestamp: DateTime.now(),
      recommendations: _generateRecommendations(riskLevel, riskFactors),
    );

    // Generate alert if risk is medium or higher
    if (riskLevel.index >= RiskLevel.medium.index) {
      final alert = FraudAlert(
        id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
        transaction: transaction,
        riskAssessment: assessment,
        alertType: _getAlertType(riskLevel),
        message: _generateAlertMessage(transaction, assessment),
        timestamp: DateTime.now(),
        isRead: false,
      );
      
      _recentAlerts.insert(0, alert);
      _fraudAlertsController.add(alert);
    }

    // Update transaction history and user behavior profile
    _transactionHistory.add(transaction);
    await _updateUserBehaviorProfile(transaction);

    return assessment;
  }

  /// Calculate amount-based anomaly score
  double _calculateAmountAnomaly(TransactionModel transaction) {
    if (_transactionHistory.isEmpty) return 0.0;
    
    final amounts = _transactionHistory.map((t) => t.amount.abs()).toList();
    final avgAmount = amounts.reduce((a, b) => a + b) / amounts.length;
    final deviation = (transaction.amount.abs() - avgAmount).abs();
    final normalizedDeviation = deviation / (avgAmount + 1); // Avoid division by zero
    
    // Unusual large amounts are more suspicious
    if (transaction.amount.abs() > avgAmount * 3) {
      return math.min(1.0, normalizedDeviation * 2);
    }
    
    return math.min(1.0, normalizedDeviation);
  }

  /// Calculate time-based anomaly score
  double _calculateTimeAnomaly(TransactionModel transaction) {
    final hour = transaction.timestamp.hour;
    
    // Transactions between 11 PM and 6 AM are considered more risky
    if (hour >= 23 || hour <= 6) {
      return 0.8;
    }
    
    // Check against user's typical transaction times
    final commonTimes = _userBehaviorProfile['common_transaction_times'] as List<dynamic>? ?? [];
    if (commonTimes.isNotEmpty) {
      final isTypicalTime = commonTimes.any((time) => (time - hour).abs() <= 2);
      return isTypicalTime ? 0.1 : 0.6;
    }
    
    return 0.3;
  }

  /// Calculate location-based anomaly score
  double _calculateLocationAnomaly(TransactionModel transaction) {
    // Simulate location analysis based on transaction metadata
    final location = transaction.metadata['location'] as String? ?? 'unknown';
    
    if (location == 'unknown') return 0.5;
    
    // Check against typical user locations
    final locationPatterns = _userBehaviorProfile['location_patterns'] as List<dynamic>? ?? [];
    if (locationPatterns.isEmpty) return 0.3;
    
    final isKnownLocation = locationPatterns.contains(location);
    return isKnownLocation ? 0.1 : 0.7;
  }

  /// Calculate frequency-based anomaly score
  double _calculateFrequencyAnomaly(TransactionModel transaction) {
    final now = DateTime.now();
    final recentTransactions = _transactionHistory.where(
      (t) => now.difference(t.timestamp).inHours <= 24
    ).length;
    
    final typicalFrequency = _userBehaviorProfile['typical_frequency'] as int? ?? 5;
    
    if (recentTransactions > typicalFrequency * 3) {
      return 0.9; // Very high frequency
    } else if (recentTransactions > typicalFrequency * 2) {
      return 0.6; // High frequency
    }
    
    return 0.2;
  }

  /// Calculate device-based anomaly score
  double _calculateDeviceAnomaly(TransactionModel transaction) {
    final deviceId = transaction.metadata['device_id'] as String? ?? 'unknown';
    
    if (deviceId != _deviceFingerprint) {
      return 0.8; // Different device
    }
    
    return 0.1;
  }

  /// Calculate network-based anomaly score
  double _calculateNetworkAnomaly(TransactionModel transaction) {
    final networkType = transaction.metadata['network_type'] as String? ?? 'unknown';
    
    // VPN or Tor usage is suspicious
    if (networkType.contains('vpn') || networkType.contains('tor')) {
      return 0.9;
    }
    
    // Unknown network type
    if (networkType == 'unknown') {
      return 0.5;
    }
    
    return 0.2;
  }

  /// Calculate behavioral anomaly score
  double _calculateBehavioralAnomaly(TransactionModel transaction) {
    // Check transaction pattern against user behavior
    final platform = transaction.platform;
    final preferredPlatforms = _userBehaviorProfile['preferred_platforms'] as Map<String, dynamic>? ?? {};
    
    if (preferredPlatforms.isEmpty) return 0.3;
    
    final platformUsage = preferredPlatforms[platform] as int? ?? 0;
    final totalUsage = preferredPlatforms.values.fold<int>(0, (sum, usage) => sum + (usage as int));
    
    if (totalUsage == 0) return 0.3;
    
    final platformRatio = platformUsage / totalUsage;
    
    // If user rarely uses this platform, it's suspicious
    if (platformRatio < 0.1) {
      return 0.7;
    }
    
    return 0.2;
  }

  /// Determine risk level based on risk score
  RiskLevel _determineRiskLevel(double riskScore) {
    if (riskScore >= _riskThresholds['critical']!) {
      return RiskLevel.critical;
    } else if (riskScore >= _riskThresholds['high']!) {
      return RiskLevel.high;
    } else if (riskScore >= _riskThresholds['medium']!) {
      return RiskLevel.medium;
    } else {
      return RiskLevel.low;
    }
  }

  /// Generate recommendations based on risk assessment
  List<String> _generateRecommendations(RiskLevel riskLevel, Map<String, double> riskFactors) {
    final recommendations = <String>[];
    
    switch (riskLevel) {
      case RiskLevel.critical:
        recommendations.addAll([
          'BLOCK TRANSACTION IMMEDIATELY',
          'Initiate manual verification process',
          'Contact customer directly via registered phone number',
          'Flag account for enhanced monitoring',
        ]);
        break;
      case RiskLevel.high:
        recommendations.addAll([
          'Require additional authentication',
          'Implement transaction delay (cooling period)',
          'Send SMS verification to registered number',
          'Review customer\'s recent transaction history',
        ]);
        break;
      case RiskLevel.medium:
        recommendations.addAll([
          'Send push notification for confirmation',
          'Log transaction for further analysis',
          'Monitor subsequent transactions closely',
        ]);
        break;
      case RiskLevel.low:
        recommendations.add('Process transaction normally');
        break;
    }

    // Add specific recommendations based on risk factors
    if (riskFactors['amount_anomaly']! > 0.5) {
      recommendations.add('Verify transaction amount with customer');
    }
    
    if (riskFactors['device_anomaly']! > 0.5) {
      recommendations.add('Verify device ownership');
    }
    
    if (riskFactors['location_anomaly']! > 0.5) {
      recommendations.add('Verify customer location');
    }

    return recommendations;
  }

  /// Get alert type based on risk level
  FraudAlertType _getAlertType(RiskLevel riskLevel) {
    switch (riskLevel) {
      case RiskLevel.critical:
        return FraudAlertType.critical;
      case RiskLevel.high:
        return FraudAlertType.suspicious;
      case RiskLevel.medium:
        return FraudAlertType.warning;
      case RiskLevel.low:
        return FraudAlertType.info;
    }
  }

  /// Generate alert message
  String _generateAlertMessage(TransactionModel transaction, RiskAssessment assessment) {
    final platform = transaction.platform;
    final amount = transaction.amount.abs();
    
    switch (assessment.riskLevel) {
      case RiskLevel.critical:
        return 'CRITICAL FRAUD ALERT: Suspicious $platform transaction of ${CurrencyFormatter.formatAmount(amount)} detected. Risk Score: ${(assessment.riskScore * 100).toStringAsFixed(1)}%';
      case RiskLevel.high:
        return 'HIGH RISK: $platform transaction of ${CurrencyFormatter.formatAmount(amount)} requires verification. Risk Score: ${(assessment.riskScore * 100).toStringAsFixed(1)}%';
      case RiskLevel.medium:
        return 'MEDIUM RISK: $platform transaction of ${CurrencyFormatter.formatAmount(amount)} flagged for monitoring. Risk Score: ${(assessment.riskScore * 100).toStringAsFixed(1)}%';
      case RiskLevel.low:
        return 'LOW RISK: $platform transaction of ${CurrencyFormatter.formatAmount(amount)} processed safely.';
    }
  }

  /// Update user behavior profile with new transaction data
  Future<void> _updateUserBehaviorProfile(TransactionModel transaction) async {
    try {
      // Update average transaction amount
      final amounts = _transactionHistory.map((t) => t.amount.abs()).toList();
      _userBehaviorProfile['average_transaction_amount'] = 
          amounts.fold(0.0, (sum, amount) => sum + amount) / amounts.length;

      // Update common transaction times
      final times = _transactionHistory.map((t) => t.timestamp.hour).toList();
      _userBehaviorProfile['common_transaction_times'] = times.toSet().toList();

      // Update preferred platforms
      final platforms = <String, int>{};
      for (final t in _transactionHistory) {
        platforms[t.platform] = (platforms[t.platform] ?? 0) + 1;
      }
      _userBehaviorProfile['preferred_platforms'] = platforms;

      // Update typical frequency (transactions per day)
      final now = DateTime.now();
      final recentTransactions = _transactionHistory.where(
        (t) => now.difference(t.timestamp).inDays <= 30
      ).length;
      _userBehaviorProfile['typical_frequency'] = (recentTransactions / 30).round();

      // Save updated profile
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_behavior_profile', json.encode(_userBehaviorProfile));
      
    } catch (e) {
      debugPrint('Error updating user behavior profile: $e');
    }
  }

  /// Get recent fraud alerts
  List<FraudAlert> getRecentAlerts() {
    return List.from(_recentAlerts);
  }

  /// Get fraud statistics
  Map<String, dynamic> getFraudStats() {
    final total = _transactionHistory.length;
    if (total == 0) return {'total': 0, 'fraud_rate': 0.0, 'blocked': 0};

    final blocked = _recentAlerts.where((alert) => 
        alert.riskAssessment.riskLevel == RiskLevel.critical).length;
    final fraudRate = blocked / total;

    return {
      'total_transactions': total,
      'fraud_rate': fraudRate,
      'blocked_transactions': blocked,
      'alerts_generated': _recentAlerts.length,
    };
  }

  /// Dispose resources
  void dispose() {
    _fraudAlertsController.close();
  }
}
