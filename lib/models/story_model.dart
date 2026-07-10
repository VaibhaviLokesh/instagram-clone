class StoryModel {
  final String storyId;
  final String uid;
  final String username;
  final String profilePicture;
  final String localImagePath;
  final DateTime datePublished;

  StoryModel({
    required this.storyId,
    required this.uid,
    required this.username,
    required this.profilePicture,
    required this.localImagePath,
    required this.datePublished,
  });

  Map<String, dynamic> toJson() => {
        'storyId': storyId,
        'uid': uid,
        'username': username,
        'profilePicture': profilePicture,
        'localImagePath': localImagePath,
        'datePublished': datePublished.toIso8601String(),
      };

  factory StoryModel.fromJson(Map<String, dynamic> json) => StoryModel(
        storyId: json['storyId'],
        uid: json['uid'],
        username: json['username'],
        profilePicture: json['profilePicture'] ?? '',
        localImagePath: json['localImagePath'] ?? '',
        datePublished: DateTime.parse(json['datePublished']),
      );

  bool get isExpired =>
      DateTime.now().difference(datePublished).inHours >= 24;
}