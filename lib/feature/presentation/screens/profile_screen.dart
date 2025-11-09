import 'package:camp_nest/core/extension/error_extension.dart';
import 'package:camp_nest/feature/presentation/provider/auth_provider.dart';
import 'package:camp_nest/feature/presentation/provider/listing_provider.dart';
import 'package:camp_nest/core/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_screen.dart';
import 'edit_profile_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:camp_nest/core/service/image_upload_service.dart';
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      try {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 85,
                        );
                        if (picked == null) {
                          return;
                        }

                        final file = File(picked.path);
                        final uploader = ImageUploadService();
                        'Uploading profile image...'.showInfo(context);

                        final url = await uploader.uploadImage(
                          file,
                          'profiles',
                        );
                        final currentUser = ref.read(authProvider).user;
                        if (currentUser == null) {
                          return;
                        }

                        final updated = UserModel(
                          id: currentUser.id,
                          name: currentUser.name,
                          email: currentUser.email,
                          profileImage: url,
                          school: currentUser.school,
                          age: currentUser.age,
                          gender: currentUser.gender,
                          phoneNumber: currentUser.phoneNumber,
                          preferences: currentUser.preferences,
                        );

                        await ref
                            .read(authProvider.notifier)
                            .updateUserProfile(updated);
                        final error = ref.read(authProvider).error;
                        if (error != null) {
                          error.showError(context);
                        } else {
                          'Profile image updated successfully'.showSuccess(
                            context,
                          );
                        }
                      } catch (e) {
                        e.showError(context);
                      }
                    },
                    child: CircleAvatar(
                      radius: 90,
                      backgroundColor: Colors.black,
                      backgroundImage: NetworkImage(
                        (user?.profileImage != null &&
                                user!.profileImage!.isNotEmpty)
                            ? user.profileImage!
                            : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user?.name ?? 'User')}&background=0D8ABC&color=fff&size=128',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? 'User',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user?.email ?? '',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.school ?? '',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
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

              final updated = await Navigator.of(context).push<UserModel>(
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(user: currentUser),
                ),
              );

              if (updated != null) {
                // Call API to persist changes, then update local state
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
              // Reset questionnaire state and navigate to questionnaire flow
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
                MaterialPageRoute(builder: (_) => const MatchResultsScreen()),
              );
            },
          ),

          _ProfileMenuItem(
            icon: Icons.home_outlined,
            title: 'My Listings',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyListingsScreen()),
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
            icon: Icons.settings_ethernet,
            title: 'Debug: Test Network & Backend',
            onTap: () async {
              final authService = ref.read(authServiceProvider);
              await authService.debugEnvironmentConfig();
              'Network test completed. Check console for results.'.showInfo(
                context,
              );
            },
          ),
          _ProfileMenuItem(
            icon: Icons.bug_report,
            title: 'Debug: Test Profile Image Persistence',
            onTap: () async {
              final currentUser = ref.read(authProvider).user;
              if (currentUser == null) {
                'No user found'.showError(context);
                return;
              }

              final currentImageUrl = currentUser.profileImage;

              // Test 1: Check local storage
              final storedUser =
                  await ref.read(authServiceProvider).getStoredUser();
              final storedImageUrl = storedUser?.profileImage;

              // Test 2: Check backend
              final backendUser = await ref
                  .read(authServiceProvider)
                  .getUserProfile(currentUser.id);
              final backendImageUrl = backendUser?.profileImage;

              // Test 3: Force refresh current user
              final refreshedUser =
                  await ref.read(authServiceProvider).refreshCurrentUser();
              final refreshedImageUrl = refreshedUser?.profileImage;

              'Profile test completed. Check console for results.'.showInfo(
                context,
              );
            },
          ),

          _ProfileMenuItem(
            icon: Icons.security,
            title: 'Debug: Check Token',
            onTap: () async {
              final listingsService = ref.read(listingsServiceProvider);
              await listingsService.debugToken();
              'Token check completed. Check console for details.'.showInfo(
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
                      content: const Text('Are you sure you want to sign out?'),
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
                                builder: (context) => const AuthScreen(),
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
    );
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
