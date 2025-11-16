import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:camp_nest/core/extension/error_extension.dart';
import 'package:camp_nest/core/model/user_model.dart';

import 'package:camp_nest/core/service/image_upload_service.dart';
import 'package:camp_nest/feature/presentation/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart' as fp;

class EditProfileScreen extends ConsumerStatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _schoolController;
  late final TextEditingController _ageController;
  late final TextEditingController _phoneController;
  String _gender = '';
  bool _isUploading = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _schoolController = TextEditingController(text: widget.user.school);
    _ageController = TextEditingController(
      text: widget.user.age == 0 ? '' : widget.user.age.toString(),
    );
    _phoneController = TextEditingController(
      text: widget.user.phoneNumber ?? '',
    );
    _gender = widget.user.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _schoolController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Photo',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon:
                              _isUploading
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.photo_camera_outlined),
                          label: Text(
                            _isUploading ? 'Uploading...' : 'Update Photo',
                          ),
                          onPressed:
                              _isUploading
                                  ? null
                                  : () async {
                                    setState(() => _isUploading = true);
                                    final uploadSvc = ImageUploadService();
                                    try {
                                      String url;
                                      if (kIsWeb) {
                                        final res = await fp.FilePicker.platform.pickFiles(
                                          allowMultiple: false,
                                          withData: true,
                                          type: fp.FileType.custom,
                                          allowedExtensions: ['jpg','jpeg','png','webp'],
                                        );
                                        if (res == null || res.files.isEmpty || res.files.first.bytes == null) {
                                          setState(() => _isUploading = false);
                                          return;
                                        }
                                        final bytes = res.files.first.bytes!;
                                        final filename = res.files.first.name;
                                        url = await uploadSvc.uploadImageBytes(bytes, filename, 'profiles');
                                      } else {
                                        final picker = ImagePicker();
                                        final picked = await picker.pickImage(
                                          source: ImageSource.gallery,
                                          imageQuality: 85,
                                        );
                                        if (picked == null) {
                                          setState(() => _isUploading = false);
                                          return;
                                        }
                                        final file = File(picked.path);
                                        url = await uploadSvc.uploadImage(file, 'profiles');
                                      }

                                      // Update provider state immediately for UI refresh
                                      final currentUser = ref.read(authProvider).user;
                                      if (currentUser != null) {
                                        final updatedUser = currentUser.copyWith(profileImage: url);
                                        ref.read(authProvider.notifier).setUser(updatedUser);
                                      }

                                      // Persist to backend
                                      final updatedUser = ref.read(authProvider).user!;
                                      await ref.read(authProvider.notifier).updateUserProfile(updatedUser);

                                      'Profile photo updated successfully'.showSuccess(context);
                                    } catch (e) {
                                      e.showError(context);
                                    } finally {
                                      if (mounted) setState(() => _isUploading = false);
                                    }
                                  },
                        ),
                      ),

                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          hintText: 'Enter your name',
                        ),
                        validator:
                            (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Name is required'
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'Enter your email',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator:
                            (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Email is required'
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _schoolController,
                        decoration: const InputDecoration(
                          labelText: 'School',
                          hintText: 'Enter your school',
                        ),
                        validator:
                            (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'School is required'
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _ageController,
                        decoration: const InputDecoration(
                          labelText: 'Age',
                          hintText: 'Enter your age',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return null; // optional
                          final value = int.tryParse(v.trim());
                          if (value == null || value < 0)
                            return 'Enter a valid age';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: (_gender.isEmpty) ? null : _gender,
                        items: const [
                          DropdownMenuItem(value: 'male', child: Text('Male')),
                          DropdownMenuItem(
                            value: 'female',
                            child: Text('Female'),
                          ),
                          DropdownMenuItem(
                            value: 'other',
                            child: Text('Other'),
                          ),
                        ],
                        decoration: const InputDecoration(labelText: 'Gender'),
                        onChanged: (value) {
                          setState(() {
                            _gender = value ?? '';
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          hintText: 'Enter your phone number',
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                  child: const Text('Save Profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    // Get current user from provider (this has latest profileImage if updated)
    final currentUser = ref.read(authProvider).user;

    if (currentUser == null) return;

    final updatedUser = currentUser.copyWith(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      school: _schoolController.text.trim(),
      age: int.tryParse(_ageController.text.trim()) ?? currentUser.age,
      gender: _gender.isEmpty ? currentUser.gender : _gender,
      phoneNumber:
          _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
      // profileImage is already updated in provider when user uploads
    );

    try {
      // Update provider state immediately for UI
      ref.read(authProvider.notifier).setUser(updatedUser);

      // Persist to backend
      await ref.read(authProvider.notifier).updateUserProfile(updatedUser);

      // Return the updated user to previous screen
      if (mounted) {
        Navigator.pop(context, updatedUser);
      }
    } catch (e) {
      e.showError(context);
    }
  }
}
