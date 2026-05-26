# Ace Strike: Missile Dodge — Game Feel & Mechanics System Prompt

> **For the implementing agent:** You are building refinements to an existing Flutter + Flame game called **Ace Strike: Missile Dodge**. Read this document in full before writing any code. Every section contains an explicit implementation contract. Do not deviate from the patterns described. Where a section says "AGENT TASK", that is your direct instruction.

---

## Current Game State (Context)

The game is a 2D arcade missile-dodge game built with Flutter and Flame. The current implementation has:

- A **plane fixed at the center of the screen** that rotates in place
- The player controls **left/right rotation** — the plane turns `-360°` to `+360°` freely
- **Homing missiles** spawn from the edges of the screen and chase the plane
- The plane can **thrust forward** in the direction it faces to dodge
- The game loop is survival-based: avoid missiles as long as possible

You are implementing a set of targeted improvements that transform the game from functional to **refined and genuinely enjoyable**. These changes touch physics, rendering, scoring, audio triggers, and haptics.

---

## 1. Rotation Physics — Weighted, Momentum-Based Turning

### Problem
Instant rotation snapping feels like dragging a cursor, not piloting an aircraft.

### Implementation Contract

**File:** `lib/game/components/plane/plane_component.dart`

The plane's **visual rotation** must lag behind the **logical input rotation** using angular velocity with damping. The input drives a target angle; the rendered angle interpolates toward it.

```dart
// Properties to add to PlaneComponent
double _inputAngle = 0.0;       // driven directly by player input
double _visualAngle = 0.0;      // what is actually rendered
double _angularVelocity = 0.0;  // current rotational momentum

// Constants (add to core/constants.dart)
const double kAngularAcceleration = 12.0;  // rad/s² — how fast rotation builds
const double kAngularDamping = 8.0;        // drag coefficient — how fast it settles
const double kMaxAngularVelocity = 6.0;    // rad/s cap

// In update(double dt)
void _updateRotation(double dt) {
  final angleDelta = _normalizeAngle(_inputAngle - _visualAngle);
  _angularVelocity += angleDelta * kAngularAcceleration * dt;
  _angularVelocity = _angularVelocity.clamp(-kMaxAngularVelocity, kMaxAngularVelocity);
  _angularVelocity *= (1.0 - kAngularDamping * dt); // damping
  _visualAngle += _angularVelocity * dt;
  angle = _visualAngle; // Flame uses `angle` for rendering
}

double _normalizeAngle(double a) {
  while (a > pi) a -= 2 * pi;
  while (a < -pi) a += 2 * pi;
  return a;
}
```

**Afterimage / ghost frames:**
Render 3 ghost copies of the plane sprite behind the current position when `_angularVelocity.abs() > 2.0`. Each ghost is offset by `-0.08`, `-0.16`, `-0.24` radians from the current `_visualAngle` with decreasing opacity `[0.18, 0.10, 0.05]`.

```dart
// In render(Canvas canvas) — draw BEFORE the main sprite
void _renderAfterimages(Canvas canvas) {
  if (_angularVelocity.abs() < 2.0) return;
  final offsets = [-0.08, -0.16, -0.24];
  final alphas  = [0.18,  0.10,  0.05];
  for (int i = 0; i < 3; i++) {
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(_visualAngle - offsets[i] * _angularVelocity.sign);
    canvas.translate(-size.x / 2, -size.y / 2);
    _sprite.render(canvas, size: size,
      overridePaint: Paint()..color = Colors.cyanAccent.withOpacity(alphas[i]));
    canvas.restore();
  }
}
```

---

## 2. Missile Behavior — Acceleration Curve & Missile Types

### 2.1 Homing Missiles: Acceleration, Not Constant Speed

**File:** `lib/game/components/missile/missile_component.dart`

Missiles must **start slow and accelerate** toward their max speed over a configurable ramp duration. This creates an escape window at spawn time that skilled players can exploit.

