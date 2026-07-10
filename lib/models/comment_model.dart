class CommentModel {
  final String commentId;
  final String uid;
  final String username;
  final String text;
  final DateTime datePublished;

  CommentModel({
    required this.commentId,
    required this.uid,
    required this.username,
    required this.text,
    required this.datePublished,
  });

  Map<String, dynamic> toJson() => {
        'commentId': commentId,
        'uid': uid,
        'username': username,
        'text': text,
        'datePublished': datePublished.toIso8601String(),
      };

  factory CommentModel.fromJson(Map<String, dynamic> json) => CommentModel(
        commentId: json['commentId'],
        uid: json['uid'],
        username: json['username'],
        text: json['text'],
        datePublished: DateTime.parse(json['datePublished']),
      );
}