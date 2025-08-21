import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'signup.dart';
import 'simple_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Only initialize Firebase on supported platforms (Android, iOS, Web)
  if (kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      // If Firebase options are not configured properly, initialize without options
      await Firebase.initializeApp();
    }
  }
  
  // App initialized successfully
  debugPrint('✅ Mobile Money Security App initialized successfully');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobile Money Security - Tanzania',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        cardTheme: const CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  
  String _email = '';
  String _password = '';
  bool _loading = false;

  // Check if Firebase is supported on current platform
  bool get _isFirebaseSupported => kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _loading = true);

    try {
      if (!_isFirebaseSupported) {
        // For unsupported platforms (like Linux desktop), show a message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Firebase authentication is not supported on this platform. Please run on Android, iOS, or Web.")),
        );
        return;
      }

      final auth = FirebaseAuth.instance;
      UserCredential userCredential = await auth.signInWithEmailAndPassword(
        email: _email.trim(),
        password: _password.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        // Login successful - proceed to home page without email verification
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SimpleHomePage()));
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = "Login failed";
      if (e.code == 'user-not-found') message = "No user found with this email.";
      if (e.code == 'wrong-password') message = "Incorrect password.";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _navigateToSignup() {
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App Logo/Title
                Icon(
                  Icons.security,
                  size: 64,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 16),
                Text(
                  'Mobile Money Security',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  _getTanzanianGreeting(),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tanzania Mobile Money & Airtime Security Platform',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Login Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => v == null || v.isEmpty ? 'Enter email' : null,
                        onSaved: (v) => _email = v ?? '',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (v) => v == null || v.isEmpty ? 'Enter password' : null,
                        onSaved: (v) => _password = v ?? '',
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          child: _loading 
                              ? const CircularProgressIndicator(color: Colors.white) 
                              : const Text('Login', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () async {
                              if (!_isFirebaseSupported) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Password reset is not available on this platform.")),
                                );
                                return;
                              }
                              
                              if (_email.isNotEmpty) {
                                final auth = FirebaseAuth.instance;
                                await auth.sendPasswordResetEmail(email: _email);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Password reset email sent")),
                                );
                              } else {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Enter email first")),
                                );
                              }
                            },
                            child: const Text('Forgot Password?'),
                          ),
                          TextButton(
                            onPressed: _navigateToSignup, 
                            child: const Text('Sign Up'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Supported Services Section (moved to bottom)
                _buildSupportedServicesCard(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build supported services card
  Widget _buildSupportedServicesCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified_user, color: Colors.green[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Supported Services',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Mobile Money Services
            _buildServiceSection(
              context, 
              'Mobile Money Services', 
              Icons.account_balance_wallet,
              Colors.blue,
              [
                {'name': 'M-Pesa (Vodacom)', 'icon': Icons.phone_android, 'color': Colors.green},
                {'name': 'Airtel Money', 'icon': Icons.phone_android, 'color': Colors.red},
                {'name': 'HaloPesa (Halotel)', 'icon': Icons.phone_android, 'color': Colors.purple},
                {'name': 'T-Pesa (TTCL)', 'icon': Icons.phone_android, 'color': Colors.orange},
              ]
            ),
            
            const SizedBox(height: 16),
            
            // Airtime Services
            _buildServiceSection(
              context,
              'Airtime & Bundle Services',
              Icons.wifi,
              Colors.orange,
              [
                {'name': 'Vodacom', 'icon': Icons.signal_cellular_4_bar, 'color': Colors.red},
                {'name': 'Airtel', 'icon': Icons.signal_cellular_4_bar, 'color': Colors.red[300]},
                {'name': 'Halotel', 'icon': Icons.signal_cellular_4_bar, 'color': Colors.purple},
                {'name': 'TTCL', 'icon': Icons.signal_cellular_4_bar, 'color': Colors.orange},
                {'name': 'Mixx by Yas', 'icon': Icons.signal_cellular_4_bar, 'color': Colors.teal},
              ]
            ),
            
            const SizedBox(height: 16),
            
            // Transaction Limits
            _buildTransactionLimits(context),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceSection(
    BuildContext context, 
    String title, 
    IconData titleIcon, 
    Color titleColor,
    List<Map<String, dynamic>> services
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(titleIcon, color: titleColor, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: services.map((service) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (service['color'] as Color).withOpacity(0.1),
              border: Border.all(
                color: (service['color'] as Color).withOpacity(0.3),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  service['icon'] as IconData,
                  size: 14,
                  color: service['color'] as Color,
                ),
                const SizedBox(width: 4),
                Text(
                  service['name'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: service['color'] as Color,
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
      ],
    );
  }

  // Get proper Tanzanian greeting based on East Africa Time (EAT)
  String _getTanzanianGreeting() {
    // Tanzania is UTC+3 (East Africa Time)
    final now = DateTime.now().toUtc().add(const Duration(hours: 3));
    final hour = now.hour;
    
    if (hour >= 6 && hour < 12) {
      return 'Habari za asubuhi! 🌅'; // Morning (6 AM - 12 PM)
    } else if (hour >= 12 && hour < 17) {
      return 'Habari za mchana! ☀️'; // Afternoon (12 PM - 5 PM)  
    } else if (hour >= 17 && hour < 20) {
      return 'Habari za jioni! 🌇'; // Evening (5 PM - 8 PM)
    } else {
      return 'Habari za usiku! 🌙'; // Night (8 PM - 6 AM)
    }
  }

  Widget _buildTransactionLimits(BuildContext context) {
    final limits = [
      {'service': 'M-Pesa', 'min': 'TShs 500', 'max': 'TShs 10,000,000', 'color': Colors.green},
      {'service': 'Airtel Money', 'min': 'TShs 500', 'max': 'TShs 7,000,000', 'color': Colors.red},
      {'service': 'HaloPesa', 'min': 'TShs 1,000', 'max': 'TShs 5,000,000', 'color': Colors.purple},
      {'service': 'T-Pesa', 'min': 'TShs 500', 'max': 'TShs 3,000,000', 'color': Colors.orange},
      {'service': 'Airtime', 'min': 'TShs 500', 'max': 'TShs 500,000', 'color': Colors.blue},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.account_balance, color: Colors.indigo, size: 18),
            const SizedBox(width: 8),
            Text(
              'Transaction Limits (Per Day)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.indigo,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: limits.map((limit) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: limit['color'] as Color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Text(
                      limit['service'] as String,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      limit['min'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      limit['max'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.amber[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.amber[800]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Security monitoring active 24/7 for fraud prevention',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.amber[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
