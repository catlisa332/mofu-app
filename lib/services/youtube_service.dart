import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/video_post.dart';

const _apiKey = 'AIzaSyCxSHMioA2ecYOwbOGfLQL1wmFrCrW8Y1Y';
const _baseUrl = 'https://www.googleapis.com/youtube/v3';

// 動物種別ごとの検索クエリ
const _queries = [
  ('猫 かわいい',          AnimalType.cat,          ['猫', 'YouTube', 'かわいい']),
  ('cat relaxing cute',   AnimalType.cat,          ['猫', 'YouTube', 'おだやか']),
  ('犬 かわいい 動画',      AnimalType.dog,          ['犬', 'YouTube', 'かわいい']),
  ('dog cute fluffy',     AnimalType.dog,          ['犬', 'YouTube', 'ふわふわ']),
  ('カワウソ かわいい',      AnimalType.otter,        ['カワウソ', 'YouTube']),
  ('otter cute',          AnimalType.otter,        ['カワウソ', 'YouTube', 'かわいい']),
  ('カピバラ',              AnimalType.capybara,     ['カピバラ', 'YouTube', 'のんびり']),
  ('capybara relax',      AnimalType.capybara,     ['カピバラ', 'YouTube', 'まったり']),
  ('うさぎ かわいい',        AnimalType.smallAnimal,  ['うさぎ', 'YouTube', 'もふもふ']),
  ('柴犬',                AnimalType.dog,          ['柴犬', 'YouTube', 'りりしい']),
  ('ハムスター',            AnimalType.smallAnimal,  ['ハムスター', 'YouTube', 'まん丸']),
  ('鳥 かわいい インコ',     AnimalType.bird,         ['鳥', 'YouTube', 'かわいい']),
  ('赤ちゃん動物',          AnimalType.babyAnimal,   ['赤ちゃん', 'YouTube', 'ちいさい']),
  ('動物 癒し asmr',       AnimalType.mixedSpecies, ['ASMR', 'YouTube', '癒し']),
];

Future<List<VideoPost>> fetchYouTubeVideos({int perQuery = 3}) async {
  final List<VideoPost> posts = [];

  final futures = _queries.map((q) => _searchVideos(
    query: q.$1,
    animalType: q.$2,
    tags: q.$3,
    maxResults: perQuery,
  ));

  final results = await Future.wait(futures, eagerError: false);
  for (final r in results) posts.addAll(r);

  posts.shuffle();
  return posts;
}

Future<List<VideoPost>> _searchVideos({
  required String query,
  required AnimalType animalType,
  required List<String> tags,
  int maxResults = 3,
}) async {
  try {
    final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: {
      'part': 'snippet',
      'q': query,
      'type': 'video',
      'videoDuration': 'short',    // 4分以内（Shorts含む）
      'videoEmbeddable': 'true',
      'safeSearch': 'strict',
      'maxResults': maxResults.toString(),
      'relevanceLanguage': 'ja',
      'key': _apiKey,
    });

    final res = await http.get(uri).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return [];

    final data = jsonDecode(res.body);
    final List items = data['items'] ?? [];

    return items.map((item) {
      final id = item['id']['videoId'] as String;
      final snippet = item['snippet'];
      final title = snippet['title'] as String? ?? '';
      final thumb = snippet['thumbnails']['high']?['url'] ??
          snippet['thumbnails']['medium']?['url'] ?? '';

      return VideoPost(
        id: 'yt_$id',
        sourceUrl: 'https://youtu.be/$id',
        thumbnailUrl: thumb,
        animalType: animalType,
        tags: [...tags, ..._tagsFromTitle(title)].take(3).toList(),
        calmScore: _calmScoreFromTitle(title),
        soundLevel: 0.3,
        mood: 'healing',
        hasSadContext: _hasSadWords(title),
        youtubeVideoId: id,
      );
    }).where((p) => !p.hasSadContext && p.thumbnailUrl.isNotEmpty).toList();
  } catch (_) {
    return [];
  }
}

List<String> _tagsFromTitle(String title) {
  final lower = title.toLowerCase();
  final tags = <String>[];
  if (lower.contains('asmr')) tags.add('ASMR');
  if (lower.contains('sleep') || lower.contains('眠') || lower.contains('寝')) tags.add('寝顔');
  if (lower.contains('baby') || lower.contains('赤ちゃん') || lower.contains('子')) tags.add('赤ちゃん');
  if (lower.contains('fluffy') || lower.contains('もふ') || lower.contains('ふわ')) tags.add('もふもふ');
  return tags;
}

double _calmScoreFromTitle(String title) {
  final lower = title.toLowerCase();
  double score = 0.75;
  if (lower.contains('asmr') || lower.contains('relaxing') || lower.contains('癒し')) score += 0.1;
  if (lower.contains('sleep') || lower.contains('眠') || lower.contains('寝')) score += 0.1;
  if (lower.contains('loud') || lower.contains('funny') || lower.contains('fail')) score -= 0.15;
  return score.clamp(0.3, 1.0);
}

bool _hasSadWords(String title) {
  final lower = title.toLowerCase();
  return ['died', 'rip', 'sick', 'rescue only', 'abuse', 'missing']
      .any(lower.contains);
}
