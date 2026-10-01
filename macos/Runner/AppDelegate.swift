import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  // 트레이 상주 앱: 창을 닫아도 종료하지 않는다.
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  // Dock 아이콘을 눌렀을 때 트레이로 숨겨 둔 창을 다시 보여준다.
  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if !flag {
      for window in sender.windows { window.makeKeyAndOrderFront(self) }
    }
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
