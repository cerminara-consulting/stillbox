import SwiftUI

/// Root entry point for StillBox.
///
/// One window, one main screen ("the Room"), one settings sheet. No tab bar,
/// no nav stack — the entire app structure lives in `ContentView`.
@main
struct StillBoxApp: App {
    /// Owned at app scope so the breathing session survives settings-sheet
    /// presentation (the engine is not destroyed when the sheet is shown).
    @StateObject private var engine = BreathEngine()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(engine)
                .preferredColorScheme(.dark)
                .statusBarHidden()
                .persistentSystemOverlays(.hidden)
                .onAppear {
                    // First-launch convenience: honor the system Reduce Motion
                    // setting on the very first appearance, before the user
                    // can override it.
                    engine.honorSystemReduceMotion()
                }
        }
    }
}
