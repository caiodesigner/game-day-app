import 'package:audioplayers/audioplayers.dart';

enum GameSound { place, clear, gameOver }

abstract interface class GameAudio {
  Future<void> play(GameSound sound);
  Future<void> stop();
  Future<void> dispose();
}

/// Local assets only. Commands are serialized and stale requests are discarded.
class LocalGameAudio implements GameAudio {
  AudioPlayer? _player;
  Future<void> _pending = Future.value();
  int _generation = 0;
  bool _disposed = false;

  Future<void> _enqueue(Future<void> Function() action) {
    _pending = _pending.then((_) async {
      try {
        await action();
      } catch (_) {
        // Audio is optional: a native playback failure must not stop the game.
      }
    });
    return _pending;
  }

  @override
  Future<void> play(GameSound sound) {
    final generation = ++_generation;
    return _enqueue(() async {
      if (_disposed || generation != _generation) return;
      final player = _player ??= AudioPlayer();
      await player.stop();
      if (_disposed || generation != _generation) return;
      await player.play(AssetSource('audio/${sound.name}.wav'), volume: .45);
    });
  }

  @override
  Future<void> stop() {
    _generation++;
    return _enqueue(() async {
      await _player?.stop();
    });
  }

  @override
  Future<void> dispose() {
    _disposed = true;
    _generation++;
    return _enqueue(() async {
      await _player?.dispose();
      _player = null;
    });
  }
}
