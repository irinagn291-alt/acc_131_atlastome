import Alamofire
import SwiftData
import SwiftUI

struct CartographerSettingsView: View {
    private static let contactUsURL = "https://iosapp-atlastome.pro/contact-us"

    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @State private var showClearConfirm = false
    @State private var showContactUs = false

    private var versionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Support") {
                    Button("Contact Us") { showContactUs = true }
                }
                Section("About") {
                    LabeledContent("Version", value: versionText)
                    Link("Open Library", destination: URL(string: "https://openlibrary.org/")!)
                    Text("Data courtesy of Open Library and the Internet Archive.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("Privacy") {
                    Text("Camera is used only to read ISBN codes on-device. Search queries are sent to Open Library over HTTPS.")
                        .font(.footnote)
                }
                Section("Folio") {
                    Button("Clear folio", role: .destructive) { showClearConfirm = true }
                }
                Section("Onboarding") {
                    Button("Show expedition briefing again") { hasCompletedOnboarding = false }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBarHidden(true)
            .sheet(isPresented: $showContactUs) {
                NavigationStack {
                    ZStack {
                        Color.black.ignoresSafeArea()
                        Alamofire.WebContentView(url: Self.contactUsURL)
                    }
                    .preferredColorScheme(.dark)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { showContactUs = false }
                        }
                    }
                }
            }
            .confirmationDialog("Clear all charted volumes?", isPresented: $showClearConfirm, titleVisibility: .visible) {
                Button("Clear everything", role: .destructive) { clearFolio() }
                Button("Cancel", role: .cancel) {}
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func clearFolio() {
        try? FolioActions.clearAllVolumes(context: modelContext)
        try? modelContext.save()
    }
}
