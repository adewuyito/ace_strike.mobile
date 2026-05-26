import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../managers/game_manager.dart';
import '../ace_strike_game.dart';

final gameStateProvider = StateProvider<GameState>((ref) => GameState.menu);
final scoreProvider = StateProvider<int>((ref) => 0);
final hiScoreProvider = StateProvider<int>((ref) => 0);
final livesProvider = StateProvider<int>((ref) => 3);
final levelProvider = StateProvider<int>((ref) => 1);
final boostChargeProvider = StateProvider<double>((ref) => 1.0);
final isBoostingProvider = StateProvider<bool>((ref) => false);
final shieldActiveProvider = StateProvider<bool>((ref) => false);
final scoreMultiplierProvider = StateProvider<double>((ref) => 1.0);
final consecutiveDodgesProvider = StateProvider<int>((ref) => 0);

final gameProvider = Provider<AceStrikeGame>((ref) {
  return AceStrikeGame(ref.container);
});
