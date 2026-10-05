import '../../../core/errors/failure.dart';

/// Shared submission state for the three auth forms.
///
/// Immutable and owned by a Riverpod `Notifier` (PLAN.md §1.1) — the
/// screen reads it and renders; it never mutates it.
///
/// One state type for all three forms because the three forms have the
/// same two facts: whether a request is in flight, and whether the last
/// one failed. Giving each its own type would duplicate this file three
/// times without adding a single field.
class AuthSubmitState {
  const AuthSubmitState({this.submitting = false, this.failure});

  /// Idle — nothing in flight, nothing outstanding.
  static const initial = AuthSubmitState();

  /// True from the moment a request starts until it resolves. Blocks a
  /// second tap and drives [PrimaryButton]'s progress.
  final bool submitting;

  /// The last failure, cleared when a new attempt starts.
  ///
  /// Null means "no outstanding failure", which is also the idle state —
  /// callers that need to distinguish success from never-started ask the
  /// controller, which returns that answer directly.
  final Failure? failure;

  bool get hasFailure => failure != null;
}
