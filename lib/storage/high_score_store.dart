import 'package:shared_preferences/shared_preferences.dart';

abstract interface class HighScoreStore {
  Future<int> read();
  Future<void> write(int score);
}

class PreferencesHighScoreStore implements HighScoreStore {
  PreferencesHighScoreStore({
    SharedPreferencesAsync? preferences,
    this.storageKey = key,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  static const key = 'block_puzzle.high_score';
  static const fallingKey = 'falling_blocks.high_score';
  static const snakeKey = 'snake.high_score';
  final String storageKey;
  final SharedPreferencesAsync _preferences;

  @override
  Future<int> read() async {
    final value = await _preferences.getInt(storageKey) ?? 0;
    return value < 0 ? 0 : value;
  }

  @override
  Future<void> write(int score) => _preferences.setInt(storageKey, score);
}
