import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';

const _kDislikeIdsKey = 'disliked_ids';

class DislikeNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final sp = await SharedPreferences.getInstance();
    final local = (sp.getStringList(_kDislikeIdsKey) ?? []).toSet();

    if (SupabaseService.isLoggedIn) {
      final cloud = await SupabaseService.fetchDislikeIds();
      final merged = {...local, ...cloud};
      await sp.setStringList(_kDislikeIdsKey, merged.toList());
      return merged;
    }

    return local;
  }

  Future<void> dislike(String postId, List<String> tags) async {
    final current = {...state.valueOrNull ?? {}};
    current.add(postId);
    state = AsyncData(current);

    final sp = await SharedPreferences.getInstance();
    await sp.setStringList(_kDislikeIdsKey, current.toList());

    await SupabaseService.syncDislike(postId: postId, tags: tags);
  }

  bool isDisliked(String postId) =>
      state.valueOrNull?.contains(postId) ?? false;
}

final dislikeProvider =
    AsyncNotifierProvider<DislikeNotifier, Set<String>>(DislikeNotifier.new);

final ngTagsProvider = FutureProvider<List<String>>((ref) async {
  final sp = await SharedPreferences.getInstance();
  return sp.getStringList('disliked_tags') ?? [];
});
