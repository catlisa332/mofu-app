import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/feed_provider.dart';
import '../../providers/sleep_provider.dart';
import '../../theme/app_theme.dart';

class SleepScreen extends ConsumerStatefulWidget {
  const SleepScreen({super.key});

  @override
  ConsumerState<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends ConsumerState<SleepScreen> {
  int _imageIndex = 0;

  // 眠い系タグだけフィルタ
  static const _sleepTags = ['寝顔', '睡眠', 'sleep', 'nap', 'おやすみ'];

  @override
  Widget build(BuildContext context) {
    final sleep = ref.watch(sleepProvider);
    final feedAsync = ref.watch(feedProvider);

    if (!sleep.isActive) {
      return const _SleepEntryScreen();
    }

    // 穏やかな画像だけ抽出
    final calmPosts = feedAsync.valueOrNull
            ?.where((p) => p.calmScore >= 0.75 && !p.hasSadContext)
            .toList() ??
        [];

    final post = calmPosts.isEmpty
        ? null
        : calmPosts[_imageIndex % calmPosts.length];

    return Scaffold(
      backgroundColor: const Color(0xFF1A1410),
      body: GestureDetector(
        onTap: () {
          if (calmPosts.isNotEmpty) {
            setState(() => _imageIndex++);
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 背景画像（暗め）
            if (post != null)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                child: CachedNetworkImage(
                  key: ValueKey(post.id),
                  imageUrl: post.thumbnailUrl,
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(0.55),
                  colorBlendMode: BlendMode.darken,
                  errorWidget: (_, __, ___) =>
                      Container(color: const Color(0xFF1A1410)),
                ),
              ),

            // 全体グラデーション
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x88000000),
                    Color(0x22000000),
                    Color(0x88000000),
                  ],
                ),
              ),
            ),

            // コンテンツ
            SafeArea(
              child: Column(
                children: [
                  // タイマー表示（上部）
                  if (sleep.timerMinutes > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        sleep.timerLabel,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                          letterSpacing: 1,
                        ),
                      ),
                    ),

                  const Spacer(),

                  // 中央メッセージ
                  Column(
                    children: [
                      const Text('🌙',
                          style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 12),
                      const Text(
                        'おやすみ',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 22,
                          fontWeight: FontWeight.w200,
                          letterSpacing: 6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'タップで次の子へ',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // 終了ボタン（下部）
                  Padding(
                    padding: const EdgeInsets.only(bottom: 36),
                    child: TextButton(
                      onPressed: () =>
                          ref.read(sleepProvider.notifier).deactivate(),
                      child: const Text(
                        '睡眠モードを終了',
                        style: TextStyle(
                          color: Colors.white30,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 睡眠モード開始画面
class _SleepEntryScreen extends ConsumerWidget {
  const _SleepEntryScreen();

  static const _timers = [
    (0, 'タイマーなし'),
    (10, '10分後'),
    (20, '20分後'),
    (30, '30分後'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1812),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🌙', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 20),
              const Text(
                '睡眠モード',
                style: TextStyle(
                  color: Color(0xFFEED9B8),
                  fontSize: 26,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'おだやかな動物だけが流れます\n画面が暗くなります',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 13,
                  height: 1.8,
                ),
              ),
              const SizedBox(height: 48),

              // タイマー選択
              const Text(
                'タイマー',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              ..._timers.map((t) => _TimerButton(
                    label: t.$2,
                    onTap: () => ref
                        .read(sleepProvider.notifier)
                        .activate(timerMinutes: t.$1),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TimerButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFEED9B8),
            side: const BorderSide(color: Color(0x44EED9B8)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(label, style: const TextStyle(fontSize: 15)),
        ),
      ),
    );
  }
}
