import 'package:camp_nest/feature/admin/provider/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminUsersTab extends ConsumerWidget {
  const AdminUsersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);

    return usersAsync.when(
      data:
          (users) => ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      user.profileImage != null
                          ? NetworkImage(user.profileImage!)
                          : null,
                  child:
                      user.profileImage == null
                          ? Text(user.name[0].toUpperCase())
                          : null,
                ),
                title: Row(
                  children: [
                    Text(user.name),
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!user.isVerified)
                      IconButton(
                        icon: const Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                        ),
                        tooltip: 'Verify User',
                        onPressed: () async {
                          await ref
                              .read(adminServiceProvider)
                              .verifyUser(user.id);
                          ref.invalidate(adminUsersProvider);
                        },
                      ),
                    if (!user.isBanned)
                      IconButton(
                        icon: const Icon(Icons.block, color: Colors.red),
                        tooltip: 'Ban User',
                        onPressed: () async {
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
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                      child: const Text('Ban'),
                                    ),
                                  ],
                                ),
                          );

                          if (confirm == true) {
                            await ref
                                .read(adminServiceProvider)
                                .banUser(user.id);
                            ref.invalidate(adminUsersProvider);
                          }
                        },
                      ),
                    if (user.isBanned)
                      const Text(
                        'BANNED',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, stack) => Center(child: Text('Error: $e')),
    );
  }
}
