import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/bookly_design_system.dart';
import '../../../core/snackbar/bookly_toast.dart';
import '../../../core/snackbar/present_failure.dart';
import '../../../core/utils/avatar_image.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/avatar_field.dart';
import '../../../core/widgets/bookly_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../application/edit_profile_controller.dart';
import '../application/edit_profile_state.dart';

/// Changing the signed-in reader's own row (PLAN.md §3.3).
///
/// Display name · bio (≤160) · avatar, with live validation and an
/// optimistic save that rolls the portrait back if it fails — the
/// semantics live in [EditProfileState], not here.
///
/// The two `TextEditingController`s belong to the screen rather than to
/// the provider because the *text* is view state: the provider receives
/// a copy through [EditProfileController.setName] to validate against and
/// to save from, but it never writes what the reader sees back into the
/// field. A provider that owned the string would round-trip every
/// keystroke — caret position and all — through a rebuild for no benefit
/// the validation does not already provide.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _bio = TextEditingController();

  /// The notifier, not its state: `ref.read(provider)` reads what the
  /// provider *exposes* (an [EditProfileState]), which is why the notifier
  /// has to come from `.notifier`.
  EditProfileController get _controller =>
      ref.read(editProfileControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    // A dismissed picker stays null and is never treated as a failure
    // (§3.3 — declining to choose a photo is not a thing that went wrong).
    final bytes = await pickAndCompressAvatar();
    if (bytes != null) _controller.chooseAvatar(bytes);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(editProfileControllerProvider);

    // Registered on every build and released with it, so there is exactly
    // one listener at a time and each event carries the states it moved
    // between. Every branch here compares against `previous`, which is
    // what stops a save that already toasted from toasting again on the
    // next rebuild.
    ref.listen(
      editProfileControllerProvider,
      (previous, next) {
        final prev = previous;

        // Seed the fields once the row lands. Doing it here rather than
        // in `build` keeps the text out of the render path: the reader
        // sees the fields only after this has already run.
        if (prev != null && prev.loading && !next.loading && !next.loadFailed) {
          _name.text = next.name;
          _bio.text = next.bio;
        }

        if (next.saved && !(prev?.saved ?? false)) {
          BooklyToast.success('Profile saved.');
          if (mounted) context.pop();
        }

        // A failure is presented once, on the transition into it. The
        // provider keeps it until the reader acts, so presenting from
        // `build` would re-toast on every subsequent rebuild.
        if (next.failure != null && prev?.failure == null) {
          presentFailure(next.failure!);
        }
      },
    );

    if (state.loading) {
      return Scaffold(
        backgroundColor: colors.bg,
        body: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.textSecondary,
            ),
          ),
        ),
      );
    }

    if (state.loadFailed) {
      return Scaffold(
        backgroundColor: colors.bg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(BooklySpace.screenMobile),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.failure?.message ??
                        'Something went wrong. Please try again.',
                    textAlign: TextAlign.center,
                    style: BooklyType.bodyMd.copyWith(
                      color: colors.textSecondary,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: BooklySpace.lg),
                  PrimaryButton(label: 'Try again', onPressed: _controller.load),
                  const SizedBox(height: BooklySpace.xs),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Back'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final showingAvatar = state.pendingAvatar != null ||
        (!state.removeAvatar && (state.avatarUrl?.isNotEmpty ?? false));

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: BooklySpace.screenMobile,
                vertical: BooklySpace.lg,
              ),
              children: [
                Row(
                  children: [
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Back'),
                    ),
                  ],
                ),
                Text(
                  'Edit profile',
                  style: BooklyType.headlineMd.copyWith(color: colors.text),
                ),
                const SizedBox(height: BooklySpace.xs),
                Text(
                  'How your reading circle sees you.',
                  style: BooklyType.bodySm.copyWith(
                    color: colors.textSecondary,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: BooklySpace.xl),
                Center(
                  child: AvatarField(
                    bytes: state.pendingAvatar,
                    imageUrl: state.removeAvatar ? null : state.avatarUrl,
                    onPick: _pickAvatar,
                    onClear: showingAvatar && !state.removeAvatar
                        ? _controller.removeAvatar
                        : null,
                  ),
                ),
                const SizedBox(height: BooklySpace.lg),
                BooklyTextField(
                  controller: _name,
                  label: 'Display name',
                  errorText: state.nameError,
                  textInputAction: TextInputAction.next,
                  onChanged: _controller.setName,
                ),
                const SizedBox(height: BooklySpace.lg),
                BooklyTextField(
                  controller: _bio,
                  label: 'Bio',
                  maxLines: 4,
                  errorText: state.bioError,
                  // Counted after trimming, matching both what is stored
                  // and what `bioError` measures — a counter that
                  // disagreed with the error beneath it would be worse
                  // than no counter.
                  helperText:
                      '${state.bio.trim().length} / ${Validators.bioMaxLength}',
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: _controller.setBio,
                ),
                const SizedBox(height: BooklySpace.xl),
                PrimaryButton(
                  label: 'Save changes',
                  submitting: state.saving,
                  onPressed: () => _controller.save(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
