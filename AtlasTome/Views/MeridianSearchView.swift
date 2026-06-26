import Foundation
import SwiftUI

enum MeridianRunState: Equatable {
    case idle, loading, empty, results, error(String)
}

@MainActor
final class MeridianSearchModel: ObservableObject {
    @Published var query = ""
    @Published var mode: MeridianQueryMode = .general
    @Published var results: [AtlasVolumePreview] = []
    @Published var runState: MeridianRunState = .idle
    private var debounceTask: Task<Void, Never>?

    func scheduleSearch() {
        debounceTask?.cancel()
        let q = query, m = mode
        if q.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            results = []
            runState = .idle
            return
        }
        runState = .loading
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 450_000_000)
            guard !Task.isCancelled else { return }
            await runSearch(query: q, mode: m)
        }
    }

    func searchImmediately() async {
        debounceTask?.cancel()
        let q = query, m = mode
        if q.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            results = []
            runState = .idle
            return
        }
        runState = .loading
        await runSearch(query: q, mode: m)
    }

    private func runSearch(query: String, mode: MeridianQueryMode) async {
        do {
            let found = try await AtlasArchiveGateway.shared.search(mode: mode, query: query, limit: 40)
            results = found
            runState = found.isEmpty ? .empty : .results
        } catch {
            runState = .error(error.localizedDescription)
        }
    }
}

struct MeridianSearchView: View {
    @StateObject private var viewModel = MeridianSearchModel()

    var body: some View {
        NavigationStack {
            MeridianResultsHost(viewModel: viewModel, lockedMode: nil, initialQuery: nil)
                .navigationBarHidden(true)
                .navigationDestination(for: AtlasVolumePreview.self) { preview in
                    VolumeDetailView(preview: preview)
                }
        }
    }
}

struct MeridianResultsHost: View {
    @ObservedObject var viewModel: MeridianSearchModel
    let lockedMode: MeridianQueryMode?
    let initialQuery: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let grid = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ZStack {
            AtlasPalette.meridianGradient.ignoresSafeArea()
            GridBackdrop().opacity(0.15)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if lockedMode == nil {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(MeridianQueryMode.allCases) { mode in
                                    meridianPill(mode: mode, selected: viewModel.mode == mode)
                                }
                            }
                        }
                    }
                    HStack(spacing: 12) {
                        Image(systemName: "location.north.line")
                            .foregroundStyle(AtlasPalette.secondary)
                        TextField(placeholder, text: $viewModel.query)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.search)
                            .onSubmit { Task { await viewModel.searchImmediately() } }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: AtlasPalette.radiusChip, style: .continuous)
                            .fill(AtlasPalette.surface)
                            .shadow(color: AtlasPalette.text.opacity(0.06), radius: 8, y: 4)
                    )
                    content
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }
        }
        .onAppear {
            if let lockedMode { viewModel.mode = lockedMode }
            if let initialQuery {
                viewModel.query = initialQuery
                Task { await viewModel.searchImmediately() }
            }
        }
        .onChange(of: viewModel.query) { _, _ in viewModel.scheduleSearch() }
        .onChange(of: viewModel.mode) { _, _ in
            if lockedMode == nil { viewModel.scheduleSearch() }
        }
    }

    private func meridianPill(mode: MeridianQueryMode, selected: Bool) -> some View {
        Button { viewModel.mode = mode } label: {
            Text(mode.label)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(selected ? AtlasPalette.primary : AtlasPalette.surface)
                        .overlay(Capsule().stroke(AtlasPalette.contourStroke, lineWidth: selected ? 0 : 1))
                )
                .foregroundStyle(selected ? AtlasPalette.surface : AtlasPalette.text)
        }
        .buttonStyle(.plain)
    }

    private var placeholder: String {
        switch viewModel.mode {
        case .general: "Search the atlas"
        case .title: "Title coordinates"
        case .author: "Explorer name"
        case .subject: "Subject region"
        case .isbn: "ISBN beacon"
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.runState {
        case .idle:
            VStack(alignment: .leading, spacing: 8) {
                Text("Plot your meridian")
                    .font(AtlasPalette.chartTitle(.headline))
                Text("Choose a filter and describe the territory you want to explore.")
                    .font(.footnote)
                    .foregroundStyle(AtlasPalette.text.opacity(0.62))
            }
            .padding(.top, 18)
        case .loading:
            VStack(spacing: 14) {
                CompassRoseIndicator(spokes: 7, accent: AtlasPalette.accent)
                    .frame(height: 48)
                Text("Surveying archives…")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AtlasPalette.text.opacity(0.55))
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 24)
        case .empty:
            ContentUnavailableView("No coordinates found", systemImage: "map", description: Text("Try another filter or broaden your search."))
        case .error(let message):
            Text(message).foregroundStyle(AtlasPalette.accent).padding()
        case .results:
            LazyVGrid(columns: grid, spacing: 12) {
                ForEach(viewModel.results) { item in
                    NavigationLink(value: item) { meridianTile(item) }
                        .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
        }
    }

    private func meridianTile(_ item: AtlasVolumePreview) -> some View {
        let sh = AtlasPalette.elevationShadow(reduceMotion: reduceMotion)
        return VStack(alignment: .leading, spacing: 8) {
            CoverPlateView(coverURL: item.coverURL(size: "M"), cornerRadius: 14)
                .frame(height: 132)
            Text(item.title).font(.caption.weight(.bold)).lineLimit(2)
            Text(item.authors.joined(separator: ", "))
                .font(.caption2)
                .foregroundStyle(AtlasPalette.text.opacity(0.6))
                .lineLimit(1)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: AtlasPalette.radiusCard, style: .continuous)
                .fill(AtlasPalette.surface)
                .shadow(color: sh.color, radius: sh.radius * 0.85, y: sh.y)
        )
    }
}
