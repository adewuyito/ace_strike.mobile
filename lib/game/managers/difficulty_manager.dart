class DifficultyConfig {
  final int level;
  final double spawnInterval;
  final int scoreThreshold;

  const DifficultyConfig({
    required this.level,
    required this.spawnInterval,
    required this.scoreThreshold,
  });
}

class DifficultyManager {
  static const List<DifficultyConfig> levels = [
    DifficultyConfig(level: 1, spawnInterval: 2.0, scoreThreshold: 0),
    DifficultyConfig(level: 2, spawnInterval: 1.5, scoreThreshold: 500),
    DifficultyConfig(level: 3, spawnInterval: 1.0, scoreThreshold: 1000),
    DifficultyConfig(level: 4, spawnInterval: 0.7, scoreThreshold: 2000),
    DifficultyConfig(level: 5, spawnInterval: 0.4, scoreThreshold: 3500),
  ];

  static DifficultyConfig getDifficulty(int score) {
    for (int i = levels.length - 1; i >= 0; i--) {
      if (score >= levels[i].scoreThreshold) {
        return levels[i];
      }
    }
    return levels.first;
  }
}
