import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:camp_nest/core/extension/error_extension.dart';
import 'package:camp_nest/core/model/user_model.dart';

import 'package:camp_nest/core/service/image_upload_service.dart';
import 'package:camp_nest/feature/presentation/provider/auth_provider.dart';
import 'package:camp_nest/feature/presentation/widgets/fade_in_slide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

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
  bool _isLoading = false;

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Photo Section
                    FadeInSlide(
                      duration: 0.5,
                      child: Center(
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.primaryColor,
                                  width: 2,
                                ),
                              ),
                              child: Consumer(
                                builder: (context, ref, _) {
                                  final currentUser =
                                      ref.watch(authProvider).user ??
                                      widget.user;
                                  return CircleAvatar(
                                    radius: 60,
                                    backgroundColor: theme.primaryColor
                                        .withOpacity(0.1),
                                    backgroundImage:
                                        currentUser.profileImage != null &&
                                                currentUser
                                                    .profileImage!
                                                    .isNotEmpty
                                            ? NetworkImage(
                                              currentUser.profileImage!,
                                            )
                                            : null,
                                    child:
                                        currentUser.profileImage == null ||
                                                currentUser
                                                    .profileImage!
                                                    .isEmpty
                                            ? Text(
                                              currentUser.name.isNotEmpty
                                                  ? currentUser.name[0]
                                                      .toUpperCase()
                                                  : 'U',
                                              style: TextStyle(
                                                fontSize: 40,
                                                fontWeight: FontWeight.bold,
                                                color: theme.primaryColor,
                                              ),
                                            )
                                            : null,
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: _isUploading ? null : _uploadImage,
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme.scaffoldBackgroundColor,
                                      width: 3,
                                    ),
                                  ),
                                  child:
                                      _isUploading
                                          ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : const Icon(
                                            Icons.camera_alt_outlined,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Form Fields
                    FadeInSlide(
                      duration: 0.5,
                      delay: 0.1,
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            hint: 'Your Name',
                            icon: Icons.person_outline,
                            validator:
                                (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Name is required'
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email',
                            hint: 'your.email@example.com',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator:
                                (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Email is required'
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _schoolController,
                            label: 'School',
                            hint: 'University/College Name',
                            icon: Icons.school_outlined,
                            validator:
                                (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'School is required'
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _ageController,
                                  label: 'Age',
                                  hint: '20',
                                  icon: Icons.cake_outlined,
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty)
                                      return null;
                                    final value = int.tryParse(v.trim());
                                    if (value == null || value < 0)
                                      return 'Invalid';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isDark
                                            ? Colors.grey[900]
                                            : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.withOpacity(0.2),
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButtonFormField<String>(
                                      value: (_gender.isEmpty) ? null : _gender,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        prefixIcon: Icon(
                                          Icons.people_outline,
                                          size: 22,
                                        ),
                                        labelText: 'Gender',
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'male',
                                          child: Text('Male'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'female',
                                          child: Text('Female'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'other',
                                          child: Text('Other'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _gender = value ?? '';
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _phoneController,
                            label: 'Phone Number',
                            hint: '+1234567890',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Save Button
                    FadeInSlide(
                      duration: 0.5,
                      delay: 0.2,
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _onSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            shadowColor: theme.primaryColor.withOpacity(0.4),
                          ),
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(
            icon,
            size: 22,
            color: Theme.of(context).primaryColor,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
        validator: validator,
      ),
    );
  }

  Future<void> _uploadImage() async {
    setState(() => _isUploading = true);
    final uploadSvc = ImageUploadService();
    try {
      String url;
      if (kIsWeb) {
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );
        if (picked == null) {
          setState(() => _isUploading = false);
          return;
        }
        final bytes = await picked.readAsBytes();
        url = await uploadSvc.uploadImageBytes(bytes, picked.name, 'profiles');
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

      if (mounted) {
        'Profile photo updated successfully'.showSuccess(context);
      }
    } catch (e) {
      if (mounted) {
        e.showError(context);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Get current user from provider (this has latest profileImage if updated)
    final currentUser = ref.read(authProvider).user;

    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

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
      // Simulate network delay for UX
      await Future.delayed(const Duration(milliseconds: 800));

      // Update provider state immediately for UI
      ref.read(authProvider.notifier).setUser(updatedUser);

      // Persist to backend
      await ref.read(authProvider.notifier).updateUserProfile(updatedUser);

      // Return the updated user to previous screen
      if (mounted) {
        'Profile updated successfully'.showSuccess(context);
        Navigator.pop(context, updatedUser);
      }
    } catch (e) {
      if (mounted) {
        e.showError(context);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