```dart
// Properties
double _currentSpeed = 0.0;
double _maxSpeed = 0.0;        // set by MissileFactory based on type + level
double _rampDuration = 1.5;    // seconds to reach max speed
double _age = 0.0;

// In update(double dt)
void _updateSpeed(double dt) {
  _age += dt;
  final t = (_age / _rampDuration).clamp(0.0, 1.0);
  // Ease-in curve: slow start, fast finish
  final eased = t * t;
  _currentSpeed = lerpDouble(kMissileStartSpeedFactor * _maxSpeed, _maxSpeed, eased)!;
}
```

**Constants (core/constants.dart):**
```dart
const double kMissileStartSpeedFactor = 0.45;  // starts at 45% of max speed
const double kMissileRampDuration = 1.5;        // seconds to full speed
```

### 2.2 Predictive Missiles (New Type)

Add `MissileType.predictive` to the `MissileType` enum. A predictive missile does **not** home on the current position — it calculates where the plane **will be** based on its current velocity and fires a straight line to that point.

```dart
// In MissileFactory — configure predictive missile
Vector2 _calculatePredictiveTarget(PlaneComponent plane, Vector2 origin) {
  const double travelTime = 1.8; // seconds of prediction lookahead
  return plane.position + (plane.velocity * travelTime);
}

// Predictive missiles travel in a straight line — no steering after launch
// velocity is set once at spawn and never updated
```

**Spawn weight by level (add to DifficultyConfig):**

| Level | Homing % | Predictive % | Rocket % |
|-------|----------|--------------|----------|
| 1     | 100%     | 0%           | 0%       |
| 2     | 70%      | 30%          | 0%       |
| 3     | 50%      | 30%          | 20%      |
| 4+    | 40%      | 35%          | 25%      |

### 2.3 Missile Lifetime

Every missile must have a **maximum lifetime of 12 seconds**. After that, trigger a small explosion effect and remove the component. This prevents screen saturation and enables the stalling skill technique.

```dart
// In missile_component.dart
const double kMissileMaxLifetime = 12.0;

void update(double dt) {
  _age += dt;
  if (_age >= kMissileMaxLifetime) {
    _expire(); // plays small expiry explosion, returns to pool
    return;
  }
  // ... rest of update
}
```

### 2.4 Spawn Patterns by Level

**File:** `lib/game/managers/spawn_manager.dart`

Replace random spawning with choreographed patterns. Each `SpawnPattern` defines missile count, angular spread from a base direction, and delay between each missile.

```dart
// core/constants.dart
class SpawnPattern {
  final int count;
  final List<double> angleOffsets; // relative to plane position
  final List<double> delaySeconds;
  const SpawnPattern({
    required this.count,
    required this.angleOffsets,
    required this.delaySeconds,
  });
}

// Predefined patterns
const kPatternSingle    = SpawnPattern(count: 1, angleOffsets: [0],               delaySeconds: [0]);
const kPatternOpposite  = SpawnPattern(count: 2, angleOffsets: [0, pi],            delaySeconds: [0, 0]);
const kPatternTriangle  = SpawnPattern(count: 3, angleOffsets: [0, 2*pi/3, 4*pi/3], delaySeconds: [0, 0, 0]);
const kPatternPincer    = SpawnPattern(count: 2, angleOffsets: [-pi/6, pi/6],      delaySeconds: [0, 0.3]);
```

SpawnManager selects the pattern based on current level and fires missiles with `Future.delayed` for the offsets.

---

## 3. Close-Dodge Scoring System

### Design
If a missile passes within `kNearMissRadius` pixels of the plane **without hitting**, award bonus score and increment a multiplier. The multiplier stacks and resets on hit.

**File:** `lib/game/managers/game_manager.dart`

