import SwiftUI

/// Owns shared profile and recording state so switching tabs does not lose a walk.
struct MainTabView: View {
    @State private var selection: AppTab = .home
    @StateObject private var profile = ProfilePhotoStore()
    @StateObject private var maps = CampusMapStore()
    @StateObject private var recorder = WalkRecorder()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Lets simulator checks open a tab without changing the normal Home launch.
        #if DEBUG
            let arguments = ProcessInfo.processInfo.arguments
            if let index = arguments.firstIndex(of: "--preview-tab"), arguments.indices.contains(index + 1) {
                let tabs: [String: AppTab] = [
                    "home": .home, "simulate": .simulate, "record": .record, "profile": .profile,
                ]
                _selection = State(initialValue: tabs[arguments[index + 1]] ?? .home)
            }
        #endif
    }

    var body: some View {
        TabView(selection: $selection) {
            HomeView(selectedTab: $selection)
                .toolbarVisibility(.hidden, for: .tabBar).tag(AppTab.home)
            SimulationView(isTabSelected: selection == .simulate)
                .toolbarVisibility(.hidden, for: .tabBar).tag(AppTab.simulate)
            WalkRecordingView()
                .toolbarVisibility(.hidden, for: .tabBar).tag(AppTab.record)
            ProfileView()
                .toolbarVisibility(.hidden, for: .tabBar).tag(AppTab.profile)
        }
        // Home already owns its tab row inside the bottom card.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if selection != .home {
                AppTabBar(selection: $selection)
                    .background(GlassBackground(shape: Rectangle()).ignoresSafeArea(edges: .bottom))
            }
        }
        .font(.poppins(.body))
        .foregroundStyle(AppColors.ink)
        .preferredColorScheme(.light)
        .tint(AppColors.ink)
        .environmentObject(profile)
        .environmentObject(recorder)
        .environmentObject(maps)
        .onChange(of: scenePhase) {
            if scenePhase == .background, recorder.recording { recorder.stop() }
        }
    }
}

#Preview { MainTabView() }
