import 'dart:ui';
import 'dart:convert'; // Required for jsonEncode/jsonDecode
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http; // Required for API calls
import 'main.dart'; // To access UserAccountProvider

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController(); // For Sign Up
  bool _isLogin = true;
  bool _isLoading = false; // To show a progress indicator during API calls

  void _showVibeSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // --- AUTH LOGIC CONNECTED TO FASTAPI ---
  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    // 1. Basic Validation
    if (email.isEmpty || password.isEmpty) {
      _showVibeSnackBar("Please fill in all fields", Colors.redAccent);
      return;
    }

    if (!_isLogin && name.isEmpty) {
      _showVibeSnackBar("Please enter your name", Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        // --- LOGIN FLOW ---
        final response = await http.post(
          Uri.parse('http://localhost:8000/login'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"email": email, "password": password}),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          _showVibeSnackBar("Welcome back, ${data['username']}!", Colors.green);

          // Update Provider and Navigate
          final authProvider = Provider.of<UserAccountProvider>(
            context,
            listen: false,
          );
          authProvider.login();
        } else {
          final error = jsonDecode(response.body);
          _showVibeSnackBar(
            error['detail'] ?? "Login failed",
            Colors.redAccent,
          );
        }
      } else {
        // --- SIGN UP FLOW ---
        final response = await http.post(
          Uri.parse('http://localhost:8000/signup'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "email": email,
            "password": password,
            "username": name,
          }),
        );

        if (response.statusCode == 200) {
          _showVibeSnackBar("Account created! Please sign in.", Colors.green);
          setState(() => _isLogin = true); // Switch to login view
        } else {
          final error = jsonDecode(response.body);
          _showVibeSnackBar(
            error['detail'] ?? "Sign up failed",
            Colors.redAccent,
          );
        }
      }
    } catch (e) {
      _showVibeSnackBar(
        "Server unreachable. Check if FastAPI is running.",
        Colors.orange,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isWideScreen = screenSize.width > 600;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Background Decor
          Positioned(
            top: -100,
            right: isWideScreen ? 50 : -50,
            child: CircleAvatar(
              radius: isWideScreen ? 200 : 150,
              backgroundColor: Colors.blueAccent.withOpacity(0.15),
            ),
          ),
          Positioned(
            bottom: -50,
            left: isWideScreen ? 50 : -50,
            child: CircleAvatar(
              radius: isWideScreen ? 150 : 100,
              backgroundColor: Colors.purpleAccent.withOpacity(0.1),
            ),
          ),

          // 2. The Form
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: EdgeInsets.all(isWideScreen ? 48 : 32),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isLogin ? "VIBE" : "JOIN VIBE",
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 4,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isLogin
                                    ? "Empowering Silence"
                                    : "Start your journey today",
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 40),

                              if (!_isLogin) ...[
                                _buildTextField(
                                  _nameController,
                                  "Full Name",
                                  Icons.person_outline,
                                ),
                                const SizedBox(height: 20),
                              ],
                              _buildTextField(
                                _emailController,
                                "Email Address",
                                Icons.email_outlined,
                              ),
                              const SizedBox(height: 20),
                              _buildTextField(
                                _passwordController,
                                "Password",
                                Icons.lock_outline,
                                isObscure: true,
                              ),

                              const SizedBox(height: 40),
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    elevation: 10,
                                    shadowColor: Colors.blueAccent.withOpacity(
                                      0.5,
                                    ),
                                  ),
                                  onPressed: _isLoading ? null : _handleAuth,
                                  child: _isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : Text(
                                          _isLogin
                                              ? "Sign In"
                                              : "Create Account",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isLogin = !_isLogin;
                                  });
                                },
                                child: Text(
                                  _isLogin
                                      ? "Don't have an account? Create one"
                                      : "Already have an account? Sign In",
                                  style: const TextStyle(color: Colors.white38),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isObscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.blueAccent, size: 20),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 1),
        ),
      ),
    );
  }
}
