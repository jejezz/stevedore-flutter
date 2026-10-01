/// 정리 대상에서 빼는 파일: 받는 중인 임시 파일, 숨김 파일, OS가 만든 파일.
/// 브라우저는 받는 동안 이 확장자로 쓰다가 끝나면 최종 이름으로 바꾼다.
const _partialSuffixes = [
  '.crdownload', // Chrome, Edge
  '.download', // Safari, Firefox (macOS)
  '.part', // Firefox
  '.partial',
  '.opdownload', // Opera
  '.aria2',
  '.!ut', // uTorrent
  '.bc!', // BitComet
  '.tmp',
];

const _systemNames = {'desktop.ini', 'thumbs.db'};

bool isIgnoredFileName(String name) {
  final lower = name.toLowerCase();
  if (lower.startsWith('.') || lower.startsWith('~\$')) return true;
  if (_systemNames.contains(lower)) return true;
  return _partialSuffixes.any(lower.endsWith);
}
