import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';

const _kFavKey = 'favorite_ids';

class FavoritesNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    // ローカルから読み込み
    final sp = await SharedPreferences.getInstance();
    final local = (sp.getStringList(_kFavKey) ?? []).toSet();

    // ログイン中ならクラウドとマージ
    if (SupabaseService.isLoggedIn) {
      final cloud = await SupabaseService.fetchFavoriteIds();
      final merged = {...local, ...cloud};
      await sp.setStringList(_kFavKey, merged.toList());
      return merged;
    }

    return local;
  }

  Future<void> toggle(String postId, {
    String thumbnailUrl = '',
    String sourceUrl = '',
    String animalType = '',
    List<String> tags = const [],
    double calmScore = 0.8,
  }) async {
    final current = {...state.valueOrNull ?? {}};
    final isFavoriting = !current.contains(postId);

    if (isFavoriting) {
      current.add(postId);
    } else {
      current.remove(postId);
    }

    state = AsyncData(current);

    // ローカル保存
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList(_kFavKey, current.toList());

    // クラウド同期
    await SupabaseService.syncFavorite(
      postId: postId,
      thumbnailUrl: thumbnailUrl,
      sourceUrl: sourceUrl,
      animalType: animalType,
      tags: tags,
      calmScore: calmScore,
      isFavorited: isFavoriting,
    );
  }

  bool isFavorite(String postId) =>
      state.valueOrNull?.contains(postId) ?? false;
}

final favoritesProvider =
    AsyncNotifierProvider<FavoritesNotifier, Set<String>>(FavoritesNotifier.new);
