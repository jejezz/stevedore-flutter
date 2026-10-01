/// 크기와 수정 시각이 [settle] 동안 변하지 않은 파일만 "다 받았다"고 본다.
/// 임시 확장자를 쓰지 않는 다운로더(스트리밍 저장, 복사 중인 파일)를 거르는 장치다.
class StabilityTracker {
  StabilityTracker({this.settle = const Duration(seconds: 5)});

  final Duration settle;
  final Map<String, _Seen> _seen = {};

  /// [path]를 지금 관찰한 결과 안정됐는지. 처음 보거나 값이 바뀌었으면 false.
  bool isStable(String path, {required int size, required DateTime modified, required DateTime now}) {
    final seen = _seen[path];
    if (seen == null || seen.size != size || seen.modified != modified) {
      _seen[path] = _Seen(size, modified, now);
      return false;
    }
    return now.difference(seen.since) >= settle;
  }

  /// 사라진 파일의 기록을 버린다.
  void retainOnly(Set<String> livePaths) => _seen.removeWhere((path, _) => !livePaths.contains(path));

  void forget(String path) => _seen.remove(path);
}

class _Seen {
  _Seen(this.size, this.modified, this.since);

  final int size;
  final DateTime modified;
  final DateTime since;
}
