import '../../../core/errors/failure.dart';

/// Submission state for `CreateBookScreen` (PLAN.md §5.1, §5.3).
///
/// The book's *contents* are not here. Unlike an avatar — which the
/// reader cannot cheaply re-pick — everything on this form is text they
/// can retype, and it already lives in the screen's controllers where
/// it can survive a failed submit without ever crossing a provider
/// boundary on each keystroke. What belongs here is the attempt itself.
class CreateBookState {
  const CreateBookState({
    this.saving = false,
    this.createdBookId,
    this.failure,
  });

  /// Idle — nothing in flight, nothing outstanding.
  static const initial = CreateBookState();

  /// True from the moment the insert starts until it resolves. Blocks a
  /// second tap and drives [PrimaryButton]'s progress.
  ///
  /// It spans cover upload and both inserts, not just the first request:
  /// to the reader there is one operation, and letting them press Save
  /// again while chapters are still being written would race
  /// `unique (book_id, position)`.
  final bool saving;

  /// The row's id once it exists — which is also the success signal, so
  /// there is no separate `saved` flag to keep in step with it.
  final String? createdBookId;

  /// The last failure, cleared when a new attempt starts.
  final Failure? failure;

  bool get hasFailure => failure != null;
  bool get created => createdBookId != null;
}
