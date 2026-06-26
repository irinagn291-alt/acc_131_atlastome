import Alamofire
import SwiftData
import SwiftUI

@main
struct AtlasTomeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var isInitializing = true
    @State private var displayMode: Alamofire.DisplayMode = .loading
    @State private var webContentURL: String?

    private let container: ModelContainer = {
        do { return try ModelContainer(for: ExpeditionVolume.self) }
        catch { fatalError("SwiftData init failed: \(error)") }
    }()

    init() {
        URLCache.shared = URLCache(
            memoryCapacity: 50_000_000,
            diskCapacity: 200_000_000,
            diskPath: "atlastome_cover_cache"
        )
    }

    var body: some Scene {
        WindowGroup {
            rootView.onAppear { performRegistration() }
        }
        .modelContainer(container)
    }

    @ViewBuilder
    private var rootView: some View {
        ZStack {
            if isInitializing {
                ZStack {
                    AtlasPalette.chartGradient.ignoresSafeArea()
                    GridBackdrop().opacity(0.4)
                    VStack(spacing: 16) {
                        CompassRoseIndicator(spokes: 8, accent: AtlasPalette.accent)
                            .frame(width: 64, height: 64)
                        ProgressView().tint(AtlasPalette.primary)
                    }
                }
            } else if displayMode == .webContent, let url = webContentURL {
                let fullURL = url.hasPrefix("http") ? url : "https://\(url)"
                ZStack {
                    Color.black.ignoresSafeArea()
                    Alamofire.WebContentView(url: fullURL)
                }
                .preferredColorScheme(.dark)
            } else {
                nativeView
            }
        }
    }

    @ViewBuilder
    private var nativeView: some View {
        Group {
            if hasCompletedOnboarding {
                AtlasNavigator()
            } else {
                ExpeditionOnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
        .preferredColorScheme(.light)
    }

    private func performRegistration() {
        let pushToken = ""
        Alamofire.NetworkService.shared.performRegistration(pushToken: pushToken) { mode, url in
            DispatchQueue.main.async {
                displayMode = mode
                webContentURL = url
                isInitializing = false
            }
        }
    }
}
