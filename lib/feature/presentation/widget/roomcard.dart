// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:camp_nest/core/service/auth_service.dart';
import 'package:camp_nest/feature/presentation/widget/Media.dart';
// import 'package:flutter_svg/flutter_svg.dart';
import 'package:camp_nest/core/model/room_listing.dart';
import 'package:camp_nest/feature/presentation/screens/roomate_detailed.dart';
import 'package:flutter/material.dart';
// import 'dart:io';
// import 'package:video_player/video_player.dart';
// import 'package:chewie/chewie.dart';

class RoomCard extends StatefulWidget {
  final RoomListingModel listing;

  const RoomCard({super.key, required this.listing});

  @override
  State<RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<RoomCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => RoomDetailScreen(listing: widget.listing),
            ),
          );
        },
        child: SizedBox(
          height: 390, // Fixed height to prevent overflow
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with CachedNetworkImage
              Container(
                height: 250, // Fixed image height
                width: double.infinity,
                child:
                    widget.listing.images.isNotEmpty
                        ? MediaDisplayWidget(
                          mediaUrl: widget.listing.images.first,
                        )
                        : _buildPlaceholder(),
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
                              widget.listing.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\N${widget.listing.price.toInt()}/yr',
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
                              widget.listing.location,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 17,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // // Owner
                      // Text(
                      //   'by ${listing.ownerName}',
                      //   style: TextStyle(color: Colors.grey[500], fontSize: 10),
                      //   maxLines: 1,
                      //   overflow: TextOverflow.ellipsis,
                      // ),

                      // const SizedBox(height: 6),

                      // Amenities - Show only top 2 with smaller chips
                      if (widget.listing.amenities.isNotEmpty)
                        Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children:
                              widget.listing.amenities.take(2).map((amenity) {
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
                                      fontSize: 16,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),

                      // const Spacer(), // Push gender preference to bottom
                      // Gender preference
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Icon(
                            widget.listing.gender == 'male'
                                ? Icons.male
                                : widget.listing.gender == 'female'
                                ? Icons.female
                                : Icons.people,
                            size: 17,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.listing.gender == 'any'
                                  ? 'Any gender'
                                  : '${widget.listing.gender.toUpperCase()} only',
                              style: TextStyle(
                                fontSize: 17,
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

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          size: 50,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}
