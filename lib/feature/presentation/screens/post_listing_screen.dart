import 'package:camp_nest/core/extension/error_extension.dart';
import 'package:camp_nest/core/model/room_listing.dart';
import 'package:camp_nest/core/service/image_upload_service.dart';
import 'package:camp_nest/feature/presentation/provider/listing_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart' as fp;

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

  Future<void> _pickMedia() async {
    try {
      if (kIsWeb) {
        // Use file_picker for web
        final res = await fp.FilePicker.platform.pickFiles(
          allowMultiple: true,
          withData: true, // get bytes
          type: fp.FileType.custom,
          allowedExtensions: ['jpg','jpeg','png','webp'],
        );
        if (res != null && res.files.isNotEmpty) {
          final files = res.files.take(5).toList();
          setState(() {
            _selectedImageBytes = files.where((f) => f.bytes != null).map((f) => f.bytes!).toList();
            _selectedFilenames = files.map((f) => f.name).toList();
            _selectedImages.clear(); // clear mobile list
          });
        }
      } else {
        // Mobile/desktop via image_picker
        final List<XFile> mediaFiles = await _picker.pickMultipleMedia();
        if (mediaFiles.isNotEmpty) {
          final limitedFiles = mediaFiles.take(5).toList();
          setState(() {
            _selectedImages = limitedFiles.map((xFile) => File(xFile.path)).toList();
            _selectedImageBytes.clear();
            _selectedFilenames.clear();
          });
        }
      }
    } catch (e) {
      e.showError(context, duration: const Duration(seconds: 4));
    }
  }

  Future<void> _takePicture() async {
    if (kIsWeb) {
      // Camera access via image_picker is limited on web; fall back to file picker
      await _pickMedia();
      return;
    }
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (image != null && _selectedImages.length < 5) {
        final file = File(image.path);
        setState(() {
          _selectedImages.add(file);
        });
      }
    } catch (e) {
      e.showError(context, duration: const Duration(seconds: 4));
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
                        onPressed: () {
                          Navigator.pop(context);
                          _pickMedia();
                        },
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                      ),
                    ),
                    const SizedBox(width: 16),
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
          print('Starting web image upload for ${_selectedImageBytes.length} images');
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

        final listing = RoomListingModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text,
          description: _descriptionController.text,
          price: double.parse(_priceController.text),
          location: _locationController.text,
          images: imageUrls,
          ownerId: 'current_user_id',
          ownerName: 'Current User',
          ownerPhone:
              _ownerPhoneController.text.isNotEmpty
                  ? _ownerPhoneController.text
                  : null,
          amenities: _selectedAmenities,
          rules: _rules,
          gender: _selectedGender,
          availableFrom: DateTime.now().add(const Duration(days: 7)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post a Listing')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                    (!kIsWeb && _selectedImages.isEmpty) || (kIsWeb && _selectedImageBytes.isEmpty)
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
                              child: kIsWeb
                                  ? Image.memory(
                                      _selectedImageBytes.first,
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      _selectedImages.first,
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        print('Image display error: $error');
                                        return Container(
                                          color: Colors.grey[400],
                                          child: const Center(
                                            child: Icon(
                                              Icons.error,
                                              color: Colors.red,
                                            ),
                                          ),
                                        );
                                      },
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
                                  '${(kIsWeb ? _selectedImageBytes.length : _selectedImages.length)} image${(kIsWeb ? _selectedImageBytes.length : _selectedImages.length) > 1 ? 's' : ''}',
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
            if ((!kIsWeb && _selectedImages.isNotEmpty) || (kIsWeb && _selectedImageBytes.isNotEmpty)) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: kIsWeb ? _selectedImageBytes.length : _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: kIsWeb
                                ? Image.memory(
                                    _selectedImageBytes[index],
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    _selectedImages[index],
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[400],
                                        child: const Icon(
                                          Icons.error,
                                          color: Colors.red,
                                        ),
                                      );
                                    },
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
    );
  }
}
