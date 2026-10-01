import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
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
}
