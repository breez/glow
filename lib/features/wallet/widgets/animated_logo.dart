import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class AnimatedLogo extends StatefulWidget {
  const AnimatedLogo({super.key});

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo> with SingleTickerProviderStateMixin {
  static const Duration duration = Duration(milliseconds: 2720);
  static const int frameCount = 67;

  late AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: duration)..forward(from: 0.0);

    _animation = IntTween(begin: 0, end: frameCount).animate(_controller);

    if (_controller.isCompleted) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _animation,
      builder: (BuildContext context, Widget? child) {
        final int currentFrame = _animation.value;
        //        final String frame = currentFrame.toString().padLeft(2, '0');

        return Column(
          children: <Widget>[
            /* SizedBox(
              height: screenSize.height * 0.19,
              child: Image.asset(
                'assets/animations/wallet/frame_${frame}_delay-0.04s.png',
                gaplessPlayback: true,
                fit: BoxFit.cover,
              ),
            ), */
            AnimatedOpacity(
              opacity: currentFrame >= 44 ? _controller.value : 0.0,
              duration: const Duration(milliseconds: 400),
              child: Column(
                children: [
                  SizedBox(
                    height: screenSize.height * 0.19,
                    child: Text(
                      'Glow',
                      style: TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  AutoSizeText(
                    'TBD: Tagline Text',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 21.0, height: 1.1),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
