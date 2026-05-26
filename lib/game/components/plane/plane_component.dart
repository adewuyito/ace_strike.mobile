import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../ace_strike_game.dart';
import '../../providers/game_providers.dart';
import '../missile/missile_component.dart';
import 'package:flame/particles.dart';
import '../effects/danger_ring.dart';

class PlaneComponent extends PositionComponent with HasGameReference<AceStrikeGame>, CollisionCallbacks {
  double heading = 0.0; // radians, 0 = up/north, increases clockwise — this is the INPUT angle
  double turnRate = 0.0; // legacy property (kept for resetGame compatibility)
  bool isBoosting = false;
  bool isInvincible = false;
  bool hasShield = false;
  double boostCharge = 1.0;
  bool isDragging = false;
  double keyboardSteerDirection = 0.0;
  double buttonSteerDirection = 0.0;
  
  // Rotation physics — momentum-based turning
  double _visualAngle = 0.0;      // what is actually rendered (lags behind heading)
  double _angularVelocity = 0.0;  // current rotational momentum
  
  double _invincibilityTimer = 0;
  double _flashTimer = 0;
  late final Sprite _sprite;

  PlaneComponent({required super.position}) : super(size: GameConstants.planeSpriteSize, anchor: Anchor.center) {
    priority = GameConstants.zPlaneBody;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Load plane sprite
    _sprite = Sprite(game.images.fromCache('ships/ship_0005.png'));

    // 70% size hitbox for forgiveness margin
    add(RectangleHitbox(
      size: size * GameConstants.planeSizeMultiplier,
      position: size * ((1 - GameConstants.planeSizeMultiplier) / 2),
    ));
    
    // Danger ring — visual proximity indicator, centered
    add(DangerRing()
      ..position = size / 2
      ..anchor = Anchor.center);
    
    // Near-miss spark effect subscription
    game.gameManager.nearMissStream.listen((_) => _playNearMissEffect());
    
    // Center initially
    position.setValues(game.size.x / 2, game.size.y / 2);
  }

  /// The velocity the plane is conceptually moving in world space,
  /// based on heading and speed. Other components drift opposite to this.
  Vector2 get worldVelocity {
    final speed = GameConstants.planeSpeed * (isBoosting ? GameConstants.planeBoostMultiplier : 1.0);
    return Vector2(sin(heading), -cos(heading)) * speed;
  }

  void steer(double deltaX) {
    // Drag steering: directly adjust the input heading
    heading += deltaX * 0.008;
  }

  /// Reset rotation state to zero (called on game reset).
  void resetRotation() {
    _visualAngle = 0.0;
    _angularVelocity = 0.0;
    angle = 0.0;
  }

  void toggleBoost() {
    if (boostCharge > 0.15) {
      isBoosting = !isBoosting;
      game.updateProvider(isBoostingProvider, isBoosting);
    }
  }

