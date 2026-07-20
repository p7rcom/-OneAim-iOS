import SwiftUI

@main
struct OneStateAimTrainerApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
                .preferredColorScheme(.dark)
                .statusBarHidden(true)
        }
    }
}
