import 'package:camp_nest/feature/presentation/provider/auth_provider.dart';
import 'package:camp_nest/feature/presentation/widgets/fade_in_slide.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _showOTPStep = false;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!value.contains('@') || !value.contains('.com')) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validateOTP(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the code';
    }
    if (value.length != 8) {
      return 'Code must be 8 digits';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ref
          .read(authProvider.notifier)
          .sendPasswordResetOTP(_emailController.text.trim());

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _showOTPStep = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Code sent to your email!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to send code'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ref
          .read(authProvider.notifier)
          .verifyOTPAndResetPassword(
            email: _emailController.text.trim(),
            otp: _otpController.text.trim(),
            newPassword: _passwordController.text,
          );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Password reset successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back to login
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to reset password'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeInSlide(
                  duration: 0.6,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_reset_rounded,
                          size: 48,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _showOTPStep
                            ? 'Enter Code & New Password'
                            : 'Forgot Password?',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _showOTPStep
                            ? 'Enter the 8-digit code sent to ${_emailController.text}'
                            : 'Enter your email to receive a reset code',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                if (!_showOTPStep) ...[
                  FadeInSlide(
                    duration: 0.6,
                    delay: 0.2,
                    child: TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeInSlide(
                    duration: 0.6,
                    delay: 0.3,
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sendOTP,
                        child:
                            _isLoading
                                ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Text('Send Reset Code'),
                      ),
                    ),
                  ),
                ] else ...[
                  FadeInSlide(
                    duration: 0.6,
                    delay: 0.2,
                    child: TextFormField(
                      controller: _otpController,
                      decoration: const InputDecoration(
                        labelText: 'Verification Code',
                        hintText: '00000000',
                        prefixIcon: Icon(Icons.pin_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 8,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        letterSpacing: 4,
                        fontWeight: FontWeight.bold,
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: _validateOTP,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeInSlide(
                    duration: 0.6,
                    delay: 0.3,
                    child: TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      obscureText: !_isPasswordVisible,
                      validator: _validatePassword,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeInSlide(
                    duration: 0.6,
                    delay: 0.4,
                    child: TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible;
                            });
                          },
                        ),
                      ),
                      obscureText: !_isConfirmPasswordVisible,
                      validator: _validateConfirmPassword,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeInSlide(
                    duration: 0.6,
                    delay: 0.5,
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _resetPassword,
                        child:
                            _isLoading
                                ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Text('Reset Password'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isLoading ? null : _sendOTP,
                    child: const Text('Didn\'t receive code? Resend'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
