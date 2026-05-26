import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../ace_strike_game.dart';
import '../missile/missile_component.dart';

/// A visual ring around the plane that transitions from faint blue to
/// vivid red based on the distance to the nearest missile.
class DangerRing extends PositionComponent with HasGameReference<AceStrikeGame> {
  double _intensity = 0.0; // 0.0 = safe, 1.0 = critical
  double _pulseTimer = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTimer += dt;

    // Find the nearest missile distance
    double nearest = double.infinity;
    for (final component in game.children) {
      if (component is MissileComponent) {
        final dist = (component.position - game.plane.position).length;
        if (dist < nearest) nearest = dist;
      }
    }

    // Map distance to intensity
    _intensity = 1.0 - ((nearest - GameConstants.dangerRingMinDist) /
        (GameConstants.dangerRingMaxDist - GameConstants.dangerRingMinDist))
        .clamp(0.0, 1.0);
    // Squared ease curve — subtle at distance, aggressive up close
    _intensity = _intensity * _intensity;
  }

  @override
  void render(Canvas canvas) {
    if (_intensity < 0.01) return;

    // Pulse effect — subtle breathing at low intensity, faster at high
    final pulseSpeed = 2.0 + _intensity * 4.0;
    final pulse = 1.0 + sin(_pulseTimer * pulseSpeed) * 0.08 * _intensity;

    final radius = (50.0 + (1.0 - _intensity) * 80.0) * pulse;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 + _intensity * 2.0
      ..color = Color.lerp(
        const Color(0x220080FF), // calm: faint blue
        const Color(0xCCFF2200), // critical: vivid red
        _intensity,
      )!;
    canvas.drawCircle(Offset.zero, radius, paint);

    // Inner glow ring at high intensity
    if (_intensity > 0.5) {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
        ..color = Color.lerp(
          const Color(0x00FF2200),
          const Color(0x88FF2200),
          (_intensity - 0.5) * 2.0,
        )!;
      canvas.drawCircle(Offset.zero, radius * 0.95, glowPaint);
    }
  }
}
