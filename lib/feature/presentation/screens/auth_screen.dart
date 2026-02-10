import 'package:camp_nest/feature/presentation/provider/auth_provider.dart';
import 'package:camp_nest/feature/presentation/screens/forgot_password_screen.dart';
import 'package:camp_nest/feature/presentation/screens/verify_email_screen.dart';
import 'package:camp_nest/feature/presentation/screens/home_screen.dart';
import 'package:camp_nest/feature/presentation/widgets/fade_in_slide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _schoolController = TextEditingController();
  final _ageController = TextEditingController();
  String _selectedGender = 'male';
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _schoolController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    // Basic school email validation
    if (!value.contains('@') || !value.contains('.com')) {
      return 'Please use your school email (.com)';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_isSignUp) {
        final result = await ref
            .read(authProvider.notifier)
            .signUp(
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
              school: _schoolController.text.trim(),
              age: int.parse(_ageController.text.trim()),
              gender: _selectedGender.trim(),
            );

        if (result['success'] == true) {
          if (mounted) {
            // DEV: Bypass email confirmation dialog
            /*
            if (result['emailConfirmationRequired'] == true) {
              // Show dialog for email confirmation
              showDialog(
                context: context,
                barrierDismissible: false,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Check Your Email 📧'),
                      content: const Text(
                        'We\'ve sent you a confirmation link.\nPlease check your email to verify your account before logging in.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Close dialog

                            if (!mounted) return;

                            // Switch to sign in mode
                            setState(() {
                              _isSignUp = false;
                              _formKey.currentState?.reset();
                            });
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    ),
              );
            } else {
            */
            // Send OTP and navigate to verification screen
            final email = _emailController.text.trim();
            final otpResult = await ref
                .read(authProvider.notifier)
                .sendEmailVerificationOTP(email);

            if (!mounted) return;

            if (otpResult['success'] == true) {
              // Navigate to verification screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VerifyEmailScreen(email: email),
                ),
              );
            } else {
              // Failed to send OTP
              String errorMessage =
                  otpResult['error'] ?? 'Failed to send verification code';

              // Check if it's a rate limit error
              if (errorMessage.toLowerCase().contains(
                    'email rate limit exceeded',
                  ) ||
                  errorMessage.toLowerCase().contains('too many requests') ||
                  errorMessage.toLowerCase().contains('security purposes')) {
                // If rate limited, it likely means we JUST sent a code or user is retrying too fast.
                // We should still let them go to the verification screen to enter the code they (hopefully) received.
                errorMessage = 'Code already sent! Please check your email.';

                // FORCE NAVIGATION even if rate limited
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VerifyEmailScreen(email: email),
                  ),
                );
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorMessage),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
            // }
          }
        } else {
          // Check if error is because user already exists
          if (mounted && result['error'] != null) {
            final error = result['error'].toString();

            // Check if error is about duplicate email/user already exists
            if (error.toLowerCase().contains('already') ||
                error.toLowerCase().contains('duplicate') ||
                error.toLowerCase().contains('exists')) {
              // User already exists (probably unverified) - try to send OTP
              final email = _emailController.text.trim();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account exists! Sending verification code...'),
                  duration: Duration(seconds: 2),
                ),
              );

              final otpResult = await ref
                  .read(authProvider.notifier)
                  .sendEmailVerificationOTP(email);

              if (!mounted) return;

              if (otpResult['success'] == true) {
                // Navigate to verification screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VerifyEmailScreen(email: email),
                  ),
                );
              } else {
                // Failed to send OTP
                String errorMessage =
                    otpResult['error'] ?? 'Failed to send verification code';

                if (errorMessage.toLowerCase().contains(
                      'email rate limit exceeded',
                    ) ||
                    errorMessage.toLowerCase().contains('too many requests') ||
                    errorMessage.toLowerCase().contains('security purposes')) {
                  // If rate limited, force navigation so they can enter the code
                  errorMessage = 'Code already sent! Please check your email.';

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VerifyEmailScreen(email: email),
                    ),
                  );
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(errorMessage),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            } else {
              // Some other error
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          }
        }
      } else {
        final result = await ref
            .read(authProvider.notifier)
            .signIn(
              _emailController.text.trim(),
              _passwordController.text.trim(),
            );

        if (result['success'] == true) {
          // Don't navigate immediately - let the auth state listener handle it
          // This prevents race conditions with token storage
        } else {
          // Show clean error feedback
          if (mounted && result['error'] != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['error'].toString()),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.user != null && !next.isLoading) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo or Graphic
                    FadeInSlide(
                      duration: 0.6,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isSignUp
                                ? Icons.person_add_outlined
                                : Icons.login_rounded,
                            size: 48,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Header Text
                    FadeInSlide(
                      duration: 0.6,
                      delay: 0.1,
                      child: Column(
                        children: [
                          Text(
                            _isSignUp ? 'Create Account' : 'Welcome Back',
                            style: Theme.of(
                              context,
                            ).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isSignUp
                                ? 'Join the community to find your perfect match'
                                : 'Sign in to access your dashboard',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Form Fields
                    if (_isSignUp) ...[
                      FadeInSlide(
                        duration: 0.6,
                        delay: 0.2,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator:
                                  (value) =>
                                      value!.isEmpty
                                          ? 'Please enter your name'
                                          : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _schoolController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'School/University',
                                prefixIcon: Icon(Icons.school_outlined),
                              ),
                              validator:
                                  (value) =>
                                      value!.isEmpty
                                          ? 'Please enter your school'
                                          : null,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _ageController,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
                                      labelText: 'Age',
                                      prefixIcon: Icon(Icons.cake_outlined),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty)
                                        return 'Required';
                                      final age = int.tryParse(value);
                                      if (age == null || age < 16)
                                        return 'Invalid';
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedGender,
                                    decoration: const InputDecoration(
                                      labelText: 'Gender',
                                      prefixIcon: Icon(Icons.people_outline),
                                    ),
                                    items:
                                        ['male', 'female', 'other']
                                            .map(
                                              (g) => DropdownMenuItem(
                                                value: g,
                                                child: Text(
                                                  g[0].toUpperCase() +
                                                      g.substring(1),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                    onChanged:
                                        (v) => setState(
                                          () => _selectedGender = v!,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],

                    FadeInSlide(
                      duration: 0.6,
                      delay: _isSignUp ? 0.3 : 0.2,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            obscureText: true,
                            validator: _validatePassword,
                            onFieldSubmitted: (_) => _submitForm(),
                          ),
                          if (!_isSignUp) ...[
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 0,
                                    vertical: 8,
                                  ),
                                  foregroundColor: Colors.grey[600],
                                ),
                                child: const Text('Forgot Password?'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    FadeInSlide(
                      duration: 0.6,
                      delay: _isSignUp ? 0.4 : 0.3,
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: authState.isLoading ? null : _submitForm,
                          child:
                              authState.isLoading
                                  ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                  : Text(
                                    _isSignUp ? 'Create Account' : 'Sign In',
                                    style: const TextStyle(fontSize: 18),
                                  ),
                        ),
                      ),
                    ),

                    if (authState.error != null) ...[
                      const SizedBox(height: 24),
                      FadeInSlide(
                        duration: 0.4,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.error.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  authState.error!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Toggle Mode
                    FadeInSlide(
                      duration: 0.6,
                      delay: _isSignUp ? 0.5 : 0.4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isSignUp
                                ? 'Already have an account?'
                                : 'Don\'t have an account?',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isSignUp = !_isSignUp;
                                _formKey.currentState?.reset();
                              });
                            },
                            child: Text(
                              _isSignUp ? 'Sign In' : 'Sign Up',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
