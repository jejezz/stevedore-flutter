import 'rule.dart';

/// 처음 쓰는 사람을 위한 추천 규칙. 이름과 이동 폴더 이름은 언어에 따라 달라서
/// 만드는 쪽(화면)이 문구를 넘겨준다.
enum RulePreset {
  oldInstallers(['dmg', 'pkg', 'exe', 'msi'], olderThanDays: 30, trash: true),
  documents(['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'hwp', 'hwpx', 'txt', 'rtf', 'csv']),
  images(['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'bmp', 'svg', 'tiff']),
  installers(['dmg', 'pkg', 'exe', 'msi']),
  archives(['zip', 'rar', '7z', 'tar', 'tgz', 'gz', 'bz2', 'xz']);

  const RulePreset(this.extensions, {this.olderThanDays, this.trash = false});

  final List<String> extensions;
  final int? olderThanDays;

  /// 휴지통으로 보내는 규칙. 파일이 사라지는 쪽이라 처음에는 선택하지 않은 채로 보여준다.
  final bool trash;

  /// 이동 규칙의 목적지는 감시 폴더 안의 하위 폴더 — 파일이 Downloads 밖으로 사라지지 않는다.
  Rule build({required String id, required String name, required String folderName, String watchedFolder = '~/Downloads'}) =>
      Rule(
        id: id,
        name: name,
        watchedFolder: watchedFolder,
        condition: RuleCondition(extensions: extensions, olderThanDays: olderThanDays),
        action: trash ? const TrashAction() : MoveAction('$watchedFolder/$folderName'),
      );
}
