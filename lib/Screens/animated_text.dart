import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class AnimatedLoadingText extends StatelessWidget {
  final List<String> loadingTexts;

  const AnimatedLoadingText({
    super.key,
    required this.loadingTexts,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 250.0,
          child: TypewriterAnimatedTextKit(
            isRepeatingAnimation: true,
            speed: const Duration(milliseconds: 200),
            onTap: () {
            },
            text: loadingTexts,
            textStyle: const TextStyle(
              fontSize: 25.0,
              color: Colors.blue,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20.0),
        const CircularProgressIndicator(
          backgroundColor: Colors.white,
        ),
      ],
    );
  }
}