import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';
import 'settings.dart';
import 'transactions.dart';
import 'analytics.dart';
import 'notifications.dart';
import 'reporting.dart';
import 'services/fraud_detection_service.dart';
import 'models/fraud_alert_model.dart';
import 'models/risk_assessment_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _userName = 'User';
  String _userSurname = '';
  bool _isLoading = true;
  
  // Fraud Detection Service
  final FraudDetectionService _fraudService = FraudDetectionService();
  StreamSubscription<FraudAlert>? _fraudAlertsSubscription;
  List<FraudAlert> _recentAlerts = [];
  Map<String, dynamic> _fraudStats = {};
  
  // Check if Firebase is supported on current platform
  bool get _isFirebaseSupported => kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initializeFraudMonitoring();
  }
  
  @override
  void dispose() {
    _fraudAlertsSubscription?.cancel();
    super.dispose();
  }
  
  /// Initialize real-time fraud monitoring
  void _initializeFraudMonitoring() {
    // Listen to fraud alerts
    _fraudAlertsSubscription = _fraudService.fraudAlerts.listen(
      (alert) {
        if (mounted) {
          setState(() {
            _recentAlerts.insert(0, alert);
            if (_recentAlerts.length > 10) {
              _recentAlerts.removeLast();
            }
          });
          
          // Show critical alerts as snack bars
          if (alert.alertType == FraudAlertType.critical) {
            _showCriticalAlert(alert);
          }
        }
      },
      onError: (error) {
        debugPrint('Error listening to fraud alerts: $error');
      },
    );
    
    // Load initial data
    _loadFraudStats();
    _loadRecentAlerts();
  }
  
  /// Load fraud statistics
  void _loadFraudStats() {
    final stats = _fraudService.getFraudStats();
    if (mounted) {
      setState(() {
        _fraudStats = stats;
      });
    }
  }
  
  /// Load recent alerts
  void _loadRecentAlerts() {
    final alerts = _fraudService.getRecentAlerts();
    if (mounted) {
      setState(() {
        _recentAlerts = alerts.take(5).toList();
      });
    }
  }
  
  /// Show critical fraud alert
  void _showCriticalAlert(FraudAlert alert) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                alert.message,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'VIEW',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationsPage()),
            );
          },
        ),
      ),
    );
  }

  Future<void> _loadUserData() async {
    if (_isFirebaseSupported) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          
          if (userDoc.exists) {
            final data = userDoc.data();
            setState(() {
              _userSurname = data?['surname'] ?? '';
              _userName = _userSurname.isNotEmpty ? _userSurname : (data?['firstName'] ?? 'User');
              _isLoading = false;
            });
            return;
          }
        }
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
    
    // Fallback for unsupported platforms or errors
    setState(() {
      _userName = 'User';
      _isLoading = false;
    });
  }

  void _toggleDrawer() {
    if (_scaffoldKey.currentState!.isDrawerOpen) {
      Navigator.of(context).pop();
    } else {
      _scaffoldKey.currentState!.openDrawer();
    }
  }

  Future<void> _logout() async {
    if (_isFirebaseSupported) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        // Handle logout error
      }
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Welcome, $_userName', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsPage())),
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: _toggleDrawer,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 20),
            _buildQuickStats(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.deepPurpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.deepPurple),
                ),
                const SizedBox(height: 12),
                Text(
                  _userName,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Security Agent',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(Icons.security, 'Security Dashboard', () => Navigator.pop(context)),
                _buildDrawerItem(Icons.mobile_friendly, 'Mobile Money Logs', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionsPage()));
                }),
                _buildDrawerItem(Icons.analytics, 'Fraud Analytics', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsPage()));
                }),
                _buildDrawerItem(Icons.notifications_active, 'Security Alerts', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsPage()));
                }),
                _buildDrawerItem(Icons.assessment, 'Security Reports', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportingPage()));
                }),
                _buildDrawerItem(Icons.admin_panel_settings, 'Security Settings', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
                }),
                const Divider(),
                _buildDrawerItem(Icons.help_outline, 'Help & Support', () => Navigator.pop(context)),
                _buildDrawerItem(Icons.logout, 'Logout', _logout, isLogout: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? Colors.red : Colors.deepPurple),
      title: Text(title, style: TextStyle(color: isLogout ? Colors.red : null)),
      onTap: onTap,
      hoverColor: Colors.deepPurple.withOpacity(0.1),
    );
  }

  Widget _buildWelcomeCard() {
    final hour = DateTime.now().hour;
    String greeting = 'Habari za asubuhi';
    if (hour >= 12 && hour < 17) greeting = 'Habari za mchana';
    if (hour >= 17) greeting = 'Habari za jioni';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.deepPurple, Colors.deepPurpleAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting $_userName!',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mobile Money Security Dashboard',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.security, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('Total Protected: ', style: TextStyle(color: Colors.white70)),
              const Text('TShs 2,450,750', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.verified_user, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              const Text('Fraud Detection: Active', style: TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final blockedCount = _fraudStats['blocked_transactions'] ?? 0;
    final suspiciousCount = _recentAlerts.where((alert) => 
        alert.alertType == FraudAlertType.suspicious).length;
    final totalTransactions = _fraudStats['total_transactions'] ?? 0;
    final safeTransactions = totalTransactions - blockedCount - suspiciousCount;
    
    return Row(
      children: [
        Expanded(child: _buildStatCard(
          'Scams Blocked', 
          blockedCount.toString(), 
          '-23%', 
          Colors.green, 
          Icons.security
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(
          'Suspicious', 
          suspiciousCount.toString(), 
          '+15%', 
          Colors.orange, 
          Icons.warning
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(
          'Safe Trans.', 
          safeTransactions.toString(), 
          '+8%', 
          Colors.blue, 
          Icons.verified_user
        )),
      ],
    );
  }

  Widget _buildStatCard(String title, String amount, String change, Color color, IconData icon) {
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
              Text(change, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(amount, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildActionCard('Report Fraud', Icons.report, Colors.red, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionsPage())))),
            const SizedBox(width: 12),
            Expanded(child: _buildActionCard('Fraud Analytics', Icons.analytics, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsPage())))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildActionCard('Security Report', Icons.assessment, Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportingPage())))),
            const SizedBox(width: 12),
            Expanded(child: _buildActionCard('Settings', Icons.security, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage())))),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Security Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionsPage())),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
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
            children: [
              _buildActivityItem('M-Pesa Scam Blocked', 'TShs 50,000', '2 min ago', Icons.block, Colors.red),
              const Divider(height: 1),
              _buildActivityItem('Airtel Money - Verified', 'TShs 25,000', '1 hour ago', Icons.verified, Colors.green),
              const Divider(height: 1),
              _buildActivityItem('HaloPesa - Suspicious', 'TShs 15,000', '3 hours ago', Icons.warning, Colors.orange),
              const Divider(height: 1),
              _buildActivityItem('Tigo Pesa - Safe Transfer', 'TShs 8,500', 'Today', Icons.check_circle, Colors.blue),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String amount, String time, IconData icon, Color color) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(time, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      trailing: Text(amount, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}
