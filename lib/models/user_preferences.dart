import 'video_post.dart';

class UserPreferences {
  final List<AnimalType> favoriteAnimals;
  final List<MoodType> preferredMoods;
  final List<String> avoidTags;
  final bool isTiredMode;
  final bool isNightMode;
  final bool isMutePreferred;
  final bool showCalmScore;

  const UserPreferences({
    this.favoriteAnimals = const [],
    this.preferredMoods = const [],
    this.avoidTags = const [],
    this.isTiredMode = false,
    this.isNightMode = false,
    this.isMutePreferred = false,
    this.showCalmScore = true,
  });

  UserPreferences copyWith({
    List<AnimalType>? favoriteAnimals,
    List<MoodType>? preferredMoods,
    List<String>? avoidTags,
    bool? isTiredMode,
    bool? isNightMode,
    bool? isMutePreferred,
    bool? showCalmScore,
  }) {
    return UserPreferences(
      favoriteAnimals: favoriteAnimals ?? this.favoriteAnimals,
      preferredMoods: preferredMoods ?? this.preferredMoods,
      avoidTags: avoidTags ?? this.avoidTags,
      isTiredMode: isTiredMode ?? this.isTiredMode,
      isNightMode: isNightMode ?? this.isNightMode,
      isMutePreferred: isMutePreferred ?? this.isMutePreferred,
      showCalmScore: showCalmScore ?? this.showCalmScore,
    );
  }

  Map<String, dynamic> toJson() => {
    'favoriteAnimals': favoriteAnimals.map((e) => e.index).toList(),
    'preferredMoods': preferredMoods.map((e) => e.index).toList(),
    'avoidTags': avoidTags,
    'isTiredMode': isTiredMode,
    'isNightMode': isNightMode,
    'isMutePreferred': isMutePreferred,
    'showCalmScore': showCalmScore,
  };

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      UserPreferences(
        favoriteAnimals: (json['favoriteAnimals'] as List<dynamic>?)
                ?.map((e) => AnimalType.values[e as int])
                .toList() ??
            [],
        preferredMoods: (json['preferredMoods'] as List<dynamic>?)
                ?.map((e) => MoodType.values[e as int])
                .toList() ??
            [],
        avoidTags: List<String>.from(json['avoidTags'] ?? []),
        isTiredMode: json['isTiredMode'] ?? false,
        isNightMode: json['isNightMode'] ?? false,
        isMutePreferred: json['isMutePreferred'] ?? false,
        showCalmScore: json['showCalmScore'] ?? true,
      );
}

// 苦手タグの定義（オンボーディングQ3）
const kAvoidTagOptions = [
  ('loud_sounds', '大声'),
  ('heavy_editing', '過剰編集'),
  ('too_many_humans', '人間が多い'),
  ('sad_context', '悲しい系'),
  ('rescue_stories', '保護系'),
  ('emotional_drama', '感動演出'),
  ('insects', '虫'),
  ('reptiles', '爬虫類'),
  ('loud_music', '騒がしい音'),
];
