import 'package:camp_nest/core/extension/error_extension.dart';
import 'package:camp_nest/feature/presentation/screens/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camp_nest/feature/presentation/provider/auth_provider.dart';
import 'package:camp_nest/feature/presentation/screens/home_screen.dart';
import 'package:pinput/pinput.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  final String userId; // UUID from backend
  final String email;

  const VerificationScreen({
    super.key,
    required this.userId,
    required this.email,
  });

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final _pinController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  Future<void> _verifyCode() async {
    if (_pinController.text.isEmpty) return;

    setState(() => _isLoading = true);
    final success = await ref
        .read(authProvider.notifier)
        .verifyOtp(widget.userId, _pinController.text.trim());

    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 400));
        'Email verified successfully! Please log in.'.showSuccess(context);

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
      }
    } else {
      'Invalid or expired code. Try again.'.showError(context);
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isResending = true);
    final ok = await ref.read(authProvider.notifier).resendOtp(widget.userId);
    setState(() => _isResending = false);

    if (ok) {
      'New code sent to ${widget.email}'.showSuccess(context);
    } else {
      'Failed to resend code'.showError(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Your Email'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Icon(
              Icons.mark_email_unread_outlined,
              size: 90,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Verification Code Sent!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please enter the 6-digit code sent to:',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            Text(
              widget.email,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // PIN INPUT FIELD
            Pinput(
              length: 6,
              controller: _pinController,
              showCursor: true,
              keyboardType: TextInputType.number,
              defaultPinTheme: PinTheme(
                width: 55,
                height: 60,
                textStyle: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // VERIFY BUTTON
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _verifyCode,
              icon:
                  _isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.verified_outlined),
              label: Text(_isLoading ? 'Verifying...' : 'Verify'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),

            const SizedBox(height: 20),

            // RESEND OTP
            TextButton(
              onPressed: _isResending ? null : _resendOtp,
              child: Text(
                _isResending ? 'Resending...' : 'Didn’t get the code? Resend',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),

            const Spacer(),

            Text(
              'The code expires in 10 minutes.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
