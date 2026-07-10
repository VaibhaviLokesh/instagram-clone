import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/auth_provider.dart' as ap;

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  bool _isLoading = false;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    final authProvider =
        Provider.of<ap.AuthProvider>(context, listen: false);
    _usernameController.text = authProvider.userModel?.username ?? '';
    _bioController.text = authProvider.userModel?.bio ?? '';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      setState(() => _profileImage = File(image.path));
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    final authProvider =
        Provider.of<ap.AuthProvider>(context, listen: false);

    Map<String, dynamic> updateData = {
      'username': _usernameController.text.trim(),
      'bio': _bioController.text.trim(),
    };

    if (_profileImage != null) {
      updateData['profilePicture'] = _profileImage!.path;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(authProvider.userModel!.uid)
        .update(updateData);

    await authProvider.loadUserData();
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<ap.AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFF3797EF),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile picture
            GestureDetector(
              onTap: _pickProfilePhoto,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : (authProvider.userModel?.profilePicture.isNotEmpty == true
                        ? FileImage(
                            File(authProvider.userModel!.profilePicture))
                        : null),
                child: _profileImage == null &&
                        (authProvider.userModel?.profilePicture.isEmpty ?? true)
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickProfilePhoto,
              child: const Text(
                'Change profile photo',
                style: TextStyle(
                  color: Color(0xFF3797EF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Username field
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: UnderlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Bio field
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Bio',
                border: UnderlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            if (_isLoading)
              const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}