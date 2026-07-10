import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/auth_provider.dart' as ap;
import '../providers/post_provider.dart';
import '../providers/story_provider.dart';
import '../models/post_model.dart';
import '../models/story_model.dart';
import 'comments_screen.dart';
import 'story_viewer_screen.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  Future<void> _addStory(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;

    final authProvider =
        Provider.of<ap.AuthProvider>(context, listen: false);
    final storyProvider =
        Provider.of<StoryProvider>(context, listen: false);

    await storyProvider.addStory(
      uid: authProvider.userModel!.uid,
      username: authProvider.userModel!.username,
      profilePicture: authProvider.userModel!.profilePicture,
      localImagePath: image.path,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Story added!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = Provider.of<PostProvider>(context);
    final authProvider = Provider.of<ap.AuthProvider>(context);
    final storyProvider = Provider.of<StoryProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Instagram',
          style: TextStyle(
            fontFamily: 'Billabong',
            fontSize: 32,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.send_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Stories row
          SizedBox(
            height: 100,
            child: StreamBuilder<List<StoryModel>>(
              stream: storyProvider.getStories(),
              builder: (context, snapshot) {
                List<StoryModel> allStories = snapshot.data ?? [];

                // Deduplicate — one bubble per user
                final seen = <String>{};
                List<StoryModel> stories = allStories.where((s) {
                  if (seen.contains(s.uid)) return false;
                  seen.add(s.uid);
                  return true;
                }).toList();

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: stories.length + 1,
                  itemBuilder: (context, index) {
                    // First item — "Your story" / Add story
                    if (index == 0) {
                      final myStories = allStories
                          .where((s) => s.uid == authProvider.userModel?.uid)
                          .toList();
                      return GestureDetector(
                        onTap: myStories.isEmpty
                            ? () => _addStory(context)
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StoryViewerScreen(
                                      stories: myStories,
                                    ),
                                  ),
                                );
                              },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    decoration: myStories.isNotEmpty
                                        ? BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: const Color(0xFFE1306C),
                                              width: 2,
                                            ),
                                          )
                                        : null,
                                    child: Padding(
                                      padding: const EdgeInsets.all(2),
                                      child: CircleAvatar(
                                        radius: 28,
                                        backgroundColor: Colors.grey[200],
                                        backgroundImage: authProvider.userModel
                                                        ?.profilePicture
                                                        .isNotEmpty ==
                                                    true
                                            ? FileImage(File(authProvider
                                                .userModel!.profilePicture))
                                            : null,
                                        child: authProvider.userModel
                                                    ?.profilePicture.isEmpty ??
                                                true
                                            ? const Icon(Icons.person)
                                            : null,
                                      ),
                                    ),
                                  ),
                                  if (myStories.isEmpty)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF3797EF),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                myStories.isEmpty ? 'Your story' : 'Your story',
                                style: const TextStyle(fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Other users' stories
                    final story = stories[index - 1];
                    // Skip current user's story (already shown as first)
                    if (story.uid == authProvider.userModel?.uid) {
                      return const SizedBox.shrink();
                    }

                    final userStories = allStories
                        .where((s) => s.uid == story.uid)
                        .toList();

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StoryViewerScreen(
                              stories: userStories,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFE1306C),
                                  width: 2,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.grey[300],
                                  backgroundImage:
                                      story.profilePicture.isNotEmpty
                                          ? FileImage(
                                              File(story.profilePicture))
                                          : null,
                                  child: story.profilePicture.isEmpty
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              story.username,
                              style: const TextStyle(fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Posts feed
          Expanded(
            child: StreamBuilder<List<PostModel>>(
              stream: postProvider.getFeedPosts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No posts yet.\nBe the first to post!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    PostModel post = snapshot.data![index];
                    bool isLiked =
                        post.likes.contains(authProvider.userModel?.uid);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.grey[300],
                                child: const Icon(Icons.person, size: 16),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  post.username,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (post.uid == authProvider.userModel?.uid)
                                IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        content: ListTile(
                                          leading: const Icon(Icons.delete,
                                              color: Colors.red),
                                          title: const Text('Delete post'),
                                          onTap: () {
                                            postProvider.deletePost(
                                                post.postId, post.uid);
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),

                        // Image with double tap to like
                        GestureDetector(
                          onDoubleTap: () {
                            if (!isLiked) {
                              postProvider.likePost(
                                post.postId,
                                authProvider.userModel!.uid,
                                post.likes,
                              );
                            }
                          },
                          child: post.localImagePath.isNotEmpty
                              ? Image.file(
                                  File(post.localImagePath),
                                  width: double.infinity,
                                  height: 300,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 300,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.broken_image,
                                        size: 60),
                                  ),
                                )
                              : Container(
                                  height: 300,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image, size: 60),
                                ),
                        ),

                        // Like button row
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isLiked ? Colors.red : Colors.black,
                              ),
                              onPressed: () {
                                postProvider.likePost(
                                  post.postId,
                                  authProvider.userModel!.uid,
                                  post.likes,
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.chat_bubble_outline),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CommentsScreen(
                                      postId: post.postId,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.send_outlined),
                              onPressed: () {},
                            ),
                          ],
                        ),

                        // Likes count
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '${post.likes.length} likes',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                        ),

                        // Caption
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(color: Colors.black),
                              children: [
                                TextSpan(
                                  text: post.username,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: '  ${post.caption}'),
                              ],
                            ),
                          ),
                        ),

                        // View comments
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 2),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CommentsScreen(
                                    postId: post.postId,
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              'View all comments',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),

                        // Time
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          child: Text(
                            timeago.format(post.datePublished),
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                        ),

                        const Divider(),
                      ],
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
}