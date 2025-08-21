import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String _surname = '';
  String _firstName = '';
  String _middleName = '';
  String _phone = '';
  String _email = '';
  String _password = '';
  bool _loading = false;

  // Check if Firebase is supported on current platform
  bool get _isFirebaseSupported => kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> _signup() async {
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
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: _email.trim(),
        password: _password.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        // Save user info in Firestore including password
        await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
          "surname": _surname,
          "firstName": _firstName,
          "middleName": _middleName,
          "phone": _phone,
          "email": _email,
          "password": _password, // <-- Added password field
          "signupDate": DateTime.now(),
          "emailVerified": user.emailVerified,
        });

        try {
          await user.sendEmailVerification();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Signup successful! Verification email sent to $_email. Please check your inbox and spam folder."),
              duration: const Duration(seconds: 5),
            ),
          );
        } catch (emailError) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Signup successful but failed to send verification email: $emailError"),
              duration: const Duration(seconds: 5),
            ),
          );
        }

        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup failed: ${e.message}")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.deepPurple, size: 32),
                onPressed: () {
                  if (mounted) Navigator.pop(context);
                },
              ),
            ),
            Center(
              child: SingleChildScrollView(
                child: Container(
                  width: 350,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6)),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Signup', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 24),
                        TextFormField(
                          decoration: const InputDecoration(labelText: "Surname"),
                          validator: (v) => v == null || v.isEmpty ? "Enter surname" : null,
                          onSaved: (v) => _surname = v!.trim(),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: const InputDecoration(labelText: "First Name"),
                          validator: (v) => v == null || v.isEmpty ? "Enter first name" : null,
                          onSaved: (v) => _firstName = v!.trim(),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: const InputDecoration(labelText: "Middle Name"),
                          onSaved: (v) => _middleName = v?.trim() ?? '',
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: const InputDecoration(labelText: "Phone Number"),
                          keyboardType: TextInputType.phone,
                          validator: (v) => v == null || v.isEmpty ? "Enter phone" : null,
                          onSaved: (v) => _phone = v!.trim(),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: const InputDecoration(labelText: "Email"),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return "Enter email";
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return "Enter valid email";
                            return null;
                          },
                          onSaved: (v) => _email = v!.trim(),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(labelText: "Password"),
                          obscureText: true,
                          validator: (v) => v == null || v.length < 6 ? "Password must be >= 6 chars" : null,
                          onSaved: (v) => _password = v!.trim(),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: const InputDecoration(labelText: "Confirm Password"),
                          obscureText: true,
                          validator: (v) {
                            if (v == null || v.isEmpty) return "Confirm password";
                            if (v != _passwordController.text) return "Passwords do not match";
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _signup,
                            child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text("Signup"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
