릴리스·버전·패키징·정보 창·아이콘·라이선스·UI/UX·글꼴·언어·테마는
https://github.com/jejezz/application-release-templates/tree/main/conventions
규약을 따른다. 이 앱에 적용된 규약 버전: conventions-v1

# Stevedore

다운로드 폴더 등을 규칙(확장자·이름·크기·경과 일수)에 따라 자동 분류·정리하는
상주형(트레이/메뉴바) 파일 정리 유틸리티. 상주 감시와 "지금 정리" 수동 실행을
함께 지원한다. 대상 플랫폼: macOS, Windows (Linux 없음).

- 표시 이름 `Stevedore`, 패키지 `stevedore`, 식별자 `art.zoomon.stevedore`
- 삭제는 항상 휴지통으로 보낸다. 규칙 저장 전 dry-run 미리보기와 이동 이력(되돌리기)을 제공한다.
- 다운로드 중인 임시 파일(`.crdownload`, `.download`, `.part`)은 건드리지 않고, 크기가 안정된 뒤 처리한다.
- 아이콘 글리프(`assets/icon/source_glyph.png`)는 임시 그림이다. 교체 후 `python3 tool/icon/generate_icons.py`.
