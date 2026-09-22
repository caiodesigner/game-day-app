import 'package:block_puzzle/game/game_controller.dart';
import 'package:block_puzzle/game/piece.dart';
import 'package:block_puzzle/ui/game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  Future<GameController> load(WidgetTester tester, {Piece? piece}) async {
    final game = GameController(nextPiece: () => piece ?? Pieces.single);
    addTearDown(game.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: game,
        child: const MaterialApp(home: GameScreen()),
      ),
    );
    return game;
  }

  Future<TestGesture> dragTo(
    WidgetTester tester,
    int slot,
    int x,
    int y,
  ) async {
    await tester.pumpAndSettle();
    final dock = find.byKey(ValueKey('dock-$slot'));
    final draggable = tester.widget<Draggable<DockPiece>>(
      find.ancestor(of: dock, matching: find.byType(Draggable<DockPiece>)),
    );
    final start = tester.getCenter(dock);
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(0, -25));
    await tester.pump();
    await gesture.moveTo(
      tester.getCenter(find.byKey(ValueKey('cell-$x-$y'))) -
          draggable.feedbackOffset,
    );
    await tester.pump();
    return gesture;
  }

  testWidgets('previews then places, scores, consumes and refills the dock', (
    tester,
  ) async {
    final game = await load(tester);
    final gesture = await dragTo(tester, 0, 0, 0);
    expect(game.score, 0);
    expect(
      tester
          .widget<JewelCell>(
            find.descendant(
              of: find.byKey(const ValueKey('cell-0-0')),
              matching: find.byType(JewelCell),
            ),
          )
          .preview,
      isTrue,
    );
    await gesture.up();
    await tester.pump();
    expect(game.score, 1);
    expect(find.byKey(const ValueKey('dock-0')), findsNothing);
    expect(find.text('1'), findsOneWidget);
    for (var i = 1; i < 3; i++) {
      final next = await dragTo(tester, i, i, 0);
      await next.up();
      await tester.pump();
    }
    expect(game.round, 2);
    expect(game.score, 3);
    for (var i = 0; i < 3; i++) {
      expect(find.byKey(ValueKey('dock-$i')), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid boundary and outside drops preserve piece and score', (
    tester,
  ) async {
    final game = await load(tester, piece: Pieces.square2);
    final initial = game.dock;
    final gesture = await dragTo(tester, 0, 7, 7);
    expect(
      tester
          .widget<JewelCell>(
            find.descendant(
              of: find.byKey(const ValueKey('cell-7-7')),
              matching: find.byType(JewelCell),
            ),
          )
          .preview,
      isFalse,
    );
    await gesture.up();
    await tester.pump();
    expect(game.dock, initial);
    expect(game.score, 0);
    final outside = await dragTo(tester, 0, 0, 0);
    await outside.moveTo(const Offset(5, 5));
    await outside.up();
    await tester.pump();
    expect(game.dock, initial);
    expect(game.dragging, isNull);
    expect(game.score, 0);
    expect(tester.takeException(), isNull);
  });

  for (final shape in [
    Pieces.single,
    Pieces.square3,
    Pieces.verticalLines.last,
    Pieces.j,
  ]) {
    testWidgets(
      'raised ${shape.blockCount}-block piece stays above finger and matches drop preview',
      (tester) async {
        final game = await load(tester, piece: shape);
        final dock = find.byKey(const ValueKey('dock-0'));
        final draggable = tester.widget<Draggable<DockPiece>>(
          find.ancestor(of: dock, matching: find.byType(Draggable<DockPiece>)),
        );
        final target = tester.getCenter(find.byKey(const ValueKey('cell-1-1')));
        final finger = target - draggable.feedbackOffset;
        final gesture = await dragTo(tester, 0, 1, 1);
        final bounds = tester.getRect(
          find.byKey(const ValueKey('drag-feedback')),
        );
        expect(finger.dy - bounds.bottom, closeTo(50, .01));
        expect(bounds.center.dx, closeTo(finger.dx, .01));
        final cellBounds = tester.getRect(
          find.byKey(const ValueKey('cell-1-1')),
        );
        expect(bounds.topLeft.dx, closeTo(cellBounds.left, .01));
        expect(bounds.topLeft.dy, closeTo(cellBounds.top, .01));
        expect(game.score, 0);
        await gesture.up();
        await tester.pumpAndSettle();
        expect(game.score, shape.blockCount);
        for (final cell in shape.cells) {
          expect(game.cells[1 + cell.y][1 + cell.x], isPositive);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('restart clears a played board', (tester) async {
    final game = await load(tester);
    final gesture = await dragTo(tester, 0, 0, 0);
    await gesture.up();
    await tester.pump();
    await tester.tap(find.byTooltip('Reiniciar partida'));
    await tester.pump();
    expect(game.score, 0);
    expect(game.cells.expand((r) => r), everyElement(0));
    expect(find.byKey(const ValueKey('dock-0')), findsOneWidget);
  });

  testWidgets(
    'game over shows score and record, restart returns to playable board',
    (tester) async {
      var generated = 0;
      final game = GameController(
        nextPiece: () => generated++ < 4 ? Pieces.single : Pieces.square3,
      );
      addTearDown(game.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: game,
          child: const MaterialApp(home: GameScreen()),
        ),
      );
      for (final p in [(2, 2), (5, 2), (2, 5), (5, 5)]) {
        game.place(game.dock.whereType<DockPiece>().first, p.$1, p.$2);
      }
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('game-over')), findsOneWidget);
      expect(find.text('Pontuação: 4'), findsOneWidget);
      expect(find.text('Recorde: 4'), findsOneWidget);
      expect(find.byType(Draggable<DockPiece>), findsNothing);
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('game-over')), findsOneWidget);
      await tester.tap(find.text('Jogar novamente'));
      await tester.pump();
      expect(find.byKey(const ValueKey('game-over')), findsNothing);
      expect(find.byType(DragTarget<DockPiece>), findsNWidgets(64));
      expect(find.text('Recorde: 4'), findsOneWidget);
      expect(game.score, 0);
      expect(game.isGameOver, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(800, 360),
    const Size(768, 1024),
  ]) {
    testWidgets('layout fits $size without overflow', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await load(tester, piece: Pieces.verticalLines.last);
      expect(tester.takeException(), isNull);
      expect(find.byType(DragTarget<DockPiece>), findsNWidgets(64));
    });
  }
}