```dart
// Constants
const double kNearMissRadius = 55.0;  // pixels
const double kNearMissScore  = 50;
const double kMultiplierStep = 0.5;   // added per close dodge
const double kMaxMultiplier  = 4.0;

// State
double _scoreMultiplier = 1.0;
int    _consecutiveDodges = 0;

// Called from MissileComponent when it passes the plane without hitting
void onNearMiss() {
  _consecutiveDodges++;
  _scoreMultiplier = (_scoreMultiplier + kMultiplierStep).clamp(1.0, kMaxMultiplier);
  addScore(kNearMissScore.toInt());
  _nearMissController.add(NearMissEvent(multiplier: _scoreMultiplier));
}

// Called from PlaneComponent.onCollisionStart
void onHit() {
  _scoreMultiplier = 1.0;
  _consecutiveDodges = 0;
  loseLife();
}
```

**Near-miss detection in MissileComponent:**
In `update()`, after moving, check distance to plane. If distance < `kNearMissRadius` and missile has never triggered near-miss before (`_nearMissFired = false`):

```dart
void _checkNearMiss(PlaneComponent plane) {
  if (_nearMissFired) return;
  final dist = position.distanceTo(plane.position);
  if (dist < kNearMissRadius) {
    _nearMissFired = true;
    game.gameManager.onNearMiss();
    // Trigger visual + haptic feedback (see Section 5 & 6)
  }
}
```

---

## 4. Visual Feedback Systems

### 4.1 Danger Ring

**File:** `lib/game/components/effects/danger_ring.dart`

A `PositionComponent` that renders as a circle centered on the plane. Its radius and opacity are driven by the distance to the **nearest missile**.

```dart
class DangerRing extends PositionComponent with HasGameRef<AceStrikeGame> {
  double _intensity = 0.0; // 0.0 = safe, 1.0 = critical

  @override
  void update(double dt) {
    final nearest = game.world.children
        .whereType<MissileComponent>()
        .map((m) => m.position.distanceTo(game.plane.position))
        .fold(double.infinity, min);

    const double maxDist = 300.0;
    const double minDist = 60.0;
    _intensity = 1.0 - ((nearest - minDist) / (maxDist - minDist)).clamp(0.0, 1.0);
    _intensity = _intensity * _intensity; // ease curve — subtle until very close
  }

  @override
  void render(Canvas canvas) {
    if (_intensity < 0.01) return;
    final radius = 50.0 + (1.0 - _intensity) * 80.0; // shrinks as danger grows
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 + _intensity * 2.0
      ..color = Color.lerp(
        const Color(0x220080FF), // calm: faint blue
        const Color(0xCCFF2200), // critical: vivid red
        _intensity,
      )!;
    canvas.drawCircle(Offset(0, 0), radius, paint);
  }
}
```

Add `DangerRing` as a child of `PlaneComponent` so it always follows the plane position automatically.

### 4.2 Hit Stop

**File:** `lib/game/ace_strike_game.dart`

On missile collision, freeze `dt` propagation for `kHitStopFrames` game ticks before resuming. Do NOT use `paused = true` — that stops Flame's overlay system too.

```dart
// AceStrikeGame
int _hitStopFrames = 0;
const int kHitStopFrames = 4;

@override
void update(double dt) {
  if (_hitStopFrames > 0) {
    _hitStopFrames--;
    return; // skip world update entirely — creates the freeze
  }
  super.update(dt);
}

void triggerHitStop() {
  _hitStopFrames = kHitStopFrames;
}
```

Call `game.triggerHitStop()` from `PlaneComponent.onCollisionStart()` **before** the explosion effect plays.

### 4.3 Screen Shake

**File:** `lib/game/ace_strike_game.dart` (or a `CameraShake` component)

Use Flame's `CameraComponent` with a shake effect. Create a reusable method:

