import '../errors/failure.dart';
import '../errors/failure_mapper.dart';
import '../errors/failure_surface.dart';
import '../errors/toast_tone.dart';
import 'bookly_toast.dart';

/// Presents [failure] as a toast, on the surface §3.2 says it belongs to.
///
/// The toast-surface half only. Inline failures — a weak password, an
/// address with no account — are rendered by the field that owns them,
/// because a bar at the top of the app cannot say *which* input was
/// wrong; callers check [FailureMapper.surface] and put those under the
/// field instead.
///
/// Exists so no call site re-decides the mapping. Without it, every
/// screen that catches a `Failure` would pick its own `BooklyToast`
/// method, and the §3.2 matrix would drift one branch at a time into
/// whatever seemed right that afternoon.
void presentFailure(Failure failure) {
  if (FailureMapper.surface(failure.code) != FailureSurface.toast) return;

  switch (FailureMapper.tone(failure.code)) {
    case ToastTone.error:
      BooklyToast.error(failure.message);
    case ToastTone.warning:
      BooklyToast.warning(failure.message);
    case ToastTone.success:
      BooklyToast.success(failure.message);
    case ToastTone.danger:
      // A `danger` that survived the surface check is not attached to a
      // field, so it goes up as a bar rather than vanishing.
      BooklyToast.danger(failure.message);
    case ToastTone.info:
      BooklyToast.info(failure.message);
    case ToastTone.help:
      BooklyToast.help(failure.message);
  }
}
