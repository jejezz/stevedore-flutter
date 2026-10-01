import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import 'paths.dart';

/// 파일을 실제로 옮기고 휴지통에 보내는 부분. 엔진은 이 인터페이스만 안다.
abstract class FileOps {
  /// [src]를 [destDir]로 옮기고 최종 경로를 돌려준다. 같은 이름이 있으면
  /// `이름 (1).확장자`처럼 번호를 붙여 덮어쓰지 않는다. [asName]을 주면 그 이름으로
  /// 옮긴다 (되돌리기에서 원래 이름을 되찾을 때).
  Future<String> move(String src, String destDir, {String? asName});

  /// 휴지통으로 보낸다. 휴지통 안의 경로를 알 수 있으면 돌려준다 (되돌리기용).
  Future<String?> trash(String path);
}

class SystemFileOps implements FileOps {
  SystemFileOps({this.env});

  static const _channel = MethodChannel('art.zoomon.stevedore/trash');
  final Map<String, String>? env;

  @override
  Future<String> move(String src, String destDir, {String? asName}) async {
    final dir = expandPath(destDir, env: env);
    await Directory(dir).create(recursive: true);
    final target = await uniquePath(dir, asName ?? p.basename(src));
    try {
      await File(src).rename(target);
    } on FileSystemException catch (e) {
      // 다른 볼륨으로는 rename이 안 된다 (POSIX EXDEV 18, Windows 17): 복사 후 삭제.
      final code = e.osError?.errorCode;
      if (code != 18 && code != 17) rethrow;
      await File(src).copy(target);
      await File(src).delete();
    }
    return target;
  }

  @override
  Future<String?> trash(String path) async {
    if (Platform.isMacOS) {
      return _channel.invokeMethod<String>('trash', path);
    }
    if (Platform.isWindows) {
      // 경로는 환경 변수로 넘겨 따옴표 이스케이프 문제를 피한다.
      final result = await Process.run(
        'powershell',
        [
          '-NoProfile',
          '-NonInteractive',
          '-Command',
          'Add-Type -AssemblyName Microsoft.VisualBasic; '
              r"[Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($env:STEVEDORE_TRASH_PATH, 'OnlyErrorDialogs', 'SendToRecycleBin')",
        ],
        environment: {'STEVEDORE_TRASH_PATH': path},
      );
      if (result.exitCode != 0) throw FileSystemException('휴지통으로 보내지 못했습니다: ${result.stderr}', path);
      return null;
    }
    throw UnsupportedError('휴지통은 macOS와 Windows만 지원합니다');
  }
}

/// [dir] 안에서 [name]이 비어 있으면 그대로, 아니면 `이름 (1).확장자`, `(2)`…
Future<String> uniquePath(String dir, String name) async {
  var candidate = p.join(dir, name);
  if (!await _exists(candidate)) return candidate;
  final ext = _extensionOf(name);
  final stem = name.substring(0, name.length - ext.length);
  for (var i = 1;; i++) {
    candidate = p.join(dir, '$stem ($i)$ext');
    if (!await _exists(candidate)) return candidate;
  }
}

Future<bool> _exists(String path) async => await FileSystemEntity.type(path, followLinks: false) != FileSystemEntityType.notFound;

/// `tar.gz`처럼 겹 확장자는 마지막 것만 떼면 `a.tar (1).gz`가 되므로 따로 다룬다.
String _extensionOf(String name) {
  final lower = name.toLowerCase();
  for (final double in const ['.tar.gz', '.tar.bz2', '.tar.xz']) {
    if (lower.endsWith(double)) return name.substring(name.length - double.length);
  }
  return p.extension(name);
}
