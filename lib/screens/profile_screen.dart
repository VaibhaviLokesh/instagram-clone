import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/auth_provider.dart' as ap;
import '../models/user_model.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;
  const ProfileScreen({super.key, required this.uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserModel? _profileUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    DocumentSnapshot doc =
        await _firestore.collection('users').doc(widget.uid).get();
    setState(() {
      _profileUser = UserModel.fromJson(doc.data() as Map<String, dynamic>);
      _isLoading = false;
    });
  }

  Future<void> _followUnfollow(String currentUid) async {
    if (_profileUser == null) return;

    if (_profileUser!.followers.contains(currentUid)) {
      await _firestore.collection('users').doc(widget.uid).update({
        'followers': FieldValue.arrayRemove([currentUid]),
      });
      await _firestore.collection('users').doc(currentUid).update({
        'following': FieldValue.arrayRemove([widget.uid]),
      });
    } else {
      await _firestore.collection('users').doc(widget.uid).update({
        'followers': FieldValue.arrayUnion([currentUid]),
      });
      await _firestore.collection('users').doc(currentUid).update({
        'following': FieldValue.arrayUnion([widget.uid]),
      });
    }
    _loadProfile();
  }

  Widget _buildProfilePicture(String? picturePath, {double radius = 40}) {
    if (picturePath != null && picturePath.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(picturePath)),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[300],
      child: Icon(Icons.person, size: radius),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<ap.AuthProvider>(context);
    final isOwnProfile = widget.uid == authProvider.userModel?.uid;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_profileUser == null) {
      return const Scaffold(
        body: Center(child: Text('User not found')),
      );
    }

    bool isFollowing =
        _profileUser!.followers.contains(authProvider.userModel?.uid);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _profileUser!.username,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {},
            ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildProfilePicture(_profileUser!.profilePicture),
                const SizedBox(width: 24),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statColumn(
                          _profileUser!.posts.length.toString(), 'Posts'),
                      _statColumn(
                          _profileUser!.followers.length.toString(),
                          'Followers'),
                      _statColumn(
                          _profileUser!.following.length.toString(),
                          'Following'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _profileUser!.username,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_profileUser!.bio.isNotEmpty)
                  Text(_profileUser!.bio),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: isOwnProfile
                ? OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EditProfileScreen()),
                    ).then((_) => _loadProfile()),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Edit Profile',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: () =>
                        _followUnfollow(authProvider.userModel!.uid),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFollowing
                          ? Colors.grey[200]
                          : const Color(0xFF3797EF),
                      foregroundColor:
                          isFollowing ? Colors.black : Colors.white,
                      minimumSize: const Size(double.infinity, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isFollowing ? 'Following' : 'Follow',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
          ),
          const SizedBox(height: 12),

          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Icon(Icons.grid_on, size: 28),
          ),
          const Divider(height: 1),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('posts')
                  .where('uid', isEqualTo: widget.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined,
                            size: 60, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'No posts yet',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                  ),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final data = snapshot.data!.docs[index].data()
                        as Map<String, dynamic>;
                    final imagePath = data['localImagePath'] ?? '';
                    return imagePath.isNotEmpty
                        ? Image.file(
                            File(imagePath),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image),
                            ),
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.image),
                          );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statColumn(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}