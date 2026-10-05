import 'package:flutter/widgets.dart';

import '../sound/book_sound.dart';
import '../sound/bookly_sound_player.dart';

/// Fires the toast's chime the moment it is laid out.
///
/// ## This is what makes the chime and the bar simultaneous
///
/// Playing the sound at the call site would ring for a bar that was replaced
/// before it ever appeared, or ring under a *different* toast — because toasts
/// replace rather than queue. Wrapping the content means this widget builds
/// exactly when the bar is presented, so the sound and the sight of it are one
/// event by construction rather than by arithmetic (PLAN.md §4.5).
class ChimeOnPresent extends StatefulWidget {
  const ChimeOnPresent({super.key, required this.child});

  final Widget child;

  @override
  State<ChimeOnPresent> createState() => _ChimeOnPresentState();
}

class _ChimeOnPresentState extends State<ChimeOnPresent> {
  @override
  void initState() {
    super.initState();

    /// `initState` rather than `build`, so a rebuild does not re-fire the
    /// chime — a gesture or a media-query change that rebuilds this bar must
    /// not replay the sound.
    BooklySoundPlayer.play(BookSound.notification);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
