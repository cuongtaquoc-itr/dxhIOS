import Foundation
import UIKit

public class AppInfo {
    public static func generateAppInfo() -> String {
        let versionName = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let versionCode = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
        let model = UIDevice.current.model
        return "ADDVER=\(AddVer.ADDVER_0)},APPINFO=\(versionName),\(versionCode),\(model), 0"
    }
}
