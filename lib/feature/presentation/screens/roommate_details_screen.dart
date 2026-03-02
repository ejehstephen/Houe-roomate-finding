import 'package:camp_nest/core/model/roomate_matching.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class RoommateDetailsScreen extends StatelessWidget {
  final RoommateMatchModel match;
  final String? avatarOverrideUrl;

  const RoommateDetailsScreen({
    super.key,
    required this.match,
    this.avatarOverrideUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Image
                SizedBox(
                  height: 400,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _resolveProfileImage(context),
                      // Gradient to make text readable
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 150,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.8),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Name and basic info
                      Positioned(
                        bottom: 24,
                        left: 24,
                        right: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              match.name,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${match.age} years old • ${match.school}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Compatibility Score
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _getCompatibilityColor(
                            match.compatibilityScore,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _getCompatibilityColor(
                              match.compatibilityScore,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Match Compatibility',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${match.compatibilityScore}%',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _getCompatibilityColor(
                                  match.compatibilityScore,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Common Interests
                      if (match.commonInterests.isNotEmpty) ...[
                        Text(
                          'Common Interests',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              match.commonInterests.map((interest) {
                                return Chip(
                                  label: Text(interest),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.1),
                                  labelStyle: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  side: BorderSide.none,
                                );
                              }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Lifestyle Preferences
                      if (match.preferences.isNotEmpty) ...[
                        Text(
                          'Lifestyle & Habits',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...match.preferences.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getPreferenceIcon(entry.key),
                                    color: Colors.grey[700],
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getPreferenceLabel(entry.key),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        entry.value,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(
                          height: 80,
                        ), // Padding for the floating button
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: FloatingActionButton.extended(
              onPressed: () => _contactViaWhatsApp(context),
              backgroundColor: const Color(0xFF25D366), // WhatsApp Green
              elevation: 4,
              icon: const Icon(Icons.chat, color: Colors.white),
              label: const Text(
                'Contact via WhatsApp',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _resolveProfileImage(BuildContext context) {
    final url =
        (avatarOverrideUrl != null && avatarOverrideUrl!.trim().isNotEmpty)
            ? avatarOverrideUrl!
            : match.profileImage;

    final hasValidImage =
        url.trim().isNotEmpty &&
        (url.startsWith('http://') ||
            url.startsWith('https://') ||
            url.startsWith('/'));

    if (hasValidImage) {
      if (url.startsWith('http://') ||
          url.startsWith('https://') ||
          url.startsWith('/')) {
        return CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          memCacheWidth: 600,
          maxWidthDiskCache: 600,
          errorWidget: (context, url, error) => _buildFallbackInitial(),
        );
      }
    }

    return _buildFallbackInitial();
  }

  Widget _buildFallbackInitial() {
    final initial =
        match.name.isNotEmpty ? match.name.substring(0, 1).toUpperCase() : 'U';
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 100,
            fontWeight: FontWeight.bold,
            color: Colors.grey[500],
          ),
        ),
      ),
    );
  }

  Color _getCompatibilityColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
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

  Future<void> _contactViaWhatsApp(BuildContext context) async {
    final phone = match.phoneNumber;

    if (phone == null || phone.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This user hasn\'t added a phone number yet'),
          ),
        );
      }
      return;
    }

    final message = Uri.encodeComponent(
      "Hi ${match.name}! I found you through CampsNest and would like to discuss potential roommate arrangements.",
    );

    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    final candidates = <String>{};
    if (cleaned.isNotEmpty) candidates.add(cleaned);

    if (cleaned.startsWith('0')) {
      final withoutZero = cleaned.replaceFirst(RegExp(r'^0+'), '');
      if (withoutZero.isNotEmpty) {
        candidates.add(withoutZero);
        candidates.add('234$withoutZero');
      }
    }

    if (cleaned.length <= 10 && !cleaned.startsWith('234')) {
      candidates.add('234$cleaned');
    }

    final candidatesWithPlus =
        candidates.map((c) => c.startsWith('+') ? c : '+$c').toList();
    bool launched = false;

    for (final cand in [...candidates, ...candidatesWithPlus]) {
      final candDigits = cand.replaceAll(RegExp(r'[^0-9]'), '');
      final schemes = [
        Uri.parse('whatsapp://send?phone=$candDigits&text=$message'),
        Uri.parse('https://wa.me/$candDigits?text=$message'),
      ];

      for (final uri in schemes) {
        try {
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            launched = true;
            return;
          }
        } catch (e) {
          debugPrint('Launch error for $cand: $e');
        }
      }
    }

    if (!launched) {
      await Clipboard.setData(ClipboardData(text: phone));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'WhatsApp not available. Phone number copied to clipboard.',
            ),
          ),
        );
      }
    }
  }
}
