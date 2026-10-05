/// A reader's own profile row (PLAN.md §2.1, §3.3).
///
/// Mirrors `public.profiles`'s editable surface and nothing else: the
/// sharing toggles and `daily_reminder_time` are settings (§3.4 / Phase
/// 3), not this screen's business.
///
/// [avatarPath] and [avatarUrl] are both carried deliberately. The path
/// is what the database stores and what a rollback restores — it is
/// stable, offline-safe and policy-meaningful. The URL is what the widget
/// renders, and it only exists because `avatars` is a public bucket
/// (`20261005000008_storage.sql`). Keeping both means the screen never
/// has to reach for a Supabase client to draw a portrait, and a failed
/// save can fall back to the path it came from rather than re-deriving
/// one.
class Profile {
  const Profile({
    required this.id,
    required this.name,
    this.bio = '',
    this.avatarPath,
    this.avatarUrl,
  });

  final String id;

  /// 1–60 characters, `not null` in the database.
  final String name;

  /// ≤160 characters; empty rather than null so the form has no null case
  /// to render (the column allows null, the editor never needs to say so).
  final String bio;

  /// Bucket-relative object path, e.g. `{uid}/avatar.jpg`.
  final String? avatarPath;

  /// Public URL for [avatarPath], or `null` when there is no portrait.
  final String? avatarUrl;

  Profile copyWith({
    String? name,
    String? bio,
    String? avatarPath,
    String? avatarUrl,
    bool clearAvatar = false,
  }) =>
      Profile(
        id: id,
        name: name ?? this.name,
        bio: bio ?? this.bio,
        avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
        avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
      );
}
