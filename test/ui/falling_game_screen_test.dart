import 'package:block_puzzle/game/falling/falling_controller.dart';
import 'package:block_puzzle/game/piece.dart';
import 'package:block_puzzle/main.dart';
import 'package:block_puzzle/storage/high_score_store.dart';
import 'package:block_puzzle/ui/falling_game_screen.dart';
import 'package:block_puzzle/ui/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'game_effects_test.dart' show FakeAudio;

void main() {
  Future<FallingController> mount(
    WidgetTester tester, {
    FakeAudio? audio,
  }) async {
    final game = FallingController(
      autoStart: false,
      nextPiece: () => Pieces.square2,
    );
    addTearDown(game.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: game,
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: FallingGameScreen(audioFactory: () => audio ?? FakeAudio()),
        ),
      ),
    );
    return game;
  }

  testWidgets('touch and keyboard controls move, rotate, drop and pause', (
    tester,
  ) async {
    final audio = FakeAudio();
    final game = await mount(tester, audio: audio);
    await tester.tap(find.byTooltip('Mover para a esquerda'));
    expect(game.x, 2);
    await tester.tap(find.byTooltip('Mover para a direita'));
    expect(game.x, 3);
    await tester.tap(find.byTooltip('Girar peça'));
    await tester.tap(find.byTooltip('Descer um passo'));
    expect(game.y, 1);
    await tester.tap(find.byTooltip('Soltar peça'));
    await tester.pump();
    expect(game.score, 4);
    expect(audio.played.length, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    expect(game.x, 2);
    await tester.tap(find.byTooltip('Pausar partida'));
    await tester.pump();
    expect(find.text('Pausado'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(game.score, 4);
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    expect(game.isPaused, isFalse);
    await tester.tap(find.byTooltip('Silenciar sons'));
    await tester.pump();
    await tester.tap(find.byTooltip('Soltar peça'));
    expect(audio.played.length, 1);
    await tester.tap(find.byTooltip('Reiniciar partida'));
    await tester.pump();
    expect(game.score, 0);
    expect(game.highScore, 8);
    expect(tester.takeException(), isNull);
  });

  testWidgets('background interruption pauses and disposal releases audio', (
    tester,
  ) async {
    final audio = FakeAudio();
    final game = await mount(tester, audio: audio);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(game.isPaused, isTrue);
    expect(audio.stopped, greaterThan(0));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(game.isPaused, isTrue);
    await tester.pumpWidget(const SizedBox());
    expect(audio.disposed, isTrue);
  });

  testWidgets('top-out shows correct reason and restart starts a new game', (
    tester,
  ) async {
    final game = await mount(tester);
    for (var i = 0; i < 8; i++) {
      game.drop();
    }
    await tester.pumpAndSettle();
    expect(
      find.text('As peças chegaram ao topo do tabuleiro.'),
      findsOneWidget,
    );
    expect(find.text('Pontuação: 32'), findsOneWidget);
    await tester.tap(find.text('Jogar novamente'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('falling-board')), findsOneWidget);
    expect(game.score, 0);
  });

  for (final size in [
    const Size(320, 568),
    const Size(800, 360),
    const Size(768, 1024),
  ]) {
    testWidgets('falling game fits $size with reachable controls', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final game = await mount(tester);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Soltar peça'));
      await tester.pump();
      expect(game.score, 4);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'catalog opens Block Fall with independent record and returns safely',
    (tester) async {
      final previous = SharedPreferencesAsyncPlatform.instance;
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      addTearDown(() => SharedPreferencesAsyncPlatform.instance = previous);
      await PreferencesHighScoreStore().write(200);
      final fallingStore = PreferencesHighScoreStore(
        storageKey: PreferencesHighScoreStore.fallingKey,
      );
      await fallingStore.write(80);
      await tester.pumpWidget(const GameDayApp());
      await tester.scrollUntilVisible(find.text('Block Fall'), 250);
      await tester.tap(find.text('Block Fall'));
      await tester.pumpAndSettle();
      expect(find.byType(FallingGameScreen), findsOneWidget);
      final game = tester
          .element(find.byType(FallingGameScreen))
          .read<FallingController>();
      expect(game.highScore, 80);
      await tester.pump(const Duration(milliseconds: 800));
      expect(game.y, greaterThan(0));
      await tester.tap(find.byTooltip('Voltar aos jogos'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      final y = game.y;
      await tester.pump(const Duration(seconds: 2));
      expect(game.y, y);
      expect(await PreferencesHighScoreStore().read(), 200);
      expect(tester.takeException(), isNull);
    },
  );
}
