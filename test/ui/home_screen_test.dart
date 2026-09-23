import 'package:block_puzzle/game/game_controller.dart';
import 'package:block_puzzle/main.dart';
import 'package:block_puzzle/storage/high_score_store.dart';
import 'package:block_puzzle/ui/game_over_panel.dart';
import 'package:block_puzzle/ui/game_screen.dart';
import 'package:block_puzzle/ui/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    final previous = SharedPreferencesAsyncPlatform.instance;
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    addTearDown(() => SharedPreferencesAsyncPlatform.instance = previous);
  });

  testWidgets(
    'opens catalog, plays, returns and starts fresh with saved record',
    (tester) async {
      await PreferencesHighScoreStore().write(100);
      await tester.pumpWidget(const GameDayApp());
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Block Puzzle'), findsOneWidget);
      expect(find.byType(GameScreen), findsNothing);

      await tester.tap(find.text('Jogar'));
      await tester.pumpAndSettle();
      final first = tester
          .element(find.byType(GameScreen))
          .read<GameController>();
      expect(first.highScore, 100);
      await tester.tap(find.byTooltip('Silenciar sons'));
      await tester.pump();
      expect(first.place(first.dock.first!, 0, 0), isNotNull);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Voltar aos jogos'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(GameScreen), findsNothing);

      await tester.tap(find.text('Jogar'));
      await tester.pumpAndSettle();
      final second = tester
          .element(find.byType(GameScreen))
          .read<GameController>();
      expect(identical(first, second), isFalse);
      expect(second.score, 0);
      expect(second.highScore, 100);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('game over can return to the catalog', (tester) async {
    await tester.pumpWidget(const GameDayApp());
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push<void>(
      MaterialPageRoute(
        builder: (_) => GameOverPanel(
          score: 50,
          record: 100,
          storageError: false,
          onRestart: () {},
          soundButton: const SizedBox(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voltar aos jogos'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(GameOverPanel), findsNothing);
  });

  for (final size in [
    const Size(320, 568),
    const Size(800, 360),
    const Size(768, 1024),
  ]) {
    testWidgets('catalog and game navigation fit $size', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const GameDayApp());
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Jogar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jogar'));
      await tester.pumpAndSettle();
      expect(find.byType(GameScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Voltar aos jogos'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  }
}
