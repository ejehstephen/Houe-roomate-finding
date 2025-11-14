import 'package:camp_nest/core/model/roomate_matching.dart';
import 'package:camp_nest/feature/presentation/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class RoommateCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header with profile and compatibility
            Row(
              children: [
                CircleAvatar(
                  radius: 50,
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

            // WhatsApp contact button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await _contactViaWhatsApp(context, ref);
                },
                icon: const Icon(Icons.chat, color: Colors.white, size: 16),
                label: const Text('Contact via WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider<Object>? _resolveAvatarImage() {
    final url =
        (avatarOverrideUrl != null && avatarOverrideUrl!.trim().isNotEmpty)
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
    final hasImage =
        (avatarOverrideUrl != null && avatarOverrideUrl!.trim().isNotEmpty) ||
        match.profileImage.trim().isNotEmpty;
    if (hasImage) return null;
    final initial =
        match.name.isNotEmpty ? match.name.substring(0, 1).toUpperCase() : 'U';
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

  Future<void> _contactViaWhatsApp(BuildContext context, WidgetRef ref) async {
    if (match.phoneNumber == null || match.phoneNumber!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This user hasn\'t added a phone number yet'),
        ),
      );
      return;
    }

    // Sanitize and normalize matched user's phone number
    String phoneNumber = match.phoneNumber!;

    // Add +234 prefix if not present
    if (!phoneNumber.startsWith('+234') && !phoneNumber.startsWith('234')) {
      if (phoneNumber.startsWith('0')) {
        phoneNumber = '+234${phoneNumber.substring(1)}';
      } else {
        phoneNumber = '+234$phoneNumber';
      }
    }

    // Sanitize phone number
    final sanitizedPhone = phoneNumber.replaceAll(RegExp(r'[\s\-()]+'), '');
    final normalizedPhone =
        sanitizedPhone.startsWith('+')
            ? sanitizedPhone.substring(1)
            : sanitizedPhone;

    // Create WhatsApp URL
    final whatsappUrl =
        'https://wa.me/$normalizedPhone?text=${Uri.encodeComponent('Hi ${match.name}! I found you through CampNest and would like to discuss potential roommate arrangements.')}';

    // Launch WhatsApp
    try {
      final uri = Uri.parse(whatsappUrl);
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to open WhatsApp. Please make sure WhatsApp is installed.',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open WhatsApp. Please make sure WhatsApp is installed.',
          ),
        ),
      );
    }
  }
}
