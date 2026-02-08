import 'package:flutter/material.dart';

enum FadeSlideDirection { btt, ttb, ltr, rtl }

class FadeInSlide extends StatefulWidget {
  final Widget child;
  final double duration;
  final double delay;
  final FadeSlideDirection direction;

  const FadeInSlide({
    super.key,
    required this.child,
    this.duration = 0.6,
    this.delay = 0.0,
    this.direction = FadeSlideDirection.btt,
  });

  @override
  State<FadeInSlide> createState() => _FadeInSlideState();
}

class _FadeInSlideState extends State<FadeInSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (widget.duration * 1000).toInt()),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Offset beginOffset;
    switch (widget.direction) {
      case FadeSlideDirection.btt:
        beginOffset = const Offset(0, 0.1); // Bottom to Top
        break;
      case FadeSlideDirection.ttb:
        beginOffset = const Offset(0, -0.1); // Top to Bottom
        break;
      case FadeSlideDirection.ltr:
        beginOffset = const Offset(-0.1, 0); // Left to Right
        break;
      case FadeSlideDirection.rtl:
        beginOffset = const Offset(0.1, 0); // Right to Left
        break;
    }

    _slideAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.delay == 0) {
      _controller.forward();
    } else {
      Future.delayed(Duration(milliseconds: (widget.delay * 1000).toInt()), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}
