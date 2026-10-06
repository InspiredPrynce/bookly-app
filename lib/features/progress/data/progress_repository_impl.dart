import 'dart:io' show SocketException;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failure.dart';
import '../../../core/errors/failure_code.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../domain/book_progress.dart';
import '../domain/item_status.dart';
import '../domain/progress_repository.dart';

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepositoryImpl(ref.watch(supabaseClientProvider)),
);

/// Supabase implementation of [ProgressRepository].
///
/// ## The write path is read-then-write, never `upsert`
///
/// Both partial unique indexes on `item_progress` carry a predicate
/// (`where chapter_id is not null`), and Postgres cannot infer a
/// *partial* index from a bare `ON CONFLICT (user_id, chapter_id)` —
/// it would raise "no unique or exclusion constraint matching the ON
/// CONFLICT specification" the first time the reader tapped. Supabase's
/// client does not expose the `ON CONFLICT … WHERE` form that inference
/// needs, so `upsert` is not merely awkward here, it is unavailable.
///
/// The two round trips buy something anyway: the read is where the
/// monotonic rule is decided, and that decision needs the row's current
/// status either way.
class ProgressRepositoryImpl implements ProgressRepository {
  ProgressRepositoryImpl(this._client);

  final SupabaseClient _client;

  // ── Reads ───────────────────────────────────────────────────────────────

  @override
  Future<BookProgress> load(String bookId) => _guard(() async {
        final rows = await _client
            .from('item_progress')
            .select('chapter_id, link_id, status')
            .eq('user_id', _userId)
            .eq('book_id', bookId);

        final chapters = <String, ItemStatus>{};
        final links = <String, ItemStatus>{};

        for (final row in rows as List? ?? const []) {
          final status = ItemStatus.fromDb(row['status'] as String?);
          final chapterId = row['chapter_id'] as String?;
          final linkId = row['link_id'] as String?;

          // `one_target` guarantees exactly one of these is set, so the
          // row lands in one map and cannot be counted twice.
          if (chapterId != null) chapters[chapterId] = status;
          if (linkId != null) links[linkId] = status;
        }

        return BookProgress(chapters: chapters, links: links);
      });

  // ── Writes ──────────────────────────────────────────────────────────────

  @override
  Future<ItemStatus> startChapter({
    required String bookId,
    required String chapterId,
  }) =>
      _advance(
        bookId: bookId,
        chapterId: chapterId,
        wanted: ItemStatus.reading,
      );

  @override
  Future<ItemStatus> finishChapter({
    required String bookId,
    required String chapterId,
  }) =>
      _advance(
        bookId: bookId,
        chapterId: chapterId,
        wanted: ItemStatus.finished,
      );

  @override
  Future<ItemStatus> startLink({
    required String bookId,
    required String linkId,
  }) =>
      _advance(bookId: bookId, linkId: linkId, wanted: ItemStatus.reading);

  @override
  Future<ItemStatus> finishLink({
    required String bookId,
    required String linkId,
  }) =>
      _advance(bookId: bookId, linkId: linkId, wanted: ItemStatus.finished);

