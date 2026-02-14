// import 'dart:io';
import 'package:camp_nest/core/model/room_listing.dart';
import 'package:camp_nest/core/model/user_model.dart';
import 'package:camp_nest/feature/presentation/provider/auth_provider.dart';
import 'package:camp_nest/feature/presentation/provider/listing_provider.dart';
import 'package:camp_nest/feature/presentation/widget/Media.dart';
import 'package:camp_nest/feature/presentation/widgets/fade_in_slide.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoomDetailScreen extends ConsumerStatefulWidget {
  final RoomListingModel listing;

  const RoomDetailScreen({super.key, required this.listing});

  @override
  ConsumerState<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends ConsumerState<RoomDetailScreen> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  UserModel? _listingOwner;
  bool _loadingOwner = true;
  // Create a list of controllers to manage them
  List<ChewieController?> _chewieControllers = [];

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _chewieControllers) {
      controller?.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadListingOwner();
    // Initialize a list of controllers, one for each media item
    _chewieControllers = List.generate(
      widget.listing.images.length,
      (index) => null,
    );
  }

  Future<void> _loadListingOwner() async {
    try {
      // Fetch the listing owner's profile using their ID
      final ownerId = widget.listing.ownerId;
      if (ownerId.isNotEmpty) {
        final data =
            await Supabase.instance.client
                .from('users')
                .select()
                .eq('id', ownerId)
                .single();

        _listingOwner = UserModel.fromJson(data);
      }
    } catch (e) {
      print('Error loading listing owner: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loadingOwner = false;
        });
      }
    }
  }

  Future<void> _contactViaWhatsApp() async {
    final supportNumber =
        await ref.read(listingsProvider.notifier).getSupportNumber();

    final message =
        "Hi CampNest, I'm interested in the listing: ${widget.listing.title} located at ${widget.listing.location} (ID: ${widget.listing.id}). Is it still available?";
    final url =
        "https://wa.me/$supportNumber?text=${Uri.encodeComponent(message)}";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp')),
        );
      }
    }
  }

  void _shareRoom() {
    const shareText = 'Check out this room listing on RoomMatch!';
    Clipboard.setData(const ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Room details copied to clipboard!')),
    );
  }

  void _handlePageChanged(int index) {
    if (_chewieControllers[index] != null) {
      _chewieControllers[_currentImageIndex]?.pause();
      _chewieControllers[index]!.play();
    }

    setState(() {
      _currentImageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: CustomScrollView(
            slivers: [
              // App Bar with Images
              SliverAppBar(
                expandedHeight: 400,
                pinned: true,
                backgroundColor: Theme.of(context).primaryColor,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.black26,
                    child: const BackButton(color: Colors.white),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image carousel
                      if (widget.listing.images.isEmpty)
                        _buildPlaceholder()
                      else
                        PageView.builder(
                          controller: _pageController,
                          onPageChanged: _handlePageChanged,
                          itemCount: widget.listing.images.length,
                          itemBuilder: (context, index) {
                            return MediaDisplayWidget(
                              key: ValueKey(widget.listing.images[index]),
                              mediaUrl: widget.listing.images[index],
                              fit: BoxFit.cover,
                            );
                          },
                        ),

                      // Gradient Overlay
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.2),
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.4),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Image Dot Indicators (Centered)
                      if (widget.listing.images.length > 1)
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children:
                                widget.listing.images.asMap().entries.map((
                                  entry,
                                ) {
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width:
                                        _currentImageIndex == entry.key
                                            ? 24
                                            : 8,
                                    height: 8,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color:
                                          _currentImageIndex == entry.key
                                              ? Theme.of(context).primaryColor
                                              : Colors.white.withOpacity(0.5),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),

                      // Image Limit Counter (Bottom Right)
                      if (widget.listing.images.length > 1)
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_currentImageIndex + 1} / ${widget.listing.images.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                actions: [
                  // Share/Delete buttons
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.black26,
                      child: Builder(
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
                                          'Are you sure? This cannot be undone.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  ctx,
                                                ).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () =>
                                                    Navigator.of(ctx).pop(true),
                                            child: const Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                );

                                if (confirmed == true) {
                                  // Perform delete logic
                                  try {
                                    await ref
                                        .read(listingsProvider.notifier)
                                        .deleteListing(widget.listing.id);
                                    if (mounted) {
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Listing deleted'),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to delete: $e'),
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                              ),
                            );
                          }

                          return IconButton(
                            onPressed: _shareRoom,
                            icon: const Icon(Icons.share, color: Colors.white),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),

              // Content
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  transform: Matrix4.translationValues(0, -20, 0),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Price
                        FadeInSlide(
                          duration: 0.5,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.listing.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              // Owner Verification Status Badge removed
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(
                                        context,
                                      ).primaryColor.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '₦${NumberFormat('#,###').format(widget.listing.price.toInt())}/yr',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Location
                        FadeInSlide(
                          duration: 0.5,
                          delay: 0.1,
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.listing.location,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),

                        // Listing Owner
                        FadeInSlide(
                          duration: 0.5,
                          delay: 0.2,
                          child:
                              _loadingOwner
                                  ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                  : ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      radius: 28,
                                      backgroundColor: Theme.of(
                                        context,
                                      ).primaryColor.withOpacity(0.1),
                                      backgroundImage:
                                          _listingOwner?.profileImage != null &&
                                                  _listingOwner!
                                                      .profileImage!
                                                      .isNotEmpty
                                              ? NetworkImage(
                                                _listingOwner!.profileImage!,
                                              )
                                              : null,
                                      child:
                                          _listingOwner?.profileImage == null ||
                                                  _listingOwner!
                                                      .profileImage!
                                                      .isEmpty
                                              ? Text(
                                                _getUserInitials(
                                                  _listingOwner?.name ??
                                                      widget.listing.ownerName,
                                                ),
                                                style: TextStyle(
                                                  color:
                                                      Theme.of(
                                                        context,
                                                      ).primaryColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                              : null,
                                    ),
                                    title: Text(
                                      _listingOwner?.name ??
                                          widget.listing.ownerName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: const Text('Listing Owner'),
                                    // trailing: IconButton(
                                    //   icon: Container(
                                    //     padding: const EdgeInsets.all(8),
                                    //     decoration: BoxDecoration(
                                    //       color: Theme.of(
                                    //         context,
                                    //       ).primaryColor.withOpacity(0.1),
                                    //       shape: BoxShape.circle,
                                    //     ),
                                    //     child: Icon(
                                    //       Icons.message_outlined,
                                    //       color: Theme.of(context).primaryColor,
                                    //       size: 20,
                                    //     ),
                                    //   ),
                                    //   onPressed: _contactViaWhatsApp,
                                    // ),
                                  ),
                        ),

                        const SizedBox(height: 24),

                        // Key Details Grid
                        FadeInSlide(
                          duration: 0.5,
                          delay: 0.3,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildDetailItem(
                                  context,
                                  Icons.calendar_today_outlined,
                                  'Available',
                                  '${widget.listing.availableFrom.day}/${widget.listing.availableFrom.month}',
                                ),
                                _buildVerticalDivider(),
                                _buildDetailItem(
                                  context,
                                  widget.listing.gender == 'male'
                                      ? Icons.male
                                      : widget.listing.gender == 'female'
                                      ? Icons.female
                                      : Icons.people_outline,
                                  'Gender',
                                  widget.listing.gender == 'any'
                                      ? 'Any'
                                      : widget.listing.gender[0].toUpperCase() +
                                          widget.listing.gender.substring(1),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Description
                        FadeInSlide(
                          duration: 0.5,
                          delay: 0.4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'About this place',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                widget.listing.description,
                                style: TextStyle(
                                  fontSize: 16,
                                  height: 1.6,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Amenities
                        if (widget.listing.amenities.isNotEmpty) ...[
                          FadeInSlide(
                            duration: 0.5,
                            delay: 0.5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Amenities',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children:
                                      widget.listing.amenities.map((amenity) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).scaffoldBackgroundColor,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey.withOpacity(
                                                0.2,
                                              ),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.02,
                                                ),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _getAmenityIcon(amenity),
                                                size: 18,
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).primaryColor,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                amenity,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey[800],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],

                        // House Rules
                        if (widget.listing.rules.isNotEmpty) ...[
                          FadeInSlide(
                            duration: 0.5,
                            delay: 0.6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'House Rules',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    children:
                                        widget.listing.rules.map((rule) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  Icons.check_circle,
                                                  size: 20,
                                                  color:
                                                      Theme.of(
                                                        context,
                                                      ).primaryColor,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    rule,
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      color: Colors.grey[800],
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],

                        const SizedBox(height: 80), // Bottom padding
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // Bottom Action Bar
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            // Report Button
            Expanded(
              child: SizedBox(
                height: 56,
                child: TextButton.icon(
                  onPressed: _showReportDialog,
                  icon: const Icon(Icons.flag_outlined, color: Colors.red),
                  label: const Text(
                    'Report',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Contact Button
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _contactViaWhatsApp,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text(
                    'Contact Us',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    elevation: 4,
                    shadowColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showReportDialog() {
    String selectedReason = 'Scam';
    final TextEditingController detailsController = TextEditingController();
    final List<String> reasons = [
      'Scam',
      'Fake Listing',
      'Inappropriate Content',
      'Price is much higher than market rate',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Report Listing'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Why are you reporting this listing?'),
                    const SizedBox(height: 16),
                    ...reasons.map((reason) {
                      return RadioListTile<String>(
                        title: Text(reason),
                        value: reason,
                        groupValue: selectedReason,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) {
                          setState(() {
                            selectedReason = value!;
                          });
                        },
                      );
                    }),
                    const SizedBox(height: 16),
                    TextField(
                      controller: detailsController,
                      decoration: const InputDecoration(
                        labelText: 'Additional Details (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(ctx);
                    try {
                      await ref
                          .read(listingsProvider.notifier)
                          .reportListing(
                            listingId: widget.listing.id,
                            reason: selectedReason,
                            details: detailsController.text,
                          );

                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Report submitted. Thank you!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Failed to report: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Submit Report',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 40, width: 1, color: Colors.grey.withOpacity(0.2));
  }

  IconData _getAmenityIcon(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'wifi':
        return Icons.wifi;
      case 'laundry':
        return Icons.local_laundry_service_outlined;
      case 'kitchen':
        return Icons.kitchen_outlined;
      case 'parking':
        return Icons.local_parking;
      case 'gym':
        return Icons.fitness_center;
      case 'pool':
        return Icons.pool;
      case 'study room':
        return Icons.menu_book_outlined;
      case 'backyard':
        return Icons.deck_outlined; // deck is close to backyard
      case 'ac':
      case 'air conditioning':
        return Icons.ac_unit;
      case 'tv':
        return Icons.tv;
      default:
        return Icons.check_circle_outline;
    }
  }

  String _getUserInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 64,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}
