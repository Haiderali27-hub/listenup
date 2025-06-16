import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../routes/app_routes.dart';
import '../../widgets/custom_text_field.dart';
import 'reset_password_screen.dart';
import 'package:sound_app/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });
    if (_emailController.text.isEmpty) {
      setState(() {
        _emailError = 'Email is required';
      });
      return;
    }
    if (_passwordController.text.isEmpty) {
      setState(() {
        _passwordError = 'Password is required';
      });
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      print('Sending login request...');
      final response = await http.post(
        Uri.parse('http://13.61.5.249:8000/auth/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );
      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await AuthService.saveTokens(
          data['access_token'], 
          data['refresh_token'],
          _emailController.text.trim()
        );
        print('Access token set: ${AuthService.accessToken}');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', AuthService.accessToken!);
        await prefs.setBool('onboarding_complete', true);
        Get.offAllNamed(AppRoutes.home);
        Get.snackbar(
          'Success',
          'Welcome back!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        final error = jsonDecode(response.body);
        print('Login error: ${error['detail'] ?? response.body}');
        Get.snackbar(
          'Login Failed',
          error['detail'] ?? 'Invalid credentials',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Login exception: ${e.toString()}');
      Get.snackbar(
        'Error',
        'An error occurred. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
        child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 36,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sign in to\nListen Up!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D2B55),
                ),
              ),
              const SizedBox(height: 30),
              CustomTextField(
                labelText: 'Email or Phone Number',
                keyboardType: TextInputType.emailAddress,
                errorText: _emailError,
                controller: _emailController,
                  enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                labelText: 'Password',
                isPassword: true,
                errorText: _passwordError,
                controller: _passwordController,
                  enabled: !_isLoading,
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ResetPasswordScreen(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text(
                    'Forgot Password / Login Issue?',
                    style: TextStyle(
                      color: Color(0xFF0D2B55),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: _isLoading ? null : _validateAndSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D2B55),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                    'Sign in',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () {
                    Get.offAllNamed(AppRoutes.signup);
                  },
                    child: Text(
                    "Don't have an account? Sign up",
                    style: TextStyle(
                        color: _isLoading ? Colors.grey : const Color(0xFF0D2B55),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
