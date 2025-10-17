import 'package:flutter/material.dart';

class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                colorScheme.surfaceVariant,
                colorScheme.surfaceVariant.withOpacity(0.5),
                colorScheme.surfaceVariant,
              ],
              stops: [
                0.0,
                0.5 + _animation.value * 0.2,
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }
}

class TrackShimmer extends StatelessWidget {
  const TrackShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLoading(
            width: 160,
            height: 120,
            borderRadius: BorderRadius.circular(16),
          ),
          const SizedBox(height: 12),
          const ShimmerLoading(width: 140, height: 16),
          const SizedBox(height: 8),
          const ShimmerLoading(width: 100, height: 12),
        ],
      ),
    );
  }
}

class ArtistShimmer extends StatelessWidget {
  const ArtistShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          ShimmerLoading(
            width: 140,
            height: 110,
            borderRadius: BorderRadius.circular(16),
          ),
          const SizedBox(height: 12),
          const ShimmerLoading(width: 100, height: 16),
        ],
      ),
    );
  }
}
