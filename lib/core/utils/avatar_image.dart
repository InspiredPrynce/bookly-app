import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Choosing an avatar image and returning it ready to upload.
///
/// Lives in `core/` rather than in either feature that calls it because
/// **two features need it**: register (§3.1, optional at sign-up) and
/// `EditProfileScreen` (§3.3). Putting it in `features/auth/presentation/`
/// would force `features/profile` to reach into another feature to do the
/// same job, which §1.1 forbids — so the shared thing goes where both are
/// allowed to look.
///
/// ## Why the picker does the compressing
///
/// §3.3 describes the path as *pick → compress → Storage → row update*.
/// The compression happens at selection rather than at upload because
/// the alternative is holding a 6-megapixel decode in memory across the
/// whole form session, and a reader who changes their mind would pay that
/// cost twice. 512px is generous for a circular avatar.
///
/// ## Cancelling is not an error
///
/// A dismissed picker returns `null`, and that has to stay `null` all the
/// way back: turning it into a failure would tell the reader they did
/// something wrong by declining to pick a photo at all.
Future<Uint8List?> pickAndCompressAvatar() =>
    pickAndCompressImage(maxWidth: 512, maxHeight: 512, imageQuality: 85);

/// The same pick → resize → return-a-`null`-on-dismiss path, sized by the
/// caller.
///
/// Worth having beside [pickAndCompressAvatar] rather than only inside it:
/// a book cover (§5.1) goes through an identical flow but is a 2:3 jacket
/// rather than a circle, and 512px round is generous for one and thin for
/// the other. Two functions that each opened their own `ImagePicker` would
/// have to be kept in step by hand — including the property that matters
/// most, that a dismissed picker is `null` and not a failure.
Future<Uint8List?> pickAndCompressImage({
  required int maxWidth,
  required int maxHeight,
  int imageQuality = 85,
}) async {
  final picked = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: maxWidth.toDouble(),
    maxHeight: maxHeight.toDouble(),
    imageQuality: imageQuality,
  );

  if (picked == null) return null;
  return picked.readAsBytes();
}
