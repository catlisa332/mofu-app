import 'package:supabase_flutter/supabase_flutter.dart';

const _supabaseUrl = 'https://jnrzpuaxztukbwijvhyq.supabase.co';
const _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpucnpwdWF4enR1a2J3aWp2aHlxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkzMTUyNTMsImV4cCI6MjA5NDg5MTI1M30.vSc8A93SYtDI3M7yPLe3mwSWF04j7FcRLsUj_CYiNYA';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  static User? get currentUser => client.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
  }

  // お気に入りをクラウドに保存
  static Future<void> syncFavorite({
    required String postId,
    required String thumbnailUrl,
    required String sourceUrl,
    required String animalType,
    required List<String> tags,
    required double calmScore,
    required bool isFavorited,
  }) async {
    if (!isLoggedIn) return;
    final userId = currentUser!.id;
    try {
      if (isFavorited) {
        await client.from('favorites').upsert({
          'user_id': userId,
          'post_id': postId,
          'thumbnail_url': thumbnailUrl,
          'post_url': sourceUrl,
          'animal_type': animalType,
          'tags': tags,
          'calm_score': calmScore,
        });
      } else {
        await client
            .from('favorites')
            .delete()
            .eq('user_id', userId)
            .eq('post_id', postId);
      }
    } catch (_) {}
  }

  // NGリストをクラウドに保存
  static Future<void> syncDislike({
    required String postId,
    required List<String> tags,
  }) async {
    if (!isLoggedIn) return;
    try {
      await client.from('dislikes').upsert({
        'user_id': currentUser!.id,
        'post_id': postId,
        'tags': tags,
      });
    } catch (_) {}
  }

  // クラウドからお気に入りIDを取得
  static Future<Set<String>> fetchFavoriteIds() async {
    if (!isLoggedIn) return {};
    try {
      final res = await client
          .from('favorites')
          .select('post_id')
          .eq('user_id', currentUser!.id);
      return (res as List).map((e) => e['post_id'] as String).toSet();
    } catch (_) {
      return {};
    }
  }

  // クラウドからNGリストを取得
  static Future<Set<String>> fetchDislikeIds() async {
    if (!isLoggedIn) return {};
    try {
      final res = await client
          .from('dislikes')
          .select('post_id')
          .eq('user_id', currentUser!.id);
      return (res as List).map((e) => e['post_id'] as String).toSet();
    } catch (_) {
      return {};
    }
  }
}
