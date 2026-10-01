import 'dart:convert';
import 'dart:io';

/// 설정 폴더 안의 JSON 파일 하나. 저장은 임시 파일에 쓴 뒤 바꿔치기해서 저장 도중
/// 꺼져도 이전 파일이 남고, 읽다 실패한 깨진 파일은 `.bak`으로 보존한다.
class JsonFile {
  JsonFile(this.directory, this.fileName);

  final Directory directory;
  final String fileName;

  File get _file => File('${directory.path}${Platform.pathSeparator}$fileName');

  /// 파일이 없거나 깨졌으면 null. 깨진 파일은 `.bak`으로 옮겨 둔다.
  Future<Map<String, Object?>?> read() async {
    final file = _file;
    if (!await file.exists()) return null;
    try {
      return jsonDecode(await file.readAsString()) as Map<String, Object?>;
    } on Object {
      await quarantine();
      return null;
    }
  }

  Future<void> write(Map<String, Object?> json) async {
    await directory.create(recursive: true);
    final tmp = File('${_file.path}.tmp');
    await tmp.writeAsString(const JsonEncoder.withIndent('  ').convert(json), flush: true);
    await tmp.rename(_file.path);
  }

  /// 내용을 해석하지 못한 파일을 `.bak`으로 옮긴다 (읽는 쪽이 형식 오류를 찾았을 때도 쓴다).
  Future<void> quarantine() async {
    final file = _file;
    if (await file.exists()) await file.rename('${file.path}.bak');
  }
}
