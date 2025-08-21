import 'transaction_model.dart';
import 'risk_assessment_model.dart';

enum FraudAlertType {
  critical,
  suspicious,
  warning,
  info,
  resolved,
}

extension FraudAlertTypeExtension on FraudAlertType {
  String get displayName {
    switch (this) {
      case FraudAlertType.critical:
        return 'Critical Alert';
      case FraudAlertType.suspicious:
        return 'Suspicious Activity';
      case FraudAlertType.warning:
        return 'Warning';
      case FraudAlertType.info:
        return 'Information';
      case FraudAlertType.resolved:
        return 'Resolved';
    }
  }

  String get icon {
    switch (this) {
      case FraudAlertType.critical:
        return 'error';
      case FraudAlertType.suspicious:
        return 'warning';
      case FraudAlertType.warning:
        return 'info';
      case FraudAlertType.info:
        return 'info_outline';
      case FraudAlertType.resolved:
        return 'check_circle';
    }
  }

  int get colorValue {
    switch (this) {
      case FraudAlertType.critical:
        return 0xFFF44336; // Red
      case FraudAlertType.suspicious:
        return 0xFFFF5722; // Deep Orange
      case FraudAlertType.warning:
        return 0xFFFF9800; // Orange
      case FraudAlertType.info:
        return 0xFF2196F3; // Blue
      case FraudAlertType.resolved:
        return 0xFF4CAF50; // Green
    }
  }

  int get priority {
    switch (this) {
      case FraudAlertType.critical:
        return 5;
      case FraudAlertType.suspicious:
        return 4;
      case FraudAlertType.warning:
        return 3;
      case FraudAlertType.info:
        return 2;
      case FraudAlertType.resolved:
        return 1;
    }
  }
}

class FraudAlert {
  final String id;
  final TransactionModel transaction;
  final RiskAssessment riskAssessment;
  final FraudAlertType alertType;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final bool isResolved;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final String? resolution;
  final Map<String, dynamic>? metadata;

  FraudAlert({
    required this.id,
    required this.transaction,
    required this.riskAssessment,
    required this.alertType,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.isResolved = false,
    this.resolvedBy,
    this.resolvedAt,
    this.resolution,
    this.metadata,
  });

  factory FraudAlert.fromJson(Map<String, dynamic> json) {
    return FraudAlert(
      id: json['id'] as String,
      transaction: TransactionModel.fromJson(json['transaction'] as Map<String, dynamic>),
      riskAssessment: RiskAssessment.fromJson(json['riskAssessment'] as Map<String, dynamic>),
      alertType: FraudAlertType.values[json['alertType'] as int],
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
      isResolved: json['isResolved'] as bool? ?? false,
      resolvedBy: json['resolvedBy'] as String?,
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt'] as String) : null,
      resolution: json['resolution'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction': transaction.toJson(),
      'riskAssessment': riskAssessment.toJson(),
      'alertType': alertType.index,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'isResolved': isResolved,
      'resolvedBy': resolvedBy,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'resolution': resolution,
      'metadata': metadata,
    };
  }

  FraudAlert copyWith({
    String? id,
    TransactionModel? transaction,
    RiskAssessment? riskAssessment,
    FraudAlertType? alertType,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    bool? isResolved,
    String? resolvedBy,
    DateTime? resolvedAt,
    String? resolution,
    Map<String, dynamic>? metadata,
  }) {
    return FraudAlert(
      id: id ?? this.id,
      transaction: transaction ?? this.transaction,
      riskAssessment: riskAssessment ?? this.riskAssessment,
      alertType: alertType ?? this.alertType,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isResolved: isResolved ?? this.isResolved,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolution: resolution ?? this.resolution,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Mark alert as read
  FraudAlert markAsRead() {
    return copyWith(isRead: true);
  }

  /// Resolve alert with resolution details
  FraudAlert resolve(String resolvedBy, String resolution) {
    return copyWith(
      isResolved: true,
      resolvedBy: resolvedBy,
      resolvedAt: DateTime.now(),
      resolution: resolution,
      alertType: FraudAlertType.resolved,
    );
  }

  /// Get time elapsed since alert was created
  Duration get timeElapsed {
    return DateTime.now().difference(timestamp);
  }

  /// Get formatted time elapsed string
  String get timeElapsedString {
    final duration = timeElapsed;
    if (duration.inMinutes < 1) {
      return 'Just now';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m ago';
    } else if (duration.inHours < 24) {
      return '${duration.inHours}h ago';
    } else {
      return '${duration.inDays}d ago';
    }
  }

  /// Check if alert is urgent (requires immediate attention)
  bool get isUrgent {
    return alertType == FraudAlertType.critical || 
           (alertType == FraudAlertType.suspicious && timeElapsed.inMinutes < 30);
  }

  /// Get formatted alert summary
  String get summary {
    return '${alertType.displayName}: ${transaction.platform} transaction of ${transaction.formattedAmount}';
  }

  /// Get detailed alert description
  String get detailedDescription {
    final buffer = StringBuffer();
    buffer.writeln('Alert: ${alertType.displayName}');
    buffer.writeln('Transaction: ${transaction.typeDisplayName}');
    buffer.writeln('Platform: ${transaction.platform}');
    buffer.writeln('Amount: ${transaction.formattedAmount}');
    buffer.writeln('Risk Score: ${riskAssessment.formattedRiskScore}');
    buffer.writeln('Time: ${timeElapsedString}');
    
    if (riskAssessment.riskFactors.isNotEmpty) {
      buffer.writeln('\nRisk Factors:');
      for (final factor in riskAssessment.sortedRiskFactors.take(3)) {
        buffer.writeln('• ${riskAssessment.getRiskFactorDisplayName(factor.key)}: ${(factor.value * 100).toStringAsFixed(1)}%');
      }
    }
    
    return buffer.toString().trim();
  }

  /// Get recommended actions based on alert type
  List<String> get recommendedActions {
    switch (alertType) {
      case FraudAlertType.critical:
        return [
          'Block transaction immediately',
          'Contact customer via registered phone',
          'Initiate fraud investigation',
          'Flag account for monitoring',
        ];
      case FraudAlertType.suspicious:
        return [
          'Review transaction details',
          'Verify customer identity',
          'Check transaction history',
          'Monitor account activity',
        ];
      case FraudAlertType.warning:
        return [
          'Monitor transaction',
          'Log for analysis',
          'Review if pattern continues',
        ];
      case FraudAlertType.info:
        return [
          'Document for future reference',
          'Include in regular reports',
        ];
      case FraudAlertType.resolved:
        return [
          'Archive alert',
          'Update knowledge base',
        ];
    }
  }

  /// Check if alert should trigger notification
  bool get shouldNotify {
    return !isRead && !isResolved && alertType.priority >= 3;
  }

  /// Get notification priority level
  int get notificationPriority {
    if (isResolved) return 0;
    return alertType.priority;
  }

  @override
  String toString() {
    return 'FraudAlert(id: $id, type: ${alertType.displayName}, transaction: ${transaction.id}, resolved: $isResolved)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FraudAlert &&
        other.id == id &&
        other.transaction.id == transaction.id &&
        other.alertType == alertType &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(id, transaction.id, alertType, timestamp);
  }
}
