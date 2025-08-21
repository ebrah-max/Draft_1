enum RiskLevel {
  low,
  medium,
  high,
  critical,
}

extension RiskLevelExtension on RiskLevel {
  String get displayName {
    switch (this) {
      case RiskLevel.low:
        return 'Low Risk';
      case RiskLevel.medium:
        return 'Medium Risk';
      case RiskLevel.high:
        return 'High Risk';
      case RiskLevel.critical:
        return 'Critical Risk';
    }
  }

  String get description {
    switch (this) {
      case RiskLevel.low:
        return 'Transaction appears legitimate with minimal risk indicators';
      case RiskLevel.medium:
        return 'Transaction shows some suspicious patterns, requires monitoring';
      case RiskLevel.high:
        return 'Transaction displays multiple fraud indicators, verification recommended';
      case RiskLevel.critical:
        return 'Transaction poses severe fraud risk, immediate action required';
    }
  }

  int get colorValue {
    switch (this) {
      case RiskLevel.low:
        return 0xFF4CAF50; // Green
      case RiskLevel.medium:
        return 0xFFFF9800; // Orange
      case RiskLevel.high:
        return 0xFFFF5722; // Deep Orange
      case RiskLevel.critical:
        return 0xFFF44336; // Red
    }
  }

  double get severity {
    switch (this) {
      case RiskLevel.low:
        return 0.25;
      case RiskLevel.medium:
        return 0.5;
      case RiskLevel.high:
        return 0.75;
      case RiskLevel.critical:
        return 1.0;
    }
  }
}

class RiskAssessment {
  final String transactionId;
  final double riskScore; // 0.0 to 1.0
  final RiskLevel riskLevel;
  final Map<String, double> riskFactors;
  final DateTime timestamp;
  final List<String> recommendations;
  final Map<String, dynamic>? additionalData;

  RiskAssessment({
    required this.transactionId,
    required this.riskScore,
    required this.riskLevel,
    required this.riskFactors,
    required this.timestamp,
    required this.recommendations,
    this.additionalData,
  });

  factory RiskAssessment.fromJson(Map<String, dynamic> json) {
    return RiskAssessment(
      transactionId: json['transactionId'] as String,
      riskScore: (json['riskScore'] as num).toDouble(),
      riskLevel: RiskLevel.values[json['riskLevel'] as int],
      riskFactors: Map<String, double>.from(
        (json['riskFactors'] as Map).map(
          (key, value) => MapEntry(key as String, (value as num).toDouble()),
        ),
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      recommendations: List<String>.from(json['recommendations'] as List),
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'riskScore': riskScore,
      'riskLevel': riskLevel.index,
      'riskFactors': riskFactors,
      'timestamp': timestamp.toIso8601String(),
      'recommendations': recommendations,
      'additionalData': additionalData,
    };
  }

  /// Get the primary risk factor (highest scoring factor)
  MapEntry<String, double> get primaryRiskFactor {
    return riskFactors.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
  }

  /// Get risk factors sorted by score (descending)
  List<MapEntry<String, double>> get sortedRiskFactors {
    final entries = riskFactors.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  /// Get human-readable risk factor names
  String getRiskFactorDisplayName(String factor) {
    switch (factor) {
      case 'amount_anomaly':
        return 'Amount Anomaly';
      case 'time_anomaly':
        return 'Time Pattern Anomaly';
      case 'location_anomaly':
        return 'Location Anomaly';
      case 'frequency_anomaly':
        return 'Transaction Frequency';
      case 'device_anomaly':
        return 'Device Mismatch';
      case 'network_anomaly':
        return 'Network Anomaly';
      case 'behavioral_anomaly':
        return 'Behavioral Pattern';
      case 'recipient_anomaly':
        return 'Recipient Risk';
      case 'velocity_anomaly':
        return 'Transaction Velocity';
      case 'pattern_anomaly':
        return 'Pattern Recognition';
      default:
        return factor.replaceAll('_', ' ').split(' ')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }

  /// Get risk factor description
  String getRiskFactorDescription(String factor) {
    switch (factor) {
      case 'amount_anomaly':
        return 'Transaction amount deviates significantly from user\'s typical transaction amounts';
      case 'time_anomaly':
        return 'Transaction occurred at an unusual time based on user\'s historical patterns';
      case 'location_anomaly':
        return 'Transaction initiated from an unfamiliar or high-risk location';
      case 'frequency_anomaly':
        return 'User\'s transaction frequency is significantly higher than normal';
      case 'device_anomaly':
        return 'Transaction initiated from an unrecognized or suspicious device';
      case 'network_anomaly':
        return 'Network characteristics suggest potential security risks (VPN, Tor, etc.)';
      case 'behavioral_anomaly':
        return 'Transaction pattern doesn\'t match user\'s typical behavior profile';
      case 'recipient_anomaly':
        return 'Recipient account shows suspicious activity or characteristics';
      case 'velocity_anomaly':
        return 'Multiple transactions in rapid succession exceeding normal velocity';
      case 'pattern_anomaly':
        return 'AI model detected suspicious patterns in transaction sequence';
      default:
        return 'Risk factor detected by fraud detection system';
    }
  }

  /// Get formatted risk score as percentage
  String get formattedRiskScore {
    return '${(riskScore * 100).toStringAsFixed(1)}%';
  }

  /// Check if assessment requires immediate action
  bool get requiresImmediateAction {
    return riskLevel == RiskLevel.critical || riskScore >= 0.9;
  }

  /// Check if assessment requires manual review
  bool get requiresManualReview {
    return riskLevel.index >= RiskLevel.high.index || riskScore >= 0.7;
  }

  /// Get confidence level of the assessment
  double get confidenceLevel {
    // Higher confidence when multiple factors contribute significantly
    final significantFactors = riskFactors.values.where((score) => score > 0.3).length;
    final totalFactors = riskFactors.length;
    
    if (totalFactors == 0) return 0.5;
    
    final factorBalance = significantFactors / totalFactors;
    final scoreConsistency = 1.0 - (riskFactors.values.toList()..sort()).sublist(1)
        .fold(0.0, (sum, score) => sum + (score - riskFactors.values.first).abs()) / riskFactors.length;
    
    return ((factorBalance + scoreConsistency) / 2).clamp(0.0, 1.0);
  }

  /// Get top recommendations (most important ones)
  List<String> get topRecommendations {
    return recommendations.take(3).toList();
  }

  @override
  String toString() {
    return 'RiskAssessment(id: $transactionId, score: ${formattedRiskScore}, level: ${riskLevel.displayName})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RiskAssessment &&
        other.transactionId == transactionId &&
        other.riskScore == riskScore &&
        other.riskLevel == riskLevel &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(transactionId, riskScore, riskLevel, timestamp);
  }
}