  void _updateInvincibility(double dt) {
    if (isInvincible) {
      _invincibilityTimer -= dt;
      if (_invincibilityTimer <= 0) {
        isInvincible = false;
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Lock position to the center of the screen
    position.setValues(game.size.x / 2, game.size.y / 2);
    
    _updateSteering(dt);
    _updateRotation(dt);
    _updateInvincibility(dt);

    if (isInvincible) {
      _flashTimer += dt;
    } else {
      _flashTimer = 0;
    }

    // Handle boost consumption and regeneration
    if (isBoosting) {
      boostCharge -= GameConstants.planeBoostDrainRate * dt;
      if (boostCharge <= 0) {
        boostCharge = 0;
        isBoosting = false;
        game.updateProvider(isBoostingProvider, false);
      }
    } else {
      if (boostCharge < 1.0) {
        boostCharge += GameConstants.planeBoostRegenRate * dt;
        if (boostCharge > 1.0) boostCharge = 1.0;
      }
    }
    game.updateProvider(boostChargeProvider, boostCharge);
  }

  void _updateSteering(double dt) {
    // Determine steering input (keyboard/button or drag)
    final steerDirection = keyboardSteerDirection != 0.0 ? keyboardSteerDirection : buttonSteerDirection;
    
    if (steerDirection != 0.0) {
      // Button/keyboard: rotate input heading at a fixed turn speed
      heading += steerDirection * GameConstants.planeTurnSpeed * dt;
    }
  }

  /// Momentum-based rotation: _visualAngle interpolates toward heading
  /// using angular velocity with damping.
  void _updateRotation(double dt) {
    final angleDelta = _normalizeAngle(heading - _visualAngle);
    _angularVelocity += angleDelta * GameConstants.angularAcceleration * dt;
    _angularVelocity = _angularVelocity.clamp(
      -GameConstants.maxAngularVelocity,
      GameConstants.maxAngularVelocity,
    );
    _angularVelocity *= (1.0 - GameConstants.angularDamping * dt);
    _visualAngle += _angularVelocity * dt;
  }

  /// Normalize an angle to the range [-π, π].
  static double _normalizeAngle(double a) {
    while (a > pi) a -= 2 * pi;
    while (a < -pi) a += 2 * pi;
    return a;
  }

  /// Emit a burst of cyan sparks on near-miss dodge.
  void _playNearMissEffect() {
    game.add(ParticleSystemComponent(
      position: position.clone(),
      particle: Particle.generate(
        count: 8,
        lifespan: 0.4,
        generator: (i) => AcceleratedParticle(
          acceleration: Vector2(0, 20),
          speed: Vector2(
            cos(i * pi / 4) * 120,
            sin(i * pi / 4) * 120,
          ),
          child: CircleParticle(
            radius: 2.5,
            paint: Paint()..color = const Color(0xFF00FFFF),
          ),
        ),
      ),
    ));
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    
    if (other is MissileComponent && !isInvincible) {
      // Hit-stop FIRST — freeze the world for visual weight
      game.triggerHitStop();

      if (hasShield) {
        hasShield = false;
        game.updateProvider(shieldActiveProvider, false);
        isInvincible = true;
        _invincibilityTimer = 1.0;
        game.triggerShake(
          intensity: GameConstants.shakeHitIntensity * 0.5,
          duration: GameConstants.shakeHitDuration * 0.7,
        );
        other.explode();
      } else {
        game.gameManager.onPlayerHit();
        isInvincible = true;
        _invincibilityTimer = GameConstants.planeInvincibilityDuration;
        game.triggerShake(
          intensity: GameConstants.shakeHitIntensity,
          duration: GameConstants.shakeHitDuration,
        );
        other.explode();
      }
    }
  }

  /// Draw ghost afterimages behind the plane when turning fast.
  void _renderAfterimages(Canvas canvas) {
    if (_angularVelocity.abs() < 2.0) return;
    
    final offsets = [-0.08, -0.16, -0.24];
    final alphas  = [46, 26, 13]; // ~0.18, ~0.10, ~0.05 out of 255
    
    for (int i = 0; i < 3; i++) {
      canvas.save();
      canvas.translate(size.x / 2, size.y / 2);
      canvas.rotate(_visualAngle - offsets[i] * _angularVelocity.sign);
      canvas.translate(-size.x / 2, -size.y / 2);
      
      final ghostPaint = Paint()
        ..colorFilter = ColorFilter.mode(
          AppColors.accent.withAlpha(alphas[i]),
          BlendMode.srcATop,
        );
        
      _sprite.render(canvas, size: size, overridePaint: ghostPaint);
      canvas.restore();
    }
  }

  @override
  void render(Canvas canvas) {
    if (isInvincible && (_flashTimer * 10).toInt() % 2 == 0) {
      return;
    }
    
    super.render(canvas);
    
    // Draw afterimages BEFORE the main sprite
    _renderAfterimages(canvas);
    
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    
    // Rotate by visual angle (smoothed, momentum-based)
    canvas.rotate(_visualAngle);
    
    canvas.translate(-size.x / 2, -size.y / 2);
    
    // Render the ship sprite!
    _sprite.render(
      canvas,
      size: size,
    );
    
    if (hasShield) {
      final shieldPaint = Paint()
        ..color = Colors.blue.withAlpha(77)
        ..style = PaintingStyle.fill;
        
      final shieldOutline = Paint()
        ..color = AppColors.accent.withAlpha(204)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
        
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x * 0.85, shieldPaint);
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x * 0.85, shieldOutline);
    }
    
    canvas.restore();
  }
}
