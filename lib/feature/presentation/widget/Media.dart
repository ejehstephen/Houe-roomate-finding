import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:camp_nest/core/service/auth_service.dart';

class MediaDisplayWidget extends StatefulWidget {
  final String mediaUrl;

  const MediaDisplayWidget({super.key, required this.mediaUrl});

  @override
  _MediaDisplayWidgetState createState() => _MediaDisplayWidgetState();
}

class _MediaDisplayWidgetState extends State<MediaDisplayWidget> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeMedia();
  }

  @override
  void didUpdateWidget(covariant MediaDisplayWidget oldWidget) {
    if (widget.mediaUrl != oldWidget.mediaUrl) {
      _disposeControllers();
      _initializeMedia();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    _chewieController?.dispose();
    _videoController?.dispose();
    _chewieController = null;
    _videoController = null;
    _isInitialized = false;
  }

  void _initializeMedia() async {
    final resolvedUrl =
        widget.mediaUrl.startsWith('http')
            ? widget.mediaUrl
            : '${AuthService().baseUrl}${widget.mediaUrl}';

    // Handle Video - Check this first to avoid passing it to Image.network
    if (resolvedUrl.toLowerCase().endsWith('.mp4') ||
        resolvedUrl.contains('/video/')) {
      try {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(resolvedUrl),
        );
        await _videoController!.initialize();
        if (mounted) {
          setState(() {
            _chewieController = ChewieController(
              videoPlayerController: _videoController!,
              autoPlay: true,
              looping: false,
            );
            _isInitialized = true;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isInitialized = true; // Mark as initialized to show fallback
          });
        }
        print('Error initializing video: $e');
      }
    } else {
      if (mounted) {
        // Add a mounted check here as well for consistency
        setState(() {
          _isInitialized = true;
        });
      } // Exit here after handling video logic
    }

    // Handle SVG
    if (resolvedUrl.toLowerCase().endsWith('.svg')) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
      return; // Exit here after handling SVG
    }

    // For images, no controller needed. Mark as initialized.
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final resolvedUrl =
        widget.mediaUrl.startsWith('http')
            ? widget.mediaUrl
            : '${AuthService().baseUrl}${widget.mediaUrl}';

    // Explicitly check for video again in the build method
    if (resolvedUrl.toLowerCase().endsWith('.mp4') ||
        resolvedUrl.contains('/video/')) {
      if (_chewieController != null &&
          _chewieController!.videoPlayerController.value.isInitialized) {
        return Chewie(controller: _chewieController!);
      }
      return const Center(child: Icon(Icons.videocam_off, size: 50));
    }

    // Explicitly check for SVG
    if (resolvedUrl.toLowerCase().endsWith('.svg')) {
      return SvgPicture.network(
        resolvedUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    // Default to Image.network for standard images
    return Image.network(
      resolvedUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
      errorBuilder:
          (context, error, stackTrace) =>
              const Center(child: Icon(Icons.error, size: 50)),
    );
  }
}
