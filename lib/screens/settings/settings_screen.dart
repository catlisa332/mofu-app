import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_preferences.dart';
import '../../models/video_post.dart';
import '../../providers/learning_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(preferencesProvider);

    return Scaffold(
      backgroundColor: MofuColors.cream,
      appBar: AppBar(
        backgroundColor: MofuColors.cream,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('設定',
            style: TextStyle(
                color: MofuColors.textDark,
                fontSize: 20,
                fontWeight: FontWeight.w300,
                letterSpacing: 2)),
      ),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (prefs) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 好きな動物
            _section('好きな動物', [
              _AnimalSelector(
                selected: prefs.favoriteAnimals.toSet(),
                onChanged: (set) => ref
                    .read(preferencesProvider.notifier)
                    .save(prefs.copyWith(favoriteAnimals: set.toList())),
              ),
            ]),
            const SizedBox(height: 16),

            // 苦手なもの
            _section('苦手なもの（表示しない）', [
              _AvoidTagSelector(
                selected: prefs.avoidTags.toSet(),
                onChanged: (set) => ref
                    .read(preferencesProvider.notifier)
                    .save(prefs.copyWith(avoidTags: set.toList())),
              ),
            ]),
            const SizedBox(height: 16),

            // 表示モード
            _section('表示モード', [
              SwitchListTile(
                title: const Text('夜モード'),
                subtitle: const Text('色をおだやかに'),
                value: prefs.isNightMode,
                activeColor: MofuColors.mossGreen,
                onChanged: (v) =>
                    ref.read(preferencesProvider.notifier).setNightMode(v),
              ),
              SwitchListTile(
                title: const Text('心が疲れてる日モード'),
                subtitle: const Text('超おだやかなコンテンツのみ'),
                value: prefs.isTiredMode,
                activeColor: MofuColors.softLavender,
                onChanged: (v) =>
                    ref.read(preferencesProvider.notifier).setTiredMode(v),
              ),
              SwitchListTile(
                title: const Text('Calm Scoreを表示'),
                value: prefs.showCalmScore,
                activeColor: MofuColors.warmTan,
                onChanged: (v) => ref
                    .read(preferencesProvider.notifier)
                    .save(prefs.copyWith(showCalmScore: v)),
              ),
            ]),
            const SizedBox(height: 16),

            // 音声
            _section('音声', [
              SwitchListTile(
                title: const Text('ミュートを優先'),
                subtitle: const Text('音量の大きいコンテンツを下げる'),
                value: prefs.isMutePreferred,
                activeColor: MofuColors.warmTan,
                onChanged: (v) => ref
                    .read(preferencesProvider.notifier)
                    .save(prefs.copyWith(isMutePreferred: v)),
              ),
            ]),
            const SizedBox(height: 16),

            // アカウント
            _section('アカウント', [
              ListTile(
                leading: const Text('☁️', style: TextStyle(fontSize: 20)),
                title: const Text('ログイン'),
                subtitle: const Text('お気に入りをデバイス間で同期'),
                trailing: const Icon(Icons.chevron_right,
                    color: MofuColors.textLight),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // 学習結果
            _LearningSection(),
            const SizedBox(height: 16),

            // その他
            _section('その他', [
              ListTile(
                leading: const Text('🔄', style: TextStyle(fontSize: 20)),
                title: const Text('最初からやり直す'),
                subtitle: const Text('好みの設定をリセット'),
                onTap: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      title: const Text('設定をリセット？'),
                      content: const Text('好みの設定・苦手リストがリセットされます。'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('キャンセル',
                              style: TextStyle(color: MofuColors.textLight)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('リセット',
                              style: TextStyle(color: Color(0xFFE07B5A))),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await ref
                        .read(preferencesProvider.notifier)
                        .save(const UserPreferences());
                    final sp = await SharedPreferences.getInstance();
                    await sp.remove('onboarding_done');
                    await sp.remove('leaf_hint_shown');
                    await sp.remove('install_banner_dismissed');
                    if (context.mounted) context.go('/onboarding');
                  }
                },
              ),
              const Divider(height: 1, indent: 16),
              ListTile(
                leading: const Text('ℹ️', style: TextStyle(fontSize: 20)),
                title: const Text('バージョン'),
                trailing: const Text('v0.1.0',
                    style: TextStyle(
                        color: MofuColors.textLight, fontSize: 13)),
              ),
            ]),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Text(title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: MofuColors.textLight,
                letterSpacing: 0.5,
              )),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

// 学習結果表示
class _LearningSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final learner = ref.watch(learningProvider.notifier);
    final topTags = learner.topTags;

    if (topTags.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Text('あなたの好み（学習中）',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: MofuColors.textLight,
                letterSpacing: 0.5,
              )),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: topTags.map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: MofuColors.softPeach,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('❤️', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text('#$tag',
                      style: const TextStyle(
                          fontSize: 12,
                          color: MofuColors.softBrown,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }
}

// 好きな動物セレクター
class _AnimalSelector extends StatelessWidget {
  final Set<AnimalType> selected;
  final void Function(Set<AnimalType>) onChanged;

  const _AnimalSelector({required this.selected, required this.onChanged});

  static const _items = [
    (AnimalType.cat,         '🐱', '猫'),
    (AnimalType.dog,         '🐶', '犬'),
    (AnimalType.smallAnimal, '🐹', '小動物'),
    (AnimalType.bird,        '🐦', '鳥'),
    (AnimalType.otter,       '🦦', 'カワウソ'),
    (AnimalType.capybara,    '🦫', 'カピバラ'),
    (AnimalType.reptile,     '🦎', '爬虫類'),
    (AnimalType.seaCreature, '🐠', '海の生き物'),
    (AnimalType.mixedSpecies,'🐾', '異種仲良し'),
    (AnimalType.babyAnimal,  '🍼', '赤ちゃん動物'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _items.map((item) {
          final isSel = selected.contains(item.$1);
          return GestureDetector(
            onTap: () {
              final next = {...selected};
              isSel ? next.remove(item.$1) : next.add(item.$1);
              onChanged(next);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSel ? MofuColors.warmTan : MofuColors.cream,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSel ? MofuColors.warmTan : MofuColors.divider,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item.$2, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(item.$3,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSel ? Colors.white : MofuColors.textDark,
                        fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                      )),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// 苦手タグセレクター
class _AvoidTagSelector extends StatelessWidget {
  final Set<String> selected;
  final void Function(Set<String>) onChanged;

  const _AvoidTagSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: kAvoidTagOptions.map((item) {
          final isSel = selected.contains(item.$1);
          return GestureDetector(
            onTap: () {
              final next = {...selected};
              isSel ? next.remove(item.$1) : next.add(item.$1);
              onChanged(next);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSel ? const Color(0xFFE07B5A) : MofuColors.cream,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSel
                      ? const Color(0xFFE07B5A)
                      : MofuColors.divider,
                ),
              ),
              child: Text(item.$2,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSel ? Colors.white : MofuColors.textDark,
                  )),
            ),
          );
        }).toList(),
      ),
    );
  }
}
