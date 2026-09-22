import 'package:shared_preferences/shared_preferences.dart';

abstract interface class HighScoreStore {
  Future<int> read();
  Future<void> write(int score);
}

class PreferencesHighScoreStore implements HighScoreStore {
  PreferencesHighScoreStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const key = 'block_puzzle.high_score';
  final SharedPreferencesAsync _preferences;

  @override
  Future<int> read() async {
    final value = await _preferences.getInt(key) ?? 0;
    return value < 0 ? 0 : value;
  }

  @override
  Future<void> write(int score) => _preferences.setInt(key, score);
}
