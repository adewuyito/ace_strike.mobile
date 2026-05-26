import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart' hide Image;
import 'dart:ui' show lerpDouble;

import '../../../core/constants.dart';
import '../../ace_strike_game.dart';
import 'missile_type.dart';
import '../world/explosion_component.dart';

class MissileComponent extends PositionComponent with HasGameReference<AceStrikeGame>, CollisionCallbacks {
  final MissileType type;
  Vector2 velocity;
  final bool isSubCluster; // True if this is a mini-missile spawned by a cluster split
  
  double _timeAlive = 0;
  bool _hasSplit = false;
  bool _isExploding = false; // Guard against double-explosion
  bool _nearMissFired = false; // Tracks if near-miss event has been fired for this missile
  late final double _lifetime;
  double _maxSpeed = 0.0; // Set from initial velocity in onLoad for acceleration ramp
  static const double homingDuration = 2.0;
  static const double shockwaveRadius = 80.0; // Proximity radius for chain damage
  late final Sprite _sprite;

  /// Scale trail brightness/size by proximity to the plane (0.0 = far, 1.0 = close).
  double get _trailIntensity {
    if (!isMounted) return 0.0;
    final dist = (position - game.plane.position).length;
    return (1.0 - (dist / 350.0)).clamp(0.0, 1.0);
  }

