import 'dart:io';

import '../rules/rule_store.dart';
import '../storage/json_file.dart';

enum HistoryKind { move, trash }

/// 정리한 파일 하나의 기록. 되돌리기에 필요한 경로를 함께 남긴다.
class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.time,
    required this.ruleId,
    required this.ruleName,
    required this.kind,
    required this.fileName,
    required this.sourcePath,
    this.resultPath,
    this.error,
    this.restoredPath,
  });

  final String id;
  final DateTime time;
  final String ruleId;
  final String ruleName;
  final HistoryKind kind;
  final String fileName;
  final String sourcePath;

  /// 옮긴 곳, 또는 휴지통 안의 위치. 휴지통 위치를 알 수 없으면 null (Windows).
  final String? resultPath;
  final String? error;

  /// 되돌렸다면 되돌려진 위치.
  final String? restoredPath;

  bool get succeeded => error == null;
  bool get undone => restoredPath != null;
  bool get canUndo => succeeded && !undone && resultPath != null;

  HistoryEntry withRestored(String path) => HistoryEntry(
        id: id,
        time: time,
        ruleId: ruleId,
        ruleName: ruleName,
        kind: kind,
        fileName: fileName,
        sourcePath: sourcePath,
        resultPath: resultPath,
        error: error,
        restoredPath: path,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'time': time.toIso8601String(),
        'ruleId': ruleId,
        'ruleName': ruleName,
        'kind': kind.name,
        'fileName': fileName,
        'sourcePath': sourcePath,
        if (resultPath != null) 'resultPath': resultPath,
        if (error != null) 'error': error,
        if (restoredPath != null) 'restoredPath': restoredPath,
      };

  factory HistoryEntry.fromJson(Map<String, Object?> json) => HistoryEntry(
        id: json['id'] as String,
        time: DateTime.parse(json['time'] as String),
        ruleId: json['ruleId'] as String,
        ruleName: json['ruleName'] as String,
        kind: HistoryKind.values.byName(json['kind'] as String),
        fileName: json['fileName'] as String,
        sourcePath: json['sourcePath'] as String,
        resultPath: json['resultPath'] as String?,
        error: json['error'] as String?,
        restoredPath: json['restoredPath'] as String?,
      );
}

/// 기록을 `history.json`에 저장한다. 최근 [maxEntries]개만 남긴다.
class HistoryStore {
  HistoryStore(Directory directory) : _file = JsonFile(directory, fileName);

  factory HistoryStore.standard() => HistoryStore(Directory(RuleStore.appSupportPath()));

  static const fileName = 'history.json';
  static const maxEntries = 500;

  final JsonFile _file;

  /// 최신 항목이 앞에 오는 목록.
  Future<List<HistoryEntry>> load() async {
    final json = await _file.read();
    if (json == null) return [];
    try {
      return [for (final e in (json['entries'] as List)) HistoryEntry.fromJson((e as Map).cast<String, Object?>())];
    } on Object {
      await _file.quarantine();
      return [];
    }
  }

  Future<void> save(List<HistoryEntry> entries) => _file.write({
        'version': 1,
        'entries': [for (final e in entries.take(maxEntries)) e.toJson()],
      });
}
