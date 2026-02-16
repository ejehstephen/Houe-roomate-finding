import 'dart:io';

import 'package:video_player/video_player.dart';
import 'package:camp_nest/core/service/auth_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MediaDisplayWidget extends StatefulWidget {
  final String? mediaUrl;
  final File? file;
  final bool isThumbnail;
  final BoxFit fit;

  const MediaDisplayWidget({
    super.key,
    this.mediaUrl,
    this.file,
    this.isThumbnail = false,
    this.fit = BoxFit.cover,
  }) : assert(
         mediaUrl != null || file != null,
         'Either mediaUrl or file must be provided',
       );

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
    if (widget.mediaUrl != oldWidget.mediaUrl ||
        widget.file != oldWidget.file ||
        widget.isThumbnail != oldWidget.isThumbnail) {
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
    if (widget.file != null) {
      final path = widget.file!.path.toLowerCase();
      if (path.endsWith('.mp4') ||
          path.endsWith('.mov') ||
          path.endsWith('.avi')) {
        try {
          _videoController = VideoPlayerController.file(widget.file!);
          await _videoController!.initialize();
          if (mounted) {
            setState(() {
              _setupControllers();
              _isInitialized = true;
            });
          }
        } catch (e) {
          if (mounted) setState(() => _isInitialized = true);
        }
      } else {
        if (mounted) setState(() => _isInitialized = true);
      }
      return;
    }

    final resolvedUrl =
        widget.mediaUrl != null && widget.mediaUrl!.startsWith('http')
            ? widget.mediaUrl!
            : '${AuthService().baseUrl}${widget.mediaUrl ?? ""}';

    // Handle Video
    if (resolvedUrl.toLowerCase().endsWith('.mp4') ||
        resolvedUrl.contains('/video/') ||
        resolvedUrl.contains('.mov') ||
        resolvedUrl.contains('.avi')) {
      try {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(resolvedUrl),
        );
        await _videoController!.initialize();

        if (mounted) {
          setState(() {
            _setupControllers();
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
      // Images/SVG
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  void _setupControllers() {
    if (_videoController == null) return;

    if (widget.isThumbnail) {
      // Just initialize, don't play
      _videoController!.setVolume(0);
    } else {
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Handle File rendering
    if (widget.file != null) {
      if (_videoController != null && _videoController!.value.isInitialized) {
        if (widget.isThumbnail) {
          return ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                FittedBox(
                  fit: widget.fit,
                  child: SizedBox(
                    width: _videoController!.value.size.width,
                    height: _videoController!.value.size.height,
                    child: VideoPlayer(_videoController!),
                  ),
                ),
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (_chewieController != null) {
          return ClipRect(
            child: FittedBox(
              fit: widget.fit,
              child: SizedBox(
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: Chewie(controller: _chewieController!),
              ),
            ),
          );
        }
        return const Center(child: Icon(Icons.videocam_off, size: 50));
      }

      // File Image
      return Image.file(
        widget.file!,
        fit: widget.fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder:
            (context, error, stackTrace) =>
                const Center(child: Icon(Icons.error, size: 50)),
      );
    }

    final resolvedUrl =
        widget.mediaUrl != null && widget.mediaUrl!.startsWith('http')
            ? widget.mediaUrl!
            : '${AuthService().baseUrl}${widget.mediaUrl ?? ""}';

    // Handle Video
    if (resolvedUrl.toLowerCase().endsWith('.mp4') ||
        resolvedUrl.contains('/video/') ||
        resolvedUrl.contains('.mov') ||
        resolvedUrl.contains('.avi')) {
      if (_videoController != null && _videoController!.value.isInitialized) {
        if (widget.isThumbnail) {
          return ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                FittedBox(
                  fit: widget.fit,
                  child: SizedBox(
                    width: _videoController!.value.size.width,
                    height: _videoController!.value.size.height,
                    child: VideoPlayer(_videoController!),
                  ),
                ),
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ClipRect(
          child: FittedBox(
            fit: widget.fit,
            child: SizedBox(
              width: _videoController!.value.size.width,
              height: _videoController!.value.size.height,
              child: Chewie(controller: _chewieController!),
            ),
          ),
        );
      }
      return const Center(child: Icon(Icons.videocam_off, size: 50));
    }

    // Handle SVG
    if (resolvedUrl.toLowerCase().endsWith('.svg')) {
      return SvgPicture.network(
        resolvedUrl,
        fit: widget.fit,
        width: double.infinity,
        height: double.infinity,
      );
    }

    // Default to Image.network
    // Default to CachedNetworkImage
    return CachedNetworkImage(
      imageUrl: resolvedUrl,
      fit: widget.fit,
      width: double.infinity,
      height: double.infinity,
      placeholder:
          (context, url) => const Center(child: CircularProgressIndicator()),
      errorWidget:
          (context, url, error) =>
              const Center(child: Icon(Icons.error, size: 50)),
      fadeInDuration: const Duration(milliseconds: 300),
    );
  }
}
