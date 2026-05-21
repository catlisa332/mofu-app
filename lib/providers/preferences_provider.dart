import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_preferences.dart';

const _kPrefsKey = 'user_preferences';
const _kOnboardingDone = 'onboarding_done';

class PreferencesNotifier extends AsyncNotifier<UserPreferences> {
  @override
  Future<UserPreferences> build() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_kPrefsKey);
    if (json == null) return const UserPreferences();
    return UserPreferences.fromJson(jsonDecode(json));
  }

  Future<void> save(UserPreferences prefs) async {
    state = AsyncData(prefs);
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kPrefsKey, jsonEncode(prefs.toJson()));
  }

  Future<void> setTiredMode(bool value) async {
    final current = state.valueOrNull ?? const UserPreferences();
    await save(current.copyWith(isTiredMode: value));
  }

  Future<void> setNightMode(bool value) async {
    final current = state.valueOrNull ?? const UserPreferences();
    await save(current.copyWith(isNightMode: value));
  }
}

final preferencesProvider =
    AsyncNotifierProvider<PreferencesNotifier, UserPreferences>(
  PreferencesNotifier.new,
);

final isOnboardingDoneProvider = FutureProvider<bool>((ref) async {
  final sp = await SharedPreferences.getInstance();
  return sp.getBool(_kOnboardingDone) ?? false;
});

Future<void> markOnboardingDone() async {
  final sp = await SharedPreferences.getInstance();
  await sp.setBool(_kOnboardingDone, true);
}
