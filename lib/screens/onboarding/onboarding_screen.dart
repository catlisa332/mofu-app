import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_preferences.dart';
import '../../models/video_post.dart';
import '../../providers/preferences_provider.dart';
import '../../theme/app_theme.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  // 0=ウェルカム, 1=動物, 2=雰囲気, 3=苦手
  static const _totalPages = 4;

  final Set<AnimalType> _selectedAnimals = {};
  final Set<MoodType> _selectedMoods = {};
  final Set<String> _selectedAvoidTags = {};

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    final prefs = UserPreferences(
      favoriteAnimals: _selectedAnimals.toList(),
      preferredMoods: _selectedMoods.toList(),
      avoidTags: _selectedAvoidTags.toList(),
    );
    await ref.read(preferencesProvider.notifier).save(prefs);
    await markOnboardingDone();
    if (mounted) context.go('/feed');
  }

  String get _buttonLabel {
    if (_currentPage == 0) return 'はじめる';
    if (_currentPage == _totalPages - 1) return 'MOFUを開く 🐾';
    return 'つぎへ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MofuColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            // プログレスバー（ウェルカム画面は非表示）
            AnimatedOpacity(
              opacity: _currentPage == 0 ? 0 : 1,
              duration: const Duration(milliseconds: 300),
              child: _buildProgress(),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  const _WelcomePage(),
                  _AnimalTypePage(
                    selected: _selectedAnimals,
                    onToggle: (a) => setState(() => _selectedAnimals.contains(a)
                        ? _selectedAnimals.remove(a)
                        : _selectedAnimals.add(a)),
                  ),
                  _MoodTypePage(
                    selected: _selectedMoods,
                    onToggle: (m) => setState(() => _selectedMoods.contains(m)
                        ? _selectedMoods.remove(m)
                        : _selectedMoods.add(m)),
                  ),
                  _AvoidTagPage(
                    selected: _selectedAvoidTags,
                    onToggle: (t) => setState(
                        () => _selectedAvoidTags.contains(t)
                            ? _selectedAvoidTags.remove(t)
                            : _selectedAvoidTags.add(t)),
                    onSkip: _finishOnboarding,
                  ),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress() {
    // Q3枚のうち何枚目か（ウェルカムを除く）
    final step = (_currentPage - 1).clamp(0, 2);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: List.generate(3, (i) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              height: 4,
              decoration: BoxDecoration(
                color: i <= step ? MofuColors.warmTan : MofuColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        )),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _nextPage,
          style: ElevatedButton.styleFrom(
            backgroundColor: _currentPage == _totalPages - 1
                ? MofuColors.mossGreen
                : MofuColors.warmTan,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _buttonLabel,
              key: ValueKey(_currentPage),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}

// ウェルカム画面
class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🐾', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 24),
          const Text(
            'MOFU',
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w200,
              letterSpacing: 10,
              color: MofuColors.softBrown,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '疲れた脳にモフを補給',
            style: TextStyle(
              fontSize: 16,
              color: MofuColors.textLight,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 48),
          _featureRow('🚫', '炎上・不安・刺激を排除'),
          const SizedBox(height: 14),
          _featureRow('🧠', '脳を休ませるフィード'),
          const SizedBox(height: 14),
          _featureRow('🫂', '心が疲れてる日の特別モード'),
          const SizedBox(height: 48),
          Text(
            'あなたの好みを教えてください\n（3問だけ）',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: MofuColors.textLight,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureRow(String emoji, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 14),
          Text(text,
              style: const TextStyle(
                fontSize: 15,
                color: MofuColors.textDark,
                fontWeight: FontWeight.w400,
              )),
        ],
      ),
    );
  }
}

// Q1: 好きな動物
class _AnimalTypePage extends StatelessWidget {
  final Set<AnimalType> selected;
  final void Function(AnimalType) onToggle;

  const _AnimalTypePage({required this.selected, required this.onToggle});

  static const _animals = [
    (AnimalType.cat, '🐱', '猫'),
    (AnimalType.dog, '🐶', '犬'),
    (AnimalType.smallAnimal, '🐹', '小動物'),
    (AnimalType.bird, '🐦', '鳥'),
    (AnimalType.otter, '🦦', 'カワウソ'),
    (AnimalType.capybara, '🦫', 'カピバラ'),
    (AnimalType.reptile, '🦎', '爬虫類'),
    (AnimalType.seaCreature, '🐠', '海の生き物'),
    (AnimalType.mixedSpecies, '🐾', '異種仲良し'),
    (AnimalType.babyAnimal, '🍼', '赤ちゃん動物'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('好きな動物は？',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w300,
                  color: MofuColors.textDark)),
          const SizedBox(height: 6),
          const Text('複数選べます・あとで変えられます',
              style: TextStyle(fontSize: 13, color: MofuColors.textLight)),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.8,
              children: _animals.map((item) {
                final isSelected = selected.contains(item.$1);
                return _SelectTile(
                  emoji: item.$2,
                  label: item.$3,
                  isSelected: isSelected,
                  selectedColor: MofuColors.warmTan,
                  onTap: () => onToggle(item.$1),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// Q2: 見たい雰囲気
class _MoodTypePage extends StatelessWidget {
  final Set<MoodType> selected;
  final void Function(MoodType) onToggle;

  const _MoodTypePage({required this.selected, required this.onToggle});

  static const _moods = [
    (MoodType.healing, '🌸', '癒し'),
    (MoodType.spacing, '😶', 'ぼーっとしたい'),
    (MoodType.laughing, '😄', '笑いたい'),
    (MoodType.asmr, '🎵', 'ASMR'),
    (MoodType.quiet, '🤫', '静か'),
    (MoodType.sleep, '🌙', '寝る前向け'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('どんな雰囲気が好き？',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w300,
                  color: MofuColors.textDark)),
          const SizedBox(height: 6),
          const Text('複数選べます',
              style: TextStyle(fontSize: 13, color: MofuColors.textLight)),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.8,
              children: _moods.map((item) {
                final isSelected = selected.contains(item.$1);
                return _SelectTile(
                  emoji: item.$2,
                  label: item.$3,
                  isSelected: isSelected,
                  selectedColor: MofuColors.mossGreen,
                  onTap: () => onToggle(item.$1),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// Q3: 苦手なもの
class _AvoidTagPage extends StatelessWidget {
  final Set<String> selected;
  final void Function(String) onToggle;
  final VoidCallback onSkip;

  const _AvoidTagPage({
    required this.selected,
    required this.onToggle,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text('苦手なものは？',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w300,
                        color: MofuColors.textDark)),
              ),
              TextButton(
                onPressed: onSkip,
                child: const Text('スキップ',
                    style: TextStyle(
                        color: MofuColors.textLight, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('選んだものは一切表示しません',
              style: TextStyle(fontSize: 13, color: MofuColors.textLight)),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: kAvoidTagOptions.map((item) {
                  final isSelected = selected.contains(item.$1);
                  return GestureDetector(
                    onTap: () => onToggle(item.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFE07B5A)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFE07B5A)
                              : MofuColors.divider,
                        ),
                      ),
                      child: Text(item.$2,
                          style: TextStyle(
                            fontSize: 14,
                            color: isSelected
                                ? Colors.white
                                : MofuColors.textDark,
                          )),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 共通の選択タイル
class _SelectTile extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _SelectTile({
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? selectedColor : MofuColors.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(
                  color: selectedColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? Colors.white : MofuColors.textDark,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                )),
          ],
        ),
      ),
    );
  }
}