  /// One row, one transition, and one answer to hand back.
  ///
  /// ## Why it writes nothing most of the time
  ///
  /// `circle_events` is fired by a trigger on `item_progress` inserts
  /// *and* updates (migration 000006), so a write that changes no state
  /// still posts an event: a reader who taps a watched link twice would
  /// appear in their circle's feed to have watched it twice. Skipping
  /// the request entirely is therefore not an optimisation — it is what
  /// keeps the feed true.
  ///
  /// ## Why `finished` never moves
  ///
  /// Reopening something already finished leaves it finished, for two
  /// reasons. The row would otherwise emit a *second* `started_link` for
  /// an item the feed already reported as started, and — worse — the
  /// one fact that must not be lost is that it is done: a reader who
  /// rewinds one chapter would silently un-complete a book they had
  /// finished, and `reading_progress.read_count` (§5.4) counts on that
  /// being monotonic too.
  Future<ItemStatus> _advance({
    required String bookId,
    required ItemStatus wanted,
    String? chapterId,
    String? linkId,
  }) =>
      _guard(() async {
        final userId = _userId;
        final (column, target) =
            chapterId != null ? ('chapter_id', chapterId) : ('link_id', linkId!);

        final existing = await _client
            .from('item_progress')
            .select('status')
            .eq('user_id', userId)
            .eq('book_id', bookId)
            .eq(column, target)
            .maybeSingle();

        final current = existing == null
            ? ItemStatus.notStarted
            : ItemStatus.fromDb(existing['status'] as String?);

        final effective = current == ItemStatus.finished ? current : wanted;
        if (current == effective) return effective;

        final now = DateTime.now().toUtc().toIso8601String();

        if (existing == null) {
          await _client.from('item_progress').insert({
            'user_id': userId,
            'book_id': bookId,
            'item_type': chapterId != null ? 'chapter' : 'link',
            'chapter_id': chapterId,
            'link_id': linkId,
            'status': effective.dbValue,
            // Neither column has a default: `started_at` is "when this
            // reader first touched the item", and leaving it null would
            // record a start nobody could recover later.
            'started_at': now,
            if (effective == ItemStatus.finished) 'finished_at': now,
          });
        } else {
          await _client
              .from('item_progress')
              .update({
                'status': effective.dbValue,
                if (effective == ItemStatus.finished) 'finished_at': now,
              })
              .eq('user_id', userId)
              .eq('book_id', bookId)
              .eq(column, target);
        }

        return effective;
      });

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      // Every column below is `not null` and points at `profiles`, so
      // there is no row to write without a session — and RLS would
      // refuse the insert anyway.
      throw const Failure(
        code: FailureCode.unauthorised,
        message: 'Please sign in again to continue.',
      );
    }
    return id;
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on Failure {
      rethrow;
    } on PostgrestException catch (e) {
      throw _mapPostgrest(e);
    } catch (e) {
      throw _mapOffline(e);
    }
  }

  static Failure _mapPostgrest(PostgrestException e) {
    final code = e.code?.toUpperCase() ?? '';

    if (code == 'PGRST116' || code == '42501') {
      return Failure(
        code: FailureCode.unauthorised,
        message: 'Please sign in again to continue.',
        cause: e,
      );
    }

    // Two taps landing together is the realistic cause of 23505 here —
    // the row was inserted by the first before the second read it. The
    // reader's intent has already been recorded, so the copy says so
    // rather than accusing them of anything.
    if (code == '23505') {
      return Failure(
        code: FailureCode.conflict,
        message: 'That was already saved.',
        cause: e,
      );
    }

    // `type_matches_fk` and `one_target` are satisfied by this file, but
    // a chapter or link deleted between the screen loading and the tap
    // would leave an id pointing nowhere.
    if (code == '23503') {
      return Failure(
        code: FailureCode.notFound,
        message: 'That item is no longer part of this book.',
        cause: e,
      );
    }

    return Failure(
      code: FailureCode.unknown,
      message: 'Something went wrong. Please try again.',
      cause: e,
    );
  }

  /// The concrete type differs by which layer gave up first — dart:io or
  /// Supabase's own wrapper — so both the type and the wording are
  /// checked. Whether the reader is told "you're offline" should not
  /// depend on which of them happened to surface it.
  static Failure _mapOffline(Object e) {
    final text = e.toString().toLowerCase();
    final offline = e is SocketException ||
        text.contains('socket') ||
        text.contains('clientexception') ||
        text.contains('failed host lookup') ||
        text.contains('connection closed') ||
        text.contains('connection refused');

    if (offline) {
      return Failure(
        code: FailureCode.networkOffline,
        message: "You're offline. Check your connection and try again.",
        cause: e,
      );
    }

    return Failure(
      code: FailureCode.unknown,
      message: 'Something went wrong. Please try again.',
      cause: e,
    );
  }
}
