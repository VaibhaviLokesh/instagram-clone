import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/reel_model.dart';

class ReelProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Upload a reel
  Future<String> uploadReel({
    required String uid,
    required String username,
    required String profilePicture,
    required String caption,
    required String localVideoPath,
  }) async {
    try {
      String reelId = _uuid.v1();
      ReelModel reel = ReelModel(
        reelId: reelId,
        uid: uid,
        username: username,
        profilePicture: profilePicture,
        caption: caption,
        localVideoPath: localVideoPath,
        datePublished: DateTime.now(),
      );

      await _firestore.collection('reels').doc(reelId).set(reel.toJson());
      notifyListeners();
      return 'success';
    } catch (e) {
      return e.toString();
    }
  }

  // Get all reels
  Stream<List<ReelModel>> getReels() {
    return _firestore
        .collection('reels')
        .orderBy('datePublished', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReelModel.fromJson(doc.data()))
            .toList());
  }

  // Like / Unlike a reel
  Future<void> likeReel(String reelId, String uid, List likes) async {
    if (likes.contains(uid)) {
      await _firestore.collection('reels').doc(reelId).update({
        'likes': FieldValue.arrayRemove([uid]),
      });
    } else {
      await _firestore.collection('reels').doc(reelId).update({
        'likes': FieldValue.arrayUnion([uid]),
      });
    }
  }
}