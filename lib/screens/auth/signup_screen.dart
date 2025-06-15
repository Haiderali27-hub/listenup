import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/validators.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() async {
    setState(() {
      _nameError = Validators.validateName(_nameController.text);
      _emailError = Validators.validateEmail(_emailController.text);
      _passwordError = Validators.validatePassword(_passwordController.text);
    });

    if (_nameError == null &&
        _emailError == null &&
        _passwordError == null &&
        _agreeToTerms) {
      setState(() {
        _isLoading = true;
      });

      try {
        print('Sending registration request...');
        final response = await http.post(
          Uri.parse('http://13.61.5.249:8000/auth/register/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'fullname': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'password': _passwordController.text,
          }),
        );
        print('Registration response status: ${response.statusCode}');
        print('Registration response body: ${response.body}');
        if (response.statusCode == 201 || response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['access_token'] != null && data['refresh_token'] != null) {
            await AuthService.saveTokens(data['access_token'], data['refresh_token']);
            Get.offAllNamed(AppRoutes.home);
          } else {
            Get.snackbar(
              'Success',
              'Account created successfully!',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white,
              duration: const Duration(seconds: 2),
            );
            Get.offAllNamed(AppRoutes.login);
          }
        } else {
          final error = jsonDecode(response.body);
          print('Registration error: ${error['detail'] ?? response.body}');
          Get.snackbar(
            'Registration Failed',
            error['detail'] ?? 'Could not register',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } catch (e) {
        print('Registration exception: ${e.toString()}');
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
    } else if (!_agreeToTerms) {
      Get.snackbar(
        'Error',
        'Please agree to the Terms and Conditions',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create a new\naccount',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D2B55),
                  ),
                ),
                const SizedBox(height: 30),
                CustomTextField(
                  labelText: 'Full Name',
                  keyboardType: TextInputType.name,
                  errorText: _nameError,
                  controller: _nameController,
                  validator: Validators.validateName,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  labelText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  errorText: _emailError,
                  controller: _emailController,
                  validator: Validators.validateEmail,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  labelText: 'Password',
                  isPassword: true,
                  errorText: _passwordError,
                  controller: _passwordController,
                  validator: Validators.validatePassword,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _agreeToTerms,
                      onChanged: _isLoading
                          ? null
                          : (value) {
                        setState(() {
                          _agreeToTerms = value ?? false;
                        });
                      },
                    ),
                    const Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'By creating an account, you agree to our ',
                          children: [
                            TextSpan(
                              text: 'Term and Conditions',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  text: 'Create account',
                  onPressed: _isLoading ? null : _validateAndSubmit,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () {
                            Get.offAllNamed(AppRoutes.login);
                          },
                    child: Text(
                      'Already have an account? Sign in',
                      style: TextStyle(
                        color: _isLoading ? Colors.grey : const Color(0xFF0D2B55),
                        fontWeight: FontWeight.w500,
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
