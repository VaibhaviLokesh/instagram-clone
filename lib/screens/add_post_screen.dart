import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/auth_provider.dart' as ap;
import '../providers/post_provider.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  File? _image;
  final TextEditingController _captionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      setState(() => _image = File(image.path));
    }
  }

  Future<void> _post() async {
    final authProvider =
        Provider.of<ap.AuthProvider>(context, listen: false);

    if (authProvider.userModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in again')),
      );
      return;
    }

    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    if (_captionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a caption')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final postProvider =
        Provider.of<PostProvider>(context, listen: false);

    String result = await postProvider.createPost(
      uid: authProvider.userModel!.uid,
      username: authProvider.userModel!.username,
      profilePicture: authProvider.userModel!.profilePicture,
      caption: _captionController.text.trim(),
      localImagePath: _image!.path,
    );

    setState(() => _isLoading = false);

    if (result == 'success') {
      if (mounted) {
        _captionController.clear();
        setState(() => _image = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post shared!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'New Post',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _post,
            child: const Text(
              'Share',
              style: TextStyle(
                color: Color(0xFF3797EF),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Image picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 300,
                color: Colors.grey[200],
                child: _image != null
                    ? Image.file(_image!, fit: BoxFit.cover)
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate,
                              size: 60, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'Tap to select photo',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
              ),
            ),

            // Caption
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 20,
                    child: Icon(Icons.person),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _captionController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'Write a caption...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(),

            if (_isLoading)
              const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}