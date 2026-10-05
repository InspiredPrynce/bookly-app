import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import 'book_sound.dart';

/// Plays Bookly's chime, and never anything else.
///
/// ## Decoration, treated as decoration
///
/// Every entry point is fire-and-forget and swallows its own failures. A
/// missing asset, a platform channel that has not attached, or an audio
/// session the OS refuses — none of those may stop a save, a join, or a
/// toast. The caller cannot tell "chimed" from "did not" and must not need
/// to, so an audio failure is a `debugPrint` and nothing more.
///
/// ## One player per sound, preloaded
///
/// Each [BookSound] gets its own [AudioPlayer] holding only that source. A
/// single-source player has no loop mode and no playlist sequence to walk
/// into, which is the whole reason: the earlier pattern of one player
/// seeking an index through a list of sounds meant `LoopMode.off` ran on
/// into the next sound after the first played, and `LoopMode.one` repeated
/// it forever. Neither can happen here — a dedicated player plays once,
/// finishes, and stops.
///
/// There is exactly one sound today, so this buys nothing *yet*; it buys the
/// absence of the bug class when there is a second.
///
/// Preloading is what makes the chime land *with* its toast rather than
/// after it — decoding a short MP3 on demand costs a couple of hundred
/// milliseconds, which reads as the sound being late.
///
/// ## The audio session is a notification session, not a music session
///
/// `just_audio` defaults to a music-style session, which on iOS is
/// `AVAudioSessionCategoryPlayback` — a category that **ignores the silent
/// switch**. A reader whose phone is on silent would get a chime at full
/// volume in a meeting, which is the exact failure this configuration
/// exists to prevent.
///
/// So: `ambient` on iOS, which respects the switch and mixes with whatever
/// else is playing; and `sonification` with transient-may-duck focus on
/// Android, so the chime dips the reader's music for its half second rather
/// than stopping it.
abstract final class BooklySoundPlayer {
  /// One warm player per sound, built by [preload].
  ///
  /// A missing entry means that sound could not be loaded, and [play] then
  /// does nothing for it. Deliberately not a "player exists but is broken"
  /// state: that would throw again on every play, turning one logged failure
  /// at startup into a log line per toast for the rest of the session.
  static final Map<BookSound, AudioPlayer> _players = <BookSound, AudioPlayer>{};

  /// The in-flight (or completed) warm-up, or null before it starts.
  ///
  /// A future rather than a bool, because [preload] is deliberately not
  /// awaited on the critical path to the first frame — a toast raised while
  /// the player is still decoding is a *normal* case, not an error path. A
  /// `bool _prepared` guard would make that first chime see an empty map,
  /// decide it was already done, and silently drop the very chime that
  /// proves the feature works. Holding the future instead lets [play] queue
  /// behind the warm-up and still sound, just fractionally late.
  static Future<void>? _ready;

  /// Warms the session and the players. Safe to call more than once.
  static Future<void> preload() => _ready ??= _warmUp();

  static Future<void> _warmUp() async {
    try {
      /// `instance` is a Future in `audio_session` 0.2.x, not a getter.
      final session = await AudioSession.instance;
      await session.configure(_sessionConfiguration);

      for (final sound in BookSound.values) {
        final player = AudioPlayer();
        try {
          await player.setAsset(_assetFor(sound));
        } catch (error) {
          debugPrint('🔊 BooklySound: could not preload ${sound.name}: $error');
          await player.dispose();
          continue;
        }
        _players[sound] = player;
      }
    } catch (error) {
      /// A refused session leaves the map empty, so every later play is a
      /// no-op. That is the intended failure: silence, not a crash.
      debugPrint('🔊 BooklySound: audio session unavailable: $error');
    }
  }

  /// The chime configuration — see the class doc for why this is not `music()`.
  static const _sessionConfiguration = AudioSessionConfiguration(
    avAudioSessionCategory: AVAudioSessionCategory.ambient,
    androidAudioAttributes: AndroidAudioAttributes(
      contentType: AndroidAudioContentType.sonification,
      usage: AndroidAudioUsage.assistanceSonification,
    ),
    androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
  );

  /// Whether chimes are on.
  ///
  /// Defaults to true. The Settings screen that owns this lands in Phase 3
  /// (PLAN.md §9); until then there is no reader-facing switch, and
  /// inventing a persisted one here would duplicate that work.
  static bool soundEnabled = true;

  /// Plays [sound] with a light haptic, if sounds are on.
  ///
  /// Returns immediately — the toast this accompanies must not wait on a
  /// decoder.
  static void play(BookSound sound) {
    if (!soundEnabled) return;

    /// Haptic **before** audio (PLAN.md §4.5). The haptic is free — no
    /// package, no asset — and it is the half of the "that worked" signal
    /// most people feel first: on a muted device it is the only half left.
    /// Firing it before the audio await means the confirmation is felt the
    /// instant the toast appears even when the chime is a moment behind it.
    HapticFeedback.lightImpact();

    unawaited(_play(sound));
  }

  static Future<void> _play(BookSound sound) async {
    try {
      await preload();
    } catch (_) {
      return;
    }

    final player = _players[sound];
    if (player == null) return;

    try {
      /// Rewind, then play. No `processingState` check: a player still going
      /// from a previous chime is rewound, so a repeat starts from the top.
      ///
      /// Nothing stops the player afterwards. The sample runs to its end and
      /// the player goes idle on its own — which is what "a chime" means —
      /// so navigating away mid-sound does not cut it off and read as a
      /// glitch.
      await player.seek(Duration.zero);
      await player.play();
    } catch (error) {
      debugPrint('🔊 BooklySound: ${sound.name} failed to play: $error');
    }
  }

  static String _assetFor(BookSound sound) => switch (sound) {
        BookSound.notification => 'assets/sound/notification.mp3',
      };
}
