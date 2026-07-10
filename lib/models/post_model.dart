class PostModel {
  final String postId;
  final String uid;
  final String username;
  final String profilePicture;
  final String caption;
  final String localImagePath;
  final List<String> likes;
  final DateTime datePublished;

  PostModel({
    required this.postId,
    required this.uid,
    required this.username,
    required this.profilePicture,
    required this.caption,
    required this.localImagePath,
    this.likes = const [],
    required this.datePublished,
  });

  Map<String, dynamic> toJson() => {
        'postId': postId,
        'uid': uid,
        'username': username,
        'profilePicture': profilePicture,
        'caption': caption,
        'localImagePath': localImagePath,
        'likes': likes,
        'datePublished': datePublished.toIso8601String(),
      };

  factory PostModel.fromJson(Map<String, dynamic> json) => PostModel(
        postId: json['postId'],
        uid: json['uid'],
        username: json['username'],
        profilePicture: json['profilePicture'] ?? '',
        caption: json['caption'],
        localImagePath: json['localImagePath'] ?? '',
        likes: List<String>.from(json['likes'] ?? []),
        datePublished: DateTime.parse(json['datePublished']),
      );
}