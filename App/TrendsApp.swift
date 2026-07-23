import SwiftUI

@main
struct TrendsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 480, minHeight: 520)
        }
        .windowResizability(.contentSize)
    }
}
