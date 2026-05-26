import 'dart:async';
import '../../core/constants.dart';
import 'package:flame/components.dart';
import '../ace_strike_game.dart';
import '../providers/game_providers.dart';
import '../components/missile/missile_component.dart';
import '../components/powerup/powerup_component.dart';

enum GameState { menu, playing, paused, dead, levelUp }

class GameManager extends Component with HasGameReference<AceStrikeGame> {
  GameState state = GameState.menu;
  
  int _score = 0;
  int _hiScore = 0;
  int _lives = 3;
  int _level = 1;
  double _scoreAccumulator = 0;

  final _scoreController = StreamController<int>.broadcast();
  final _livesController = StreamController<int>.broadcast();
  final _levelController = StreamController<int>.broadcast();

  Stream<int> get scoreStream => _scoreController.stream;
  Stream<int> get livesStream => _livesController.stream;
  Stream<int> get levelStream => _levelController.stream;

  // ── Near-Miss / Streak State ──
  double _scoreMultiplier = 1.0;
  int _consecutiveDodges = 0;

  final _nearMissController = StreamController<NearMissEvent>.broadcast();
  Stream<NearMissEvent> get nearMissStream => _nearMissController.stream;

  double get scoreMultiplier => _scoreMultiplier;
  int get consecutiveDodges => _consecutiveDodges;

  int get score => _score;
  int get lives => _lives;
  int get level => _level;

  void transitionTo(GameState next) {
    state = next;
    
    // Sync with Riverpod
    game.updateProvider(gameStateProvider, next);
    
    // Handle Overlay activation and engine running
    switch (next) {
      case GameState.menu:
        game.overlays.add('MainMenu');
        game.overlays.remove('HUD');
        game.overlays.remove('PauseMenu');
        game.overlays.remove('GameOver');
        break;
      case GameState.playing:
        game.overlays.remove('MainMenu');
        game.overlays.add('HUD');
        game.overlays.remove('PauseMenu');
        game.overlays.remove('GameOver');
        game.resumeEngine();
        break;
      case GameState.paused:
        game.overlays.add('PauseMenu');
        game.pauseEngine();
        break;
      case GameState.dead:
        game.overlays.remove('HUD');
        game.overlays.add('GameOver');
        game.triggerShake(
          intensity: GameConstants.shakeGameOverIntensity,
          duration: GameConstants.shakeGameOverDuration,
        );
        break;
      case GameState.levelUp:
        game.hapticsManager.mediumImpact();
        // Temporary state, auto-reverts back to playing after 1s
        Future.delayed(const Duration(seconds: 1), () {
          if (state == GameState.levelUp) {
            transitionTo(GameState.playing);
          }
        });
        break;
    }
  }

  void addScore(int delta) {
    _score += delta;
    _scoreController.add(_score);
    game.updateProvider(scoreProvider, _score);
    
    if (_score > _hiScore) {
      _hiScore = _score;
      game.updateProvider(hiScoreProvider, _hiScore);
    }
  }

  void loseLife() {
    _lives--;
    _livesController.add(_lives);
    game.updateProvider(livesProvider, _lives);
    
    if (_lives <= 0) {
      game.hapticsManager.heavyImpact();
      transitionTo(GameState.dead);
    }
  }

  void gainLife() {
    if (_lives < 5) {
      _lives++;
      _livesController.add(_lives);
      game.updateProvider(livesProvider, _lives);
    }
  }

  /// Called when a missile passes close to the plane without hitting.
  void onNearMiss() {
    _consecutiveDodges++;
    _scoreMultiplier = (_scoreMultiplier + GameConstants.multiplierStep)
        .clamp(1.0, GameConstants.maxMultiplier);
    addScore((GameConstants.nearMissScore * _scoreMultiplier).toInt());

    // Milestone bonus
    final bonus = GameConstants.streakMilestoneBonuses[_consecutiveDodges];
    if (bonus != null) {
      addScore(bonus);
      game.triggerShake(intensity: 3.0, duration: 0.1);
    }

    // Sync to Riverpod
    game.updateProvider(scoreMultiplierProvider, _scoreMultiplier);
    game.updateProvider(consecutiveDodgesProvider, _consecutiveDodges);

    _nearMissController.add(NearMissEvent(
      multiplier: _scoreMultiplier,
      consecutiveDodges: _consecutiveDodges,
    ));

    // Haptic feedback
    game.hapticsManager.lightImpact();
  }

