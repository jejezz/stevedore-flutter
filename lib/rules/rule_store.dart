import 'dart:convert';
import 'dart:io';

import 'rule.dart';

/// 규칙을 `rules.json`에 저장한다. 위치는 identity.md §6: 설정 폴더 이름은
/// 파일 이름(PascalCase) `Stevedore`.
class RuleStore {
  RuleStore(this.directory);

  /// 이 앱의 설정 폴더 (`~/Library/Application Support/Stevedore`, `%APPDATA%\Stevedore`).
  factory RuleStore.standard() => RuleStore(Directory(defaultDirectoryPath()));

  static const fileName = 'rules.json';

  /// 파일 형식 버전. 형식이 바뀔 때 올리고, 읽을 때 옛 형식을 변환한다.
  static const formatVersion = 1;

  final Directory directory;

  File get _file => File('${directory.path}${Platform.pathSeparator}$fileName');

  static String defaultDirectoryPath() {
    final env = Platform.environment;
    if (Platform.isWindows) return '${env['APPDATA']}\\Stevedore';
    return '${env['HOME']}/Library/Application Support/Stevedore';
  }

  /// 저장된 규칙. 파일이 없으면 빈 목록. 파일이 깨졌으면 `rules.json.bak`으로
  /// 옮겨 두고 빈 목록으로 시작한다 — 읽다 실패해서 규칙을 잃는 일은 없어야 한다.
  Future<List<Rule>> load() async {
    final file = _file;
    if (!await file.exists()) return [];
    try {
      final json = jsonDecode(await file.readAsString()) as Map<String, Object?>;
      return [
        for (final r in (json['rules'] as List)) Rule.fromJson((r as Map).cast<String, Object?>()),
      ];
    } on Object {
      await file.rename('${file.path}.bak');
      return [];
    }
  }

  /// 임시 파일에 쓴 뒤 바꿔치기해서, 저장 도중 꺼져도 이전 파일이 남는다.
  Future<void> save(List<Rule> rules) async {
    await directory.create(recursive: true);
    final tmp = File('${_file.path}.tmp');
    final json = {'version': formatVersion, 'rules': [for (final r in rules) r.toJson()]};
    await tmp.writeAsString(const JsonEncoder.withIndent('  ').convert(json), flush: true);
    await tmp.rename(_file.path);
  }
}
