import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMagicLink() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;

    setState(() { _loading = true; _error = null; });

    try {
      await Supabase.instance.client.auth.signInWithOtp(email: email);
      if (mounted) setState(() { _sent = true; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MofuColors.cream,
      appBar: AppBar(
        backgroundColor: MofuColors.cream,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('ログイン',
            style: TextStyle(
                color: MofuColors.textDark,
                fontWeight: FontWeight.w300,
                letterSpacing: 2)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _sent ? _buildSentState() : _buildEmailForm(),
      ),
    );
  }

  Widget _buildEmailForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🐾', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 16),
        const Text('メールアドレスでログイン',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w300,
                color: MofuColors.textDark)),
        const SizedBox(height: 8),
        Text('お気に入りを複数のデバイスで同期できます',
            style: TextStyle(fontSize: 13, color: MofuColors.textLight)),
        const SizedBox(height: 32),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: MofuColors.divider),
          ),
          child: TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'メールアドレス',
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none,
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!,
              style: const TextStyle(color: Color(0xFFE07B5A), fontSize: 12)),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _loading ? null : _sendMagicLink,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('マジックリンクを送信',
                    style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ログインせずに続ける',
                style: TextStyle(color: MofuColors.textLight)),
          ),
        ),
      ],
    );
  }

  Widget _buildSentState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📬', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 20),
          const Text('メールを送りました！',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300)),
          const SizedBox(height: 12),
          Text(
            '${_emailCtrl.text} に届いたリンクをタップしてください',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: MofuColors.textLight),
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () => setState(() => _sent = false),
            child: const Text('メールアドレスを変更',
                style: TextStyle(color: MofuColors.textLight)),
          ),
        ],
      ),
    );
  }
}
