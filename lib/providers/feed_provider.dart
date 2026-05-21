import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/video_post.dart';

const _edgeFunctionUrl =
    'https://jnrzpuaxztukbwijvhyq.supabase.co/functions/v1/animal-feed';
const _anonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpucnpwdWF4enR1a2J3aWp2aHlxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkzMTUyNTMsImV4cCI6MjA5NDg5MTI1M30.vSc8A93SYtDI3M7yPLe3mwSWF04j7FcRLsUj_CYiNYA';

// キャッシュ（2分）
List<VideoPost>? _cache;
DateTime? _lastFetch;

// 犬種タグ
List<String> _dogTagsFromUrl(String url) {
  final lower = url.toLowerCase();
  if (lower.contains('samoyed'))    return ['サモエド', 'ふわふわ', '白い'];
  if (lower.contains('pomeranian')) return ['ポメラニアン', 'ふわふわ', 'まん丸'];
  if (lower.contains('chow'))       return ['チャウチャウ', 'もふもふ', 'ふわふわ'];
  if (lower.contains('dalmatian')) return ['ダルメシアン', '水玉模様', 'スポーティ'];
  if (lower.contains('boxer'))     return ['ボクサー', 'がっしり', 'かっこいい'];
  if (lower.contains('corgi'))     return ['コーギー', '短足', 'かわいい'];
  if (lower.contains('shiba'))     return ['柴犬', 'もふもふ', 'りりしい'];
  if (lower.contains('akita'))     return ['秋田犬', 'りりしい', 'もふもふ'];
  if (lower.contains('retriever')) return ['レトリーバー', 'ゴールデン', 'おだやか'];
  if (lower.contains('labrador'))  return ['ラブラドール', 'やさしい', 'おだやか'];
  if (lower.contains('husky'))     return ['ハスキー', '青い目', 'かっこいい'];
  if (lower.contains('poodle'))    return ['プードル', 'くるくる', 'かわいい'];
  if (lower.contains('maltese'))   return ['マルチーズ', 'ふわふわ', '白い'];
  if (lower.contains('beagle'))    return ['ビーグル', 'たれ耳', 'かわいい'];
  return ['犬', 'おだやか', 'かわいい'];
}

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

Future<List<VideoPost>> _fetchAll({bool forceRefresh = false}) async {
  final now = DateTime.now();
  if (!forceRefresh &&
      _cache != null &&
      _cache!.isNotEmpty &&
      _lastFetch != null &&
      now.difference(_lastFetch!).inMinutes < 2) {
    return [..._cache!]..shuffle();
  }

  final List<VideoPost> posts = [];

  // 全ソースを並行取得
  await Future.wait([
    _fetchEdge(posts),
    _fetchCatApi(posts),
    _fetchCataas(posts),
    _fetchDogApi(posts),
    _fetchShibe(posts),
    _fetchFox(posts),
    _fetchGiphy(posts),
  ]);

  if (posts.isEmpty) return [];

  // 重複除去
  final seen = <String>{};
  final unique = posts.where((p) => seen.add(p.id)).toList()..shuffle();

  _cache = unique;
  _lastFetch = now;
  return unique;
}

// Edge Function（Reddit + Giphy）
Future<void> _fetchEdge(List<VideoPost> out) async {
  try {
    final futures = _typeMap.entries.map((e) => _fetchEdgeType(e.key, e.value));
    final results = await Future.wait(futures, eagerError: false);
    for (final r in results) out.addAll(r);
  } catch (_) {}
}

Future<List<VideoPost>> _fetchEdgeType(AnimalType type, String typeStr) async {
  try {
    final res = await http.get(
      Uri.parse('$_edgeFunctionUrl?type=$typeStr&limit=8'),
      headers: {'Authorization': 'Bearer $_anonKey'},
    ).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body);
    final List posts = data['posts'] ?? [];
    return posts.map((p) => VideoPost(
      id: p['id'] ?? '', sourceUrl: p['sourceUrl'] ?? '',
      thumbnailUrl: p['thumbnailUrl'] ?? '', animalType: type,
      tags: List<String>.from(p['tags'] ?? []),
      calmScore: (p['calmScore'] as num? ?? 0.8).toDouble(),
      soundLevel: (p['soundLevel'] as num? ?? 0.1).toDouble(),
      mood: 'healing',
      hasSadContext: p['hasSadContext'] ?? false,
      isAsmr: p['isAsmr'] ?? false,
      isGif: p['isGif'] ?? false,
    )).toList();
  } catch (_) { return []; }
}

// Cat API（最大20枚）
Future<void> _fetchCatApi(List<VideoPost> out) async {
  try {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final res = await http.get(Uri.parse(
        'https://api.thecatapi.com/v1/images/search?limit=20&ts=$ts'));
    if (res.statusCode != 200) return;
    final List data = jsonDecode(res.body);
    final catTags = ['寝顔', 'ゴロゴロ', 'おっとり', '甘え', 'まん丸', 'ふみふみ', 'おだやか'];
    for (int i = 0; i < data.length; i++) {
      out.add(VideoPost(
        id: 'cat_${data[i]['id']}',
        sourceUrl: data[i]['url'], thumbnailUrl: data[i]['url'],
        animalType: AnimalType.cat,
        tags: ['猫', catTags[i % catTags.length], 'もふもふ'],
        calmScore: 0.82 + (i % 5) * 0.03,
        soundLevel: 0.1, mood: 'healing',
        isAsmr: i % 6 == 0,
      ));
    }
  } catch (_) {}
}

