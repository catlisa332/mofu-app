import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SleepState {
  final bool isActive;
  final int timerMinutes; // 0 = タイマーなし
  final int remainingSeconds;

  const SleepState({
    this.isActive = false,
    this.timerMinutes = 0,
    this.remainingSeconds = 0,
  });

  SleepState copyWith({
    bool? isActive,
    int? timerMinutes,
    int? remainingSeconds,
  }) =>
      SleepState(
        isActive: isActive ?? this.isActive,
        timerMinutes: timerMinutes ?? this.timerMinutes,
        remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      );

  String get timerLabel {
    if (remainingSeconds <= 0) return '';
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return m > 0 ? '$m分${s > 0 ? '$s秒' : ''}' : '$s秒';
  }
}

class SleepNotifier extends Notifier<SleepState> {
  Timer? _timer;

  @override
  SleepState build() => const SleepState();

  void activate({int timerMinutes = 0}) {
    _timer?.cancel();
    state = SleepState(
      isActive: true,
      timerMinutes: timerMinutes,
      remainingSeconds: timerMinutes * 60,
    );

    if (timerMinutes > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        final remaining = state.remainingSeconds - 1;
        if (remaining <= 0) {
          deactivate();
        } else {
          state = state.copyWith(remainingSeconds: remaining);
        }
      });
    }
  }

  void deactivate() {
    _timer?.cancel();
    _timer = null;
    state = const SleepState();
  }

}

final sleepProvider = NotifierProvider<SleepNotifier, SleepState>(
  SleepNotifier.new,
);
