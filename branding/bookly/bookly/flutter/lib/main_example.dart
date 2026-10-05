import 'package:flutter/material.dart';
import 'design_system/bookly_design_system.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final mode = BooklyThemeMode();
  await mode.load();
  runApp(ValueListenableBuilder<ThemeMode>(
    valueListenable: mode,
    builder: (_, m, __) => MaterialApp(
      title: 'Bookly',
      theme: BooklyTheme.light,
      darkTheme: BooklyTheme.dark,
      themeMode: m,
      home: Demo(mode: mode),
    ),
  ));
}

class Demo extends StatelessWidget {
  const Demo({super.key, required this.mode});
  final BooklyThemeMode mode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const BooklyLockup(markSize: 32)),
      body: ListView(
        padding: const EdgeInsets.all(BooklySpace.screenMobile),
        children: [
          Text('Reading with 3 friends', style: BooklyType.h2Mobile),
          const SizedBox(height: BooklySpace.s4),
          const ReadingProgressBar(readers: [
            ReaderProgress(memberIndex: 0, progress: 0.62, name: 'Ada'),
            ReaderProgress(memberIndex: 1, progress: 0.41, name: 'Tunde'),
            ReaderProgress(memberIndex: 2, progress: 0.18, name: 'Ife'),
          ]),
          const SizedBox(height: BooklySpace.s6),
          const BooklyChatBubble(kind: BubbleKind.friend, author: 'Ada', text: 'Chapter 7 wrecked me.'),
          const SizedBox(height: BooklySpace.s2),
          const BooklyChatBubble(kind: BubbleKind.gemini, text: 'The chapter turns on the letter in scene two.'),
          const SizedBox(height: BooklySpace.s2),
          const BooklyChatBubble(kind: BubbleKind.own, text: 'No spoilers past 7!'),
          const SizedBox(height: BooklySpace.s6),
          ElevatedButton(onPressed: () {}, child: const Text('Start circle')),
          const SizedBox(height: BooklySpace.s3),
          OutlinedButton(onPressed: () {}, child: const Text('Add note')),
          const SizedBox(height: BooklySpace.s6),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('System')),
              ButtonSegment(value: ThemeMode.light, label: Text('Light')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
            ],
            selected: {mode.value},
            onSelectionChanged: (s) => mode.set(s.first),
          ),
        ],
      ),
    );
  }
}
