import 'package:cached_network_image/cached_network_image.dart';
import 'package:camp_nest/core/model/room_listing.dart';
import 'package:camp_nest/feature/presentation/screens/roomate_detailed.dart';
import 'package:flutter/material.dart';
// import 'dart:io';

class RoomCard extends StatelessWidget {
  final RoomListingModel listing;

  const RoomCard({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => RoomDetailScreen(listing: listing),
            ),
          );
        },
        child: SizedBox(
          height: 300, // Fixed height to prevent overflow
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with CachedNetworkImage
              Container(
                height: 140, // Fixed image height
                width: double.infinity,
                child: _buildImage(),
              ),

              // Content - Fixed height to prevent overflow
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title and price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              listing.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\$${listing.price.toInt()}/mo',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              listing.location,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 2),

                      // Owner
                      Text(
                        'by ${listing.ownerName}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 6),

                      // Amenities - Show only top 2 with smaller chips
                      if (listing.amenities.isNotEmpty)
                        Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children:
                              listing.amenities.take(2).map((amenity) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    amenity,
                                    style: TextStyle(
                                      fontSize: 9,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),

                      const Spacer(), // Push gender preference to bottom
                      // Gender preference
                      Row(
                        children: [
                          Icon(
                            listing.gender == 'male'
                                ? Icons.male
                                : listing.gender == 'female'
                                ? Icons.female
                                : Icons.people,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              listing.gender == 'any'
                                  ? 'Any gender'
                                  : '${listing.gender.toUpperCase()} only',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    // Check if we have valid images
    if (listing.images.isEmpty ||
        listing.images.first.contains('placeholder.svg')) {
      return _buildPlaceholder();
    }

    final imageUrl = listing.images.first;

    // Check if it's a Supabase URL or other network URL
    if (imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder:
            (context, url) => Container(
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            ),
        errorWidget: (context, url, error) {
          print('Image load error: $error for URL: $url'); // Debug log
          return _buildPlaceholder();
        },
      );
    } else {
      // Fallback to placeholder
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home, size: 40, color: Colors.grey),
            SizedBox(height: 4),
            Text(
              'No Image',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
