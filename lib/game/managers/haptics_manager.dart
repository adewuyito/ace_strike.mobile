import 'package:flutter/services.dart';

/// Centralized haptic feedback manager.
/// Wraps [HapticFeedback] with an enable/disable toggle.
/// On platforms that don't support haptics (e.g., macOS), calls are silent no-ops.
class HapticsManager {
  bool enabled = true;

  /// Light tap — used for near-miss dodges.
  Future<void> lightImpact() async {
    if (!enabled) return;
    await HapticFeedback.lightImpact();
  }

  /// Medium tap — used for missile hits and level-ups.
  Future<void> mediumImpact() async {
    if (!enabled) return;
    await HapticFeedback.mediumImpact();
  }

  /// Heavy tap — used for game over.
  Future<void> heavyImpact() async {
    if (!enabled) return;
    await HapticFeedback.heavyImpact();
  }

  /// Selection click — used for powerup collection.
  Future<void> selectionClick() async {
    if (!enabled) return;
    await HapticFeedback.selectionClick();
  }
}
