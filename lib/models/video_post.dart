import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AnimalType {
  cat, dog, smallAnimal, bird, otter, capybara, reptile, seaCreature, mixedSpecies, babyAnimal
}

enum MoodType { healing, spacing, laughing, asmr, quiet, sleep }

class VideoPost {
  final String id;
  final String sourceUrl;
  final String thumbnailUrl;
  final String? videoUrl;
  final AnimalType animalType;
  final List<String> tags;
  final double calmScore;
  final double soundLevel;
  final String mood;
  final bool isAsmr;
  final bool isGif;
  final String? youtubeVideoId; // YouTube動画ID
  final bool hasLoudSounds;
  final bool hasSuddenCuts;
  final bool hasSadContext;
  final DateTime? createdAt;

  const VideoPost({
    required this.id,
    required this.sourceUrl,
    required this.thumbnailUrl,
    this.videoUrl,
    required this.animalType,
    required this.tags,
    required this.calmScore,
    required this.soundLevel,
    required this.mood,
    this.isAsmr = false,
    this.isGif = false,
    this.youtubeVideoId,
    this.hasLoudSounds = false,
    this.hasSuddenCuts = false,
    this.hasSadContext = false,
    this.createdAt,
  });

  bool get isSafeForTiredMode =>
      calmScore >= 0.7 &&
      !hasLoudSounds &&
      !hasSuddenCuts &&
      !hasSadContext &&
      soundLevel <= 0.4;

  Color get calmScoreColor {
    if (calmScore >= 0.7) return MofuColors.calmHigh;
    if (calmScore >= 0.4) return MofuColors.calmMid;
    return MofuColors.calmLow;
  }
}