```dart
void triggerShake({double intensity = 4.0, double duration = 0.15}) {
  // Flame 1.18: camera.shake is available via the CameraComponent
  camera.viewfinder.add(
    ShakeEffect(
      Vector2(intensity, intensity),
      EffectController(duration: duration, curve: Curves.easeOut),
    ),
  );
}

// Shake levels
// Near miss:   intensity=2.5, duration=0.12
// Hit:         intensity=6.0, duration=0.20
// Game over:   intensity=10.0, duration=0.35
```

### 4.4 Missile Trail Intensity

**File:** `lib/game/components/missile/missile_component.dart`

Scale the trail's width and brightness by proximity to the plane:

```dart
double get _trailIntensity {
  final dist = position.distanceTo(game.plane.position);
  return (1.0 - (dist / 350.0)).clamp(0.0, 1.0);
}

// In render — trail paint
final trailPaint = Paint()
  ..color = Color.lerp(
    const Color(0x66FF4400),
    const Color(0xFFFF8800),
    _trailIntensity,
  )!
  ..strokeWidth = 2.0 + _trailIntensity * 3.0;
```

### 4.5 Near-Miss Visual Flash

When `onNearMiss()` fires, emit a short burst of 8 cyan spark particles from the plane position and briefly tint the screen edge.

```dart
// In PlaneComponent — called via GameManager stream subscription
void _playNearMissEffect() {
  // Spark burst
  add(ParticleSystemComponent(
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
```

### 4.6 Combo Streak HUD Element

**File:** `lib/game/overlays/hud_overlay.dart`

Show a streak counter that appears when `consecutiveDodges >= 3`. Animate it in from below with a slide + fade. Flash gold at milestone counts (10, 25, 50).

```dart
// In HUDOverlay widget tree
if (consecutiveDodges >= 3)
  AnimatedStreakBadge(
    count: consecutiveDodges,
    multiplier: scoreMultiplier,
  )
```

The badge displays: `「 x2.5 」 12 DODGES` — multiplier left, dodge count right, thin border, monospaced font.

---

## 5. Haptic Feedback (iOS)

**File:** `lib/game/managers/haptics_manager.dart`

```dart
import 'package:flutter/services.dart';

class HapticsManager {
  bool enabled = true;

  Future<void> lightImpact() async {
    if (!enabled) return;
    await HapticFeedback.lightImpact();
  }

  Future<void> mediumImpact() async {
    if (!enabled) return;
    await HapticFeedback.mediumImpact();
  }

  Future<void> heavyImpact() async {
    if (!enabled) return;
    await HapticFeedback.heavyImpact();
  }

  Future<void> selectionClick() async {
    if (!enabled) return;
    await HapticFeedback.selectionClick();
  }
}
```

**Trigger map:**

| Event               | Haptic Type     | Called From                          |
|---------------------|-----------------|--------------------------------------|
| Near miss           | `lightImpact`   | `GameManager.onNearMiss()`           |
| Missile hits plane  | `mediumImpact`  | `PlaneComponent.onCollisionStart()`  |
| Game over           | `heavyImpact`   | `GameManager.transitionTo(dead)`     |
| Powerup collected   | `selectionClick`| `PlaneComponent.onCollisionStart()`  |
| Level up            | `mediumImpact`  | `GameManager.transitionTo(levelUp)`  |

Respect the `haptics_enabled` SharedPreferences key loaded into `HapticsManager.enabled` at init.

---

## 6. Combo Streak — Score Architecture

**File:** `lib/game/managers/game_manager.dart`

Add streak-based score events with milestone thresholds:

```dart
const Map<int, int> kStreakMilestoneBonuses = {
  10: 200,
  25: 500,
  50: 1500,
};

void onNearMiss() {
  _consecutiveDodges++;
  _scoreMultiplier = (_scoreMultiplier + kMultiplierStep).clamp(1.0, kMaxMultiplier);
  addScore((kNearMissScore * _scoreMultiplier).toInt());

  // Milestone bonus
  final bonus = kStreakMilestoneBonuses[_consecutiveDodges];
  if (bonus != null) {
    addScore(bonus);
    _milestoneController.add(MilestoneEvent(
      dodges: _consecutiveDodges,
      bonus: bonus,
    ));
    game.triggerShake(intensity: 3.0, duration: 0.1);
  }

  _nearMissController.add(NearMissEvent(multiplier: _scoreMultiplier));
}
```

