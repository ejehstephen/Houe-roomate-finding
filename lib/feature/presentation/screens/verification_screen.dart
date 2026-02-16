import 'package:camp_nest/feature/presentation/provider/verification_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();

  // Document State

  // Document State
  String _selectedDocType = 'School ID';
  XFile? _frontImage;
  XFile? _backImage;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isFront) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (isFront) {
          _frontImage = image;
        } else {
          _backImage = image;
        }
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_frontImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload the front image of your ID'),
          ),
        );
        return;
      }

      await ref
          .read(verificationNotifierProvider.notifier)
          .submitVerification(
            fullName: _nameController.text.trim(),
            ninNumber: 'N/A', // NIN removed as requirement
            documentType: _selectedDocType,
            frontImage: _frontImage!,
            backImage: _backImage,
          );

      // Check result via listener or simple delay/check state
      // The provider state updates to data(null) on success or error on failure
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(verificationNotifierProvider);
    final theme = Theme.of(context);

    // Listen for success/error
    ref.listen(verificationNotifierProvider, (previous, next) {
      next.when(
        data: (_) {
          if (previous?.isLoading == true) {
            // Only show on completion
            showDialog(
              context: context,
              barrierDismissible: false,
              builder:
                  (context) => AlertDialog(
                    title: const Text('Submission Successful'),
                    content: const Text(
                      'Your verification request has been submitted and is pending approval. You will be notified once reviewed.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                          Navigator.of(context).pop(); // Close screen
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  ),
            );
          }
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
        loading: () {},
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Identity Verification')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, 'Personal Information'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name (as on ID)',
                      hintText: 'Enter your full name',
                    ),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Name is required'
                                : null,
                  ),
                  const SizedBox(height: 16),

                  const SizedBox(height: 16),

                  const SizedBox(height: 32),
                  _buildSectionTitle(context, 'Document Upload'),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _selectedDocType,
                    decoration: InputDecoration(
                      labelText: 'Document Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items:
                        ['School ID', 'Selfie'].map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDocType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Front of ID (Required)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildImageUpload(
                    context,
                    _frontImage,
                    () => _pickImage(true),
                    'Tap to upload front image',
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'Back of ID (Optional)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildImageUpload(
                    context,
                    _backImage,
                    () => _pickImage(false),
                    'Tap to upload back image',
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: state.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          state.isLoading
                              ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                'Submit for Verification',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildImageUpload(
    BuildContext context,
    XFile? image,
    VoidCallback onTap,
    String placeholder,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child:
            image != null
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(image.path, fit: BoxFit.cover),
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 40,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      placeholder,
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
      ),
    );
  }
}
