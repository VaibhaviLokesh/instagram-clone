import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/post_model.dart';

class PostProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  List<PostModel> _posts = [];
  List<PostModel> get posts => _posts;

  // Create a post
  Future<String> createPost({
    required String uid,
    required String username,
    required String profilePicture,
    required String caption,
    required String localImagePath,
  }) async {
    try {
      String postId = _uuid.v1();
      PostModel post = PostModel(
        postId: postId,
        uid: uid,
        username: username,
        profilePicture: profilePicture,
        caption: caption,
        localImagePath: localImagePath,
        datePublished: DateTime.now(),
      );

      // Save to Firestore
      await _firestore.collection('posts').doc(postId).set(post.toJson());

      // Add postId to user's posts array
      await _firestore.collection('users').doc(uid).update({
        'posts': FieldValue.arrayUnion([postId]),
      });

      notifyListeners();
      return 'success';
    } catch (e) {
      return e.toString();
    }
  }

  // Fetch all posts for feed
  Stream<List<PostModel>> getFeedPosts() {
    return _firestore
        .collection('posts')
        .orderBy('datePublished', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PostModel.fromJson(doc.data()))
            .toList());
  }

  // Like / Unlike a post
  Future<void> likePost(String postId, String uid, List likes) async {
    if (likes.contains(uid)) {
      await _firestore.collection('posts').doc(postId).update({
        'likes': FieldValue.arrayRemove([uid]),
      });
    } else {
      await _firestore.collection('posts').doc(postId).update({
        'likes': FieldValue.arrayUnion([uid]),
      });
    }
  }

  // Delete a post
  Future<void> deletePost(String postId, String uid) async {
    await _firestore.collection('posts').doc(postId).delete();
    await _firestore.collection('users').doc(uid).update({
      'posts': FieldValue.arrayRemove([postId]),
    });
    notifyListeners();
  }
}