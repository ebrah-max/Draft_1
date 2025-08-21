import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';

class SimpleHomePage extends StatefulWidget {
  const SimpleHomePage({super.key});

  @override
  State<SimpleHomePage> createState() => _SimpleHomePageState();
}

class _SimpleHomePageState extends State<SimpleHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _userName = 'Security Agent';
  bool _isLoading = true;
  
  // Check if Firebase is supported on current platform
  bool get _isFirebaseSupported => kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
              _userName = data?['firstName'] ?? 'Security Agent';
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
      _userName = 'Security Agent';
      _isLoading = false;
    });
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
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
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
                  _showComingSoon('Mobile Money Logs');
                }),
                _buildDrawerItem(Icons.analytics, 'Fraud Analytics', () {
                  Navigator.pop(context);
                  _showComingSoon('Fraud Analytics');
                }),
                _buildDrawerItem(Icons.notifications_active, 'Security Alerts', () {
                  Navigator.pop(context);
                  _showComingSoon('Security Alerts');
                }),
                _buildDrawerItem(Icons.assessment, 'Security Reports', () {
                  Navigator.pop(context);
                  _showComingSoon('Security Reports');
                }),
                _buildDrawerItem(Icons.admin_panel_settings, 'Security Settings', () {
                  Navigator.pop(context);
                  _showComingSoon('Security Settings');
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
    return Row(
      children: [
        Expanded(child: _buildStatCard('Scams Blocked', '15', '-23%', Colors.green, Icons.security)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Suspicious', '3', '+15%', Colors.orange, Icons.warning)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Safe Trans.', '142', '+8%', Colors.blue, Icons.verified_user)),
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
            Expanded(child: _buildActionCard('Report Fraud', Icons.report, Colors.red, () => _showComingSoon('Report Fraud'))),
            const SizedBox(width: 12),
            Expanded(child: _buildActionCard('Fraud Analytics', Icons.analytics, Colors.blue, () => _showComingSoon('Fraud Analytics'))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildActionCard('Security Report', Icons.assessment, Colors.purple, () => _showComingSoon('Security Report'))),
            const SizedBox(width: 12),
            Expanded(child: _buildActionCard('Settings', Icons.settings, Colors.orange, () => _showComingSoon('Settings'))),
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
              onPressed: () => _showComingSoon('View All'),
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
              _buildActivityItem(Icons.security, 'Blocked suspicious transaction', 'TShs 45,000 • M-Pesa', '2 min ago', Colors.green),
              const Divider(height: 1),
              _buildActivityItem(Icons.warning, 'High-risk transaction detected', 'TShs 125,000 • Airtel Money', '5 min ago', Colors.orange),
              const Divider(height: 1),
              _buildActivityItem(Icons.verified_user, 'Transaction verified safe', 'TShs 8,500 • Tigo Pesa', '12 min ago', Colors.blue),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(IconData icon, String title, String subtitle, String time, Color color) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      trailing: Text(time, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon!'),
        backgroundColor: Colors.deepPurple,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
