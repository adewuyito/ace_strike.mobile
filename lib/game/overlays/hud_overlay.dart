import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_providers.dart';

class HudOverlay extends ConsumerWidget {
  const HudOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.read(gameProvider);
    final score = ref.watch(scoreProvider);
    final lives = ref.watch(livesProvider);
    final level = ref.watch(levelProvider);
    final boostCharge = ref.watch(boostChargeProvider);
    final isBoosting = ref.watch(isBoostingProvider);
    final shieldActive = ref.watch(shieldActiveProvider);
    final scoreMultiplier = ref.watch(scoreMultiplierProvider);
    final consecutiveDodges = ref.watch(consecutiveDodgesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            // Core HUD Info and Boost Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                children: [
                  // Top HUD Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Score and Level Box
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'SCORE: ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              Text(
                                '$score',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Courier',
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD600).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFFFD600).withOpacity(0.4)),
                            ),
                            child: Text(
                              'LEVEL $level',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFFFD600),
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Pause Button
                      GestureDetector(
                        onTap: () {
                          game.gameManager.pauseGame();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.15)),
                          ),
                          child: const Icon(
                            Icons.pause_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),

                      // Lives Box
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Active Shield Icon indicator
                          if (shieldActive) ...[
                            Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.blue.withOpacity(0.8)),
                              ),
                              child: const Icon(
                                Icons.shield_rounded,
                                color: Colors.lightBlueAccent,
                                size: 16,
                              ),
                            ),
                          ],
                          // Hearts list (up to 5 maximum)
                          ...List.generate(5, (index) {
                            final isFilled = index < lives;
                            return Icon(
                              isFilled ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: isFilled ? Colors.greenAccent : Colors.white.withOpacity(0.2),
                              size: 22,
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                  
                  const Spacer(),

                  // Bottom HUD: Boost Bar
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            color: isBoosting ? Colors.cyanAccent : Colors.cyan.withOpacity(0.7),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isBoosting ? 'AFTERBURNER ACTIVE' : 'AFTERBURNER CHARGE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                              color: isBoosting ? Colors.cyanAccent : Colors.white60,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      // Boost progress bar
                      Container(
                        width: 200, // Slightly narrower to give the steering buttons space
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isBoosting
                                ? Colors.cyanAccent.withOpacity(0.8)
                                : Colors.white.withOpacity(0.15),
                            width: 1.5,
                          ),
                          boxShadow: isBoosting
                              ? [
                                  BoxShadow(
                                    color: Colors.cyanAccent.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: LinearProgressIndicator(
                            value: boostCharge,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              boostCharge < 0.15
                                  ? Colors.redAccent
                                  : isBoosting
                                      ? Colors.cyanAccent
                                      : const Color(0xFF00E5FF),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // Left Steering Button
            Positioned(
              left: 20,
              bottom: 20,
              child: SteeringButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onPressedStart: () => game.plane.buttonSteerDirection = -1.0,
                onPressedEnd: () => game.plane.buttonSteerDirection = 0.0,
              ),
            ),

            // Right Steering Button
            Positioned(
              right: 20,
              bottom: 20,
              child: SteeringButton(
                icon: Icons.arrow_forward_ios_rounded,
                onPressedStart: () => game.plane.buttonSteerDirection = 1.0,
                onPressedEnd: () => game.plane.buttonSteerDirection = 0.0,
              ),
            ),

            // Combo Streak Badge
            if (consecutiveDodges >= 3)
              Positioned(
                left: 16,
                top: 90,
                child: _StreakBadge(
                  consecutiveDodges: consecutiveDodges,
                  scoreMultiplier: scoreMultiplier,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int consecutiveDodges;
  final double scoreMultiplier;

  const _StreakBadge({
    required this.consecutiveDodges,
    required this.scoreMultiplier,
  });

  bool get _isMilestone =>
      consecutiveDodges == 10 ||
      consecutiveDodges == 25 ||
      consecutiveDodges == 50;

  @override
  Widget build(BuildContext context) {
    final borderColor = _isMilestone
        ? const Color(0xFFFFD600)
        : Colors.cyanAccent.withAlpha(100);
    final textColor = _isMilestone
        ? const Color(0xFFFFD600)
        : Colors.cyanAccent;

    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(120),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: _isMilestone
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD600).withAlpha(80),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\u300C x${scoreMultiplier.toStringAsFixed(1)} \u300D',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                fontFamily: 'Courier',
                color: textColor,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$consecutiveDodges DODGES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: textColor.withAlpha(200),
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SteeringButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressedStart;
  final VoidCallback onPressedEnd;

  const SteeringButton({
    super.key,
    required this.icon,
    required this.onPressedStart,
    required this.onPressedEnd,
  });

  @override
  State<SteeringButton> createState() => _SteeringButtonState();
}

class _SteeringButtonState extends State<SteeringButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        setState(() {
          _isPressed = true;
        });
        widget.onPressedStart();
      },
      onPointerUp: (_) {
        setState(() {
          _isPressed = false;
        });
        widget.onPressedEnd();
      },
      onPointerCancel: (_) {
        setState(() {
          _isPressed = false;
        });
        widget.onPressedEnd();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isPressed
              ? Colors.cyanAccent.withOpacity(0.25)
              : Colors.white.withOpacity(0.04),
          border: Border.all(
            color: _isPressed
                ? Colors.cyanAccent.withOpacity(0.8)
                : Colors.white.withOpacity(0.12),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _isPressed
                  ? Colors.cyanAccent.withOpacity(0.4)
                  : Colors.black12,
              blurRadius: _isPressed ? 16 : 4,
              spreadRadius: _isPressed ? 3 : 0,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            widget.icon,
            color: _isPressed ? Colors.cyanAccent : Colors.white70,
            size: 26,
          ),
        ),
      ),
    );
  }
}
