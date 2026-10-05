import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The Supabase client, reached through the repository layer.
///
/// `bootstrap` has already called `Supabase.initialize` with the publishable
/// key before the widget tree exists (PLAN.md §1.3), so this provider only
/// exposes the initialised singleton — it does no setup of its own, and
/// therefore cannot be the reason a screen fails to build.
///
/// Held as a provider rather than imported as `Supabase.instance.client`
/// everywhere so tests can substitute a different client, and so nothing in
/// `presentation/` can reach the backend without going through a provider it
/// is allowed to depend on.
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);
