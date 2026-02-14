import 'package:camp_nest/feature/presentation/provider/theme_provider.dart';
import 'package:camp_nest/feature/presentation/screens/auth_screen.dart';
import 'package:camp_nest/feature/presentation/widgets/fade_in_slide.dart';
import 'package:camp_nest/feature/presentation/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Appearance Section
              FadeInSlide(
                duration: 0.5,
                child: _buildSectionHeader(context, 'Appearance'),
              ),
              const SizedBox(height: 8),
              FadeInSlide(
                duration: 0.5,
                delay: 0.1,
                child: _buildSettingsTile(
                  context,
                  icon: isDark ? Icons.dark_mode : Icons.light_mode,
                  title: 'Dark Mode',
                  trailing: Switch.adaptive(
                    value: isDark,
                    onChanged: (value) {
                      ref
                          .read(themeProvider.notifier)
                          .setThemeMode(
                            value ? ThemeMode.dark : ThemeMode.light,
                          );
                    },
                    activeColor: theme.primaryColor,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Account Section
              FadeInSlide(
                duration: 0.5,
                delay: 0.2,
                child: _buildSectionHeader(context, 'Account'),
              ),
              const SizedBox(height: 8),
              FadeInSlide(
                duration: 0.5,
                delay: 0.3,
                child: _buildSettingsTile(
                  context,
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  onTap: () => _showChangePasswordDialog(context),
                ),
              ),
              const SizedBox(height: 12),
              FadeInSlide(
                duration: 0.5,
                delay: 0.4,
                child: _buildSettingsTile(
                  context,
                  icon: Icons.delete_forever,
                  title: 'Delete Account',
                  isDestructive: true,
                  onTap: () => _showDeleteAccountDialog(context),
                ),
              ),

              const SizedBox(height: 48),

              // App Info
              FadeInSlide(
                duration: 0.5,
                delay: 0.5,
                child: Center(
                  child: Text(
                    'CampNest v1.0.0',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).hintColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        isDestructive
                            ? theme.colorScheme.error.withOpacity(0.1)
                            : theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color:
                        isDestructive
                            ? theme.colorScheme.error
                            : theme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isDestructive ? theme.colorScheme.error : null,
                    ),
                  ),
                ),
                if (trailing != null)
                  trailing
                else if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.grey[400],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    bool _currentVisible = false;
    bool _newVisible = false;
    bool _confirmVisible = false;

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Change Password'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: currentPasswordController,
                        obscureText: !_currentVisible,
                        decoration: InputDecoration(
                          labelText: 'Current Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _currentVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _currentVisible = !_currentVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your current password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: !_newVisible,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _newVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _newVisible = !_newVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: !_confirmVisible,
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _confirmVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _confirmVisible = !_confirmVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value != newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState?.validate() ?? false) {
                        Navigator.pop(ctx);
                        await _changePassword(
                          currentPasswordController.text,
                          newPasswordController.text,
                        );
                      }
                    },
                    child: const Text('Update'),
                  ),
                ],
              );
            },
          ),
    );
  }

  Future<void> _changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final client = Supabase.instance.client;
      final email = client.auth.currentUser?.email;

      if (email == null) {
        throw Exception('No user email found');
      }

      // Verify current password by re-authenticating
      final response = await client.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );

      if (response.user == null) {
        throw Exception('Current password is incorrect');
      }

      // Now update to new password
      await client.auth.updateUser(UserAttributes(password: newPassword));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.message == 'Invalid login credentials'
                  ? 'Current password is incorrect'
                  : 'Failed to update password: ${e.message}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update password: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Account'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: const Text(
              'Are you sure you want to delete your account? This action cannot be undone. All your data, listings, and matches will be permanently removed.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _deleteAccount();
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteAccount() async {
    try {
      await ref.read(authProvider.notifier).deleteAccount();

      if (mounted) {
        // Navigate to auth screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
