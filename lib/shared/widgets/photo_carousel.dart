import 'package:flutter/material.dart';

import '../../domain/models/profile.dart';
import 'photo_art.dart';
import 'photo_progress_bars.dart';

/// Swipeable photo pager for the profile detail, with the segmented indicator on top.
/// Tapping the left or right edge steps one photo.
class PhotoCarousel extends StatefulWidget {
  const PhotoCarousel({required this.photos, super.key});

  final List<ProfilePhoto> photos;

  @override
  State<PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<PhotoCarousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _step(int delta) {
    final next = (_index + delta).clamp(0, widget.photos.length - 1);
    if (next == _index) return;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: widget.photos.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (context, i) => PhotoArt(seed: widget.photos[i].seed),
        ),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => _step(-1),
              ),
            ),
            const Spacer(flex: 2),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => _step(1),
              ),
            ),
          ],
        ),
        Positioned(
          left: 16,
          right: 16,
          top: MediaQuery.paddingOf(context).top + 8,
          child: PhotoProgressBars(count: widget.photos.length, index: _index),
        ),
      ],
    );
  }
}
