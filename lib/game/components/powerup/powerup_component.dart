import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../ace_strike_game.dart';
import '../plane/plane_component.dart';
import '../../providers/game_providers.dart';

enum PowerupType { life, boost, shield }

class PowerupComponent extends PositionComponent with HasGameReference<AceStrikeGame>, CollisionCallbacks {
  final PowerupType type;
  final Vector2 velocity;
  double _time = 0;
  late final Sprite _sprite;
  
  PowerupComponent({
    required this.type,
    required this.velocity,
    super.position,
    super.size,
  }) : super(anchor: Anchor.center) {
    priority = GameConstants.zPowerups;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Load powerup sprite
    String spritePath;
    switch (type) {
      case PowerupType.life:
        spritePath = 'tiles/tile_0011.png';
        break;
      case PowerupType.boost:
        spritePath = 'tiles/tile_0012.png';
        break;
      case PowerupType.shield:
        spritePath = 'tiles/tile_0010.png';
        break;
    }
    _sprite = Sprite(game.images.fromCache(spritePath));
    
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    
    // Smooth velocity + subtle side-to-side drift + heading-based world scrolling
    position += velocity * dt;
    position.x += sin(_time * 2.5) * 40 * dt; // Gentle horizontal wave
    position -= game.plane.worldVelocity * dt;

    // Remove if outside extended world boundary (4x screen size in each direction)
    final marginX = game.size.x * 4;
    final marginY = game.size.y * 4;
    if (position.y > game.size.y + marginY || position.y < -marginY ||
        position.x > game.size.x + marginX || position.x < -marginX) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    
    if (other is PlaneComponent) {
      switch (type) {
        case PowerupType.life:
          game.gameManager.gainLife();
          break;
        case PowerupType.boost:
          other.boostCharge = 1.0;
          game.updateProvider(boostChargeProvider, 1.0);
          break;
        case PowerupType.shield:
          other.hasShield = true;
          game.updateProvider(shieldActiveProvider, true);
          break;
      }
      game.hapticsManager.selectionClick();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final radius = size.x / 2;
    final center = Offset(radius, size.y / 2);
    
    // Draw neon glowing aura
    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      
    final Color iconColor;
    switch (type) {
      case PowerupType.life:
        glowPaint.color = Colors.green.withOpacity(0.4);
        iconColor = AppColors.green;
        break;
      case PowerupType.boost:
        glowPaint.color = Colors.cyan.withOpacity(0.4);
        iconColor = AppColors.accent;
        break;
      case PowerupType.shield:
        glowPaint.color = Colors.blue.withOpacity(0.4);
        iconColor = Colors.blue;
        break;
    }
    
    // Render the glow aura
    canvas.drawCircle(center, radius * 1.3, glowPaint);
    
    // Render outer ring
    final ringPaint = Paint()
      ..color = iconColor.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, ringPaint);

    // Render powerup sprite!
    _sprite.render(
      canvas,
      size: size,
    );
  }
}
