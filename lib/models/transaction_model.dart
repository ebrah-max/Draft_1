import 'package:flutter/foundation.dart';
import '../utils/currency_formatter.dart';

class TransactionModel {
  final String id;
  final double amount;
  final String platform; // M-Pesa, Airtel Money, HaloPesa, Tigo Pesa, etc.
  final String type; // send, receive, pay, withdraw, deposit
  final String recipientId;
  final String? recipientName;
  final String? recipientPhone;
  final DateTime timestamp;
  final String status; // pending, completed, failed, blocked
  final Map<String, dynamic> metadata;
  
  TransactionModel({
    required this.id,
    required this.amount,
    required this.platform,
    required this.type,
    required this.recipientId,
    this.recipientName,
    this.recipientPhone,
    required this.timestamp,
    required this.status,
    required this.metadata,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      platform: json['platform'] as String,
      type: json['type'] as String,
      recipientId: json['recipientId'] as String,
      recipientName: json['recipientName'] as String?,
      recipientPhone: json['recipientPhone'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: json['status'] as String,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'platform': platform,
      'type': type,
      'recipientId': recipientId,
      'recipientName': recipientName,
      'recipientPhone': recipientPhone,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'metadata': metadata,
    };
  }

  TransactionModel copyWith({
    String? id,
    double? amount,
    String? platform,
    String? type,
    String? recipientId,
    String? recipientName,
    String? recipientPhone,
    DateTime? timestamp,
    String? status,
    Map<String, dynamic>? metadata,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      platform: platform ?? this.platform,
      type: type ?? this.type,
      recipientId: recipientId ?? this.recipientId,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionModel &&
        other.id == id &&
        other.amount == amount &&
        other.platform == platform &&
        other.type == type &&
        other.recipientId == recipientId &&
        other.recipientName == recipientName &&
        other.recipientPhone == recipientPhone &&
        other.timestamp == timestamp &&
        other.status == status &&
        mapEquals(other.metadata, metadata);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      amount,
      platform,
      type,
      recipientId,
      recipientName,
      recipientPhone,
      timestamp,
      status,
      metadata,
    );
  }

  @override
  String toString() {
    return 'TransactionModel(id: $id, amount: $amount, platform: $platform, type: $type, status: $status)';
  }

  /// Check if this is a high-value transaction
  bool get isHighValue => CurrencyFormatter.isHighValue(amount.abs());

  /// Check if this is a cross-platform transaction
  bool get isCrossPlatform {
    final senderPlatform = metadata['sender_platform'] as String?;
    return senderPlatform != null && senderPlatform != platform;
  }

  /// Get formatted amount with currency
  String get formattedAmount {
    return CurrencyFormatter.formatAmountWithDecimals(amount.abs());
  }

  /// Get platform icon name
  String get platformIcon {
    switch (platform.toLowerCase()) {
      case 'm-pesa':
      case 'mpesa':
        return 'mpesa';
      case 'airtel money':
      case 'airtel':
        return 'airtel';
      case 'halopesa':
      case 'halo pesa':
        return 'halopesa';
      case 'tigo pesa':
      case 'tigopesa':
        return 'tigo';
      default:
        return 'mobile_money';
    }
  }

  /// Get platform color
  int get platformColor {
    switch (platform.toLowerCase()) {
      case 'm-pesa':
      case 'mpesa':
        return 0xFF00A651; // Green
      case 'airtel money':
      case 'airtel':
        return 0xFFE20613; // Red
      case 'halopesa':
      case 'halo pesa':
        return 0xFF0066CC; // Blue
      case 'tigo pesa':
      case 'tigopesa':
        return 0xFFFF6600; // Orange
      default:
        return 0xFF9C27B0; // Purple
    }
  }

  /// Get transaction type display name
  String get typeDisplayName {
    switch (type.toLowerCase()) {
      case 'send':
        return 'Send Money';
      case 'receive':
        return 'Receive Money';
      case 'pay':
        return 'Pay Bill';
      case 'withdraw':
        return 'Withdraw Cash';
      case 'deposit':
        return 'Deposit Cash';
      case 'buy_airtime':
        return 'Buy Airtime';
      case 'pay_merchant':
        return 'Pay Merchant';
      default:
        return type.toUpperCase();
    }
  }

  /// Check if transaction is suspicious based on basic rules
  bool get isSuspicious {
    // Very high amounts
    if (CurrencyFormatter.isVeryHighValue(amount.abs())) return true;
    
    // Late night transactions
    final hour = timestamp.hour;
    if ((hour >= 23 || hour <= 5) && amount.abs() > 100000) return true;
    
    // Cross-platform high-value transactions
    if (isCrossPlatform && amount.abs() > 200000) return true;
    
    return false;
  }
}
