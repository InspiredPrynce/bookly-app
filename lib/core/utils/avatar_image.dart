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
Future<Uint8List?> pickAndCompressAvatar() async {
  final picked = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 512,
    maxHeight: 512,
    imageQuality: 85,
  );

  if (picked == null) return null;
  return picked.readAsBytes();
}
