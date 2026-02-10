import 'package:camp_nest/core/extension/error_extension.dart';
import 'package:camp_nest/feature/presentation/provider/auth_provider.dart';
import 'package:camp_nest/core/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_screen.dart';
import 'edit_profile_screen.dart';

import 'package:camp_nest/feature/presentation/provider/questionnaire_provider.dart';
import 'package:camp_nest/feature/presentation/screens/question_screen.dart';
import 'package:camp_nest/feature/presentation/screens/match_screen.dart';
import 'package:camp_nest/feature/presentation/screens/my_listings_screen.dart';
import 'package:camp_nest/feature/presentation/screens/settings_screen.dart';
import 'package:camp_nest/feature/presentation/widgets/fade_in_slide.dart';
import 'package:camp_nest/feature/admin/screens/admin_dashboard.dart';
import 'package:camp_nest/feature/presentation/provider/verification_provider.dart';
import 'package:camp_nest/feature/presentation/screens/verification_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
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
                padding: const EdgeInsets.all(24),
                children: [
                  // Profile header
                  FadeInSlide(
                    duration: 0.6,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).primaryColor,
                              width: 3,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Theme.of(context).primaryColor,
                            backgroundImage:
                                (user?.profileImage != null &&
                                        user!.profileImage!.isNotEmpty &&
                                        user.profileImage!.startsWith('http'))
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
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    )
                                    : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user?.name ?? 'User',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (user?.school != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              user!.school,
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        // Verification Status
                        Consumer(
                          builder: (context, ref, child) {
                            final simpleStatus = user?.isVerified == true;
                            // more detailed status
                            final verificationAsync = ref.watch(
                              verificationStatusProvider,
                            );

                            return verificationAsync.when(
                              data: (data) {
                                final status =
                                    simpleStatus ? 'approved' : data['status'];
                                final reason = data['rejection_reason'];

                                Color color;
                                IconData icon;
                                String text;
                                VoidCallback? onTap;

                                switch (status) {
                                  case 'approved':
                                    color = Colors.green;
                                    icon = Icons.verified;
                                    text = 'Identity Verified';
                                    onTap = null;

                                    // FORCE REFRESH: If local user says unverified but remote says approved, update local
                                    if (user?.isVerified != true) {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            ref
                                                .read(authProvider.notifier)
                                                .refreshUser();
                                          });
                                    }
                                    break;
                                  case 'pending':
                                    color = Colors.orange;
                                    icon = Icons.access_time_rounded;
                                    text = 'Verification Pending';
                                    onTap = null;
                                    break;
                                  case 'rejected':
                                    color = Colors.red;
                                    icon = Icons.error_outline;
                                    text = 'Verification Rejected';
                                    onTap = () {
                                      // Show reason and allow retry
                                      showDialog(
                                        context: context,
                                        builder:
                                            (context) => AlertDialog(
                                              title: const Text(
                                                'Verification Rejected',
                                              ),
                                              content: Text(
                                                reason ??
                                                    'Your document was rejected. Please try again.',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                      ),
                                                  child: const Text('Cancel'),
                                                ),
                                                FilledButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (_) =>
                                                                const VerificationScreen(),
                                                      ),
                                                    );
                                                  },
                                                  child: const Text('Retry'),
                                                ),
                                              ],
                                            ),
                                      );
                                    };
                                    break;
                                  default:
                                    color = Colors.grey;
                                    icon = Icons.gpp_bad_outlined;
                                    text = 'Unverified Identity';
                                    onTap = () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => const VerificationScreen(),
                                        ),
                                      );
                                    };
                                }

                                return GestureDetector(
                                  onTap: onTap,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: color.withOpacity(0.5),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(icon, size: 16, color: color),
                                        const SizedBox(width: 8),
                                        Text(
                                          text,
                                          style: TextStyle(
                                            color: color,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (onTap != null) ...[
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            size: 10,
                                            color: color,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                              loading:
                                  () => const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                              error: (_, __) => const SizedBox.shrink(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Menu items group
                  FadeInSlide(
                    duration: 0.6,
                    delay: 0.2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 8),
                          child: Text(
                            'General',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: Theme.of(context).hintColor),
                          ),
                        ),
                        if (user?.role == 'admin') ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 8),
                            // child: Text(
                            //   'Administration',
                            //   style: Theme.of(
                            //     context,
                            //   ).textTheme.labelLarge?.copyWith(
                            //     color: Theme.of(context).hintColor,
                            //   ),
                            // ),
                          ),
                          _ProfileMenuItem(
                            icon: Icons.admin_panel_settings,
                            title: 'Admin Dashboard',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AdminDashboard(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
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
                                    (context) =>
                                        EditProfileScreen(user: currentUser),
                              ),
                            );

                            if (updated != null) {
                              final notifier = ref.read(authProvider.notifier);
                              await notifier.updateUserProfile(updated);
                              final error = ref.read(authProvider).error;
                              if (error != null) {
                                error.showError(context);
                              } else {
                                'Profile updated successfully'.showSuccess(
                                  context,
                                );
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
                          icon: Icons.home_work_outlined, // Changed icon
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
                          icon: Icons.favorite_border, // Changed icon
                          title: 'My Matches',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const MatchResultsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  FadeInSlide(
                    duration: 0.6,
                    delay: 0.3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 8),
                          child: Text(
                            'Preferences',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: Theme.of(context).hintColor),
                          ),
                        ),
                        _ProfileMenuItem(
                          icon: Icons.settings_outlined,
                          title: 'Settings',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                        _ProfileMenuItem(
                          icon: Icons.help_outline,
                          title: 'Help & Support',
                          onTap: () {
                            'Help & Support feature coming soon'.showInfo(
                              context,
                            );
                          },
                        ),
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
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Theme.of(
                                                context,
                                              ).colorScheme.error,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () {
                                          ref
                                              .read(authProvider.notifier)
                                              .signOut();
                                          Navigator.of(
                                            context,
                                          ).pushAndRemoveUntil(
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      const AuthScreen(),
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

                  const SizedBox(height: 48),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
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
                            ? Theme.of(
                              context,
                            ).colorScheme.error.withOpacity(0.1)
                            : Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color:
                        isDestructive
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color:
                          isDestructive
                              ? Theme.of(context).colorScheme.error
                              : null,
                    ),
                  ),
                ),
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
}
