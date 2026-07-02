import SwiftUI

enum AtlasChartSection: String, CaseIterable, Identifiable {
    case chart, meridian, beacon, folio, waypoints, settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chart: "Chart"
        case .meridian: "Meridian"
        case .beacon: "Beacon"
        case .folio: "Folio"
        case .waypoints: "Waypoints"
        case .settings: "Settings"
        }
    }

    var glyph: String {
        switch self {
        case .chart: "map.fill"
        case .meridian: "magnifyingglass"
        case .beacon: "barcode.viewfinder"
        case .folio: "books.vertical.fill"
        case .waypoints: "point.topleft.down.curvedto.point.bottomright.up"
        case .settings: "gearshape.fill"
        }
    }
}

struct AtlasNavigator: View {
    @State private var active: AtlasChartSection = .chart

    var body: some View {
        ZStack {
            AtlasPalette.background.ignoresSafeArea()
            TopographicBackdrop().opacity(0.35)
            VStack(spacing: 0) {
                atlasHeader
                GeometryReader { geo in
                    sectionHost
                        .frame(width: geo.size.width, height: geo.size.height)
                }
                ExpeditionDock(active: $active)
            }
        }
    }

    private var atlasHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: "location.north.line.fill")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(AtlasPalette.accent)
                    Text("EXPEDITION LOG")
                        .font(.caption2.weight(.heavy))
                        .tracking(1.5)
                        .foregroundStyle(AtlasPalette.secondary)
                }
                Text(active.title)
                    .font(AtlasPalette.chartTitle(.title3))
                    .foregroundStyle(AtlasPalette.text)
                Text(coordinateLabel)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(AtlasPalette.accent.opacity(0.85))
            }
            Spacer(minLength: 8)
            CompassRoseIndicator(spokes: 8, accent: AtlasPalette.accent)
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(
            AtlasPalette.surface
                .shadow(color: AtlasPalette.text.opacity(0.06), radius: 8, y: 4)
        )
    }

    private var coordinateLabel: String {
        let lat = 48.8566 + Double(active.hashValue % 10) * 0.01
        let lon = 2.3522 + Double(active.hashValue % 7) * 0.02
        return String(format: "%.2f°N  %.2f°E", lat, lon)
    }

    @ViewBuilder
    private var sectionHost: some View {
        switch active {
        case .chart: ChartDiscoveryView()
        case .meridian: MeridianSearchView()
        case .beacon: BeaconScanView()
        case .folio: FolioLibraryView()
        case .waypoints: WaypointPlanView()
        case .settings: CartographerSettingsView()
        }
    }
}

struct ExpeditionDock: View {
    @Binding var active: AtlasChartSection
    @Namespace private var dockNS

    var body: some View {
        HStack(spacing: 2) {
            ForEach(AtlasChartSection.allCases) { section in
                let on = active == section
                Button {
                    withAnimation(AtlasMotion.drawerSlide(reduceMotion: false)) { active = section }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: section.glyph)
                            .font(.system(size: section == .beacon ? 20 : 16, weight: .semibold))
                        if section != .beacon {
                            Text(section.title)
                                .font(.system(size: 8, weight: .bold, design: .serif))
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, section == .beacon ? 12 : 8)
                    .foregroundStyle(on ? AtlasPalette.surface : AtlasPalette.text.opacity(0.5))
                    .background {
                        if on {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(AtlasPalette.primary)
                                .matchedGeometryEffect(id: "exp", in: dockNS)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            AtlasPalette.surface
                .overlay(Rectangle().frame(height: 1).foregroundStyle(AtlasPalette.gridStroke), alignment: .top)
                .shadow(color: AtlasPalette.text.opacity(0.08), radius: 12, y: -4)
        )
    }
}

struct TopographicBackdrop: View {
    var body: some View {
        Canvas { ctx, size in
            let step: CGFloat = 36
            var path = Path()
            stride(from: 0, through: size.width, by: step).forEach { x in
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }
            stride(from: 0, through: size.height, by: step).forEach { y in
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
            ctx.stroke(path, with: .color(AtlasPalette.gridStroke), lineWidth: 0.6)
            for i in 0..<5 {
                var ring = Path()
                let r = CGFloat(40 + i * 55)
                ring.addEllipse(in: CGRect(x: size.width * 0.6 - r, y: size.height * 0.2 - r / 2, width: r * 2, height: r))
                ctx.stroke(ring, with: .color(AtlasPalette.contourStroke.opacity(0.25)), lineWidth: 0.8)
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}
