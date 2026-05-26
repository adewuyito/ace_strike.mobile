import 'dart:math';
import 'package:flame/components.dart';
import '../ace_strike_game.dart';
import 'game_manager.dart';
import 'difficulty_manager.dart';
import '../../core/constants.dart';
import '../components/missile/missile_component.dart';
import '../components/missile/missile_type.dart';
import '../components/powerup/powerup_component.dart';

class SpawnManager extends Component with HasGameReference<AceStrikeGame> {
  double _missileTimer = 0;
  double _powerupTimer = 0;
  final Random _random = Random();
  
  // Powerups spawn every 12 seconds
  static const double powerupInterval = 12.0;

  // Spawn patterns by level (higher levels get more complex patterns)
  static const List<SpawnPattern> _earlyPatterns = [
    kPatternSingle,
    kPatternSingle,
    kPatternSingle,
  ];
  
  static const List<SpawnPattern> _midPatterns = [
    kPatternSingle,
    kPatternSingle,
    kPatternOpposite,
    kPatternPincer,
  ];

  static const List<SpawnPattern> _latePatterns = [
    kPatternSingle,
    kPatternOpposite,
    kPatternPincer,
    kPatternTriangle,
  ];

  @override
  void update(double dt) {
    super.update(dt);
    
    // Only spawn during playing state
    if (game.gameManager.state != GameState.playing) {
      return;
    }

    final score = game.gameManager.score;
    final config = DifficultyManager.getDifficulty(score);

    // Update game level if needed
    if (game.gameManager.level != config.level) {
      game.gameManager.setLevel(config.level);
    }

    // Missile spawning
    _missileTimer += dt;
    if (_missileTimer >= config.spawnInterval) {
      _missileTimer = 0;
      _spawnPattern();
    }

    // Powerup spawning
    _powerupTimer += dt;
    if (_powerupTimer >= powerupInterval) {
      _powerupTimer = 0;
      _spawnPowerup();
    }
  }

  /// Pick a random spawn position just outside one of the 4 screen edges.
  Vector2 _randomEdgePosition() {
    final screenWidth = game.size.x;
    final screenHeight = game.size.y;
    final edge = _random.nextInt(4); // 0=top, 1=bottom, 2=left, 3=right

    switch (edge) {
      case 0: // top
        return Vector2(_random.nextDouble() * screenWidth, -40);
      case 1: // bottom
        return Vector2(_random.nextDouble() * screenWidth, screenHeight + 40);
      case 2: // left
        return Vector2(-40, _random.nextDouble() * screenHeight);
      case 3: // right
        return Vector2(screenWidth + 40, _random.nextDouble() * screenHeight);
      default:
        return Vector2(_random.nextDouble() * screenWidth, -40);
    }
  }

  /// Spawn a position at a specific angle from the plane, just off-screen.
  Vector2 _edgePositionAtAngle(double angle) {
    final screenWidth = game.size.x;
    final screenHeight = game.size.y;
    final cx = screenWidth / 2;
    final cy = screenHeight / 2;
    // Push spawn point well beyond the screen edge
    final dist = max(screenWidth, screenHeight) * 0.7;
    return Vector2(
      cx + sin(angle) * dist,
      cy - cos(angle) * dist,
    );
  }

  /// Select and execute a spawn pattern based on current level.
  void _spawnPattern() {
    final level = game.gameManager.level;
    final List<SpawnPattern> patterns;
    
    if (level <= 2) {
      patterns = _earlyPatterns;
    } else if (level <= 3) {
      patterns = _midPatterns;
    } else {
      patterns = _latePatterns;
    }
    
    final pattern = patterns[_random.nextInt(patterns.length)];
    
    // Base angle: a random direction from the plane
    final baseAngle = _random.nextDouble() * 2 * pi;
    
    for (int i = 0; i < pattern.count; i++) {
      final delay = pattern.delaySeconds[i];
      final angle = baseAngle + pattern.angleOffsets[i];
      
      if (delay <= 0) {
        _spawnMissileAtAngle(angle);
      } else {
        // Delayed spawn for staggered patterns
        Future.delayed(Duration(milliseconds: (delay * 1000).toInt()), () {
          if (game.gameManager.state == GameState.playing) {
            _spawnMissileAtAngle(angle);
          }
        });
      }
    }
  }

