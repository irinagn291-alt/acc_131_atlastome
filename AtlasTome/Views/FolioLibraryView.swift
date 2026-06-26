import SwiftData
import SwiftUI

struct FolioLibraryView: View {
    @Query(sort: \ExpeditionVolume.createdAt, order: .reverse) private var volumes: [ExpeditionVolume]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                AtlasPalette.meridianGradient.ignoresSafeArea()
                if volumes.isEmpty {
                    emptyFolio
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 20) {
                            Text("Expedition folio")
                                .font(AtlasPalette.chartTitle(.title3))
                                .foregroundStyle(AtlasPalette.text)
                            ForEach(ExpeditionStatus.allCases) { status in
                                let subset = volumes.filter { $0.expeditionStatus == status }
                                if !subset.isEmpty {
                                    folioRegion(title: status.title, subset: subset)
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: AtlasVolumePreview.self) { preview in
                VolumeDetailView(preview: preview)
            }
        }
    }

    private var emptyFolio: some View {
        VStack(spacing: 18) {
            CompassRoseIndicator(spokes: 6, accent: AtlasPalette.accent)
                .frame(height: 56)
                .padding(.horizontal, 40)
            Text("Your folio awaits")
                .font(AtlasPalette.chartTitle(.title2))
            Text("Chart volumes from Meridian, Chart, or Beacon — each becomes a marked expedition.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(AtlasPalette.text.opacity(0.65))
                .padding(.horizontal, 28)
        }
    }

    private func folioRegion(title: String, subset: [ExpeditionVolume]) -> some View {
        let sh = AtlasPalette.elevationShadow(reduceMotion: reduceMotion)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title).font(.headline.weight(.bold))
                Spacer()
                Image(systemName: "map.fill").foregroundStyle(AtlasPalette.secondary)
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(subset) { volume in
                    NavigationLink(value: volumeToPreview(volume)) {
                        folioTile(volume: volume, shadow: sh)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: AtlasPalette.radiusPanel, style: .continuous)
                .fill(AtlasPalette.surface)
                .shadow(color: sh.color, radius: sh.radius, y: sh.y)
        )
    }

    private func folioTile(volume: ExpeditionVolume, shadow: (color: Color, radius: CGFloat, y: CGFloat)) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            CoverPlateView(coverURL: volume.coverURL(size: "S"))
                .frame(height: 118)
            Text(volume.title).font(.caption.weight(.semibold)).lineLimit(2)
            Text(volume.expeditionStatus.title)
                .font(.caption2.weight(.bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(AtlasPalette.secondary.opacity(0.2)))
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: AtlasPalette.radiusCard, style: .continuous)
                .fill(AtlasPalette.background)
                .shadow(color: shadow.color, radius: shadow.radius * 0.6, y: shadow.y * 0.8)
        )
    }

    private func volumeToPreview(_ volume: ExpeditionVolume) -> AtlasVolumePreview {
        AtlasVolumePreview(
            title: volume.title, authors: volume.authorsArray, isbn: volume.isbn,
            coverId: volume.coverId, workKey: volume.workKey, editionKey: volume.editionKey,
            firstPublishYear: volume.firstPublishYear, subjects: nil
        )
    }
}
