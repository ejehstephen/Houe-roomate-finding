import 'package:camp_nest/core/model/notification_model.dart';
import 'package:camp_nest/feature/presentation/screens/roomate_detailed.dart';
import 'package:camp_nest/feature/presentation/screens/match_screen.dart';
import 'package:camp_nest/feature/presentation/provider/listing_provider.dart';
import 'package:camp_nest/feature/presentation/provider/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class NotificationDetail extends ConsumerWidget {
  final NotificationModel notification;

  const NotificationDetail({super.key, required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final data = notification.data ?? {};

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Details'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete Notification',
            onPressed: () {
              ref
                  .read(notificationServiceProvider)
                  .deleteNotification(notification.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification deleted')),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getIconColor(
                          theme,
                          notification.type,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _getIcon(notification.type),
                        color: _getIconColor(theme, notification.type),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getTypeLabel(notification.type),
                            style: TextStyle(
                              color: _getIconColor(theme, notification.type),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat(
                              'MMMM d, y • h:mm a',
                            ).format(notification.createdAt),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  notification.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Divider
                Divider(color: Colors.grey[200]),
                const SizedBox(height: 16),

                // Body
                Text(
                  notification.body,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                    color: theme.textTheme.bodyLarge?.color?.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 48),

                // Actions
                if (notification.type == 'listing' &&
                    data.containsKey('listing_id')) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        // Show loading
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder:
                              (c) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                        );

                        try {
                          final listingId = data['listing_id'].toString();
                          print(
                            '🔔 NotificationDetail: Fetching listing $listingId',
                          );

                          final listing = await ref
                              .read(listingsServiceProvider)
                              .getListingById(listingId);

                          print(
                            '🔔 NotificationDetail: Fetch result: ${listing != null ? "Found" : "Null"}',
                          );

                          if (context.mounted) {
                            Navigator.pop(context); // Dismiss loading

                            if (listing != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          RoomDetailScreen(listing: listing),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Listing no longer available'),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context); // Dismiss loading
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.home),
                      label: const Text('View Property'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: theme.primaryColor,
                      ),
                    ),
                  ),
                ],

                if (notification.type == 'match') ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MatchResultsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.favorite),
                      label: const Text('View Match'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.pink,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getIconColor(ThemeData theme, String type) {
    switch (type) {
      case 'listing':
        return theme.primaryColor;
      case 'match':
        return Colors.pink;
      case 'system':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'listing':
        return Icons.home_outlined;
      case 'match':
        return Icons.favorite_outline;
      case 'system':
        return Icons.info_outline;
      default:
        return Icons.notifications_none;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'listing':
        return 'New Property';
      case 'match':
        return 'New Match';
      case 'system':
        return 'System Update';
      default:
        return 'Notification';
    }
  }
}
