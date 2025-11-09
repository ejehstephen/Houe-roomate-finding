import 'package:camp_nest/core/model/room_listing.dart';
import 'package:camp_nest/core/theme/app_theme.dart';
import 'package:camp_nest/feature/presentation/provider/auth_provider.dart';
import 'package:camp_nest/feature/presentation/provider/listing_provider.dart';
import 'package:camp_nest/feature/presentation/widget/Media.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class RoomDetailScreen extends ConsumerStatefulWidget {
  final RoomListingModel listing;

  const RoomDetailScreen({super.key, required this.listing});

  @override
  ConsumerState<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends ConsumerState<RoomDetailScreen> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _contactViaWhatsApp() async {
    final phone = widget.listing.ownerPhone;
    final backendLink = widget.listing.whatsappLink;
    final message = Uri.encodeComponent(
      "Hi! I saw your room listing: ${widget.listing.title}. Can we discuss more details?",
    );

    // Debug
    print('contactViaWhatsApp: backendLink=$backendLink phone=$phone');

    // 1) Try backend-provided link first (it's already formatted/encoded server-side)
    if (backendLink != null && backendLink.isNotEmpty) {
      try {
        final uri = Uri.parse(backendLink);
        print('Trying backend whatsappLink: $uri');
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        print('launchUrl(backendLink) returned: $launched');
        if (launched) return;
      } catch (e) {
        print('Error parsing/launching backendLink: $e');
      }
    }

    // 2) Build candidate phone formats from ownerPhone and try deep link then wa.me
    if (phone != null && phone.isNotEmpty) {
      final cleaned = phone.replaceAll(RegExp(r'\D'), '');
      final candidates = <String>{};
      if (cleaned.isNotEmpty) candidates.add(cleaned);

      // If starts with 0 -> try without leading zeros and with country code 234
      if (cleaned.startsWith('0')) {
        final withoutZero = cleaned.replaceFirst(RegExp(r'^0+'), '');
        if (withoutZero.isNotEmpty) {
          candidates.add(withoutZero);
          candidates.add('234$withoutZero');
        }
      }

      // If short (likely local), try prefixing 234
      if (cleaned.length <= 10 && !cleaned.startsWith('234')) {
        candidates.add('234$cleaned');
      }

      // Also try with + prefix
      final candidatesWithPlus =
          candidates.map((c) => c.startsWith('+') ? c : '+$c').toList();

      for (final cand in [...candidates, ...candidatesWithPlus]) {
        final candDigits = cand.replaceAll(RegExp(r'[^0-9]'), '');
        final schemeUri = Uri.parse(
          'whatsapp://send?phone=$candDigits&text=$message',
        );
        print('Trying whatsapp scheme: $schemeUri');
        try {
          final launched = await launchUrl(
            schemeUri,
            mode: LaunchMode.externalApplication,
          );
          print('launchUrl(whatsapp scheme for $cand) returned: $launched');
          if (launched) return;
        } catch (e) {
          print('whatsapp scheme launch error for $cand: $e');
        }

        final webUri = Uri.parse('https://wa.me/$candDigits?text=$message');
        print('Trying wa.me web link: $webUri');
        try {
          final launched = await launchUrl(
            webUri,
            mode: LaunchMode.externalApplication,
          );
          print('launchUrl(wa.me for $cand) returned: $launched');
          if (launched) return;
        } catch (e) {
          print('wa.me launch error for $cand: $e');
        }
      }
    }

    // 3) Nothing launched — fallback: copy phone to clipboard or inform user
    if (phone != null && phone.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: phone));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'WhatsApp not available. Phone number copied to clipboard.',
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No WhatsApp contact available for this listing.'),
          ),
        );
      }
    }
  }

  void _shareRoom() {
    // In a real app, you'd share the actual room URL
    const shareText = 'Check out this room listing on RoomMatch!';
    Clipboard.setData(const ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Room details copied to clipboard!')),
    );
  }

  // Create a list of controllers to manage them
  List<ChewieController?> _chewieControllers = [];

  @override
  void initState() {
    super.initState();
    // Initialize a list of controllers, one for each media item
    _chewieControllers = List.generate(
      widget.listing.images.length,
      (index) => null,
    );
  }

  void _handlePageChanged(int index) {
    // Pause the video that was just scrolled away
    if (_chewieControllers[_currentImageIndex] != null) {
      _chewieControllers[_currentImageIndex]!.pause();
    }

    // Play the video on the new page, if it's a video
    if (_chewieControllers[index] != null) {
      _chewieControllers[index]!.play();
    }

    setState(() {
      _currentImageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.textPrimary,
      body: CustomScrollView(
        slivers: [
          // App Bar with Images
          SliverAppBar(
            expandedHeight: 450,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Image carousel
                  if (widget.listing.images.isEmpty)
                    _buildPlaceholder(), // Handle empty case directly
                  if (widget.listing.images.isNotEmpty)
                    PageView.builder(
                      controller: _pageController,
                      onPageChanged: _handlePageChanged,
                      itemCount:
                          widget.listing.images.isEmpty
                              ? 1
                              : widget.listing.images.length,
                      itemBuilder: (context, index) {
                        if (widget.listing.images.isEmpty) {
                          return _buildPlaceholder(); // Your placeholder function
                        }

                        // Use the new reusable widget here
                        return MediaDisplayWidget(
                          key: ValueKey(widget.listing.images[index]),
                          mediaUrl: widget.listing.images[index],
                        );
                      },
                    ),

                  // Image indicators
                  if (widget.listing.images.length > 1)
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children:
                            widget.listing.images.asMap().entries.map((entry) {
                              return Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      _currentImageIndex == entry.key
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.4),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              // Delete button - only visible to owner/creator
              Builder(
                builder: (context) {
                  final currentUser = ref.watch(authProvider).user;
                  final isOwner =
                      currentUser != null &&
                      currentUser.id == widget.listing.ownerId;
                  if (isOwner) {
                    return IconButton(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder:
                              (ctx) => AlertDialog(
                                title: const Text('Delete listing'),
                                content: const Text(
                                  'Are you sure you want to delete this listing? This action cannot be undone.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(ctx).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(ctx).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                        );

                        if (confirmed == true) {
                          try {
                            await ref
                                .read(listingsProvider.notifier)
                                .deleteListing(widget.listing.id);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Listing deleted'),
                                ),
                              );
                              Navigator.of(context).pop();
                            }
                          } catch (e) {
                            // Refresh the listings to clear any stale error state and show latest data
                            try {
                              await ref
                                  .read(listingsProvider.notifier)
                                  .loadListings();
                            } catch (_) {}

                            String message = 'Failed to delete listing';
                            if (e.toString().contains('403')) {
                              message =
                                  'You can only delete your own listings.';
                            } else {
                              message = '$message: ${e.toString()}';
                            }

                            if (mounted) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text(message)));
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.delete_forever),
                      color: Colors.redAccent,
                    );
                  }

                  // default: share icon for non-owners
                  return IconButton(
                    onPressed: _shareRoom,
                    icon: const Icon(Icons.share),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black26,
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.listing.title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '\N${widget.listing.price.toInt()}/yr',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Location and Owner
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.listing.location,
                          style: TextStyle(fontSize: 19, color: Colors.white),
                        ),
                      ),
                    ],
                  ),

                  // const SizedBox(height: 8),

                  // Row(
                  //   children: [
                  //     Icon(Icons.person, color: Colors.grey[600], size: 20),
                  //     const SizedBox(width: 8),
                  //     Text(
                  //       'Listed by ${widget.listing.ownerName}',
                  //       style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  //     ),
                  //   ],
                  // ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Available from ${widget.listing.availableFrom.day}/${widget.listing.availableFrom.month}/${widget.listing.availableFrom.year}',
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Description
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.listing.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),

                  const SizedBox(height: 24),

                  // Amenities
                  if (widget.listing.amenities.isNotEmpty) ...[
                    Text(
                      'Amenities',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          widget.listing.amenities.map((amenity) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getAmenityIcon(amenity),
                                    size: 16,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    amenity,
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // House Rules
                  if (widget.listing.rules.isNotEmpty) ...[
                    Text(
                      'House Rules',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...widget.listing.rules.map((rule) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                rule,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],

                  // Gender Preference
                  Text(
                    'Preferred Tenant',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.listing.gender == 'male'
                              ? Icons.male
                              : widget.listing.gender == 'female'
                              ? Icons.female
                              : Icons.people,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.listing.gender == 'any'
                              ? 'Open to any gender'
                              : '${widget.listing.gender.toUpperCase()} preferred',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 90), // Space for bottom buttons
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom action buttons
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.textPrimary,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _shareRoom,
                icon: const Icon(Icons.share),
                label: const Text('Share'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _contactViaWhatsApp,
                icon: const Icon(Icons.chat),
                label: const Text('Contact via WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // WhatsApp green
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAmenityIcon(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'wifi':
        return Icons.wifi;
      case 'laundry':
        return Icons.local_laundry_service;
      case 'kitchen':
        return Icons.kitchen;
      case 'parking':
        return Icons.local_parking;
      case 'gym':
        return Icons.fitness_center;
      case 'pool':
        return Icons.pool;
      case 'study room':
        return Icons.menu_book;
      case 'backyard':
        return Icons.grass;
      default:
        return Icons.check_circle;
    }
  }
}

Widget _buildPlaceholder() {
  return Container(
    color: Colors.grey[200],
    child: Center(
      child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey[400]),
    ),
  );
}
