import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import '../providers/auth_provider.dart' as ap;
import '../providers/reel_provider.dart';
import '../models/reel_model.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final PageController _pageController = PageController();

  Future<void> _uploadReel() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return;

    final authProvider =
        Provider.of<ap.AuthProvider>(context, listen: false);
    final reelProvider =
        Provider.of<ReelProvider>(context, listen: false);

    // Show caption dialog
    String caption = '';
    if (mounted) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Add caption'),
          content: TextField(
            onChanged: (val) => caption = val,
            decoration: const InputDecoration(hintText: 'Write a caption...'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Post'),
            ),
          ],
        ),
      );
    }

    await reelProvider.uploadReel(
      uid: authProvider.userModel!.uid,
      username: authProvider.userModel!.username,
      profilePicture: authProvider.userModel!.profilePicture,
      caption: caption,
      localVideoPath: video.path,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reel posted!')),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reelProvider = Provider.of<ReelProvider>(context);
    final authProvider = Provider.of<ap.AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Reels',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.video_call, color: Colors.white),
            onPressed: _uploadReel,
          ),
        ],
      ),
      body: StreamBuilder<List<ReelModel>>(
        stream: reelProvider.getReels(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_library_outlined,
                      size: 80, color: Colors.white54),
                  SizedBox(height: 16),
                  Text(
                    'No reels yet.\nBe the first to post!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              ReelModel reel = snapshot.data![index];
              bool isLiked = reel.likes.contains(authProvider.userModel?.uid);

              return ReelItem(
                reel: reel,
                isLiked: isLiked,
                onLike: () => reelProvider.likeReel(
                  reel.reelId,
                  authProvider.userModel!.uid,
                  reel.likes,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ReelItem extends StatefulWidget {
  final ReelModel reel;
  final bool isLiked;
  final VoidCallback onLike;

  const ReelItem({
    super.key,
    required this.reel,
    required this.isLiked,
    required this.onLike,
  });

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem> {
  VideoPlayerController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    if (widget.reel.localVideoPath.isNotEmpty) {
      _controller = VideoPlayerController.file(
        File(widget.reel.localVideoPath),
      );
      await _controller!.initialize();
      _controller!.setLooping(true);
      _controller!.play();
      setState(() => _initialized = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: widget.onLike,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video
          _initialized && _controller != null
              ? FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                )
              : const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),

          // Gradient overlay at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
            ),
          ),

          // Right side actions
          Positioned(
            right: 12,
            bottom: 100,
            child: Column(
              children: [
                GestureDetector(
                  onTap: widget.onLike,
                  child: Column(
                    children: [
                      Icon(
                        widget.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: widget.isLiked ? Colors.red : Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.reel.likes.length}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Icon(Icons.comment_outlined,
                    color: Colors.white, size: 32),
                const SizedBox(height: 4),
                const Text('0', style: TextStyle(color: Colors.white)),
                const SizedBox(height: 20),
                const Icon(Icons.send_outlined,
                    color: Colors.white, size: 32),
              ],
            ),
          ),

          // Bottom info
          Positioned(
            bottom: 60,
            left: 12,
            right: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey[300],
                      child: const Icon(Icons.person, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.reel.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (widget.reel.caption.isNotEmpty)
                  Text(
                    widget.reel.caption,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Play/pause on tap
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                if (_controller != null) {
                  setState(() {
                    _controller!.value.isPlaying
                        ? _controller!.pause()
                        : _controller!.play();
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}