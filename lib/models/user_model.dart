class UserModel {
  final String uid;
  final String email;
  final String username;
  final String bio;
  final String profilePicture;
  final List<String> followers;
  final List<String> following;
  final List<String> posts;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    this.bio = '',
    this.profilePicture = '',
    this.followers = const [],
    this.following = const [],
    this.posts = const [],
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'username': username,
        'bio': bio,
        'profilePicture': profilePicture,
        'followers': followers,
        'following': following,
        'posts': posts,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        uid: json['uid'],
        email: json['email'],
        username: json['username'],
        bio: json['bio'] ?? '',
        profilePicture: json['profilePicture'] ?? '',
        followers: List<String>.from(json['followers'] ?? []),
        following: List<String>.from(json['following'] ?? []),
        posts: List<String>.from(json['posts'] ?? []),
      );
}