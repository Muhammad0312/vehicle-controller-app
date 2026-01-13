import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettings(
      ip: prefs.getString('tcp_ip') ?? '192.168.1.100',
      port: prefs.getInt('tcp_port') ?? 8080,
      controllerId: prefs.getString('controller_id') ?? 'touch_drive',
      steeringSensitivity: prefs.getDouble('sensitivity') ?? 1.0,
      deadzone: prefs.getDouble('deadzone') ?? 0.05,
    );
  }

  Future<void> updateSettings({
    String? ip,
    int? port,
    String? controllerId,
    double? steeringSensitivity,
    double? deadzone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (ip != null) await prefs.setString('tcp_ip', ip);
    if (port != null) await prefs.setInt('tcp_port', port);
    if (controllerId != null)
      await prefs.setString('controller_id', controllerId);
    if (steeringSensitivity != null)
      await prefs.setDouble('sensitivity', steeringSensitivity);
    if (deadzone != null) await prefs.setDouble('deadzone', deadzone);

    state = state.copyWith(
      ip: ip,
      port: port,
      controllerId: controllerId,
      steeringSensitivity: steeringSensitivity,
      deadzone: deadzone,
    );
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  return SettingsNotifier();
});
