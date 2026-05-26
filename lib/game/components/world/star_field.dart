import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../ace_strike_game.dart';

class Star {
  Vector2 position;
  final double size;
  final double alpha;
  final double twinkleSpeed;
  double twinkleOffset;

  Star({
    required this.position,
    required this.size,
    required this.alpha,
    required this.twinkleSpeed,
    required this.twinkleOffset,
  });
}

class StarField extends PositionComponent with HasGameReference<AceStrikeGame> {
  final int count;
  final List<Star> _stars = [];
  final Random _random = Random();
  double _time = 0;

  StarField({this.count = 100}) {
    priority = GameConstants.zStarField;
  }

  @override
  void onLoad() {
    super.onLoad();
    for (int i = 0; i < count; i++) {
      _stars.add(Star(
        position: Vector2(
          _random.nextDouble() * game.size.x,
          _random.nextDouble() * game.size.y,
        ),
        size: _random.nextDouble() * 2 + 1, // 1 to 3
        alpha: _random.nextDouble() * 0.5 + 0.3, // 0.3 to 0.8
        twinkleSpeed: _random.nextDouble() * 3 + 1,
        twinkleOffset: _random.nextDouble() * pi * 2,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Heading-based 2D parallax: stars drift opposite to plane's world velocity
    final wv = game.plane.worldVelocity * GameConstants.backgroundParallaxSpeed;

    for (final star in _stars) {
      // Larger stars move slightly faster to simulate 3D depth
      final depthFactor = star.size / 3;
      star.position.x -= wv.x * depthFactor * dt;
      star.position.y -= wv.y * depthFactor * dt;

      // Wrap-around on all edges
      if (star.position.y > game.size.y) {
        star.position.y = 0;
        star.position.x = _random.nextDouble() * game.size.x;
      } else if (star.position.y < 0) {
        star.position.y = game.size.y;
        star.position.x = _random.nextDouble() * game.size.x;
      }

      if (star.position.x < 0) {
        star.position.x = game.size.x;
      } else if (star.position.x > game.size.x) {
        star.position.x = 0;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint();
    
    for (final star in _stars) {
      // Twinkle effect
      final currentAlpha = star.alpha * (0.5 + 0.5 * sin(_time * star.twinkleSpeed + star.twinkleOffset));
      paint.color = AppColors.white.withOpacity(currentAlpha.clamp(0.0, 1.0));
      
      canvas.drawCircle(star.position.toOffset(), star.size / 2, paint);
    }
  }
}
