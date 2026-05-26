import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'components/world/background_component.dart';
import 'components/world/star_field.dart';
import 'components/plane/plane_component.dart';
import 'managers/game_manager.dart';
import 'managers/spawn_manager.dart';
import 'managers/haptics_manager.dart';
import '../core/constants.dart';

class AceStrikeGame extends FlameGame with HasCollisionDetection, DoubleTapCallbacks, DragCallbacks, KeyboardEvents {
  late final ProviderContainer container;
  late final PlaneComponent plane;
  late final GameManager gameManager;
  final HapticsManager hapticsManager = HapticsManager();

  // ── Hit-Stop ──
  int _hitStopFrames = 0;

  // ── Screen Shake ──
  Vector2 _shakeOffset = Vector2.zero();
  double _shakeIntensity = 0;
  double _shakeDuration = 0;
  double _shakeTimer = 0;

  AceStrikeGame(this.container);

  void updateProvider<T>(StateProvider<T> provider, T value) {
    Future.microtask(() {
      container.read(provider.notifier).state = value;
    });
  }

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Preload sprites
    await images.loadAll([
      'ships/ship_0005.png',
      'tiles/tile_0000.png',
      'tiles/tile_0001.png',
      'tiles/tile_0002.png',
      'tiles/tile_0003.png',
      'tiles/tile_0004.png',
      'tiles/tile_0010.png',
      'tiles/tile_0011.png',
      'tiles/tile_0012.png',
    ]);
    
    // Add Managers
    gameManager = GameManager();
    add(gameManager);
    add(SpawnManager());
    
    // Start at main menu for Phase 3
    gameManager.transitionTo(GameState.menu);

    // Add world components
    add(BackgroundComponent());
    add(StarField());

    // Add plane (initially placed at center by component)
    plane = PlaneComponent(
      position: Vector2(size.x / 2, size.y / 2),
    );
    add(plane);
  }

  @override
  void update(double dt) {
    if (_hitStopFrames > 0) {
      _hitStopFrames--;
      return; // freeze world for one tick
    }
    super.update(dt);
    _updateShake(dt);
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(_shakeOffset.x, _shakeOffset.y);
    super.render(canvas);
    canvas.restore();
  }

  /// Freeze the game for [GameConstants.hitStopFrames] ticks.
  void triggerHitStop() {
    _hitStopFrames = GameConstants.hitStopFrames;
  }

  /// Trigger a screen shake effect.
  void triggerShake({double intensity = 4.0, double duration = 0.15}) {
    _shakeIntensity = intensity;
    _shakeDuration = duration;
    _shakeTimer = 0;
  }

  void _updateShake(double dt) {
    if (_shakeDuration <= 0) return;
    _shakeTimer += dt;
    if (_shakeTimer >= _shakeDuration) {
      _shakeDuration = 0;
      _shakeOffset = Vector2.zero();
      return;
    }
    final progress = _shakeTimer / _shakeDuration;
    final decay = 1.0 - progress;
    final offsetX = sin(_shakeTimer * 60) * _shakeIntensity * decay;
    final offsetY = cos(_shakeTimer * 45) * _shakeIntensity * decay;
    _shakeOffset = Vector2(offsetX, offsetY);
  }

  @override
  void onDoubleTapDown(DoubleTapDownEvent event) {
    if (gameManager.state == GameState.playing) {
      plane.toggleBoost();
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (gameManager.state == GameState.playing) {
      plane.isDragging = true;
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (gameManager.state == GameState.playing) {
      plane.steer(event.localDelta.x);
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (gameManager.state == GameState.playing) {
      plane.isDragging = false;
    }
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    if (gameManager.state == GameState.playing) {
      plane.isDragging = false;
    }
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (gameManager.state == GameState.playing) {
      final isLeftPressed = keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
          keysPressed.contains(LogicalKeyboardKey.keyA);
      final isRightPressed = keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
          keysPressed.contains(LogicalKeyboardKey.keyD);

      if (isLeftPressed && !isRightPressed) {
        plane.keyboardSteerDirection = -1.0;
      } else if (isRightPressed && !isLeftPressed) {
        plane.keyboardSteerDirection = 1.0;
      } else {
        plane.keyboardSteerDirection = 0.0;
      }
    } else {
      plane.keyboardSteerDirection = 0.0;
    }
    return super.onKeyEvent(event, keysPressed);
  }
}
