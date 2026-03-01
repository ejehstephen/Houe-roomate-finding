import 'package:camp_nest/feature/admin/provider/admin_provider.dart';
import 'package:camp_nest/feature/presentation/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminUsersTab extends ConsumerWidget {
  const AdminUsersTab({super.key});

  void _showUserMenu(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
    bool isSuperAdmin,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage:
                          user.profileImage != null
                              ? NetworkImage(user.profileImage!)
                              : null,
                      child:
                          user.profileImage == null
                              ? Text(user.name[0].toUpperCase())
                              : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          user.email,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(),

              // Make / Remove Admin — only visible to super admins
              if (isSuperAdmin && user.role != 'admin')
                ListTile(
                  leading: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.indigo,
                  ),
                  title: const Text('Make Admin'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      await ref.read(adminServiceProvider).makeAdmin(user.id);
                      ref.invalidate(adminUsersProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${user.name} is now an admin.'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                ),
              if (isSuperAdmin && user.role == 'admin')
                ListTile(
                  leading: const Icon(
                    Icons.remove_moderator,
                    color: Colors.orange,
                  ),
                  title: const Text('Remove Admin'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      await ref.read(adminServiceProvider).removeAdmin(user.id);
                      ref.invalidate(adminUsersProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${user.name} is no longer an admin.',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                ),

              // Verify
              if (!user.isVerified)
                ListTile(
                  leading: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                  title: const Text('Verify User'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref.read(adminServiceProvider).verifyUser(user.id);
                    ref.invalidate(adminUsersProvider);
                  },
                ),

              // Ban / Unban
              if (!user.isBanned)
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.red),
                  title: const Text('Ban User'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Ban User'),
                            content: Text(
                              'Are you sure you want to ban ${user.name}?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Ban'),
                              ),
                            ],
                          ),
                    );
                    if (confirm == true) {
                      await ref.read(adminServiceProvider).banUser(user.id);
                      ref.invalidate(adminUsersProvider);
                    }
                  },
                ),
              if (user.isBanned)
                ListTile(
                  leading: const Icon(Icons.lock_open, color: Colors.orange),
                  title: const Text('Unban User'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Unban User'),
                            content: Text(
                              'Are you sure you want to unban ${user.name}?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Unban'),
                              ),
                            ],
                          ),
                    );
                    if (confirm == true) {
                      await ref.read(adminServiceProvider).unbanUser(user.id);
                      ref.invalidate(adminUsersProvider);
                    }
                  },
                ),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);
    final currentUser = ref.watch(authProvider);
    final isSuperAdmin = currentUser.user?.isSuperAdmin ?? false;

    return usersAsync.when(
      data:
          (users) => ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                onTap: () => _showUserMenu(context, ref, user, isSuperAdmin),
                leading: CircleAvatar(
                  backgroundImage:
                      user.profileImage != null
                          ? NetworkImage(user.profileImage!)
                          : null,
                  onBackgroundImageError: (exception, stackTrace) {
                    print('Error loading admin user image: $exception');
                  },
                  child:
                      user.profileImage == null
                          ? Text(user.name[0].toUpperCase())
                          : null,
                ),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(user.name, overflow: TextOverflow.ellipsis),
                    ),
                    if (user.isVerified)
                      const Padding(
                        padding: EdgeInsets.only(left: 4.0),
                        child: Icon(
                          Icons.verified,
                          color: Colors.blue,
                          size: 16,
                        ),
                      ),
                    if (user.role == 'admin')
                      const Padding(
                        padding: EdgeInsets.only(left: 4.0),
                        child: Chip(
                          label: Text('Admin', style: TextStyle(fontSize: 10)),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
                subtitle: Text('${user.email}\nRole: ${user.role}'),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              );
            },
          ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, stack) => Center(child: Text('Error: $e')),
    );
  }
}
