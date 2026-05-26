import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../ace_strike_game.dart';

class BackgroundComponent extends PositionComponent with HasGameReference<AceStrikeGame> {
  BackgroundComponent() {
    priority = GameConstants.zBackground;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.navy,
          Color(0xFF0A101C), // Deep blue/black
        ],
      ).createShader(Rect.fromLTWH(0, 0, game.size.x, game.size.y));

    canvas.drawRect(Rect.fromLTWH(0, 0, game.size.x, game.size.y), paint);
  }
}