  /// Reset streak on player hit. Call instead of loseLife() from plane collision.
  void onPlayerHit() {
    _scoreMultiplier = 1.0;
    _consecutiveDodges = 0;
    game.updateProvider(scoreMultiplierProvider, _scoreMultiplier);
    game.updateProvider(consecutiveDodgesProvider, _consecutiveDodges);
    game.hapticsManager.mediumImpact();
    loseLife();
  }
  
  void setLevel(int newLevel) {
    if (_level != newLevel) {
      _level = newLevel;
      _levelController.add(_level);
      game.updateProvider(levelProvider, _level);
      transitionTo(GameState.levelUp);
    }
  }

  void pauseGame() {
    if (state == GameState.playing) {
      transitionTo(GameState.paused);
    }
  }

  void resumeGame() {
    if (state == GameState.paused) {
      transitionTo(GameState.playing);
    }
  }

  void exitToMenu() {
    transitionTo(GameState.menu);
  }

  void resetGame() {
    _score = 0;
    _lives = 3;
    _level = 1;
    _scoreAccumulator = 0;
    _scoreMultiplier = 1.0;
    _consecutiveDodges = 0;
    
    _scoreController.add(_score);
    _livesController.add(_lives);
    _levelController.add(_level);
    
    // Sync with Riverpod
    game.updateProvider(scoreProvider, _score);
    game.updateProvider(livesProvider, _lives);
    game.updateProvider(levelProvider, _level);
    game.updateProvider(boostChargeProvider, 1.0);
    game.updateProvider(isBoostingProvider, false);
    game.updateProvider(shieldActiveProvider, false);
    game.updateProvider(scoreMultiplierProvider, 1.0);
    game.updateProvider(consecutiveDodgesProvider, 0);

    // Reset plane position and states
    game.plane.position = Vector2(game.size.x / 2, game.size.y / 2);
    game.plane.heading = 0.0;
    game.plane.resetRotation();
    game.plane.turnRate = 0.0;
    game.plane.isDragging = false;
    game.plane.keyboardSteerDirection = 0.0;
    game.plane.buttonSteerDirection = 0.0;
    game.plane.isBoosting = false;
    game.plane.isInvincible = false;
    game.plane.hasShield = false;
    game.plane.boostCharge = 1.0;

    // Remove all active gameplay entities
    final missiles = game.children.whereType<MissileComponent>().toList();
    final worldMissiles = game.world.children.whereType<MissileComponent>().toList();
    final powerups = game.children.whereType<PowerupComponent>().toList();
    final worldPowerups = game.world.children.whereType<PowerupComponent>().toList();

    for (final m in missiles) { m.removeFromParent(); }
    for (final wm in worldMissiles) { wm.removeFromParent(); }
    for (final p in powerups) { p.removeFromParent(); }
    for (final wp in worldPowerups) { wp.removeFromParent(); }

    transitionTo(GameState.playing);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (state == GameState.playing) {
      _scoreAccumulator += dt;
      if (_scoreAccumulator >= 0.1) {
        _scoreAccumulator -= 0.1;
        addScore(1); // 10 points per second
      }
    }
  }

  @override
  void onRemove() {
    _scoreController.close();
    _livesController.close();
    _levelController.close();
    _nearMissController.close();
    super.onRemove();
  }
}

/// Event emitted when a near-miss dodge occurs.
class NearMissEvent {
  final double multiplier;
  final int consecutiveDodges;
  const NearMissEvent({required this.multiplier, required this.consecutiveDodges});
}
