// Adapted from qr_scanner/lib/screens/dashboard_screen.dart's
// _EmbeddedExerciseVideo / _ExerciseImageCarousel, made public and trimmed
// of prescription-specific bits (feedback/mark-done aren't meaningful for a
// browsed library exercise -- see patient_app.views comment above
// patient_api_browse_regions_public).
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/exercise_library.dart';

/// Picks hosted video > step-image slideshow > plain thumbnail > "no image",
/// matching the same priority the backend itself documents.
class ExerciseHeroMedia extends StatelessWidget {
  final LibraryExercise exercise;
  final double height;

  const ExerciseHeroMedia({super.key, required this.exercise, required this.height});

  @override
  Widget build(BuildContext context) {
    if ((exercise.hostedVideoUrl ?? '').trim().isNotEmpty) {
      return EmbeddedExerciseVideo(url: exercise.hostedVideoUrl!, height: height);
    }
    if (exercise.stepImages.isNotEmpty) {
      return ExerciseImageCarousel(images: exercise.stepImages, height: height);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        height: height,
        color: Colors.grey[100],
        child: exercise.exerciseUrl != null
            ? CachedNetworkImage(
                imageUrl: exercise.exerciseUrl!,
                width: double.infinity,
                height: height,
                fit: BoxFit.contain,
                fadeInDuration: const Duration(milliseconds: 150),
                placeholder: (_, __) => Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey[400]),
                  ),
                ),
                errorWidget: (_, __, ___) => _noImage(),
              )
            : _noImage(),
      ),
    );
  }

  Widget _noImage() {
    return Container(
      height: height,
      color: Colors.grey[100],
      child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
    );
  }
}

class EmbeddedExerciseVideo extends StatefulWidget {
  final String url;
  final double height;
  const EmbeddedExerciseVideo({super.key, required this.url, required this.height});

  @override
  State<EmbeddedExerciseVideo> createState() => _EmbeddedExerciseVideoState();
}

class _EmbeddedExerciseVideoState extends State<EmbeddedExerciseVideo> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _videoController = controller;
        _chewieController = ChewieController(
          videoPlayerController: controller,
          // Never autoplay -- someone browsing the exercise library
          // shouldn't get sound/data usage they didn't ask for.
          autoPlay: false,
          looping: false,
          aspectRatio: controller.value.aspectRatio,
          materialProgressColors: ChewieProgressColors(
            playedColor: Colors.teal,
            handleColor: Colors.teal,
            bufferedColor: Colors.grey[300]!,
            backgroundColor: Colors.grey[200]!,
          ),
          placeholder: Container(color: Colors.grey[100]),
          errorBuilder: (_, __) => _errorPlaceholder(),
        );
        _loading = false;
      });
    } catch (_) {
      controller.dispose();
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Widget _errorPlaceholder() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.grey[400], size: 32),
            const SizedBox(height: 6),
            Text('Could not load video', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: double.infinity,
        height: widget.height,
        child: _loading
            ? Container(color: Colors.grey[100], child: const Center(child: CircularProgressIndicator(strokeWidth: 2)))
            : (_failed || _chewieController == null)
                ? _errorPlaceholder()
                : Chewie(controller: _chewieController!),
      ),
    );
  }
}

class ExerciseImageCarousel extends StatefulWidget {
  final List<StepImage> images;
  final double height;

  const ExerciseImageCarousel({super.key, required this.images, required this.height});

  @override
  State<ExerciseImageCarousel> createState() => _ExerciseImageCarouselState();
}

class _ExerciseImageCarouselState extends State<ExerciseImageCarousel> {
  int _currentPage = 0;
  Timer? _autoPlayTimer;
  bool _isPlaying = false;
  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      for (final img in widget.images) {
        if ((img.imageUrl ?? '').isEmpty) continue;
        precacheImage(CachedNetworkImageProvider(img.imageUrl!), context);
      }
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    super.dispose();
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
    if (_isPlaying) setState(() => _isPlaying = false);
  }

  void _togglePlay() {
    if (_isPlaying) {
      _stopAutoPlay();
      return;
    }
    setState(() {
      _isPlaying = true;
      if (_currentPage >= widget.images.length - 1) _currentPage = 0;
    });
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_currentPage >= widget.images.length - 1) {
        _stopAutoPlay();
        return;
      }
      _advance(1);
    });
  }

  void _advance(int delta) {
    setState(() {
      _currentPage = (_currentPage + delta + widget.images.length) % widget.images.length;
    });
  }

  void _onManualNavigate(int delta) {
    _stopAutoPlay();
    _advance(delta);
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    final current = images[_currentPage];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: double.infinity,
            height: widget.height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: Colors.grey[100]),
                GestureDetector(
                  onHorizontalDragEnd: (details) {
                    final velocity = details.primaryVelocity ?? 0;
                    if (velocity < -200) {
                      _onManualNavigate(1);
                    } else if (velocity > 200) {
                      _onManualNavigate(-1);
                    }
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                    child: current.imageUrl == null
                        ? Center(key: ValueKey(_currentPage), child: Icon(Icons.image_not_supported, color: Colors.grey[400]))
                        : CachedNetworkImage(
                            imageUrl: current.imageUrl!,
                            key: ValueKey(_currentPage),
                            fit: BoxFit.contain,
                            fadeInDuration: Duration.zero,
                            placeholder: (_, __) => Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey[400]),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Center(
                              child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  left: 6,
                  top: 0,
                  bottom: 0,
                  child: Center(child: _carouselButton(Icons.chevron_left, () => _onManualNavigate(-1))),
                ),
                Positioned(
                  right: 6,
                  top: 0,
                  bottom: 0,
                  child: Center(child: _carouselButton(Icons.chevron_right, () => _onManualNavigate(1))),
                ),
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: _carouselButton(_isPlaying ? Icons.pause : Icons.play_arrow, _togglePlay, small: true),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            ...List.generate(images.length, (i) {
              final isActive = i == _currentPage;
              return Container(
                margin: const EdgeInsets.only(right: 4),
                width: isActive ? 8 : 6,
                height: isActive ? 8 : 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? Colors.teal : Colors.grey[300],
                ),
              );
            }),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Step ${_currentPage + 1} of ${images.length}'
                '${(current.label != null && current.label!.trim().isNotEmpty) ? ' — ${current.label}' : ''}',
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _carouselButton(IconData icon, VoidCallback onTap, {bool small = false}) {
    final size = small ? 30.0 : 36.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.45), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: small ? 18 : 22),
      ),
    );
  }
}
