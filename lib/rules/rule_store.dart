import 'dart:io';

import '../storage/json_file.dart';
import 'rule.dart';

/// 규칙을 `rules.json`에 저장한다. 위치는 identity.md §6: 설정 폴더 이름은
/// 파일 이름(PascalCase) `Stevedore`.
class RuleStore {
  RuleStore(this.directory) : _file = JsonFile(directory, fileName);

  /// 이 앱의 설정 폴더 (`~/Library/Application Support/Stevedore`, `%APPDATA%\Stevedore`).
  factory RuleStore.standard() => RuleStore(Directory(appSupportPath()));

  static const fileName = 'rules.json';

  /// 파일 형식 버전. 형식이 바뀔 때 올리고, 읽을 때 옛 형식을 변환한다.
  static const formatVersion = 1;

  final Directory directory;
  final JsonFile _file;

  static String appSupportPath() {
    final env = Platform.environment;
    if (Platform.isWindows) return '${env['APPDATA']}\\Stevedore';
    return '${env['HOME']}/Library/Application Support/Stevedore';
  }

  /// 저장된 규칙. 파일이 없으면 빈 목록. 파일이 깨졌으면 `rules.json.bak`으로
  /// 옮겨 두고 빈 목록으로 시작한다 — 읽다 실패해서 규칙을 잃는 일은 없어야 한다.
  Future<List<Rule>> load() async {
    final json = await _file.read();
    if (json == null) return [];
    try {
      return [
        for (final r in (json['rules'] as List)) Rule.fromJson((r as Map).cast<String, Object?>()),
      ];
    } on Object {
      await _file.quarantine();
      return [];
    }
  }

  Future<void> save(List<Rule> rules) =>
      _file.write({'version': formatVersion, 'rules': [for (final r in rules) r.toJson()]});
}
