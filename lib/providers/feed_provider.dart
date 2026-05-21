import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/video_post.dart';

const _edgeFunctionUrl =
    'https://jnrzpuaxztukbwijvhyq.supabase.co/functions/v1/animal-feed';
const _anonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpucnpwdWF4enR1a2J3aWp2aHlxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkzMTUyNTMsImV4cCI6MjA5NDg5MTI1M30.vSc8A93SYtDI3M7yPLe3mwSWF04j7FcRLsUj_CYiNYA';

// キャッシュ（セッション中は再取得しない）
final Map<String, List<VideoPost>> _cache = {};
DateTime? _lastFetch;

const _typeMap = {
  AnimalType.cat:          'cat',
  AnimalType.dog:          'dog',
  AnimalType.otter:        'otter',
  AnimalType.capybara:     'capybara',
  AnimalType.smallAnimal:  'smallAnimal',
  AnimalType.bird:         'bird',
  AnimalType.mixedSpecies: 'mixed',
  AnimalType.babyAnimal:   'baby',
  AnimalType.reptile:      'mixed',
  AnimalType.seaCreature:  'mixed',
};

Future<List<VideoPost>> _fetchFromEdgeFunction({bool forceRefresh = false}) async {
  // 5分以内のキャッシュがあれば再利用
  final now = DateTime.now();
  if (!forceRefresh &&
      _lastFetch != null &&
      now.difference(_lastFetch!).inMinutes < 5 &&
      _cache.isNotEmpty) {
    final cached = _cache.values.expand((e) => e).toList()..shuffle();
    return cached;
  }

  final List<VideoPost> posts = [];

  // Edge Function から並行取得（タイムアウト付き）
  final futures = _typeMap.entries.map((e) => _fetchType(e.key, e.value));
  final results = await Future.wait(futures, eagerError: false);
  for (int i = 0; i < results.length; i++) {
    final type = _typeMap.keys.elementAt(i);
    _cache[type.name] = results[i];
    posts.addAll(results[i]);
  }

  // Edge Function が全滅ならフォールバック
  if (posts.length < 5) {
    final fallback = await _fetchFallback();
    posts.addAll(fallback);
  }

  if (posts.isNotEmpty) _lastFetch = now;

  posts.shuffle();
  return posts;
}

Future<List<VideoPost>> _fetchType(AnimalType type, String typeStr) async {
  try {
    final res = await http.get(
      Uri.parse('$_edgeFunctionUrl?type=$typeStr&limit=6'),
      headers: {
        'Authorization': 'Bearer $_anonKey',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) return [];

    final data = jsonDecode(res.body);
    final List postList = data['posts'] ?? [];

    return postList.map((p) => VideoPost(
      id: p['id'] ?? '',
      sourceUrl: p['sourceUrl'] ?? '',
      thumbnailUrl: p['thumbnailUrl'] ?? '',
      animalType: type,
      tags: List<String>.from(p['tags'] ?? []),
      calmScore: (p['calmScore'] as num? ?? 0.8).toDouble(),
      soundLevel: (p['soundLevel'] as num? ?? 0.1).toDouble(),
      mood: p['mood'] ?? 'healing',
      hasSadContext: p['hasSadContext'] ?? false,
      isAsmr: p['isAsmr'] ?? false,
    )).toList();
  } catch (_) {
    return [];
  }
}

Future<List<VideoPost>> _fetchFallback() async {
  final List<VideoPost> posts = [];
  final ts = DateTime.now().millisecondsSinceEpoch;

  await Future.wait([
    // 猫
    () async {
      try {
        final res = await http.get(Uri.parse(
            'https://api.thecatapi.com/v1/images/search?limit=10&ts=$ts'));
        if (res.statusCode == 200) {
          final List data = jsonDecode(res.body);
          posts.addAll(data.map((d) => VideoPost(
            id: 'cat_${d['id']}', sourceUrl: d['url'], thumbnailUrl: d['url'],
            animalType: AnimalType.cat,
            tags: const ['猫', 'もふもふ', 'おだやか'],
            calmScore: 0.85, soundLevel: 0.1, mood: 'healing',
          )));
        }
      } catch (_) {}
    }(),
    // 犬
    () async {
      try {
        final res = await http.get(Uri.parse(
            'https://dog.ceo/api/breeds/image/random/8?ts=$ts'));
        if (res.statusCode == 200) {
          final List images = jsonDecode(res.body)['message'];
          posts.addAll(images.asMap().entries.map((e) => VideoPost(
            id: 'dog_${e.key}_$ts', sourceUrl: e.value, thumbnailUrl: e.value,
            animalType: AnimalType.dog,
            tags: const ['犬', 'しあわせ', 'ふわふわ'],
            calmScore: 0.82, soundLevel: 0.15, mood: 'healing',
          )));
        }
      } catch (_) {}
    }(),
    // 柴犬
    () async {
      try {
        final res = await http.get(Uri.parse('https://shibe.online/api/shibes?count=6'));
        if (res.statusCode == 200) {
          final List images = jsonDecode(res.body);
          posts.addAll(images.asMap().entries.map((e) => VideoPost(
            id: 'shibe_${e.key}', sourceUrl: e.value, thumbnailUrl: e.value,
            animalType: AnimalType.dog,
            tags: const ['柴犬', 'もふもふ', 'おだやか'],
            calmScore: 0.90, soundLevel: 0.05, mood: 'healing',
          )));
        }
      } catch (_) {}
    }(),
    // キツネ
    () async {
      try {
        for (int i = 0; i < 3; i++) {
          final res = await http.get(Uri.parse('https://randomfox.ca/floof/'));
          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            posts.add(VideoPost(
              id: 'fox_$i', sourceUrl: data['image'], thumbnailUrl: data['image'],
              animalType: AnimalType.smallAnimal,
              tags: const ['キツネ', 'ふわふわ', 'おだやか'],
              calmScore: 0.88, soundLevel: 0.05, mood: 'healing',
            ));
          }
        }
      } catch (_) {}
    }(),
  ].map((f) => f));

  return posts;
}

class FeedNotifier extends AsyncNotifier<List<VideoPost>> {
  @override
  Future<List<VideoPost>> build() async => _fetchFromEdgeFunction();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _fetchFromEdgeFunction(forceRefresh: true));
  }
}

final feedProvider =
    AsyncNotifierProvider<FeedNotifier, List<VideoPost>>(FeedNotifier.new);