// Cataas（GIF含む猫画像）
Future<void> _fetchCataas(List<VideoPost> out) async {
  final endpoints = [
    ('https://cataas.com/cat?json=true', false),
    ('https://cataas.com/cat/cute?json=true', false),
    ('https://cataas.com/cat/sleeping?json=true', false),
    ('https://cataas.com/cat/gif?json=true', true),
  ];
  for (int i = 0; i < endpoints.length; i++) {
    try {
      final res = await http.get(Uri.parse(endpoints[i].$1))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) continue;
      final data = jsonDecode(res.body);
      final id = data['_id'] ?? 'cataas_$i';
      out.add(VideoPost(
        id: 'cataas_$id',
        sourceUrl: 'https://cataas.com/cat/$id',
        thumbnailUrl: 'https://cataas.com/cat/$id',
        animalType: AnimalType.cat,
        tags: const ['猫', 'おだやか', 'もふもふ'],
        calmScore: 0.88, soundLevel: 0.05, mood: 'healing',
        isGif: endpoints[i].$2,
      ));
    } catch (_) {}
  }
}

// Dog API（最大20枚）
Future<void> _fetchDogApi(List<VideoPost> out) async {
  try {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final res = await http.get(Uri.parse(
        'https://dog.ceo/api/breeds/image/random/20?ts=$ts'));
    if (res.statusCode != 200) return;
    final List images = jsonDecode(res.body)['message'];
    for (int i = 0; i < images.length; i++) {
      out.add(VideoPost(
        id: 'dog_${i}_$ts', sourceUrl: images[i], thumbnailUrl: images[i],
        animalType: AnimalType.dog,
        tags: _dogTagsFromUrl(images[i] as String),
        calmScore: 0.80 + (i % 5) * 0.03,
        soundLevel: 0.15, mood: 'healing',
      ));
    }
  } catch (_) {}
}

// Shibe（柴犬 10枚）
Future<void> _fetchShibe(List<VideoPost> out) async {
  try {
    final res = await http.get(Uri.parse('https://shibe.online/api/shibes?count=10'));
    if (res.statusCode != 200) return;
    final List images = jsonDecode(res.body);
    for (int i = 0; i < images.length; i++) {
      out.add(VideoPost(
        id: 'shibe_$i', sourceUrl: images[i], thumbnailUrl: images[i],
        animalType: AnimalType.dog,
        tags: const ['柴犬', 'もふもふ', 'りりしい'],
        calmScore: 0.90, soundLevel: 0.05, mood: 'healing',
      ));
    }
  } catch (_) {}
}

// RandomFox（キツネ）
Future<void> _fetchFox(List<VideoPost> out) async {
  final futures = List.generate(5, (_) async {
    try {
      final res = await http.get(Uri.parse('https://randomfox.ca/floof/'));
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body);
      out.add(VideoPost(
        id: 'fox_${DateTime.now().microsecondsSinceEpoch}',
        sourceUrl: data['image'], thumbnailUrl: data['image'],
        animalType: AnimalType.smallAnimal,
        tags: const ['キツネ', 'ふわふわ', 'おだやか'],
        calmScore: 0.88, soundLevel: 0.05, mood: 'healing',
      ));
    } catch (_) {}
  });
  await Future.wait(futures);
}

// Giphy（直接取得・CORS対応）
Future<void> _fetchGiphy(List<VideoPost> out) async {
  const giphyKey = 'dc6zaTOxFJmzC';
  const searches = [
    ('cute cat sleeping', AnimalType.cat, ['猫', 'GIF', 'ねむい']),
    ('fluffy dog', AnimalType.dog, ['犬', 'GIF', 'ふわふわ']),
    ('otter cute', AnimalType.otter, ['カワウソ', 'GIF', 'かわいい']),
    ('capybara', AnimalType.capybara, ['カピバラ', 'GIF', 'まったり']),
    ('bunny rabbit cute', AnimalType.smallAnimal, ['うさぎ', 'GIF', 'もふもふ']),
    ('hamster cute', AnimalType.smallAnimal, ['ハムスター', 'GIF', 'まん丸']),
    ('cute bird', AnimalType.bird, ['鳥', 'GIF', 'かわいい']),
    ('baby animal', AnimalType.babyAnimal, ['赤ちゃん動物', 'GIF', 'ちいさい']),
  ];

  final futures = searches.map((s) async {
    try {
      final url = 'https://api.giphy.com/v1/gifs/search?api_key=$giphyKey'
          '&q=${Uri.encodeComponent(s.$1)}&limit=5&rating=g';
      final res = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body);
      final List gifs = data['data'] ?? [];
      for (int i = 0; i < gifs.length; i++) {
        final gifUrl = gifs[i]['images']?['fixed_height']?['url'] ?? '';
        if (gifUrl.isEmpty) continue;
        out.add(VideoPost(
          id: 'giphy_${s.$1.replaceAll(' ', '_')}_$i',
          sourceUrl: 'https://giphy.com',
          thumbnailUrl: gifUrl,
          animalType: s.$2,
          tags: s.$3,
          calmScore: 0.85, soundLevel: 0.05, mood: 'healing',
          isGif: true,
        ));
      }
    } catch (_) {}
  });
  await Future.wait(futures);
}

class FeedNotifier extends AsyncNotifier<List<VideoPost>> {
  @override
  Future<List<VideoPost>> build() async => _fetchAll();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchAll(forceRefresh: true));
  }
}

final feedProvider =
    AsyncNotifierProvider<FeedNotifier, List<VideoPost>>(FeedNotifier.new);
