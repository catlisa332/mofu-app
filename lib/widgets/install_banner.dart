import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kInstallBannerKey = 'install_banner_dismissed';

class InstallBanner extends StatefulWidget {
  const InstallBanner({super.key});

  @override
  State<InstallBanner> createState() => _InstallBannerState();
}

class _InstallBannerState extends State<InstallBanner> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _checkShouldShow();
  }

  Future<void> _checkShouldShow() async {
    final sp = await SharedPreferences.getInstance();
    final dismissed = sp.getBool(_kInstallBannerKey) ?? false;
    if (!dismissed && mounted) {
      // 少し待ってから表示（フィードが読み込まれた後）
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) setState(() => _visible = true);
    }
  }

  Future<void> _dismiss() async {
    setState(() => _visible = false);
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kInstallBannerKey, true);
  }

  void _showGuide() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _InstallGuideSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      child: GestureDetector(
        onTap: _showGuide,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0E0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD4A98A), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4A98A).withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // ✕ を左端に配置（右端の FAB と被らないよう）
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _dismiss,
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(0, 8, 10, 8),
                  child: Icon(Icons.close_rounded,
                      size: 16, color: Color(0xFFB08070)),
                ),
              ),
              const Text('📱', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ホーム画面に追加できるよ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8B6355),
                        )),
                    SizedBox(height: 2),
                    Text('アプリみたいに使えるようになるよ →',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFB08070),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// インストール手順シート
class _InstallGuideSheet extends StatelessWidget {
  const _InstallGuideSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFF8F0),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD4A98A).withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text('🐾', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          const Text('ホーム画面に追加する方法',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3D2B1F),
              )),
          const SizedBox(height: 24),

          // iPhone / Safari
          _GuideSection(
            icon: '📱',
            title: 'iPhone（Safari）',
            steps: const [
              'Safariでこのページを開く',
              '画面下の「共有」ボタン（□↑）をタップ',
              '「ホーム画面に追加」を選ぶ',
              '「追加」をタップして完了',
            ],
          ),
          const SizedBox(height: 16),

          // Android / Chrome
          _GuideSection(
            icon: '🤖',
            title: 'Android（Chrome）',
            steps: const [
              'Chromeでこのページを開く',
              '右上の「⋮」メニューをタップ',
              '「アプリをインストール」または「ホーム画面に追加」を選ぶ',
              '「インストール」をタップして完了',
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4A98A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('わかった！',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  final String icon;
  final String title;
  final List<String> steps;

  const _GuideSection({
    required this.icon,
    required this.title,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF3D2B1F),
                  )),
            ],
          ),
          const SizedBox(height: 10),
          ...steps.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(right: 8, top: 1),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD4A98A),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${e.key + 1}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(e.value,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF5D4037))),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
