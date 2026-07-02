import SwiftUI

struct CoverPlateView: View {
    let coverURL: URL?
    var cornerRadius: CGFloat = 10

    var body: some View {
        Group {
            if let coverURL {
                AsyncImage(url: coverURL) { phase in
                    switch phase {
                    case .empty: ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                    case let .success(image): image.resizable().scaledToFill()
                    default: placeholder
                    }
                }
            } else { placeholder }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [AtlasPalette.secondary.opacity(0.3), AtlasPalette.primary.opacity(0.2)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Image(systemName: "map")
                .font(.title2)
                .foregroundStyle(AtlasPalette.text.opacity(0.35))
        }
    }
}

struct CompassRoseIndicator: View {
    let spokes: Int
    let accent: Color

    var body: some View {
        GeometryReader { geo in
            let count = max(min(spokes, 8), 4)
            ForEach(0..<count, id: \.self) { index in
                let angle = Double(index) / Double(count) * .pi * 2 - .pi / 2
                Capsule()
                    .fill(accent.opacity(0.3 + Double(index) * 0.05))
                    .frame(width: geo.size.width * 0.05, height: geo.size.height * 0.5)
                    .position(
                        x: geo.size.width / 2 + cos(angle) * geo.size.width * 0.32,
                        y: geo.size.height / 2 + sin(angle) * geo.size.height * 0.3
                    )
                    .rotationEffect(.radians(angle + .pi / 2))
            }
            Image(systemName: "location.north.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(accent)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .frame(height: 48)
    }
}

struct ExpeditionPassCard: View {
    let preview: AtlasVolumePreview
    let reduceMotion: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            let sh = AtlasPalette.elevationShadow(reduceMotion: reduceMotion)
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("FIELD PASS")
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .foregroundStyle(AtlasPalette.accent)
                    Spacer()
                    Image(systemName: "ticket.fill")
                        .font(.caption2)
                        .foregroundStyle(AtlasPalette.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                HStack(alignment: .top, spacing: 12) {
                    CoverPlateView(coverURL: preview.coverURL(size: "M"), cornerRadius: 8)
                        .frame(width: 72, height: 100)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(preview.title)
                            .font(AtlasPalette.chartTitle(.subheadline))
                            .foregroundStyle(AtlasPalette.text)
                            .lineLimit(3)
                        Text(preview.authors.joined(separator: ", "))
                            .font(.caption2)
                            .foregroundStyle(AtlasPalette.text.opacity(0.6))
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(14)
                perforatedEdge
            }
            .background(
                RoundedRectangle(cornerRadius: AtlasPalette.radiusCard, style: .continuous)
                    .fill(AtlasPalette.surface)
                    .shadow(color: sh.color, radius: sh.radius, y: sh.y)
                    .overlay(
                        RoundedRectangle(cornerRadius: AtlasPalette.radiusCard, style: .continuous)
                            .stroke(AtlasPalette.contourStroke, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var perforatedEdge: some View {
        HStack(spacing: 6) {
            ForEach(0..<12, id: \.self) { _ in
                Circle()
                    .fill(AtlasPalette.background)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(AtlasPalette.secondary.opacity(0.12))
    }
}

struct ChartVolumeCard: View {
    let preview: AtlasVolumePreview
    let reduceMotion: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            let sh = AtlasPalette.elevationShadow(reduceMotion: reduceMotion)
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    CoverPlateView(coverURL: preview.coverURL(size: "M"), cornerRadius: 14)
                        .frame(width: 84, height: 114)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AtlasPalette.contourStroke, lineWidth: 1.5)
                        )
                    VStack(alignment: .leading, spacing: 6) {
                        Text(preview.title)
                            .font(AtlasPalette.chartTitle(.callout))
                            .foregroundStyle(AtlasPalette.text)
                            .lineLimit(3)
                        Text(preview.authors.joined(separator: ", "))
                            .font(.caption2)
                            .foregroundStyle(AtlasPalette.text.opacity(0.6))
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption2)
                    Text("Charted pick")
                        .font(.caption2.weight(.bold))
                }
                .foregroundStyle(AtlasPalette.accent)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: AtlasPalette.radiusCard, style: .continuous)
                    .fill(AtlasPalette.surface)
                    .shadow(color: sh.color, radius: sh.radius, y: sh.y)
                    .overlay(
                        RoundedRectangle(cornerRadius: AtlasPalette.radiusCard, style: .continuous)
                            .stroke(AtlasPalette.gridStroke, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct MeridianBanner: View {
    let text: String

    var body: some View {
        Text(text)
            .font(AtlasPalette.chartTitle(.title3))
            .foregroundStyle(AtlasPalette.text)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: AtlasPalette.radiusPanel, style: .continuous)
                    .fill(AtlasPalette.secondary.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: AtlasPalette.radiusPanel, style: .continuous)
                            .stroke(AtlasPalette.contourStroke, lineWidth: 1)
                    )
            )
    }
}

struct GridBackdrop: View {
    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 28
            var path = Path()
            stride(from: 0, through: size.width, by: step).forEach { x in
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }
            stride(from: 0, through: size.height, by: step).forEach { y in
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
            context.stroke(path, with: .color(AtlasPalette.gridStroke), lineWidth: 0.5)
        }
        .allowsHitTesting(false)
    }
}

struct AtlasTabScroll<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            content()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