  /// Spawn a single missile at a given angle from the plane.
  void _spawnMissileAtAngle(double angle) {
    final type = _pickMissileType();
    final spawnPosition = _edgePositionAtAngle(angle);
    final speed = _getSpeedForType(type);
    
    Vector2 velocity;
    if (type == MissileType.predictive) {
      // Predictive: aim at where the plane WILL be, not where it IS
      final predictedTarget = game.plane.position +
          (game.plane.worldVelocity * GameConstants.predictiveLookahead);
      final direction = (predictedTarget - spawnPosition).normalized();
      velocity = direction * speed;
    } else {
      // All other types: aim at current plane position
      final target = game.plane.position;
      final direction = (target - spawnPosition).normalized();
      velocity = direction * speed;
    }

    game.add(
      MissileComponent(
        type: type,
        position: spawnPosition,
        velocity: velocity,
      ),
    );
  }

  MissileType _pickMissileType() {
    final level = game.gameManager.level;
    final double rand = _random.nextDouble();

    // Spawn weights by level (from system prompt §2.2)
    if (level == 1) {
      // 70% rocket, 20% homing, 10% predictive
      if (rand < 0.70) return MissileType.rocket;
      if (rand < 0.90) return MissileType.homing;
      return MissileType.predictive;
    } else if (level == 2) {
      // 45% rocket, 20% homing, 15% torpedo, 20% predictive
      if (rand < 0.45) return MissileType.rocket;
      if (rand < 0.65) return MissileType.homing;
      if (rand < 0.80) return MissileType.torpedo;
      return MissileType.predictive;
    } else {
      // Level 3, 4, 5
      // 30% rocket, 20% homing, 15% torpedo, 10% cluster, 25% predictive
      if (rand < 0.30) return MissileType.rocket;
      if (rand < 0.50) return MissileType.homing;
      if (rand < 0.65) return MissileType.torpedo;
      if (rand < 0.75) return MissileType.cluster;
      return MissileType.predictive;
    }
  }

  double _getSpeedForType(MissileType type) {
    switch (type) {
      case MissileType.rocket:
        return GameConstants.planeSpeed * 1.15;
      case MissileType.homing:
        return GameConstants.planeSpeed * 1.10;
      case MissileType.torpedo:
        return GameConstants.planeSpeed * 1.20;
      case MissileType.cluster:
        return GameConstants.planeSpeed * 1.12;
      case MissileType.predictive:
        return GameConstants.planeSpeed * 1.25; // fastest — compensates for no steering
    }
  }

  void _spawnPowerup() {
    // Choose powerup type randomly (with weights)
    final double rand = _random.nextDouble();
    PowerupType type;
    
    if (rand < 0.4) {
      type = PowerupType.boost;
    } else if (rand < 0.7) {
      type = PowerupType.shield;
    } else {
      // Only spawn life if current lives is less than maximum of 5, otherwise give shield
      if (game.gameManager.lives < 5) {
        type = PowerupType.life;
      } else {
        type = PowerupType.shield;
      }
    }
    
    // Spawn from a random screen edge
    final spawnPosition = _randomEdgePosition();
    
    // Drift gently toward center
    final target = game.plane.position;
    final direction = (target - spawnPosition).normalized();
    final velocity = direction * 110.0;

    game.add(
      PowerupComponent(
        type: type,
        position: spawnPosition,
        velocity: velocity,
        size: Vector2(30, 30),
      ),
    );
  }
}
