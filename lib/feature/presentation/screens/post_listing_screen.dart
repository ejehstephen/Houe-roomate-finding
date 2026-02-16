import 'package:camp_nest/core/extension/error_extension.dart';
import 'package:camp_nest/core/model/room_listing.dart';
import 'package:camp_nest/core/service/image_upload_service.dart';
import 'package:camp_nest/feature/presentation/provider/listing_provider.dart';
import 'package:camp_nest/feature/presentation/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:camp_nest/feature/presentation/widget/Media.dart';
import 'package:camp_nest/feature/presentation/widgets/fade_in_slide.dart';
import 'package:camp_nest/feature/presentation/screens/verification_screen.dart';

class PostListingScreen extends ConsumerStatefulWidget {
  const PostListingScreen({super.key});

  @override
  ConsumerState<PostListingScreen> createState() => _PostListingScreenState();
}

class _PostListingScreenState extends ConsumerState<PostListingScreen> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _ownerPhoneController = TextEditingController();

  String _selectedGender = 'any';
  final List<String> _selectedAmenities = [];
  final List<String> _rules = [];
  List<File> _selectedImages = [];
  // For web: hold picked bytes/filenames
  List<Uint8List> _selectedImageBytes = [];
  List<String> _selectedFilenames = [];
  final _ruleController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final ImageUploadService _imageUploadService = ImageUploadService();

  final List<String> _availableAmenities = [
    'Kitchen',
    'Toilet',
    'Light',
    'Water',
    'Backyard',
  ];

  @override
  void initState() {
    super.initState();
    _testStorageConnection();
  }

  Future<void> _testStorageConnection() async {
    final isConnected = await _imageUploadService.testStorageConnection();
    if (!isConnected) {
      'Warning: Storage connection issue detected'.showWarning(context);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _ruleController.dispose();
    _ownerPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      // Use image_picker for both web and mobile
      final List<XFile> picked = await _picker.pickMultipleMedia();
      if (picked.isEmpty) return;

      final limited = picked.take(5 - _selectedImages.length).toList();
      if (kIsWeb) {
        // Store bytes and names for web
        for (final x in limited) {
          if (_selectedImageBytes.length >= 5) break;
          final b = await x.readAsBytes();
          setState(() {
            _selectedImageBytes.add(b);
            _selectedFilenames.add(x.name);
          });
        }
      } else {
        setState(() {
          if (_selectedImages.length < 5) {
            _selectedImages.addAll(limited.map((x) => File(x.path)));
          }
        });
      }
    } catch (e) {
      e.showError(context, duration: const Duration(seconds: 4));
    }
  }

  Future<void> _takePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );
      if (image == null) return;

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() {
          if (_selectedImageBytes.length < 5) {
            _selectedImageBytes.add(bytes);
            _selectedFilenames.add(image.name);
          }
        });
      } else {
        final file = File(image.path);
        setState(() {
          if (_selectedImages.length < 5) {
            _selectedImages.add(file);
          }
        });
      }
    } catch (e) {
      // Handle error
      print('Error taking picture: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      if (kIsWeb) {
        _selectedImageBytes.removeAt(index);
        _selectedFilenames.removeAt(index);
      } else {
        _selectedImages.removeAt(index);
      }
    });
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Add Photos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          // photos & videos
                          await _pickImages();
                        },
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Photos & Videos'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _takePicture();
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _submitListing() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const AlertDialog(
                content: Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text('Uploading images and posting listing...'),
                    ),
                  ],
                ),
              ),
        );

        List<String> imageUrls = [];

        // Upload images if any are selected
        if (kIsWeb && _selectedImageBytes.isNotEmpty) {
          print(
            'Starting web image upload for ${_selectedImageBytes.length} images',
          );
          imageUrls = await _imageUploadService.uploadMultipleBytes(
            _selectedImageBytes,
            _selectedFilenames,
            'listings',
          );
          print('Upload completed. URLs: $imageUrls');
          for (var url in imageUrls) {
            print('Uploaded image public URL: $url');
          }
        } else if (_selectedImages.isNotEmpty) {
          print('Starting image upload for  ${_selectedImages.length} images');
          imageUrls = await _imageUploadService.uploadMultipleImages(
            _selectedImages,
            'listings',
          );
          print('Upload completed. URLs: $imageUrls');
          for (var url in imageUrls) {
            print('Uploaded image public URL: $url');
          }
        }

        print('Image URLs to be stored in RoomListingModel: $imageUrls');

        final user = ref.read(authProvider).user;
        if (user == null || user.school.isEmpty) {
          throw Exception(
            'User school information is missing. Please update your profile.',
          );
        }

        final listing = RoomListingModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text,
          description: _descriptionController.text,
          price: double.parse(_priceController.text),
          location: _locationController.text,
          images: imageUrls,
          ownerId: user.id, // Use actual user ID
          ownerName: user.name, // Use actual user name
          ownerPhone:
              _ownerPhoneController.text.isNotEmpty
                  ? _ownerPhoneController.text
                  : user.phoneNumber, // Fallback to profile phone
          amenities: _selectedAmenities,
          rules: _rules,
          gender: _selectedGender,
          availableFrom: DateTime.now().add(const Duration(days: 7)),
          school: user.school,
          isOwnerVerified: user.isVerified,
        );

        print('Creating listing with images: ${listing.images}');
        await ref.read(listingsProvider.notifier).addListing(listing);

        // Close loading dialog
        if (mounted) Navigator.of(context).pop();

        // Show success message and pop the screen
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Listing posted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        print('Submit listing error: $e');
        // Close loading dialog if it's open
        if (mounted) Navigator.of(context).pop();

        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to post listing: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  bool _isVideo(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post a Listing')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Trust Banner
                Consumer(
                  builder: (context, ref, _) {
                    final user = ref.watch(authProvider).user;
                    if (user == null || user.isVerified) {
                      return const SizedBox.shrink();
                    }
                    return FadeInSlide(
                      duration: 0.5,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified_user_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Get Verified for Trust!',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Verified listings get 3x more views and trust.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const VerificationScreen(),
                                  ),
                                );
                              },
                              child: const Text('Verify'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Image picker
                GestureDetector(
                  onTap: _showImagePicker,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child:
                        (!kIsWeb && _selectedImages.isEmpty) ||
                                (kIsWeb && _selectedImageBytes.isEmpty)
                            ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Tap to Add Photos',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                Text(
                                  '(Up to 5 images)',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            )
                            : Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child:
                                      kIsWeb
                                          ? _isVideo(_selectedFilenames.first)
                                              ? Container(
                                                color: Colors.black,
                                                height: 200,
                                                width: double.infinity,
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.play_circle_outline,
                                                    color: Colors.white,
                                                    size: 64,
                                                  ),
                                                ),
                                              )
                                              : Image.memory(
                                                _selectedImageBytes.first,
                                                width: double.infinity,
                                                height: 200,
                                                fit: BoxFit.cover,
                                              )
                                          : MediaDisplayWidget(
                                            file: _selectedImages.first,
                                            isThumbnail: true,
                                            fit: BoxFit.cover,
                                          ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${(kIsWeb ? _selectedImageBytes.length : _selectedImages.length)} file${(kIsWeb ? _selectedImageBytes.length : _selectedImages.length) > 1 ? 's' : ''}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                  ),
                ),

                // Show selected images
                if ((!kIsWeb && _selectedImages.isNotEmpty) ||
                    (kIsWeb && _selectedImageBytes.isNotEmpty)) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount:
                          kIsWeb
                              ? _selectedImageBytes.length
                              : _selectedImages.length,
                      itemBuilder: (context, index) {
                        final isVideo =
                            kIsWeb
                                ? _isVideo(_selectedFilenames[index])
                                : _isVideo(_selectedImages[index].path);
                        return Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child:
                                    kIsWeb
                                        ? isVideo
                                            ? Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.black,
                                              child: const Center(
                                                child: Icon(
                                                  Icons.videocam,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            )
                                            : Image.memory(
                                              _selectedImageBytes[index],
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                            )
                                        : MediaDisplayWidget(
                                          file: _selectedImages[index],
                                          isThumbnail: true,
                                          fit: BoxFit.cover,
                                        ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g., Cozy Studio Near Campus',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe your room/apartment...',
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Price per month',
                          prefixText: '\N',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a price';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          hintText: 'e.g., Downtown',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a location';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Owner phone
                TextFormField(
                  controller: _ownerPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'whatsapp phone ',
                    hintText: '+234',
                  ),
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 24),

                const Text(
                  'Gender Preference',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children:
                      ['any', 'male', 'female'].map((gender) {
                        return ChoiceChip(
                          label: Text(
                            gender == 'any' ? 'Any' : gender.toUpperCase(),
                          ),
                          selected: _selectedGender == gender,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedGender = gender;
                              });
                            }
                          },
                        );
                      }).toList(),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Amenities',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      _availableAmenities.map((amenity) {
                        return FilterChip(
                          label: Text(amenity),
                          selected: _selectedAmenities.contains(amenity),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedAmenities.add(amenity);
                              } else {
                                _selectedAmenities.remove(amenity);
                              }
                            });
                          },
                        );
                      }).toList(),
                ),

                // const SizedBox(height: ),
                const Text(
                  'House Rules',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ruleController,
                        decoration: const InputDecoration(
                          hintText: 'Add a rule...',
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (_ruleController.text.isNotEmpty) {
                          setState(() {
                            _rules.add(_ruleController.text);
                            _ruleController.clear();
                          });
                        }
                      },
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),

                if (_rules.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _rules
                            .map(
                              (rule) => Chip(
                                label: Text(rule),
                                onDeleted: () {
                                  setState(() {
                                    _rules.remove(rule);
                                  });
                                },
                              ),
                            )
                            .toList(),
                  ),
                ],

                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isLoading ? null : _submitListing,
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Post Listing'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
