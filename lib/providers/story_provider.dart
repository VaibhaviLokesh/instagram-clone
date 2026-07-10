import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/story_model.dart';

class StoryProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Add a story
  Future<String> addStory({
    required String uid,
    required String username,
    required String profilePicture,
    required String localImagePath,
  }) async {
    try {
      String storyId = _uuid.v1();
      StoryModel story = StoryModel(
        storyId: storyId,
        uid: uid,
        username: username,
        profilePicture: profilePicture,
        localImagePath: localImagePath,
        datePublished: DateTime.now(),
      );

      await _firestore
          .collection('stories')
          .doc(storyId)
          .set(story.toJson());

      notifyListeners();
      return 'success';
    } catch (e) {
      return e.toString();
    }
  }

  // Get active stories (less than 24 hours old)
  Stream<List<StoryModel>> getStories() {
    return _firestore
        .collection('stories')
        .orderBy('datePublished', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StoryModel.fromJson(doc.data()))
            .where((story) => !story.isExpired)
            .toList());
  }

  // Delete expired stories
  Future<void> deleteExpiredStories() async {
    final snapshot = await _firestore.collection('stories').get();
    for (var doc in snapshot.docs) {
      StoryModel story = StoryModel.fromJson(doc.data());
      if (story.isExpired) {
        await _firestore.collection('stories').doc(story.storyId).delete();
      }
    }
  }
}