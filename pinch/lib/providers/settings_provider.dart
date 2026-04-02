import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/settings_service.dart';

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, UserSettings>(SettingsNotifier.new);

class SettingsNotifier extends AsyncNotifier<UserSettings> {
  @override
  Future<UserSettings> build() async {
    final service = ref.read(settingsServiceProvider);
    return service.load();
  }

  Future<void> save(UserSettings settings) async {
    final service = ref.read(settingsServiceProvider);
    await service.save(settings);
    state = AsyncData(settings);
  }
}
