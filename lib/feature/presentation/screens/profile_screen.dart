import 'package:camp_nest/core/extension/error_extension.dart';
import 'package:camp_nest/feature/presentation/provider/auth_provider.dart';
import 'package:camp_nest/feature/presentation/provider/listing_provider.dart';
import 'package:camp_nest/core/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_screen.dart';
import 'edit_profile_screen.dart';

import 'package:camp_nest/feature/presentation/provider/questionnaire_provider.dart';
import 'package:camp_nest/feature/presentation/screens/question_screen.dart';
import 'package:camp_nest/feature/presentation/screens/match_screen.dart';
import 'package:camp_nest/feature/presentation/screens/my_listings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth =
              constraints.maxWidth > 800 ? 800.0 : constraints.maxWidth;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Profile header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 90,
                            backgroundColor: Colors.black87,
                            backgroundImage:
                                (user?.profileImage != null &&
                                        user!.profileImage!.isNotEmpty)
                                    ? NetworkImage(user.profileImage!)
                                    : null,
                            child:
                                (user?.profileImage == null ||
                                        user!.profileImage!.isEmpty)
                                    ? Text(
                                      _getUserInitials(
                                        user?.name ?? user?.email ?? 'User',
                                      ),
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    )
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            user?.name ?? 'User',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            user?.email ?? '',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user?.school ?? '',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Menu items
                  _ProfileMenuItem(
                    icon: Icons.person_outline,
                    title: 'Edit Profile',
                    onTap: () async {
                      final currentUser = ref.read(authProvider).user;
                      if (currentUser == null) return;

                      final updated = await Navigator.of(
                        context,
                      ).push<UserModel>(
                        MaterialPageRoute(
                          builder:
                              (context) => EditProfileScreen(user: currentUser),
                        ),
                      );

                      if (updated != null) {
                        final notifier = ref.read(authProvider.notifier);
                        await notifier.updateUserProfile(updated);
                        final error = ref.read(authProvider).error;
                        if (error != null) {
                          error.showError(context);
                        } else {
                          'Profile updated successfully'.showSuccess(context);
                        }
                      }
                    },
                  ),
                  _ProfileMenuItem(
                    icon: Icons.quiz_outlined,
                    title: 'Retake Compatibility Quiz',
                    onTap: () async {
                      await ref
                          .read(questionnaireProvider.notifier)
                          .retakeQuestionnaire();
                      if (context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const QuestionnaireScreen(),
                          ),
                        );
                      }
                    },
                  ),
                  _ProfileMenuItem(
                    icon: Icons.favorite_outline,
                    title: 'My Matches',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MatchResultsScreen(),
                        ),
                      );
                    },
                  ),
                  _ProfileMenuItem(
                    icon: Icons.home_outlined,
                    title: 'My Listings',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MyListingsScreen(),
                        ),
                      );
                    },
                  ),
                  _ProfileMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      'Settings feature coming soon'.showInfo(context);
                    },
                  ),
                  _ProfileMenuItem(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () {
                      'Help & Support feature coming soon'.showInfo(context);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Debug buttons
                  _ProfileMenuItem(
                    icon: Icons.logout,
                    title: 'Sign Out',
                    isDestructive: true,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Sign Out'),
                              content: const Text(
                                'Are you sure you want to sign out?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    ref.read(authProvider.notifier).signOut();
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder:
                                            (context) => const AuthScreen(),
                                      ),
                                      (route) => false,
                                    );
                                  },
                                  child: const Text('Sign Out'),
                                ),
                              ],
                            ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Helper method to extract initials from user name or email
  String _getUserInitials(String input) {
    if (input.isEmpty) return 'U';

    // Split by spaces for names, or by @ for emails
    final parts =
        input.split(RegExp(r'[\s@]')).where((p) => p.isNotEmpty).toList();

    if (parts.length == 1) {
      // Single word - take first letter
      return parts[0].substring(0, 1).toUpperCase();
    } else {
      // Multiple words - take first letter of first two words
      return (parts[0].substring(0, 1) + parts[1].substring(0, 1))
          .toUpperCase();
    }
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: isDestructive ? Colors.red : null),
        title: Text(
          title,
          style: TextStyle(color: isDestructive ? Colors.red : null),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
