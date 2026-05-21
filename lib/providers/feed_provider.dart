import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/video_post.dart';

// CORSプロキシ経由でReddit取得
const _proxy = 'https://corsproxy.io/?url=';

const _subreddits = [
  ('aww',               AnimalType.mixedSpecies, ['癒し', 'ほっこり']),
  ('cats',              AnimalType.cat,          ['猫', 'もふもふ']),
  ('dogs',              AnimalType.dog,          ['犬', 'ふわふわ']),
  ('Rabbits',           AnimalType.smallAnimal,  ['うさぎ', 'まん丸']),
  ('Otters',            AnimalType.otter,        ['カワウソ', 'かわいい']),
  ('AnimalsBeingDerpy', AnimalType.mixedSpecies, ['おもしろ', 'ゆるい']),
];

Future<List<VideoPost>> _fetchAnimalPosts() async {
  final List<VideoPost> posts = [];

  // Reddit (CORSプロキシ経由)
  for (final (sub, animalType, baseTags) in _subreddits) {
    try {
      final redditUrl = Uri.encodeFull(
        'https://www.reddit.com/r/$sub/hot.json?limit=8&raw_json=1',
      );
      final res = await http
          .get(Uri.parse('$_proxy$redditUrl'))
          .timeout(const Duration(seconds: 8));

      if (res.statusCode != 200) continue;

      final data = jsonDecode(res.body);
      final children = data['data']['children'] as List;

      for (final child in children) {
        final post = child['data'];
        final url = post['url'] as String? ?? '';
        if (!_isImage(url)) continue;
        if (post['over_18'] == true) continue;
        if ((post['score'] as num? ?? 0) < 50) continue;

        final title = post['title'] as String? ?? '';
        final upvoteRatio = (post['upvote_ratio'] as num? ?? 0.8).toDouble();
        final calmScore = _calcCalmScore(title, upvoteRatio);
        final tags = [...baseTags, ..._extractTags(title)].take(3).toList();

        posts.add(VideoPost(
          id: 'reddit_${post['id']}',
          sourceUrl: 'https://reddit.com${post['permalink']}',
          thumbnailUrl: url,
          animalType: animalType,
          tags: tags,
          calmScore: calmScore,
          soundLevel: 0.1,
          mood: 'healing',
          hasSadContext: _hasSadWords(title),
        ));
      }
    } catch (_) {
      continue;
    }
  }

  // CORS問題で全滅した場合は複数APIでフォールバック
  if (posts.length < 8) {
    posts.addAll(await _fetchMultiFallback());
  }

  posts.shuffle();
  return posts;
}

