import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_providers.dart';

class PauseOverlay extends ConsumerWidget {
  const PauseOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.read(gameProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.55),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing Pause text
                const Text(
                  'PAUSED',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6.0,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Colors.cyanAccent, blurRadius: 15),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),

                // Resume Mission Button
                _buildMenuButton(
                  icon: Icons.play_arrow_rounded,
                  label: 'RESUME MISSION',
                  color: const Color(0xFF00E5FF),
                  onTap: () => game.gameManager.resumeGame(),
                ),

                const SizedBox(height: 16),

                // Restart Mission Button
                _buildMenuButton(
                  icon: Icons.replay_rounded,
                  label: 'RESTART MISSION',
                  color: Colors.white.withOpacity(0.9),
                  onTap: () => game.gameManager.resetGame(),
                ),

                const SizedBox(height: 16),

                // Abandon Mission Button
                _buildMenuButton(
                  icon: Icons.exit_to_app_rounded,
                  label: 'ABANDON MISSION',
                  color: Colors.redAccent,
                  onTap: () => game.gameManager.exitToMenu(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 280,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: color.withOpacity(0.35), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
