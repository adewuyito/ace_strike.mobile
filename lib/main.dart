import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'game/ace_strike_game.dart';
import 'game/providers/game_providers.dart';
import 'game/overlays/main_menu_overlay.dart';
import 'game/overlays/hud_overlay.dart';
import 'game/overlays/pause_overlay.dart';
import 'game/overlays/game_over_overlay.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: AceStrikeApp(),
    ),
  );
}

class AceStrikeApp extends ConsumerWidget {
  const AceStrikeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch our singleton game instance cached in Riverpod
    final game = ref.watch(gameProvider);

    return MaterialApp(
      title: 'Ace Strike',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF0D1B2A),
      ),
      home: Scaffold(
        body: GameWidget<AceStrikeGame>(
          game: game,
          overlayBuilderMap: {
            'MainMenu': (context, game) => const MainMenuOverlay(),
            'HUD': (context, game) => const HudOverlay(),
            'PauseMenu': (context, game) => const PauseOverlay(),
            'GameOver': (context, game) => const GameOverOverlay(),
          },
          initialActiveOverlays: const ['MainMenu'],
        ),
      ),
    );
  }
}
