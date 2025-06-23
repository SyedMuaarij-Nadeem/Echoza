
import 'package:flutter/material.dart';

class DotWaveLoader extends StatefulWidget {
  const DotWaveLoader({Key? key}) : super(key: key);

  @override
  State<DotWaveLoader> createState() => _DotWaveLoaderState();
}

class _DotWaveLoaderState extends State<DotWaveLoader> with TickerProviderStateMixin {
  final int dotCount = 5;
  final List<AnimationController> _controllers = [];
  final List<Animation<double>> _animations = [];

  final double startX = 5.0;
  final double endX = 55.0; // Adjusted to fit inside 70px width
  final double radius = 4.0;
  final Duration duration = const Duration(milliseconds: 2600);
  final List<double> opacities = [1.0, 0.8, 0.6, 0.4, 0.2];

  @override
  void initState() {
    super.initState();

    for (int i = 0; i < dotCount; i++) {
      final controller = AnimationController(vsync: this, duration: duration);

      final animation = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: startX, end: endX), weight: 1),
        TweenSequenceItem(tween: Tween(begin: endX, end: endX), weight: 1),
        TweenSequenceItem(tween: Tween(begin: endX, end: startX), weight: 1),
        TweenSequenceItem(tween: Tween(begin: startX, end: startX), weight: 1),
      ]).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

      _controllers.add(controller);
      _animations.add(animation);

      Future.delayed(Duration(milliseconds: (i * 50)), () {
        controller.repeat();
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70, // Final width as requested
      height: 30,
      child: Stack(
        children: List.generate(dotCount, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (_, __) {
              return Positioned(
                top: 10,
                left: _animations[index].value,
                child: Container(
                  width: radius * 2,
                  height: radius * 2,
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(254, 91, 84, opacities[index]),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color.fromRGBO(254, 91, 84, 1),
                      width: 1,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

