import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../../core/constants.dart';

class ExplosionComponent extends PositionComponent {
  final double duration;
  double _timeAlive = 0;
  final List<Vector2> _particleDirections = [];
  final List<double> _particleSpeeds = [];
  final Color color;

  ExplosionComponent({
    required super.position,
    this.duration = 0.5,
    this.color = Colors.orangeAccent,
  }) : super(size: Vector2(40, 40), anchor: Anchor.center) {
    priority = GameConstants.zExplosion;
    
    // Generate random particle directions and speeds
    final random = Random();
    final int particleCount = 6 + random.nextInt(5); // 6 to 10 particles
    for (int i = 0; i < particleCount; i++) {
      final angle = random.nextDouble() * 2 * pi;
      _particleDirections.add(Vector2(cos(angle), sin(angle)));
      _particleSpeeds.add(50 + random.nextDouble() * 70); // Speeds from 50 to 120
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timeAlive += dt;
    if (_timeAlive >= duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final progress = _timeAlive / duration;
    final alpha = (1.0 - progress).clamp(0.0, 1.0);
    
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);

    // 1. Draw glowing expanding shockwave ring
    final ringPaint = Paint()
      ..color = color.withOpacity(alpha * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 + (progress * 3.5);
    final ringRadius = 4.0 + (progress * 30.0);
    canvas.drawCircle(Offset.zero, ringRadius, ringPaint);

    // 2. Draw glowing expanding/fading core
    final corePaint = Paint()
      ..color = Colors.white.withOpacity(alpha)
      ..style = PaintingStyle.fill;
    final coreRadius = max(0.0, 10.0 * (1.0 - progress));
    canvas.drawCircle(Offset.zero, coreRadius, corePaint);

    // 3. Draw flying sparks/particles
    final sparkPaint = Paint()
      ..color = color.withOpacity(alpha)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < _particleDirections.length; i++) {
      final dir = _particleDirections[i];
      final speed = _particleSpeeds[i];
      final distance = progress * speed;
      final offset = Offset(dir.x * distance, dir.y * distance);
      
      // Particles shrink as they expand
      final particleSize = max(0.5, 3.0 * (1.0 - progress));
      canvas.drawCircle(offset, particleSize, sparkPaint);
    }

    canvas.restore();
  }
}
