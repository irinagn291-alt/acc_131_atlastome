import SwiftUI

struct ExpeditionOnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let slides: [(String, String, String)] = [
        ("Chart your knowledge", "AtlasTome is your non-fiction explorer — map every title across continents of ideas.", "globe.europe.africa.fill"),
        ("Survey the terrain", "Browse trending works and thematic regions powered by Open Library.", "map.fill"),
        ("Plot meridians", "Search by title, author, subject, or ISBN to locate any volume.", "magnifyingglass.circle.fill"),
        ("Activate the beacon", "Scan an ISBN barcode or enter coordinates manually to chart a new find.", "barcode.viewfinder"),
        ("Build your folio", "Archive discoveries, rate expeditions, and log field notes.", "books.vertical.fill"),
        ("Mark waypoints", "Plan reading routes, reorder your journey, and track progress.", "point.topleft.down.curvedto.point.bottomright.up")
    ]

    var body: some View {
        ZStack {
            AtlasPalette.chartGradient.ignoresSafeArea()
            GridBackdrop().opacity(0.25)
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("Skip") { hasCompletedOnboarding = true }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AtlasPalette.accent)
                }
                .padding(.horizontal, 22)
                .padding(.top, 12)

                TabView(selection: $page) {
                    ForEach(slides.indices, id: \.self) { index in
                        slide(title: slides[index].0, subtitle: slides[index].1, symbol: slides[index].2)
                            .tag(index)
                            .padding(.horizontal, 22)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(AtlasMotion.expeditionSlide(reduceMotion: reduceMotion), value: page)

                VStack(spacing: 10) {
                    Text("Waypoint \(page + 1) of \(slides.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AtlasPalette.text.opacity(0.5))
                    CompassRoseIndicator(spokes: page + 2, accent: AtlasPalette.accent)
                        .frame(height: 52)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 10)

                Button(action: advance) {
                    Text(page == slides.count - 1 ? "Begin Expedition" : "Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AtlasPalette.primary)
                        .foregroundStyle(AtlasPalette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AtlasPalette.radiusPanel, style: .continuous))
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 22)
            }
        }
    }

    private func slide(title: String, subtitle: String, symbol: String) -> some View {
        ScrollView {
            VStack(spacing: 22) {
                Image(systemName: symbol)
                    .font(.system(size: 68, weight: .semibold))
                    .foregroundStyle(AtlasPalette.primary)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(AtlasPalette.primary, AtlasPalette.secondary)
                    .padding(28)
                    .background(
                        Circle()
                            .fill(AtlasPalette.surface)
                            .shadow(color: AtlasPalette.text.opacity(0.1), radius: reduceMotion ? 2 : 14, y: 8)
                            .overlay(Circle().stroke(AtlasPalette.contourStroke, lineWidth: 1.2))
                    )
                VStack(alignment: .leading, spacing: 10) {
                    Text(title)
                        .font(AtlasPalette.chartTitle(.largeTitle))
                        .foregroundStyle(AtlasPalette.text)
                    Text(subtitle)
                        .font(.title3)
                        .foregroundStyle(AtlasPalette.text.opacity(0.72))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 24)
        }
    }

    private func advance() {
        if page < slides.count - 1 { page += 1 }
        else { hasCompletedOnboarding = true }
    }
}
