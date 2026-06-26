import SwiftUI

struct ChartDiscoveryView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var carousels: [ChartCarousel] = []
    @State private var trendingDaily: [AtlasVolumePreview] = []
    @State private var trendingWeekly: [AtlasVolumePreview] = []
    @State private var isLoading = false
    @State private var errorText: String?
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                AtlasPalette.background.ignoresSafeArea()
                GridBackdrop().opacity(0.2)
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        chartHeader
                        MeridianBanner(text: "Discover")
                            .padding(.horizontal)
                        if let errorText {
                            Text(errorText)
                                .font(.footnote)
                                .foregroundStyle(AtlasPalette.accent)
                                .padding(.horizontal)
                        }
                        if isLoading && carousels.isEmpty {
                            ProgressView().frame(maxWidth: .infinity).padding(.top, 40)
                        }
                        carouselSection(title: "Trending today", items: trendingDaily)
                        carouselSection(title: "Trending this week", items: trendingWeekly)
                        ForEach(carousels) { carousel in
                            carouselSection(title: carousel.title, items: carousel.items)
                        }
                        chartedExplorers
                    }
                    .padding(.vertical, 12)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: AtlasVolumePreview.self) { preview in
                VolumeDetailView(preview: preview)
            }
            .navigationDestination(for: String.self) { query in
                AuthorMeridianView(initialQuery: query)
            }
            .task { await load() }
        }
    }

    private var chartHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your expedition chart")
                .font(AtlasPalette.chartTitle(.title2))
                .foregroundStyle(AtlasPalette.text)
                .padding(.horizontal)
            CompassRoseIndicator(spokes: 6, accent: AtlasPalette.secondary)
                .padding(.horizontal)
            Text("Plot non-fiction across mapped regions — elevation cards, compass motifs, atlas grids.")
                .font(.footnote)
                .foregroundStyle(AtlasPalette.text.opacity(0.65))
                .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }

    private var chartedExplorers: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Charted explorers")
                .font(AtlasPalette.chartTitle(.title3))
                .foregroundStyle(AtlasPalette.text)
                .padding(.horizontal)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(ChartedExplorers.list) { explorer in
                    NavigationLink(value: explorer.searchQuery) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(explorer.displayName)
                                .font(.headline)
                                .foregroundStyle(AtlasPalette.text)
                            Text(explorer.region)
                                .font(.caption)
                                .foregroundStyle(AtlasPalette.accent)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: AtlasPalette.radiusCard, style: .continuous)
                                .fill(AtlasPalette.surface)
                                .shadow(color: AtlasPalette.text.opacity(0.06), radius: 6, y: 3)
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func carouselSection(title: String, items: [AtlasVolumePreview]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AtlasPalette.chartTitle(.title3))
                .foregroundStyle(AtlasPalette.text)
                .padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(items) { item in
                        ExpeditionPassCard(preview: item, reduceMotion: reduceMotion) { path.append(item) }
                            .frame(width: 198)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorText = nil
        do {
            async let daily = AtlasArchiveGateway.shared.fetchTrending(period: .daily)
            async let weekly = AtlasArchiveGateway.shared.fetchTrending(period: .weekly)
            let themes = [
                ("Geographic frontiers", "geography"),
                ("Historical maps", "history"),
                ("Natural world", "nature"),
                ("Science expeditions", "science")
            ]
            var built: [ChartCarousel] = []
            for (title, subject) in themes {
                let works = try await AtlasArchiveGateway.shared.fetchSubjectWorks(subject: subject, limit: 14)
                built.append(ChartCarousel(title: title, items: works))
            }
            trendingDaily = try await daily
            trendingWeekly = try await weekly
            carousels = built
        } catch {
            errorText = error.localizedDescription
        }
        isLoading = false
    }
}

private struct ChartCarousel: Identifiable, Hashable {
    var id: String { title }
    let title: String
    let items: [AtlasVolumePreview]
}

struct AuthorMeridianView: View {
    let initialQuery: String
    @StateObject private var model = MeridianSearchModel()

    var body: some View {
        MeridianResultsHost(viewModel: model, lockedMode: .author, initialQuery: initialQuery)
            .navigationTitle("Author")
            .navigationBarTitleDisplayMode(.inline)
    }
}
