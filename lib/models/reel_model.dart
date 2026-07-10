class ReelModel {
  final String reelId;
  final String uid;
  final String username;
  final String profilePicture;
  final String caption;
  final String localVideoPath;
  final List<String> likes;
  final DateTime datePublished;

  ReelModel({
    required this.reelId,
    required this.uid,
    required this.username,
    required this.profilePicture,
    required this.caption,
    required this.localVideoPath,
    this.likes = const [],
    required this.datePublished,
  });

  Map<String, dynamic> toJson() => {
        'reelId': reelId,
        'uid': uid,
        'username': username,
        'profilePicture': profilePicture,
        'caption': caption,
        'localVideoPath': localVideoPath,
        'likes': likes,
        'datePublished': datePublished.toIso8601String(),
      };

  factory ReelModel.fromJson(Map<String, dynamic> json) => ReelModel(
        reelId: json['reelId'],
        uid: json['uid'],
        username: json['username'],
        profilePicture: json['profilePicture'] ?? '',
        caption: json['caption'],
        localVideoPath: json['localVideoPath'] ?? '',
        likes: List<String>.from(json['likes'] ?? []),
        datePublished: DateTime.parse(json['datePublished']),
      );
}