import 'dart:io';

/// `~`와 `~/…`를 홈 폴더로 풀고, 끝의 구분자를 없앤다. 규칙에 적힌 폴더 경로는
/// 항상 이 함수를 거쳐 비교·사용한다.
String expandPath(String path, {Map<String, String>? env}) {
  final e = env ?? Platform.environment;
  final home = e['HOME'] ?? e['USERPROFILE'] ?? '';
  var p = path.trim();
  if (p == '~') {
    p = home;
  } else if (p.startsWith('~/') || p.startsWith('~\\')) {
    p = '$home${p.substring(1)}';
  }
  while (p.length > 1 && (p.endsWith('/') || p.endsWith('\\'))) {
    p = p.substring(0, p.length - 1);
  }
  return p;
}

/// 홈 폴더 아래 경로를 `~/…`로 줄여 보여준다 (규칙에 저장되는 형식).
String abbreviateHome(String path, {Map<String, String>? env}) {
  final e = env ?? Platform.environment;
  final home = e['HOME'] ?? e['USERPROFILE'] ?? '';
  if (home.isEmpty) return path;
  if (path == home) return '~';
  if (path.startsWith('$home/') || path.startsWith('$home\\')) return '~${path.substring(home.length)}';
  return path;
}
