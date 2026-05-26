import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_providers.dart';

class GameOverOverlay extends ConsumerWidget {
  const GameOverOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.read(gameProvider);
    final score = ref.watch(scoreProvider);
    final hiScore = ref.watch(hiScoreProvider);
    final level = ref.watch(levelProvider);
    
    final isNewHiScore = score >= hiScore && score > 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.65),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Mission Failed Glowing Header
                  const Text(
                    'MISSION FAILED',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4.0,
                      color: Colors.redAccent,
                      shadows: [
                        Shadow(color: Colors.red, blurRadius: 18),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'YOUR JET WAS DESTROYED IN COMBAT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2.0,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),

                  const Spacer(),

                  // Glassmorphic Stats Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 36),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        // Final score
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'FINAL SCORE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white60,
                                letterSpacing: 1.0,
                              ),
                            ),
                            Text(
                              '$score pts',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Courier',
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        
                        const Divider(color: Colors.white10, height: 24),
                        
                        // Level reached
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'SECTORS CLEARED',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white60,
                                letterSpacing: 1.0,
                              ),
                            ),
                            Text(
                              'LEVEL $level',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFFFD600),
                              ),
                            ),
                          ],
                        ),

                        // Render new record alert if applicable
                        if (isNewHiScore) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.greenAccent.withOpacity(0.6)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.emoji_events_rounded, color: Colors.greenAccent, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'NEW HIGH SCORE RECORD!',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.greenAccent,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Redeploy (Retry) Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        game.gameManager.resetGame();
                      },
                      borderRadius: BorderRadius.circular(30),
                      splashColor: Colors.redAccent.withOpacity(0.3),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.redAccent, Color(0xFFC62828)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(0.35),
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
                              Icon(Icons.replay_rounded, color: Colors.white, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'REDEPLOY FIGHTER',
                                style: TextStyle(
                                  fontSize: 16,
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

                  const SizedBox(height: 16),

                  // Return to Base button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        game.gameManager.exitToMenu();
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 240,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.home_rounded, color: Colors.white70, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'RETURN TO BASE',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
