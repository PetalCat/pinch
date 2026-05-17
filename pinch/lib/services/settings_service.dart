import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class UserSettings {
  final String? defaultProjectDir;
  final String model;
  final String permissionMode;
  final String effort;
  final bool dangerouslySkipPermissions;
  final bool worktree;
  final String serverHost;
  final int serverPort;
  final String serverToken;

  const UserSettings({
    this.defaultProjectDir,
    this.model = 'auto',
    this.permissionMode = 'default',
    this.effort = 'high',
    this.dangerouslySkipPermissions = false,
    this.worktree = false,
    this.serverHost = 'localhost',
    this.serverPort = 7464,
    this.serverToken = '',
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) => UserSettings(
        defaultProjectDir: json['defaultProjectDir'] as String?,
        model: json['model'] as String? ?? 'auto',
        permissionMode: json['permissionMode'] as String? ?? 'default',
        effort: json['effort'] as String? ?? 'high',
        dangerouslySkipPermissions:
            json['dangerouslySkipPermissions'] as bool? ?? false,
        worktree: json['worktree'] as bool? ?? false,
        serverHost: json['serverHost'] as String? ?? 'localhost',
        serverPort: json['serverPort'] as int? ?? 7464,
        serverToken: json['serverToken'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'defaultProjectDir': defaultProjectDir,
        'model': model,
        'permissionMode': permissionMode,
        'effort': effort,
        'dangerouslySkipPermissions': dangerouslySkipPermissions,
        'worktree': worktree,
        'serverHost': serverHost,
        'serverPort': serverPort,
        'serverToken': serverToken,
      };

  UserSettings copyWith({
    String? defaultProjectDir,
    String? model,
    String? permissionMode,
    String? effort,
    bool? dangerouslySkipPermissions,
    bool? worktree,
    String? serverHost,
    int? serverPort,
    String? serverToken,
  }) =>
      UserSettings(
        defaultProjectDir: defaultProjectDir ?? this.defaultProjectDir,
        model: model ?? this.model,
        permissionMode: permissionMode ?? this.permissionMode,
        effort: effort ?? this.effort,
        dangerouslySkipPermissions:
            dangerouslySkipPermissions ?? this.dangerouslySkipPermissions,
        worktree: worktree ?? this.worktree,
        serverHost: serverHost ?? this.serverHost,
        serverPort: serverPort ?? this.serverPort,
        serverToken: serverToken ?? this.serverToken,
      );
}

class SettingsService {
  File? _file;

  Future<File> _getFile() async {
    if (_file != null) return _file!;
    final dir = await getApplicationSupportDirectory();
    _file = File('${dir.path}/pinch_settings.json');
    return _file!;
  }

  Future<UserSettings> load() async {
    try {
      final file = await _getFile();
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString());
        return UserSettings.fromJson(json as Map<String, dynamic>);
      }
    } catch (_) {}
    return const UserSettings();
  }

  Future<void> save(UserSettings settings) async {
    final file = await _getFile();
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(settings.toJson()),
    );
  }
}
