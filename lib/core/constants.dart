import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class GameConstants {
  // Plane
  static const double planeSpeed = 250.0;
  static const double planeBoostMultiplier = 2.0;
  static const double planeBoostDrainRate = 0.8;
  static const double planeBoostRegenRate = 0.3;
  static const double planeInvincibilityDuration = 2.0;
  static const double planeRollSensitivity = 0.035;
  static const int planeTrailLength = 20;
  static const double planeSizeMultiplier = 0.7; // Box size relative to sprite
  static final Vector2 planeSpriteSize = Vector2(64, 64);
  
  // World rendering
  static const double backgroundParallaxSpeed = 0.15;
  static const double planeTurnSpeed = 2.0; // radians per second
  
  // Rotation physics — momentum-based turning
  static const double angularAcceleration = 30.0; // rad/s²
  static const double angularDamping = 6.0;       // drag coefficient
  static const double maxAngularVelocity = 8.0;   // rad/s cap
  
  // Z-Indexes
  static const int zBackground = 0;
  static const int zStarField = 1;
  static const int zCloudLayer = 2;
  static const int zGroundGrid = 3;
  static const int zPowerups = 4;
  static const int zMissileTrail = 5;
  static const int zMissileBody = 6;
  static const int zPlaneTrail = 7;
  static const int zPlaneBody = 8;
  static const int zExplosion = 9;
  static const int zWarningIndicator = 10;

  // ── Game Feel Constants ────────────────────────────────

  // Hit-stop
  static const int hitStopFrames = 4;

  // Screen shake presets (intensity in pixels, duration in seconds)
  static const double shakeNearMissIntensity  = 2.5;
  static const double shakeNearMissDuration   = 0.12;
  static const double shakeHitIntensity       = 6.0;
  static const double shakeHitDuration        = 0.20;
  static const double shakeGameOverIntensity  = 10.0;
  static const double shakeGameOverDuration   = 0.35;

  // Near-miss scoring
  static const double nearMissRadius  = 55.0;  // pixels
  static const int    nearMissScore   = 50;
  static const double multiplierStep  = 0.5;
  static const double maxMultiplier   = 4.0;

  // Danger ring
  static const double dangerRingMaxDist = 300.0;
  static const double dangerRingMinDist = 60.0;

  // Streak milestones
  static const Map<int, int> streakMilestoneBonuses = {
    10: 200,
    25: 500,
    50: 1500,
  };

  // Missile behavior
  static const double missileStartSpeedFactor = 0.45; // starts at 45% of max speed
  static const double missileRampDuration = 1.5;      // seconds to full speed
  static const double missileMaxLifetime = 12.0;      // seconds before expiry
  static const double predictiveLookahead = 1.8;      // seconds of prediction for predictive missiles
}

/// Defines a choreographed missile spawn pattern.
class SpawnPattern {
  final int count;
  final List<double> angleOffsets; // relative to plane heading
  final List<double> delaySeconds; // delay before each missile in the pattern
  const SpawnPattern({
    required this.count,
    required this.angleOffsets,
    required this.delaySeconds,
  });
}

// Predefined spawn patterns
const kPatternSingle   = SpawnPattern(count: 1, angleOffsets: [0],               delaySeconds: [0]);
const kPatternOpposite = SpawnPattern(count: 2, angleOffsets: [0, 3.14159],      delaySeconds: [0, 0]);
const kPatternTriangle = SpawnPattern(count: 3, angleOffsets: [0, 2.094, 4.189], delaySeconds: [0, 0, 0]);
const kPatternPincer   = SpawnPattern(count: 2, angleOffsets: [-0.524, 0.524],   delaySeconds: [0, 0.3]);

class AppColors {
  static const Color navy = Color(0xFF0D1B2A);
  static const Color blue = Color(0xFF1565C0);
  static const Color sky = Color(0xFF1E88E5);
  static const Color teal = Color(0xFF00838F);
  static const Color accent = Color(0xFF00B0FF);
  static const Color orange = Color(0xFFE65100);
  static const Color red = Color(0xFFD32F2F);
  static const Color green = Color(0xFF2E7D32);
  static const Color white = Color(0xFFFFFFFF);
  static const Color light = Color(0xFFE3F2FD);
}
