import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bookly/core/design_system/bookly_design_system.dart';

/// Pumps [child] under each Bookly theme so component failures surface for
/// both brightness values, not just the one the machine happens to use.
///
/// [verify] runs while the tree is mounted and before it is torn down — the
/// tree is unmounted at the end of every iteration, because leaving a pumped
/// theme alive across the next `pumpWidget` leaves the frame pipeline
/// permanently busy and `pumpAndSettle` never returns.
Future<void> pumpUnderBothThemes(
  WidgetTester tester,
  Widget Function() child, [
  void Function(WidgetTester tester)? verify,
]) async {
  final themes = <ThemeData>[BooklyTheme.light, BooklyTheme.dark];
  for (var i = 0; i < themes.length; i++) {
    final theme = themes[i];
    await tester.pumpWidget(MaterialApp(theme: theme, home: Scaffold(body: child())));
    await tester.pumpAndSettle();
    expect(
      tester.takeException(),
      isNull,
      reason: 'threw under ${theme.brightness} (theme ${i + 1} of ${themes.length})',
    );
    verify?.call(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }
}

void main() {
  testWidgets('the split design system compiles and renders every component',
      (tester) async {
    await pumpUnderBothThemes(tester, () => const Center(child: BooklyLockup()));
    await pumpUnderBothThemes(tester, () => const BooklyMark(size: 32));
    await pumpUnderBothThemes(
      tester,
      () => const MemberAvatar(memberIndex: 0, initials: 'AD'),
    );
    await pumpUnderBothThemes(
      tester,
      () => const ReadingProgressBar(
        readers: [ReaderProgress(memberIndex: 0, progress: 0.4, name: 'Ada')],
      ),
    );
    await pumpUnderBothThemes(
      tester,
      () => const BookCover(image: AssetImage('assets/logo/bookly-mark-light.png')),
    );
  });

  testWidgets('every BubbleKind renders its own styling', (tester) async {
    for (final kind in BubbleKind.values) {
      await pumpUnderBothThemes(
        tester,
        () => BooklyChatBubble(kind: kind, text: 'A note', author: 'Ada'),
        (t) => expect(find.text('A note'), findsOneWidget, reason: 'kind $kind'),
      );
    }
  });

  testWidgets('a Gemini bubble declares an AI caption and an accessible label',
      (tester) async {
    await pumpUnderBothThemes(
      tester,
      () => const BooklyChatBubble(kind: BubbleKind.gemini, text: 'About this book'),
      (t) {
        // Caption in text — DESIGN.md §11: AI output is never signalled by
        // colour alone.
        expect(find.text('GEMINI'), findsOneWidget);

        // And a spoken label that names the speaker as AI.
        final labels = t
            .widgetList<Semantics>(find.byType(Semantics))
            .map((s) => s.properties.label)
            .toSet();
        expect(
          labels,
          contains('Gemini, AI: About this book'),
          reason: 'Gemini bubble must declare an AI label',
        );
      },
    );
  });

  testWidgets('a member avatar declares its identity for assistive tech',
      (tester) async {
    await pumpUnderBothThemes(
      tester,
      () => const MemberAvatar(memberIndex: 2, initials: 'CH'),
      (t) {
        // The initials actually render, so the ring colour is never the only
        // identity cue (DESIGN.md §11).
        expect(find.text('CH'), findsOneWidget);

        final labels =
            t.widgetList<Semantics>(find.byType(Semantics)).map((s) => s.properties.label).toSet();
        expect(labels, contains('CH'));
      },
    );
  });
}
