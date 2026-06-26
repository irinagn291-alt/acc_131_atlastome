import AVFoundation
import SwiftUI

struct BeaconScanView: View {
    @State private var path = NavigationPath()
    @State private var manualISBN = ""
    @State private var statusText = ""
    @State private var permission = AVCaptureDevice.authorizationStatus(for: .video)

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                AtlasPalette.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Activate beacon")
                            .font(AtlasPalette.chartTitle(.title2))
                            .foregroundStyle(AtlasPalette.text)
                        ZStack {
                            RoundedRectangle(cornerRadius: AtlasPalette.radiusPanel, style: .continuous)
                                .fill(AtlasPalette.text.opacity(0.92))
                                .frame(height: 300)
                            BeaconScannerRepresentable(onCode: { code in
                                Task { await handleISBN(code) }
                            }, permissionChanged: { permission = $0 })
                            .id(permission)
                            .clipShape(RoundedRectangle(cornerRadius: AtlasPalette.radiusPanel, style: .continuous))
                            .frame(height: 300)
                            scannerOverlay
                        }
                        permissionPanel
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Manual coordinates")
                                .font(.headline)
                            TextField("ISBN", text: $manualISBN)
                                .keyboardType(.numbersAndPunctuation)
                                .textFieldStyle(.roundedBorder)
                            Button("Chart volume") { Task { await handleISBN(manualISBN) } }
                                .buttonStyle(.borderedProminent)
                                .tint(AtlasPalette.primary)
                        }
                        if !statusText.isEmpty {
                            Text(statusText)
                                .font(.footnote)
                                .foregroundStyle(AtlasPalette.surface)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: 14).fill(AtlasPalette.accent.opacity(0.9)))
                        }
                    }
                    .padding(18)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: AtlasVolumePreview.self) { preview in
                VolumeDetailView(preview: preview)
            }
            .onAppear { permission = AVCaptureDevice.authorizationStatus(for: .video) }
        }
    }

    @ViewBuilder
    private var permissionPanel: some View {
        switch permission {
        case .authorized: EmptyView()
        case .notDetermined:
            Button("Enable camera") {
                AVCaptureDevice.requestAccess(for: .video) { _ in
                    DispatchQueue.main.async {
                        permission = AVCaptureDevice.authorizationStatus(for: .video)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
        case .denied, .restricted:
            Text("Camera access is off. Enter ISBN coordinates manually.")
                .font(.footnote)
                .foregroundStyle(AtlasPalette.text.opacity(0.7))
        @unknown default: EmptyView()
        }
    }

    private var scannerOverlay: some View {
        GeometryReader { geo in
            let w = geo.size.width * 0.72, h = geo.size.height * 0.45
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AtlasPalette.accent.opacity(0.85), lineWidth: 3)
                .frame(width: w, height: h)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
            VStack {
                HStack {
                    Label("Align ISBN in frame", systemImage: "viewfinder")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AtlasPalette.surface)
                        .padding(10)
                        .background(.ultraThinMaterial, in: Capsule())
                    Spacer()
                }
                .padding(12)
                Spacer()
            }
        }
        .allowsHitTesting(false)
    }

    @MainActor
    private func handleISBN(_ raw: String) async {
        let digits = ISBNBarcodeNormalizer.canonicalISBN(raw) ?? raw.filter(\.isNumber)
        guard digits.count >= 10 else {
            statusText = "Enter a valid ISBN (10–13 digits)."
            return
        }
        statusText = "Triangulating ISBN…"
        do {
            let items = try await AtlasArchiveGateway.shared.fetchByISBN(digits)
            guard let first = items.first else {
                statusText = "No edition found at these coordinates."
                return
            }
            statusText = ""
            path.append(first)
        } catch {
            statusText = error.localizedDescription
        }
    }
}
