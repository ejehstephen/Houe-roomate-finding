import 'package:camp_nest/feature/presentation/widget/Media.dart';
import 'package:camp_nest/core/model/room_listing.dart';
import 'package:camp_nest/feature/presentation/screens/roomate_detailed.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RoomCard extends StatelessWidget {
  final RoomListingModel listing;

  const RoomCard({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => RoomDetailScreen(listing: listing),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              SizedBox(
                height: 350,
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child:
                          listing.images.isNotEmpty
                              ? MediaDisplayWidget(
                                mediaUrl: listing.images.first,
                                isThumbnail: true,
                                fit: BoxFit.cover,
                              )
                              : _buildPlaceholder(context),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '₦${NumberFormat('#,###').format(listing.price.toInt())}/yr',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            listing.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (listing.isOwnerVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            size: 26,
                            color: Colors.green,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            listing.location,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[400]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    // const SizedBox(height: 12),
                    // Wrap(
                    //   spacing: 8,
                    //   runSpacing: 8,
                    //   children:
                    //       listing.amenities.take(3).map((amenity) {
                    //         return Container(
                    //           padding: const EdgeInsets.symmetric(
                    //             horizontal: 8,
                    //             vertical: 4,
                    //           ),
                    //           decoration: BoxDecoration(
                    //             color:
                    //                 Theme.of(
                    //                   context,
                    //                 ).colorScheme.surfaceContainerHighest,
                    //             borderRadius: BorderRadius.circular(6),
                    //           ),
                    //           child: Text(
                    //             amenity,
                    //             style: TextStyle(
                    //               fontSize: 12,
                    //               color:
                    //                   Theme.of(
                    //                     context,
                    //                   ).colorScheme.onSurfaceVariant,
                    //             ),
                    //           ),
                    //         );
                    //       }).toList(),
                    // ),
                    // const SizedBox(height: 12),
                    // Row(
                    //   children: [
                    //     Icon(
                    //       listing.gender == 'male'
                    //           ? Icons.male
                    //           : listing.gender == 'female'
                    //           ? Icons.female
                    //           : Icons.people_outline,
                    //       size: 16,
                    //       color: Colors.grey[600],
                    //     ),
                    //     const SizedBox(width: 4),
                    //     Text(
                    //       listing.gender == 'any'
                    //           ? 'Any gender'
                    //           : '${listing.gender[0].toUpperCase()}${listing.gender.substring(1)}',
                    //       style: TextStyle(
                    //         color: Colors.grey[600],
                    //         fontSize: 13,
                    //       ),
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 48,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}
