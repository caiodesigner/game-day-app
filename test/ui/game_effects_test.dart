import 'package:block_puzzle/audio/game_audio.dart';
import 'package:block_puzzle/game/game_controller.dart';
import 'package:block_puzzle/game/piece.dart';
import 'package:block_puzzle/ui/game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class FakeAudio implements GameAudio {
  final played = <GameSound>[];
  int stopped = 0;
  bool disposed = false;
  @override
  Future<void> play(GameSound sound) async => played.add(sound);
  @override
  Future<void> stop() async {
    stopped++;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

void main() {
  Future<void> mount(
    WidgetTester tester,
    GameController game,
    FakeAudio audio, {
    bool reduced = false,
  }) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: game,
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: GameScreen(audioFactory: () => audio),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'cleared blocks fade then disappear without awarding points twice',
    (tester) async {
      final game = GameController(nextPiece: () => Pieces.single);
      addTearDown(game.dispose);
      for (var x = 0; x < 7; x++) {
        game.place(game.dock.whereType<DockPiece>().first, x, 0);
      }
      final audio = FakeAudio();
      await mount(tester, game, audio);
      game.place(game.dock.whereType<DockPiece>().first, 7, 0);
      await tester.pump();
      expect(find.byKey(const ValueKey('clearing-0-0')), findsOneWidget);
      expect(game.score, 18);
      expect(game.cells[0], everyElement(0));
      expect(audio.played, [GameSound.clear]);
      expect(
        tester
            .widgetList<Draggable<DockPiece>>(find.byType(Draggable<DockPiece>))
            .every((d) => d.maxSimultaneousDrags == 0),
        isTrue,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('clearing-0-0')), findsNothing);
      expect(game.score, 18);
      expect(audio.played, [GameSound.clear]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'mute stops playback, invalid moves are silent, restart retains mute',
    (tester) async {
      final game = GameController(nextPiece: () => Pieces.single);
      addTearDown(game.dispose);
      final audio = FakeAudio();
      await mount(tester, game, audio);
      game.place(game.dock[0]!, 0, 0);
      await tester.pumpAndSettle();
      expect(audio.played, [GameSound.place]);
      game.place(game.dock[1]!, 0, 0);
      expect(audio.played.length, 1);
      await tester.tap(find.byTooltip('Silenciar sons'));
      await tester.pump();
      expect(audio.stopped, 1);
      game.place(game.dock[1]!, 1, 0);
      await tester.pumpAndSettle();
      expect(audio.played.length, 1);
      await tester.tap(find.byTooltip('Reiniciar partida'));
      await tester.pump();
      expect(find.byTooltip('Ativar sons'), findsOneWidget);
      await tester.tap(find.byTooltip('Ativar sons'));
      await tester.pump();
      game.place(game.dock[0]!, 0, 0);
      await tester.pumpAndSettle();
      expect(audio.played.length, 2);
    },
  );

  testWidgets('game over waits for move feedback and plays only once', (
    tester,
  ) async {
    var generated = 0;
    final game = GameController(
      nextPiece: () => generated++ < 4 ? Pieces.single : Pieces.square3,
    );
    addTearDown(game.dispose);
    final audio = FakeAudio();
    await mount(tester, game, audio);
    for (final p in [(2, 2), (5, 2), (2, 5), (5, 5)]) {
      game.place(game.dock.whereType<DockPiece>().first, p.$1, p.$2);
      await tester.pump();
    }
    expect(find.byKey(const ValueKey('game-over')), findsNothing);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('game-over')), findsOneWidget);
    expect(audio.played.where((s) => s == GameSound.gameOver).length, 1);
    await tester.pump();
    expect(audio.played.where((s) => s == GameSound.gameOver).length, 1);
    await tester.tap(find.text('Jogar novamente'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('game-over')), findsNothing);
    expect(game.score, 0);
  });

  testWidgets(
    'reduced motion and disposal leave no running animation or audio',
    (tester) async {
      final game = GameController(nextPiece: () => Pieces.single);
      addTearDown(game.dispose);
      final audio = FakeAudio();
      await mount(tester, game, audio, reduced: true);
      game.place(game.dock[0]!, 0, 0);
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      expect(audio.stopped, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(const SizedBox());
      expect(audio.disposed, isTrue);
      expect(tester.takeException(), isNull);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    },
  );
}
