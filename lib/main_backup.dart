import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'signup.dart';
import 'home.dart';
import 'services/fraud_detection_service.dart';

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
  
  // Initialize Fraud Detection Service
  try {
    await FraudDetectionService().initialize();
    debugPrint('✅ AI-Powered Fraud Detection System initialized successfully');
  } catch (e) {
    debugPrint('❌ Failed to initialize Fraud Detection System: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobile Money Fraud Detection System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
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
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Login', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 24),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v == null || v.isEmpty ? 'Enter email' : null,
                    onSaved: (v) => _email = v ?? '',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (v) => v == null || v.isEmpty ? 'Enter password' : null,
                    onSaved: (v) => _password = v ?? '',
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Login'),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                      TextButton(onPressed: _navigateToSignup, child: const Text('Signup')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
