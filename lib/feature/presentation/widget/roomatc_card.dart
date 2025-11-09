import 'package:camp_nest/core/model/roomate_matching.dart';
import 'package:flutter/material.dart';

class RoommateCard extends StatelessWidget {
  final RoommateMatchModel match;
  final VoidCallback onChatPressed;
  final String? avatarOverrideUrl;

  const RoommateCard({
    super.key,
    required this.match,
    required this.onChatPressed,
    this.avatarOverrideUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header with profile and compatibility
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.transparent,
                  backgroundImage: _resolveAvatarImage(),
                  child: _resolveAvatarChild(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${match.age} • ${match.school}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Budget: \$${match.budget.toInt()}/month',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getCompatibilityColor(match.compatibilityScore),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${match.compatibilityScore}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Match',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Common interests
            if (match.commonInterests.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Common Interests',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children:
                    match.commonInterests.map((interest) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          interest,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Preferences
            if (match.preferences.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Lifestyle',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...match.preferences.entries.take(3).map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        _getPreferenceIcon(entry.key),
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_getPreferenceLabel(entry.key)}: ${entry.value}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            // Chat button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onChatPressed,
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Start Chat'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider<Object>? _resolveAvatarImage() {
    final url = (avatarOverrideUrl != null && avatarOverrideUrl!.trim().isNotEmpty)
        ? avatarOverrideUrl!
        : match.profileImage;
    if (url.trim().isEmpty) return null;
    // Normalize relative URLs if your backend returns paths
    if (url.startsWith('/')) {
      // Fallback to a relative path; app should prefix with base if needed at fetch time
      return NetworkImage(url);
    }
    return NetworkImage(url);
  }

  Widget? _resolveAvatarChild() {
    final hasImage = (avatarOverrideUrl != null && avatarOverrideUrl!.trim().isNotEmpty) ||
        match.profileImage.trim().isNotEmpty;
    if (hasImage) return null;
    final initial = match.name.isNotEmpty ? match.name.substring(0, 1).toUpperCase() : 'U';
    return Text(initial, style: const TextStyle(fontSize: 18));
  }

  Color _getCompatibilityColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 80) return Colors.orange;
    return Colors.red;
  }

  IconData _getPreferenceIcon(String key) {
    switch (key) {
      case 'cleanliness':
        return Icons.cleaning_services_outlined;
      case 'socialLevel':
        return Icons.people_outline;
      case 'sleepSchedule':
        return Icons.bedtime_outlined;
      case 'smoking':
        return Icons.smoke_free_outlined;
      default:
        return Icons.info_outline;
    }
  }

  String _getPreferenceLabel(String key) {
    switch (key) {
      case 'cleanliness':
        return 'Cleanliness';
      case 'socialLevel':
        return 'Social Level';
      case 'sleepSchedule':
        return 'Sleep Schedule';
      case 'smoking':
        return 'Smoking';
      default:
        return key;
    }
  }
}
