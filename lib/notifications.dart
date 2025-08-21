import 'dart:async';
import 'package:flutter/material.dart';
import 'services/fraud_detection_service.dart';
import 'models/fraud_alert_model.dart';
import 'models/transaction_model.dart';
import 'models/risk_assessment_model.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> with TickerProviderStateMixin {
  final FraudDetectionService _fraudService = FraudDetectionService();
  StreamSubscription<FraudAlert>? _fraudAlertsSubscription;
  
  List<FraudAlert> _fraudAlerts = [];
  List<SecurityNotification> _securityNotifications = [];
  String _selectedFilter = 'All';
  bool _isLoading = true;
  
  late TabController _tabController;
  final List<String> _filterTypes = ['All', 'Critical', 'Suspicious', 'Warning', 'Info'];
  
  // Security notification settings
  bool _fraudAlerts = true;
  bool _suspiciousActivityAlerts = true;
  bool _riskThresholdAlerts = true;
  bool _pushNotifications = true;
  bool _emailNotifications = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fraudAlertsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    setState(() => _isLoading = true);
    
    try {
      // Initialize fraud detection service
      await _fraudService.initialize();
      
      // Load existing fraud alerts
      _fraudAlerts = _fraudService.getRecentAlerts();
      
      // Generate sample security notifications
      _generateSampleSecurityNotifications();
      
      // Listen to real-time fraud alerts
      _fraudAlertsSubscription = _fraudService.fraudAlerts.listen(
        (alert) {
          if (mounted) {
            setState(() {
              _fraudAlerts.insert(0, alert);
              if (_fraudAlerts.length > 50) {
                _fraudAlerts.removeLast();
              }
            });
          }
        },
      );
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _generateSampleSecurityNotifications() {
    _securityNotifications = [
      SecurityNotification(
        id: 'SEC001',
        title: 'AI Model Update',
        message: 'Fraud detection model updated with latest patterns',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        type: SecurityNotificationType.system,
        priority: NotificationPriority.info,
        isRead: false,
      ),
      SecurityNotification(
        id: 'SEC002',
        title: 'Security Scan Complete',
        message: 'Weekly security scan completed. 156 transactions analyzed, 3 flagged',
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        type: SecurityNotificationType.report,
        priority: NotificationPriority.info,
        isRead: true,
      ),
      SecurityNotification(
        id: 'SEC003',
        title: 'Risk Threshold Update',
        message: 'Risk threshold adjusted based on recent fraud patterns',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        type: SecurityNotificationType.system,
        priority: NotificationPriority.warning,
        isRead: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final unreadFraudAlertsCount = _fraudAlerts.where((alert) => !alert.isRead).length;
    final unreadSecurityCount = _securityNotifications.where((notif) => !notif.isRead).length;
    final totalUnread = unreadFraudAlertsCount + unreadSecurityCount;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Security Alerts & Notifications',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          if (totalUnread > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all, color: Colors.white, size: 16),
              label: Text(
                '$totalUnread',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showNotificationSettings,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.security),
                  const SizedBox(width: 8),
                  const Text('Fraud Alerts'),
                  if (unreadFraudAlertsCount > 0) ..[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        unreadFraudAlertsCount.toString(),
                        style: const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications),
                  const SizedBox(width: 8),
                  const Text('Security'),
                  if (unreadSecurityCount > 0) ..[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        unreadSecurityCount.toString(),
                        style: const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFraudAlertsTab(),
                _buildSecurityNotificationsTab(),
              ],
            ),
    );
  }

  Widget _buildFraudAlertsTab() {
    final filteredAlerts = _getFilteredFraudAlerts();
    
    return Column(
      children: [
        _buildFilterBar(),
        if (filteredAlerts.isEmpty)
          Expanded(child: _buildEmptyFraudAlertsState())
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshAlerts,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredAlerts.length,
                itemBuilder: (context, index) {
                  return _buildFraudAlertCard(filteredAlerts[index]);
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filterTypes.length,
        itemBuilder: (context, index) {
          final filterType = _filterTypes[index];
          final isSelected = _selectedFilter == filterType;
          final count = _getFilterCount(filterType);
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(filterType),
                  if (count > 0) ..[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.grey[400],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected ? Colors.deepPurple : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              selectedColor: Colors.deepPurple,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filterType;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFraudAlertCard(FraudAlert alert) {
    final alertColor = _getFraudAlertColor(alert.alertType);
    final alertIcon = _getFraudAlertIcon(alert.alertType);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: alert.isRead ? 1 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: alertColor.withOpacity(0.3),
            width: alert.isRead ? 0 : 2,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showFraudAlertDetails(alert),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: alertColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(alertIcon, color: alertColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                alert.alertType.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: alertColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: alertColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Risk: ${(alert.riskAssessment.riskScore * 100).toInt()}%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: alertColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${alert.transaction.platform} • ${alert.transaction.formattedAmount}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!alert.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: alertColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  alert.message,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimestamp(alert.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    const Spacer(),
                    if (alert.alertType == FraudAlertType.critical)
                      TextButton.icon(
                        onPressed: () => _takeImmediateAction(alert),
                        icon: const Icon(Icons.security, size: 14),
                        label: const Text('TAKE ACTION'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          textStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityNotificationsTab() {
    return _securityNotifications.isEmpty
        ? _buildEmptySecurityNotificationsState()
        : RefreshIndicator(
            onRefresh: _refreshAlerts,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _securityNotifications.length,
              itemBuilder: (context, index) {
                return _buildSecurityNotificationCard(_securityNotifications[index]);
              },
            ),
          );
  }

  Widget _buildSecurityNotificationCard(SecurityNotification notification) {
    final color = _getSecurityNotificationColor(notification.type);
    final icon = _getSecurityNotificationIcon(notification.type);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: notification.isRead ? 1 : 2,
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(notification.message),
              const SizedBox(height: 4),
              Text(
                _formatTimestamp(notification.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          trailing: !notification.isRead
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
          onTap: () {
            if (!notification.isRead) {
              setState(() {
                notification.isRead = true;
              });
            }
            _showSecurityNotificationDetails(notification);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyFraudAlertsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.security,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No fraud alerts',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All transactions are secure',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySecurityNotificationsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_active,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No security notifications',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'System is running smoothly',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  List<FraudAlert> _getFilteredFraudAlerts() {
    if (_selectedFilter == 'All') {
      return _fraudAlerts;
    }
    
    return _fraudAlerts.where((alert) {
      switch (_selectedFilter) {
        case 'Critical':
          return alert.alertType == FraudAlertType.critical;
        case 'Suspicious':
          return alert.alertType == FraudAlertType.suspicious;
        case 'Warning':
          return alert.alertType == FraudAlertType.warning;
        case 'Info':
          return alert.alertType == FraudAlertType.info;
        default:
          return true;
      }
    }).toList();
  }

  int _getFilterCount(String filterType) {
    if (filterType == 'All') {
      return _fraudAlerts.length;
    }
    
    return _fraudAlerts.where((alert) {
      switch (filterType) {
        case 'Critical':
          return alert.alertType == FraudAlertType.critical;
        case 'Suspicious':
          return alert.alertType == FraudAlertType.suspicious;
        case 'Warning':
          return alert.alertType == FraudAlertType.warning;
        case 'Info':
          return alert.alertType == FraudAlertType.info;
        default:
          return false;
      }
    }).length;
  }

  Color _getFraudAlertColor(FraudAlertType alertType) {
    switch (alertType) {
      case FraudAlertType.critical:
        return Colors.red;
      case FraudAlertType.suspicious:
        return Colors.orange;
      case FraudAlertType.warning:
        return Colors.amber;
      case FraudAlertType.info:
        return Colors.blue;
    }
  }

  IconData _getFraudAlertIcon(FraudAlertType alertType) {
    switch (alertType) {
      case FraudAlertType.critical:
        return Icons.error;
      case FraudAlertType.suspicious:
        return Icons.warning;
      case FraudAlertType.warning:
        return Icons.info;
      case FraudAlertType.info:
        return Icons.info_outline;
    }
  }

  Color _getSecurityNotificationColor(SecurityNotificationType type) {
    switch (type) {
      case SecurityNotificationType.system:
        return Colors.blue;
      case SecurityNotificationType.report:
        return Colors.green;
      case SecurityNotificationType.alert:
        return Colors.orange;
      case SecurityNotificationType.update:
        return Colors.purple;
    }
  }

  IconData _getSecurityNotificationIcon(SecurityNotificationType type) {
    switch (type) {
      case SecurityNotificationType.system:
        return Icons.settings;
      case SecurityNotificationType.report:
        return Icons.assessment;
      case SecurityNotificationType.alert:
        return Icons.notification_important;
      case SecurityNotificationType.update:
        return Icons.system_update;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _markAllAsRead() {
    setState(() {
      for (var alert in _fraudAlerts) {
        alert.isRead = true;
      }
      for (var notification in _securityNotifications) {
        notification.isRead = true;
      }
    });
  }

  Future<void> _refreshAlerts() async {
    await _initializeNotifications();
  }

  void _showFraudAlertDetails(FraudAlert alert) {
    if (!alert.isRead) {
      setState(() {
        alert.isRead = true;
      });
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FraudAlertDetailsSheet(alert: alert),
    );
  }

  void _showSecurityNotificationDetails(SecurityNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 16),
            Text(
              'Received: ${_formatTimestamp(notification.timestamp)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _takeImmediateAction(FraudAlert alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Immediate Action Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This is a critical security alert that requires immediate attention.',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Text(
              'Transaction: ${alert.transaction.formattedAmount}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Platform: ${alert.transaction.platform}'),
            Text('Risk Score: ${(alert.riskAssessment.riskScore * 100).toInt()}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // In a real app, this would block the transaction
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transaction blocked successfully'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Block Transaction'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Notification Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Fraud Alerts'),
              subtitle: const Text('Receive alerts for fraudulent activities'),
              value: _fraudAlerts,
              onChanged: (value) => setState(() => _fraudAlerts = value),
            ),
            SwitchListTile(
              title: const Text('Suspicious Activity'),
              subtitle: const Text('Alert for suspicious transaction patterns'),
              value: _suspiciousActivityAlerts,
              onChanged: (value) => setState(() => _suspiciousActivityAlerts = value),
            ),
            SwitchListTile(
              title: const Text('Risk Threshold Alerts'),
              subtitle: const Text('Notify when risk thresholds are exceeded'),
              value: _riskThresholdAlerts,
              onChanged: (value) => setState(() => _riskThresholdAlerts = value),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Push Notifications'),
              subtitle: const Text('Receive notifications on your device'),
              value: _pushNotifications,
              onChanged: (value) => setState(() => _pushNotifications = value),
            ),
            SwitchListTile(
              title: const Text('Email Notifications'),
              subtitle: const Text('Receive notifications via email'),
              value: _emailNotifications,
              onChanged: (value) => setState(() => _emailNotifications = value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings saved')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// Enums and Classes
enum SecurityNotificationType {
  system,
  report,
  alert,
  update,
}

enum NotificationPriority {
  info,
  warning,
  critical,
}

class SecurityNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final SecurityNotificationType type;
  final NotificationPriority priority;
  bool isRead;

  SecurityNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    required this.priority,
    required this.isRead,
  });
}

class FraudAlertDetailsSheet extends StatelessWidget {
  final FraudAlert alert;
  
  const FraudAlertDetailsSheet({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final alertColor = _getAlertColor(alert.alertType);
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: alertColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  _getAlertIcon(alert.alertType),
                  color: alertColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.alertType.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: alertColor,
                      ),
                    ),
                    Text(
                      'Fraud Alert',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Alert Details
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: alertColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: alertColor.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Risk Score: ',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      '${(alert.riskAssessment.riskScore * 100).toInt()}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: alertColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Transaction Details
          const Text(
            'Transaction Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildDetailRow('Platform', alert.transaction.platform),
          _buildDetailRow('Amount', alert.transaction.formattedAmount),
          _buildDetailRow('Type', alert.transaction.typeDisplayName),
          _buildDetailRow('Recipient', alert.transaction.recipientName ?? 'Unknown'),
          _buildDetailRow('Status', alert.transaction.status.toUpperCase()),
          _buildDetailRow('Time', _formatDateTime(alert.transaction.timestamp)),
          
          const SizedBox(height: 20),
          
          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to transaction details or take action
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: alertColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('View Transaction'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getAlertColor(FraudAlertType alertType) {
    switch (alertType) {
      case FraudAlertType.critical:
        return Colors.red;
      case FraudAlertType.suspicious:
        return Colors.orange;
      case FraudAlertType.warning:
        return Colors.amber;
      case FraudAlertType.info:
        return Colors.blue;
    }
  }
  
  IconData _getAlertIcon(FraudAlertType alertType) {
    switch (alertType) {
      case FraudAlertType.critical:
        return Icons.error;
      case FraudAlertType.suspicious:
        return Icons.warning;
      case FraudAlertType.warning:
        return Icons.info;
      case FraudAlertType.info:
        return Icons.info_outline;
    }
  }
  
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
