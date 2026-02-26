import AppKit
import SwiftUI

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
withExtendedLifetime(delegate) {
    app.run()
}
