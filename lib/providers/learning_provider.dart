import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video_post.dart';

const _kTagScoresKey = 'tag_scores';

// タグスコア: 好き→+1, しんどい→-2, 長時間視聴→+0.5
class LearningNotifier extends AsyncNotifier<Map<String, double>> {
  @override
  Future<Map<String, double>> build() async {
    final sp = await SharedPreferences.getInstance();
    final json = sp.getString(_kTagScoresKey);
    if (json == null) return {};
    final map = jsonDecode(json) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  Future<void> onFavorite(List<String> tags) async {
    await _adjustScores(tags, delta: 1.0);
  }

  Future<void> onDislike(List<String> tags) async {
    await _adjustScores(tags, delta: -2.0);
  }

  Future<void> onLongView(List<String> tags) async {
    await _adjustScores(tags, delta: 0.5);
  }

  Future<void> _adjustScores(List<String> tags, {required double delta}) async {
    final current = {...state.valueOrNull ?? {}};
    for (final tag in tags) {
      current[tag] = (current[tag] ?? 0) + delta;
    }
    state = AsyncData(current);
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kTagScoresKey, jsonEncode(current));
  }

  // スコアが高いタグ上位5件
  List<String> get topTags {
    final scores = state.valueOrNull ?? {};
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .where((e) => e.value > 0)
        .take(5)
        .map((e) => e.key)
        .toList();
  }

  // 投稿のパーソナルスコアを計算
  double personalScore(VideoPost post) {
    final scores = state.valueOrNull ?? {};
    if (scores.isEmpty) return post.calmScore;
    double bonus = 0;
    for (final tag in post.tags) {
      bonus += scores[tag] ?? 0;
    }
    return (post.calmScore + bonus * 0.05).clamp(0.0, 2.0);
  }
}

final learningProvider =
    AsyncNotifierProvider<LearningNotifier, Map<String, double>>(
  LearningNotifier.new,
);
