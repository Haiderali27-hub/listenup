import 'package:flutter/material.dart';

class AnimatedMicButton extends StatefulWidget {
  final bool isListening;
  final VoidCallback onTap;

  const AnimatedMicButton({
    super.key,
    required this.isListening,
    required this.onTap,
  });

  @override
  State<AnimatedMicButton> createState() => _AnimatedMicButtonState();
}

class _AnimatedMicButtonState extends State<AnimatedMicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const double minRadius = 30;
  static const double maxRadius = 80;
  static const double ringThickness = 3;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    if (widget.isListening) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedMicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isListening && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget buildRing(double progress, double phaseOffset, double opacity) {
    // progress ranges 0 to 1, phaseOffset offsets animation in time [0..1]
    final double animatedProgress = ((progress + phaseOffset) % 1);
    final double radius =
        minRadius + (maxRadius - minRadius) * animatedProgress;
    final double alpha = opacity * (1 - animatedProgress);

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
        border: Border.all(
          color: Colors.blueAccent.withOpacity(alpha),
          width: ringThickness,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: maxRadius * 2 + ringThickness * 2,
      height: maxRadius * 2 + ringThickness * 2,
      child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            final double progress = _controller.value;
            final int numberOfRings = 4;
            final double ringGap = 1 / numberOfRings;

            List<Widget> rings = List.generate(numberOfRings, (index) {
              double opacity = 0.8 - index * 0.12;
              return buildRing(
                  progress, index * ringGap, opacity.clamp(0.0, 1.0));
            });

            return Stack(
              alignment: Alignment.center,
              children: [
                if (widget.isListening) ...rings,
                GestureDetector(
                  onTap: widget.onTap,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black87,
                    ),
                    child: const Icon(Icons.mic, color: Colors.white, size: 42),
                  ),
                ),
              ],
            );
          }),
    );
  }
}
