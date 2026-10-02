/// 정리 규칙의 데이터 모델과 매칭. 파일 시스템을 건드리지 않는 순수 코드라서
/// 감시·실행 쪽과 따로 테스트한다.
library;

/// 매칭에 필요한 파일 정보 (이름, 크기, 수정 시각).
class FileFacts {
  const FileFacts({required this.name, required this.sizeBytes, required this.modified});

  final String name;
  final int sizeBytes;
  final DateTime modified;
}

/// 지정한 조건을 **모두** 만족해야 일치한다 (AND). 비어 있는 항목은 보지 않는다.
class RuleCondition {
  const RuleCondition({
    this.extensions = const [],
    this.nameContains,
    this.minSizeBytes,
    this.maxSizeBytes,
    this.olderThanDays,
  });

  /// 점 없는 소문자. 여러 개면 하나라도 맞으면 된다. `tar.gz` 같은 겹 확장자도 된다.
  final List<String> extensions;

  /// 대소문자 구분 없이 이름에 들어 있는 글자.
  final String? nameContains;
  final int? minSizeBytes;
  final int? maxSizeBytes;

  /// 수정한 지 이 일수 이상 지난 파일.
  final int? olderThanDays;

  /// 조건이 하나도 없으면 모든 파일에 일치하게 되므로, 그런 규칙은 아무 것도 고르지 않는다.
  bool get isEmpty =>
      extensions.isEmpty &&
      (nameContains == null || nameContains!.isEmpty) &&
      minSizeBytes == null &&
      maxSizeBytes == null &&
      olderThanDays == null;

  bool matches(FileFacts file, {required DateTime now}) {
    if (isEmpty) return false;
    final lowerName = file.name.toLowerCase();
    if (extensions.isNotEmpty && !extensions.any((e) => lowerName.endsWith('.${normalizeExtension(e)}'))) {
      return false;
    }
    final contains = nameContains;
    if (contains != null && contains.isNotEmpty && !lowerName.contains(contains.toLowerCase())) {
      return false;
    }
    if (minSizeBytes != null && file.sizeBytes < minSizeBytes!) return false;
    if (maxSizeBytes != null && file.sizeBytes > maxSizeBytes!) return false;
    if (olderThanDays != null && now.difference(file.modified) < Duration(days: olderThanDays!)) {
      return false;
    }
    return true;
  }

  static String normalizeExtension(String e) {
    var s = e.trim().toLowerCase();
    while (s.startsWith('.')) {
      s = s.substring(1);
    }
    return s;
  }

  Map<String, Object?> toJson() => {
        if (extensions.isNotEmpty) 'extensions': [for (final e in extensions) normalizeExtension(e)],
        if (nameContains != null && nameContains!.isNotEmpty) 'nameContains': nameContains,
        if (minSizeBytes != null) 'minSizeBytes': minSizeBytes,
        if (maxSizeBytes != null) 'maxSizeBytes': maxSizeBytes,
        if (olderThanDays != null) 'olderThanDays': olderThanDays,
      };

  factory RuleCondition.fromJson(Map<String, Object?> json) => RuleCondition(
        extensions: [
          for (final e in (json['extensions'] as List?) ?? const []) normalizeExtension(e as String),
        ],
        nameContains: json['nameContains'] as String?,
        minSizeBytes: json['minSizeBytes'] as int?,
        maxSizeBytes: json['maxSizeBytes'] as int?,
        olderThanDays: json['olderThanDays'] as int?,
      );
}

/// 일치한 파일에 할 일. 삭제는 항상 휴지통이다 — 영구 삭제 동작은 만들지 않는다.
sealed class RuleAction {
  const RuleAction();

  Map<String, Object?> toJson();

  factory RuleAction.fromJson(Map<String, Object?> json) => switch (json['type']) {
        'move' => MoveAction(json['destination'] as String),
        'trash' => const TrashAction(),
        final other => throw FormatException('알 수 없는 동작: $other'),
      };
}

class MoveAction extends RuleAction {
  const MoveAction(this.destination);

  /// 옮길 폴더. 절대 경로 또는 `~/`로 시작하는 경로.
  final String destination;

  @override
  Map<String, Object?> toJson() => {'type': 'move', 'destination': destination};
}

class TrashAction extends RuleAction {
  const TrashAction();

  @override
  Map<String, Object?> toJson() => {'type': 'trash'};
}

class Rule {
  const Rule({
    required this.id,
    required this.name,
    required this.watchedFolder,
    required this.condition,
    required this.action,
    this.enabled = true,
    this.includeSubfolders = false,
  });

  /// 저장·이력에서 규칙을 가리키는 값. 이름을 바꿔도 변하지 않는다.
  final String id;
  final String name;
  final bool enabled;

  /// 감시할 폴더. 절대 경로 또는 `~/`로 시작하는 경로 (예: `~/Downloads`).
  final String watchedFolder;
  final RuleCondition condition;
  final RuleAction action;

  /// 감시 폴더의 하위 폴더 안 파일도 대상으로 삼는다. 끄면 폴더 바로 아래 파일만 본다.
  final bool includeSubfolders;

  bool matches(FileFacts file, {required DateTime now}) => enabled && condition.matches(file, now: now);

  Rule copyWith({
    String? name,
    bool? enabled,
    String? watchedFolder,
    RuleCondition? condition,
    RuleAction? action,
    bool? includeSubfolders,
  }) =>
      Rule(
        id: id,
        name: name ?? this.name,
        enabled: enabled ?? this.enabled,
        watchedFolder: watchedFolder ?? this.watchedFolder,
        condition: condition ?? this.condition,
        action: action ?? this.action,
        includeSubfolders: includeSubfolders ?? this.includeSubfolders,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'enabled': enabled,
        'watchedFolder': watchedFolder,
        if (includeSubfolders) 'includeSubfolders': true,
        'condition': condition.toJson(),
        'action': action.toJson(),
      };

  factory Rule.fromJson(Map<String, Object?> json) => Rule(
        id: json['id'] as String,
        name: json['name'] as String,
        enabled: json['enabled'] as bool? ?? true,
        includeSubfolders: json['includeSubfolders'] as bool? ?? false,
        watchedFolder: json['watchedFolder'] as String,
        condition: RuleCondition.fromJson((json['condition'] as Map).cast<String, Object?>()),
        action: RuleAction.fromJson((json['action'] as Map).cast<String, Object?>()),
      );
}
