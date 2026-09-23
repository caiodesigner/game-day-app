import 'package:block_puzzle/game/snake/snake_board.dart';
import 'package:block_puzzle/game/snake/snake_controller.dart';
import 'package:block_puzzle/main.dart';
import 'package:block_puzzle/storage/high_score_store.dart';
import 'package:block_puzzle/ui/home_screen.dart';
import 'package:block_puzzle/ui/snake_game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../game/snake_test_helpers.dart';
import 'game_effects_test.dart' show FakeAudio;

void main() {
  Future<SnakeController> mount(
    WidgetTester tester, {
    FakeAudio? audio,
    CycleFoodRandom? random,
  }) async {
    final food = random ?? CycleFoodRandom();
    final game = SnakeController(autoTick: false, random: food);
    food.readBody = () => game.body;
    addTearDown(game.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: game,
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: SnakeGameScreen(audioFactory: () => audio ?? FakeAudio()),
        ),
      ),
    );
    return game;
  }

  testWidgets('start, touch controls, keyboard, pause and restart', (
    tester,
  ) async {
    final game = await mount(tester);
    expect(find.text('Pronto para jogar?'), findsOneWidget);
    await tester.tap(find.text('Começar'));
    await tester.pump();
    await tester.tap(find.byTooltip('Mover para cima'));
    game.tick();
    expect(game.body.first, (x: 6, y: 5));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    game.tick();
    expect(game.body.first, (x: 5, y: 5));
    await tester.tap(find.byTooltip('Pausar partida'));
    await tester.pump();
    expect(find.text('Pausado'), findsOneWidget);
    final body = game.body;
    game.tick();
    expect(game.body, body);
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    expect(game.isPaused, isFalse);
    await tester.tap(find.byTooltip('Reiniciar partida'));
    await tester.pump();
    expect(game.hasStarted, isFalse);
    expect(find.text('Começar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('swiping the board turns once per gesture', (tester) async {
    final game = await mount(tester);
    await tester.tap(find.text('Começar'));
    await tester.pump();
    await tester.drag(
      find.byKey(const ValueKey('snake-board')),
      const Offset(0, -90),
    );
    game.tick();
    expect(game.direction, SnakeDirection.up);
    expect(game.body.first, (x: 6, y: 5));
    await tester.pump();
    await tester.drag(
      find.byKey(const ValueKey('snake-board')),
      const Offset(-90, 0),
    );
    game.tick();
    expect(game.direction, SnakeDirection.left);
    expect(game.body.first, (x: 5, y: 5));
  });

  testWidgets(
    'eating plays sound once, mute persists and interruption pauses',
    (tester) async {
      final audio = FakeAudio();
      final game = await mount(tester, audio: audio);
      await tester.tap(find.text('Começar'));
      game.tick();
      await tester.pump();
      expect(game.score, 10);
      expect(audio.played.length, 1);
      await tester.pump();
      expect(audio.played.length, 1);
      await tester.tap(find.byTooltip('Silenciar sons'));
      game.tick();
      await tester.pump();
      expect(game.score, 20);
      expect(audio.played.length, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(game.isPaused, isTrue);
      expect(audio.stopped, greaterThan(0));
      await tester.pumpWidget(const SizedBox());
      expect(audio.disposed, isTrue);
    },
  );

  testWidgets('collision shows final score and can restart', (tester) async {
    final game = await mount(tester);
    game.start();
    for (var i = 0; i < 6; i++) {
      game.tick();
    }
    await tester.pumpAndSettle();
    expect(find.text('Fim de jogo'), findsOneWidget);
    expect(find.text('Pontuação: 50'), findsOneWidget);
    await tester.tap(find.text('Jogar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Começar'), findsOneWidget);
    expect(game.score, 0);
    expect(game.highScore, 50);
  });

  testWidgets('filling board displays victory', (tester) async {
    final random = CycleFoodRandom();
    final game = await mount(tester, random: random);
    game.start();
    for (var i = 0; i < 141; i++) {
      game.turn(toward(game.body.first, random.after(game.body.first)));
      game.tick();
    }
    await tester.pumpAndSettle();
    expect(find.text('Você venceu!'), findsOneWidget);
    expect(find.text('Pontuação: 1410'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(320, 568),
    const Size(800, 360),
    const Size(768, 1024),
  ]) {
    testWidgets('layout and direction buttons fit $size', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final game = await mount(tester);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Começar'));
      await tester.pump();
      await tester.tap(find.byTooltip('Mover para baixo'));
      game.tick();
      await tester.pump();
      expect(game.direction, SnakeDirection.down);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('catalog, isolated record, system back and timer disposal', (
    tester,
  ) async {
    final previous = SharedPreferencesAsyncPlatform.instance;
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    addTearDown(() => SharedPreferencesAsyncPlatform.instance = previous);
    await PreferencesHighScoreStore().write(200);
    await PreferencesHighScoreStore(
      storageKey: PreferencesHighScoreStore.snakeKey,
    ).write(90);
    await tester.pumpWidget(const GameDayApp());
    await tester.scrollUntilVisible(find.text('Snake'), 250);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Snake'));
    await tester.pumpAndSettle();
    final game = tester
        .element(find.byType(SnakeGameScreen))
        .read<SnakeController>();
    expect(game.highScore, 90);
    await tester.tap(find.text('Começar'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(game.body.first, (x: 7, y: 6));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    final body = game.body;
    await tester.pump(const Duration(seconds: 2));
    expect(game.body, body);
    expect(await PreferencesHighScoreStore().read(), 200);
    expect(tester.takeException(), isNull);
  });
}
