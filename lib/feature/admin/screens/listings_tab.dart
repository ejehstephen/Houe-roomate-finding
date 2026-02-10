import 'package:camp_nest/feature/admin/provider/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminListingsTab extends ConsumerStatefulWidget {
  const AdminListingsTab({super.key});

  @override
  ConsumerState<AdminListingsTab> createState() => _AdminListingsTabState();
}

class _AdminListingsTabState extends ConsumerState<AdminListingsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(adminListingsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by title or location...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  _searchQuery.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ),
        Expanded(
          child: listingsAsync.when(
            data: (listings) {
              // Filter listings based on search query
              final filteredListings =
                  _searchQuery.isEmpty
                      ? listings
                      : listings.where((listing) {
                        final titleMatch = listing.title.toLowerCase().contains(
                          _searchQuery,
                        );
                        final locationMatch = listing.location
                            .toLowerCase()
                            .contains(_searchQuery);
                        return titleMatch || locationMatch;
                      }).toList();

              if (filteredListings.isEmpty) {
                return Center(
                  child: Text(
                    _searchQuery.isEmpty
                        ? 'No listings found'
                        : 'No listings match your search',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                );
              }

              return ListView.builder(
                itemCount: filteredListings.length,
                itemBuilder: (context, index) {
                  final listing = filteredListings[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ExpansionTile(
                      leading:
                          listing.images.isNotEmpty
                              ? (listing.images.first.toLowerCase().endsWith(
                                        '.mp4',
                                      ) ||
                                      listing.images.first
                                          .toLowerCase()
                                          .endsWith('.mov') ||
                                      listing.images.first
                                          .toLowerCase()
                                          .endsWith('.avi'))
                                  ? Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.black12,
                                    child: const Icon(
                                      Icons.videocam,
                                      color: Colors.grey,
                                    ),
                                  )
                                  : Image.network(
                                    listing.images.first,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.broken_image);
                                    },
                                  )
                              : const Icon(Icons.home),
                      title: Text(listing.title),
                      subtitle: Text(
                        '${listing.location}\nPrice: N${listing.price}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!listing.isFeatured)
                            IconButton(
                              icon: const Icon(
                                Icons.star_border,
                                color: Colors.orange,
                              ),
                              tooltip: 'Feature Listing',
                              onPressed: () async {
                                await ref
                                    .read(adminServiceProvider)
                                    .featureListing(listing.id);
                                ref.invalidate(adminListingsProvider);
                              },
                            )
                          else
                            const Icon(Icons.star, color: Colors.orange),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Delete Listing',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: const Text('Delete Listing'),
                                      content: Text(
                                        'Are you sure you want to delete "${listing.title}"?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                              );
                              if (confirm == true) {
                                await ref
                                    .read(adminServiceProvider)
                                    .deleteListing(listing.id);
                                ref.invalidate(adminListingsProvider);
                              }
                            },
                          ),
                        ],
                      ),
                      children: [
                        if (listing.ownerPhone != null)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                const Icon(Icons.phone, size: 18),
                                const SizedBox(width: 8),
                                const Text(
                                  'Owner Phone: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Expanded(
                                  child: SelectableText(
                                    listing.ownerPhone!,
                                    style: const TextStyle(color: Colors.blue),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 18),
                                  tooltip: 'Copy phone number',
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: listing.ownerPhone!),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Phone number copied!'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, stack) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }
}