// 複数の動物API（全部CORS対応・APIキー不要）
Future<List<VideoPost>> _fetchMultiFallback() async {
  final List<VideoPost> posts = [];

  // 猫
  try {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final res = await http.get(
      Uri.parse('https://api.thecatapi.com/v1/images/search?limit=12&ts=$ts'),
    );
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      for (int i = 0; i < data.length; i++) {
        posts.add(VideoPost(
          id: 'cat_${data[i]['id']}',
          sourceUrl: data[i]['url'],
          thumbnailUrl: data[i]['url'],
          animalType: AnimalType.cat,
          tags: ['猫', _catTags[i % _catTags.length], 'おだやか'],
          calmScore: 0.82 + (i % 4) * 0.04,
          soundLevel: 0.1,
          mood: 'healing',
          isAsmr: i % 5 == 0,
        ));
      }
    }
  } catch (_) {}

  // 犬
  try {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final res = await http.get(
      Uri.parse('https://dog.ceo/api/breeds/image/random/10?ts=$ts'),
    );
    if (res.statusCode == 200) {
      final List images = jsonDecode(res.body)['message'];
      for (int i = 0; i < images.length; i++) {
        posts.add(VideoPost(
          id: 'dog_${i}_${DateTime.now().millisecondsSinceEpoch}',
          sourceUrl: images[i],
          thumbnailUrl: images[i],
          animalType: AnimalType.dog,
          tags: ['犬', _extractBreed(images[i]), 'しあわせ'],
          calmScore: 0.78 + (i % 4) * 0.05,
          soundLevel: 0.15,
          mood: 'healing',
        ));
      }
    }
  } catch (_) {}

  // 柴犬
  try {
    final res = await http.get(
      Uri.parse('https://shibe.online/api/shibes?count=6'),
    );
    if (res.statusCode == 200) {
      final List images = jsonDecode(res.body);
      for (int i = 0; i < images.length; i++) {
        posts.add(VideoPost(
          id: 'shibe_$i',
          sourceUrl: images[i],
          thumbnailUrl: images[i],
          animalType: AnimalType.dog,
          tags: const ['柴犬', 'もふもふ', 'おだやか'],
          calmScore: 0.90,
          soundLevel: 0.05,
          mood: 'healing',
        ));
      }
    }
  } catch (_) {}

  // キツネ
  try {
    for (int i = 0; i < 4; i++) {
      final res = await http.get(Uri.parse('https://randomfox.ca/floof/'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        posts.add(VideoPost(
          id: 'fox_$i',
          sourceUrl: data['image'],
          thumbnailUrl: data['image'],
          animalType: AnimalType.smallAnimal,
          tags: const ['キツネ', 'ふわふわ', 'おだやか'],
          calmScore: 0.88,
          soundLevel: 0.05,
          mood: 'healing',
        ));
      }
    }
  } catch (_) {}

  return posts;
}

bool _isImage(String url) {
  final lower = url.toLowerCase();
  return lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png') ||
      lower.endsWith('.gif') ||
      lower.endsWith('.webp') ||
      lower.contains('i.redd.it') ||
      lower.contains('i.imgur.com');
}

List<String> _extractTags(String title) {
  final lower = title.toLowerCase();
  final tags = <String>[];
  if (lower.contains('sleep') || lower.contains('nap')) tags.add('寝顔');
  if (lower.contains('kitten') || lower.contains('puppy')) tags.add('赤ちゃん');
  if (lower.contains('together') || lower.contains('friend')) tags.add('仲良し');
  if (lower.contains('fluff') || lower.contains('soft')) tags.add('ふわふわ');
  return tags;
}

double _calcCalmScore(String title, double upvoteRatio) {
  double score = upvoteRatio * 0.7 + 0.2;
  if (_hasSadWords(title)) score -= 0.2;
  return score.clamp(0.3, 1.0);
}

bool _hasSadWords(String title) {
  final lower = title.toLowerCase();
  return ['died', 'rip', 'sick', 'cancer', 'passed', 'lost', 'rescue']
      .any(lower.contains);
}

String _extractBreed(String url) {
  try {
    final parts = url.split('/');
    final idx = parts.indexOf('breeds');
    if (idx >= 0 && idx + 1 < parts.length) {
      return _breedJp[parts[idx + 1]] ?? '犬';
    }
  } catch (_) {}
  return '犬';
}

const _catTags = ['寝顔', 'ゴロゴロ', 'おっとり', '甘え', 'まん丸', 'ふみふみ'];
const _breedJp = {
  'shiba': '柴犬', 'pomeranian': 'ポメラニアン', 'corgi': 'コーギー',
  'samoyed': 'サモエド', 'akita': '秋田犬', 'maltese': 'マルチーズ',
  'husky': 'ハスキー', 'retriever': 'レトリーバー', 'poodle': 'プードル',
};

class FeedNotifier extends AsyncNotifier<List<VideoPost>> {
  @override
  Future<List<VideoPost>> build() async => _fetchAnimalPosts();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchAnimalPosts);
  }
}

final feedProvider =
    AsyncNotifierProvider<FeedNotifier, List<VideoPost>>(FeedNotifier.new);
