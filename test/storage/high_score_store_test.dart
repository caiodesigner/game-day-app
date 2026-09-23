import 'package:block_puzzle/storage/high_score_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    final previous = SharedPreferencesAsyncPlatform.instance;
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    addTearDown(() => SharedPreferencesAsyncPlatform.instance = previous);
  });

  test('defaults to zero and round-trips the record through fresh preferences instances', () async {
    final first = PreferencesHighScoreStore();
    expect(await first.read(), 0);
    await first.write(123);
    expect(await PreferencesHighScoreStore().read(), 123);
    expect(
      await SharedPreferencesAsync().getInt(PreferencesHighScoreStore.key),
      123,
    );
  });

  test('game records are isolated across preferences instances', () async {
    final puzzle = PreferencesHighScoreStore();
    final falling = PreferencesHighScoreStore(
      storageKey: PreferencesHighScoreStore.fallingKey,
    );
    await puzzle.write(500);
    await falling.write(120);
    expect(await PreferencesHighScoreStore().read(), 500);
    expect(
      await PreferencesHighScoreStore(
        storageKey: PreferencesHighScoreStore.fallingKey,
      ).read(),
      120,
    );
  });

  test('invalid negative stored record is treated as zero', () async {
    await SharedPreferencesAsync().setInt(PreferencesHighScoreStore.key, -10);
    expect(await PreferencesHighScoreStore().read(), 0);
  });
}
