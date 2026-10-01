import Cocoa
import FlutterMacOS
import window_manager

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    // macOS는 실행 인자를 Dart로 넘겨주지 않는다. --background 같은 인자를 쓰려면 직접 전달한다.
    let project = FlutterDartProject()
    project.dartEntrypointArguments = Array(CommandLine.arguments.dropFirst())
    let flutterViewController = FlutterViewController(project: project)
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // 휴지통 보내기: Finder의 "되돌려 놓기"가 되도록 FileManager.trashItem을 쓴다.
    let trashChannel = FlutterMethodChannel(
      name: "art.zoomon.stevedore/trash",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    trashChannel.setMethodCallHandler { call, result in
      guard call.method == "trash", let path = call.arguments as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      do {
        var trashed: NSURL?
        try FileManager.default.trashItem(at: URL(fileURLWithPath: path), resultingItemURL: &trashed)
        result(trashed?.path)
      } catch {
        result(FlutterError(code: "trash_failed", message: error.localizedDescription, details: path))
      }
    }

    super.awakeFromNib()
  }

  // 창은 항상 숨긴 채 시작하고, Dart가 준비된 뒤 보일지 정한다 (--background면 트레이에서만 시작).
  override public func order(_ place: NSWindow.OrderingMode, relativeTo otherWin: Int) {
    super.order(place, relativeTo: otherWin)
    hiddenWindowAtLaunch()
  }
}
