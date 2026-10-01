<!-- From jejezz/application-release-templates common/tool/readme @ conventions-v1.
     tool/readme/init_readme.py가 만든 파일입니다 — conventions/readme-guide.md 참고.
     {{TODO: …}}를 모두 채우십시오. 하나라도 남아 있으면 tool/readme/check_readme.py가 실패합니다. -->

<p align="center">
  <img src="assets/icon/app_icon.png" width="128" alt="Stevedore 아이콘">
</p>

<h1 align="center">Stevedore</h1>

<p align="center">
  규칙에 따라 다운로드 폴더를 자동 또는 수동으로 정리하는 무료 오픈소스 <b>Hazel 대안 파일 정리 유틸리티</b> (macOS, Windows).
</p>

<p align="center">
  <a href="https://github.com/jejezz/stevedore-flutter/releases/latest"><img src="https://img.shields.io/github/v/release/jejezz/stevedore-flutter?style=flat-square&color=4c9dff" alt="최신 릴리스"></a>
  <a href="https://github.com/jejezz/stevedore-flutter/releases"><img src="https://img.shields.io/github/downloads/jejezz/stevedore-flutter/total?style=flat-square&color=7c5cff" alt="다운로드"></a>
  <img src="https://img.shields.io/badge/platform-macOS%20%C2%B7%20Windows-34d399?style=flat-square" alt="macOS · Windows">
  <img src="https://img.shields.io/badge/built%20with-Flutter-02569b?style=flat-square" alt="Flutter">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/jejezz/stevedore-flutter?style=flat-square" alt="MIT 라이선스"></a>
</p>

<p align="center">
  <a href="README.md">English</a> · <b>한국어</b>
</p>

<p align="center">
  <img src="docs/screenshots/demo.gif" width="720" alt="Stevedore 데모: Downloads에 떨어진 파일 네 개가 문서·이미지·설치 파일·압축 파일 폴더로 정리되고 최근 기록에 나타남">
</p>

## 기능

- **확장자·이름·크기·경과 일수로 만드는 규칙** — 조건은 모두 만족해야 일치합니다(예: 30일 지난 `dmg, pkg`). 동작은 *폴더로 이동* 또는 *휴지통으로*입니다. 목록에서 위에 있는 규칙이 먼저 적용되고, 조건이 하나도 없는 규칙은 아무 파일도 고르지 않습니다.
- **받는 즉시 Downloads 정리** — 폴더를 백그라운드로 감시하다가 파일의 크기와 수정 시각이 5초 동안 변하지 않을 때만 처리합니다. 그래서 `.crdownload`, `.download`, `.part` 같은 받는 중인 파일은 건드리지 않습니다.
- **먼저 미리 보고, 나중에 되돌리기** — *지금 정리*는 실행 전에 무엇이 어디로 가는지 정확히 보여줍니다. 모든 이동은 최근 기록에 남고 **되돌리기**로 원래 이름 그대로 돌려놓을 수 있습니다.
- **덮어쓰지도, 지우지도 않습니다** — 이름이 겹치면 `report (1).pdf`로 저장하고, "삭제"는 휴지통으로 보내는 것입니다(macOS에서는 Finder의 *되돌려 놓기*도 됩니다).
- **추천 규칙** — 문서·이미지·설치 파일·압축 파일 규칙으로 바로 시작할 수 있고(각 규칙이 지금 몇 개 파일에 해당하는지도 보여줍니다), 규칙 편집기에서 고쳐 쓸 수 있습니다.
- **트레이/메뉴바 상주** — 창을 닫아도 계속 실행되고, 로그인 시 자동 실행을 켜면 창 없이 시작합니다.
- **라이트·다크, 한국어·English** — 시스템 설정을 따르거나 툴바에서 고를 수 있습니다

<p align="center">
  <img src="docs/screenshots/home.png" width="360" alt="규칙과 최근 기록 (라이트·다크)">
  <img src="docs/screenshots/detail.png" width="360" alt="규칙 편집기">
</p>

## 설치

[**Releases**](https://github.com/jejezz/stevedore-flutter/releases/latest)에서 받습니다.

| OS | 파일 |
|---|---|
| macOS 12.0 이상 | `Stevedore-<버전>-macos-universal.dmg` — 열어서 앱을 Applications 폴더로 끌어다 놓으세요 |
| Windows 10/11 (x64) | `Stevedore-<버전>-windows-x64-setup.exe` |

**macOS:** 처음 Downloads 폴더를 열 때 macOS가 접근을 허용할지 묻습니다. **허용**을 누르세요(허용하지 않으면 규칙이 동작하지 않습니다).

**Windows:** 설치 프로그램에 아직 코드 서명이 없어서 SmartScreen이 "Windows의 PC 보호" 창을 띄웁니다. **추가 정보 → 실행**을 누르세요.

## 동작 방식

모든 일은 Dart가 합니다. `Directory.watch()`(macOS는 FSEvents, Windows는 `ReadDirectoryChangesW`)가 감시 폴더에 변화가 있을 때만 앱을 깨웁니다. 엔진은 부작용 없는 `plan`과, 파일을 건드리기 직전에 다시 확인하는 `apply`로 나뉘어 있어서 미리보기, 실시간 감시, 테스트가 같은 코드를 씁니다. 작은 Swift 브리지가 `FileManager.trashItem`을 불러서 macOS에서는 휴지통에서 되돌리기가 가능합니다. Windows는 PowerShell로 휴지통을 쓰기 때문에 아직은 앱 안에서 휴지통 이동을 되돌릴 수 없습니다.

## 개발

```bash
flutter pub get
flutter run -d macos
```

추가로 필요한 도구는 없습니다. macOS 앱은 Downloads를 읽고 임의의 폴더로 파일을 옮겨야 해서 일부러 **샌드박스를 끄고** 공증된 DMG로 배포합니다(App Store 배포 아님). 설정은 `~/Library/Application Support/Stevedore`(Windows는 `%APPDATA%\Stevedore`)의 `rules.json`, `history.json`에 저장됩니다.

릴리스: `scripts/bump-version.sh patch` → 병합 → `vX.Y.Z` 태그. CI가 모든 플랫폼을 빌드해서 올립니다. 규칙: [application-release-templates/conventions](https://github.com/jejezz/application-release-templates/tree/main/conventions).

## 크레딧

- 글꼴: [서울남산체](https://www.seoul.go.kr/seoul/font.do) (서울특별시)
- 아이콘: [Icons8](https://icons8.com)

## 라이선스

[MIT](LICENSE) © 2026 Jongyun Ahn