---

## 7. Missile Expiry Visual

When a missile reaches `kMissileMaxLifetime`, play a distinct **expiry effect** that is visually different from a hit explosion — use white sparks rather than orange, smaller radius, no screen shake. This trains the player to read expiry vs. hit feedback.

```dart
// In missile_component.dart
void _expire() {
  game.world.add(ParticleSystemComponent(
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
  removeFromParent(); // or return to pool
}
```

---

## 8. Integration Checklist

The integrating agent must verify every item below before marking the task complete:

- [ ] `PlaneComponent._visualAngle` is what gets passed to `angle` — not raw input angle
- [ ] Afterimages only render when `_angularVelocity.abs() > 2.0`
- [ ] Missiles start at 45% speed and ramp over 1.5s — verified with a debug overlay
- [ ] `MissileType.predictive` added to enum, factory, and spawn weight table
- [ ] Every missile is removed (or pooled) after 12 seconds
- [ ] `SpawnPattern` constants exist in `core/constants.dart` and are used by `SpawnManager`
- [ ] `DangerRing` is a child of `PlaneComponent`, not a separate world component
- [ ] `triggerHitStop()` is called **before** `addExplosion()` on collision
- [ ] `triggerShake()` uses `CameraComponent` — not a manual position offset
- [ ] Trail intensity scales with distance to plane — verified visually
- [ ] `HapticsManager` reads `haptics_enabled` from SharedPreferences on init
- [ ] `HapticsManager` is a singleton accessed via `game.hapticsManager`
- [ ] Near-miss spark particles fire from plane world position (not screen position)
- [ ] Streak badge only visible when `consecutiveDodges >= 3`
- [ ] Milestone bonuses fire `MilestoneEvent` on the stream (HUD listens and shows popup)
- [ ] Expiry explosion uses white sparks; hit explosion uses orange/red — never swapped
- [ ] All new constants live in `core/constants.dart` — no magic numbers in component files
- [ ] All new public methods have dartdoc comments
- [ ] `fvm flutter analyze --fatal-infos` passes with zero warnings

---

## 9. Constants Reference

All constants introduced by this system prompt. Add to `lib/core/constants.dart`:

```dart
// Rotation physics
const double kAngularAcceleration  = 12.0;
const double kAngularDamping        = 8.0;
const double kMaxAngularVelocity    = 6.0;

// Missile behavior
const double kMissileStartSpeedFactor = 0.45;
const double kMissileRampDuration     = 1.5;
const double kMissileMaxLifetime      = 12.0;

// Near-miss / scoring
const double kNearMissRadius  = 55.0;
const int    kNearMissScore   = 50;
const double kMultiplierStep  = 0.5;
const double kMaxMultiplier   = 4.0;

// Hit stop
const int kHitStopFrames = 4;

// Camera shake presets
const double kShakeNearMissIntensity  = 2.5;
const double kShakeNearMissDuration   = 0.12;
const double kShakeHitIntensity       = 6.0;
const double kShakeHitDuration        = 0.20;
const double kShakeGameOverIntensity  = 10.0;
const double kShakeGameOverDuration   = 0.35;

// Danger ring
const double kDangerRingMaxDist = 300.0;
const double kDangerRingMinDist = 60.0;

// Streak milestones
const Map<int, int> kStreakMilestoneBonuses = {
  10: 200,
  25: 500,
  50: 1500,
};
```

---

*Ace Strike: Missile Dodge — Game Feel System Prompt v1.0 · Flutter + Flame*
