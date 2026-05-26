import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_providers.dart';

class MainMenuOverlay extends ConsumerWidget {
  const MainMenuOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.read(gameProvider);
    final hiScore = ref.watch(hiScoreProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.4),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  
                  // Neon Glowing Title
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF00B0FF), Color(0xFF00E5FF), Color(0xFF00E676)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: const Text(
                      'ACE STRIKE',
                      style: TextStyle(
                        fontSize: 54,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4.0,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: Color(0xFF00B0FF), blurRadius: 15, offset: Offset(0, 0)),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 5),
                  
                  const Text(
                    'MISSILE DODGE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 6.0,
                      color: Colors.redAccent,
                    ),
                  ),
                  
                  const Spacer(),

                  // High Score Display Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'BEST RECORD',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$hiScore pts',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: Colors.white,
                            fontFamily: 'Courier', // Retro feel
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Start Game Button with hover/scale feedback
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        game.gameManager.resetGame();
                      },
                      borderRadius: BorderRadius.circular(30),
                      splashColor: const Color(0xFF00E5FF).withOpacity(0.3),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00B0FF), Color(0xFF00838F)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00B0FF).withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                              SizedBox(width: 8),
                              Text(
                                'START MISSION',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.0,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Game Controls Panel (Glassmorphic)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PILOT INSTRUCTIONS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.0,
                            color: Color(0xFF00B0FF),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInstructionRow(
                          Icons.drag_indicator_rounded,
                          'NAVIGATION',
                          'Drag your finger anywhere to maneuver the fighter jet.',
                        ),
                        const SizedBox(height: 10),
                        _buildInstructionRow(
                          Icons.bolt_rounded,
                          'AFTERBURNER BOOST',
                          'Double-tap screen to boost speed. Drains energy meter.',
                        ),
                        const SizedBox(height: 10),
                        _buildInstructionRow(
                          Icons.stars_rounded,
                          'TACTICAL ITEMS',
                          'Collect Green Hearts (+Life), Blue Shields, and Cyan Chargers.',
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionRow(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.7), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.6),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