  MissileComponent({
    required this.type,
    required this.velocity,
    this.isSubCluster = false,
    super.position,
    super.size,
    super.anchor = Anchor.center,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _lifetime = GameConstants.missileMaxLifetime;
    _maxSpeed = velocity.length;
    
    // Adjust size and hitbox based on type
    if (isSubCluster) {
      size = Vector2(8, 16);
    } else {
      switch (type) {
        case MissileType.torpedo:
          size = Vector2(12, 32);
          break;
        case MissileType.cluster:
          size = Vector2(16, 28);
          break;
        case MissileType.homing:
          size = Vector2(14, 20);
          break;
        case MissileType.rocket:
          size = Vector2(10, 20);
          break;
        case MissileType.predictive:
          size = Vector2(10, 24);
          break;
      }
    }
    
    // Load missile sprite based on type
    String spritePath;
    switch (type) {
      case MissileType.rocket:
        spritePath = 'tiles/tile_0000.png';
        break;
      case MissileType.torpedo:
        spritePath = 'tiles/tile_0001.png';
        break;
      case MissileType.homing:
        spritePath = 'tiles/tile_0002.png';
        break;
      case MissileType.cluster:
        spritePath = 'tiles/tile_0003.png';
        break;
      case MissileType.predictive:
        spritePath = 'tiles/tile_0004.png';
        break;
    }
    _sprite = Sprite(game.images.fromCache(spritePath));
    
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timeAlive += dt;
    if (_timeAlive >= _lifetime) {
      _expire();
      return;
    }

    // Acceleration ramp: start slow, ease-in to full speed
    _updateSpeed(dt);

    final target = game.plane.position;
    final toTarget = target - position;
    
    // Homing/steering is active until the missile passes the player (overshoots).
    // Once it passes, it loses lock and flies straight, allowing the player to dodge it.
    final hasPassedPlayer = velocity.dot(toTarget) < 0;
    final isSteeringActive = !hasPassedPlayer;

    if (toTarget.length2 > 0 && type != MissileType.predictive && isSteeringActive) {
      // Predictive missiles travel in a straight line — no steering after launch
      final speed = velocity.length;
      final targetAngle = toTarget.screenAngle();
      final currentAngle = velocity.screenAngle();
      
      double diff = targetAngle - currentAngle;
      diff = atan2(sin(diff), cos(diff));
      
      double currentTurnSpeed;
      switch (type) {
        case MissileType.torpedo:
          currentTurnSpeed = GameConstants.planeTurnSpeed * 0.30;
          break;
        case MissileType.rocket:
          currentTurnSpeed = GameConstants.planeTurnSpeed * 0.45;
          break;
        case MissileType.homing:
          currentTurnSpeed = GameConstants.planeTurnSpeed * 0.65;
          break;
        case MissileType.cluster:
          currentTurnSpeed = GameConstants.planeTurnSpeed * 0.45;
          break;
        case MissileType.predictive:
          currentTurnSpeed = 0.0; // no steering
          break;
      }
      
      final maxRotation = currentTurnSpeed * dt;
      final rotation = diff.clamp(-maxRotation, maxRotation);
      final newAngle = currentAngle + rotation;
      
      velocity = Vector2(sin(newAngle), -cos(newAngle)) * speed;
    }

    if (type == MissileType.cluster && !_hasSplit && !isSubCluster) {
      // Check if cluster missile should split (close to plane or after 1.2 seconds)
      final distToPlane = (position - game.plane.position).length;
      if (distToPlane < game.size.x * 0.4 || _timeAlive > 1.2) {
        _triggerClusterSplit();
        return;
      }
    }

    // Point in direction of velocity
    angle = velocity.screenAngle();

    position += velocity * dt;
    
    // Shift based on plane's world velocity to simulate open-sky flight
    position -= game.plane.worldVelocity * dt;

    // Near-miss detection
    _checkNearMiss();

    // Remove if outside extended world boundary (4x screen size in each direction)
    final marginX = game.size.x * 4;
    final marginY = game.size.y * 4;
    if (position.y > game.size.y + marginY || position.y < -marginY || 
        position.x > game.size.x + marginX || position.x < -marginX) {
      removeFromParent();
    }
  }

  void _checkNearMiss() {
    if (_nearMissFired || _isExploding) return;
    final dist = (position - game.plane.position).length;
    if (dist < GameConstants.nearMissRadius) {
      _nearMissFired = true;
      game.gameManager.onNearMiss();
      game.triggerShake(
        intensity: GameConstants.shakeNearMissIntensity,
        duration: GameConstants.shakeNearMissDuration,
      );
    }
  }

  /// Ease-in acceleration: missiles start at 45% max speed, ramp to full over 1.5s.
  void _updateSpeed(double dt) {
    final t = (_timeAlive / GameConstants.missileRampDuration).clamp(0.0, 1.0);
    final eased = t * t; // ease-in curve
    final currentSpeed = lerpDouble(
      GameConstants.missileStartSpeedFactor * _maxSpeed,
      _maxSpeed,
      eased,
    )!;
    if (velocity.length2 > 0) {
      velocity = velocity.normalized() * currentSpeed;
    }
  }

  /// Distinct expiry effect when a missile's lifetime ends.
  /// Uses white sparks to visually differentiate from orange/red hit explosions.
  void _expire() {
    if (_isExploding) return;
    _isExploding = true;

    game.add(ParticleSystemComponent(
      position: position.clone(),
      particle: Particle.generate(
        count: 12,
        lifespan: 0.5,
        generator: (i) => AcceleratedParticle(
          speed: Vector2(cos(i * pi / 6) * 60, sin(i * pi / 6) * 60),
          child: CircleParticle(
            radius: 2.0,
            paint: Paint()..color = Colors.white70,
          ),
        ),
      ),
    ));

    removeFromParent();
  }

  void _triggerClusterSplit() {
    _hasSplit = true;
    
    // Split into 3 smaller fanning rockets
    final speed = velocity.length * 1.1; // Slightly faster
    
    // Angles: fanned out left, center, right
    final List<double> angles = [-0.25, 0.0, 0.25];
    
    for (final angleOffset in angles) {
      // Calculate fanned velocity
      final currentAngle = velocity.screenAngle() + angleOffset;
      // Adjust from screen angle to standard 2D vector
      final newVelocity = Vector2(sin(currentAngle), -cos(currentAngle)) * speed;
      
      final subMissile = MissileComponent(
        type: MissileType.rocket,
        velocity: newVelocity,
        isSubCluster: true,
        position: position.clone(),
      );
      
      game.add(subMissile);
    }
    
    // Remove the original cluster missile
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final flamePaint = Paint()..style = PaintingStyle.fill;
    
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    
    // Draw flame tail — scales with proximity to plane
    final ti = _trailIntensity;
    final baseFlameSize = isSubCluster ? size.y * 0.25 : size.y * 0.35;
    final flameSize = baseFlameSize + ti * baseFlameSize * 0.6;
    flamePaint.color = Color.lerp(
      Colors.orangeAccent.withAlpha(160),
      Colors.orangeAccent,
      ti,
    )!;
    canvas.drawCircle(Offset(0, size.y / 2), flameSize, flamePaint);
    flamePaint.color = Color.lerp(
      Colors.yellow.withAlpha(140),
      Colors.white,
      ti,
    )!;
    canvas.drawCircle(Offset(0, size.y / 2), flameSize * 0.6, flamePaint);

    // Draw missile sprite centered
    _sprite.render(
      canvas,
      position: Vector2(-size.x / 2, -size.y / 2),
      size: size,
    );
    
    canvas.restore();
  }

  Color _getExplosionColor() {
    if (isSubCluster) return Colors.yellowAccent;
    switch (type) {
      case MissileType.rocket:
        return Colors.yellowAccent;
      case MissileType.torpedo:
        return Colors.greenAccent;
      case MissileType.homing:
        return Colors.redAccent;
      case MissileType.cluster:
        return Colors.amberAccent;
      case MissileType.predictive:
        return Colors.cyanAccent;
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    
    // Missile-missile collision: both explode
    if (other is MissileComponent && !_isExploding && !other._isExploding) {
      explode();
      other.explode();
    }
  }

  void explode({bool fromShockwave = false}) {
    if (_isExploding) return;
    _isExploding = true;
    
    game.add(
      ExplosionComponent(
        position: position.clone(),
        color: _getExplosionColor(),
      ),
    );
    
    // Shockwave: destroy nearby missiles in close proximity
    // Only trigger shockwave from direct collisions/lifetime, not from chain reactions
    if (!fromShockwave) {
      _triggerShockwave();
    }
    
    removeFromParent();
  }

  void _triggerShockwave() {
    final nearbyMissiles = game.children
        .whereType<MissileComponent>()
        .where((m) => m != this && !m._isExploding)
        .where((m) => (m.position - position).length <= shockwaveRadius)
        .toList();
    
    for (final missile in nearbyMissiles) {
      missile.explode(fromShockwave: true);
    }
  }
}

class MissileFactory {
  final AceStrikeGame game;

  MissileFactory(this.game);

  void spawnMissile({
    required MissileType type,
    required Vector2 position,
    required Vector2 velocity,
  }) {
    final missile = MissileComponent(
      type: type,
      velocity: velocity,
      position: position,
    );
    game.add(missile);
  }
}
