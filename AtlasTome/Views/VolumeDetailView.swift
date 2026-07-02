import SwiftData
import SwiftUI

struct VolumeDetailView: View {
    let preview: AtlasVolumePreview
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var stored: ExpeditionVolume?
    @State private var ratingEditor: Double = 0
    @State private var reviewText = ""
    @State private var notesText = ""
    @State private var startedAt = Date.now
    @State private var finishedAt = Date.now
    @State private var message: String?

    var body: some View {
        ZStack {
            AtlasPalette.chartGradient.ignoresSafeArea()
            AtlasTabScroll {
                VolumeDetailContent(
                    preview: preview, stored: stored, ratingEditor: $ratingEditor,
                    reviewText: $reviewText, notesText: $notesText,
                    startedAt: $startedAt, finishedAt: $finishedAt,
                    message: message, reduceMotion: reduceMotion,
                    onAddLibrary: { upsertFolio(plan: false) },
                    onAddPlan: { upsertFolio(plan: true) },
                    onStatusChange: { status in
                        stored?.expeditionStatus = status
                        stored?.modifiedAt = .now
                        try? modelContext.save()
                    },
                    onRatingChange: { value in
                        stored?.rating = Int(value)
                        stored?.modifiedAt = .now
                        try? modelContext.save()
                    },
                    onReviewChange: {
                        stored?.review = reviewText
                        stored?.modifiedAt = .now
                        try? modelContext.save()
                    },
                    onNotesChange: {
                        stored?.notes = notesText
                        stored?.modifiedAt = .now
                        try? modelContext.save()
                    },
                    onStartedChange: { date in
                        stored?.startedAt = date
                        stored?.modifiedAt = .now
                        try? modelContext.save()
                    },
                    onFinishedChange: { date in
                        stored?.finishedAt = date
                        stored?.modifiedAt = .now
                        try? modelContext.save()
                    }
                )
                .padding(18)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: refreshBinding)
    }

    private func refreshBinding() {
        stored = try? FolioActions.fetchStored(dedupeKey: preview.dedupeKey(), context: modelContext)
        if let stored {
            ratingEditor = Double(stored.rating)
            reviewText = stored.review
            notesText = stored.notes
            startedAt = stored.startedAt ?? .now
            finishedAt = stored.finishedAt ?? .now
        }
    }

    private func upsertFolio(plan: Bool) {
        do {
            let volume: ExpeditionVolume
            if plan {
                volume = try FolioActions.addToWaypointPlan(preview: preview, context: modelContext)
            } else {
                volume = try FolioActions.upsertFromFolio(preview: preview, context: modelContext)
            }
            try modelContext.save()
            stored = volume
            message = plan ? "Added to waypoints." : "Charted in folio."
            refreshBinding()
        } catch {
            message = error.localizedDescription
        }
    }
}

private struct VolumeDetailContent: View {
    let preview: AtlasVolumePreview
    let stored: ExpeditionVolume?
    @Binding var ratingEditor: Double
    @Binding var reviewText: String
    @Binding var notesText: String
    @Binding var startedAt: Date
    @Binding var finishedAt: Date
    let message: String?
    let reduceMotion: Bool
    let onAddLibrary: () -> Void
    let onAddPlan: () -> Void
    let onStatusChange: (ExpeditionStatus) -> Void
    let onRatingChange: (Double) -> Void
    let onReviewChange: () -> Void
    let onNotesChange: () -> Void
    let onStartedChange: (Date) -> Void
    let onFinishedChange: (Date) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            hero
            if stored != nil {
                Label("Charted in folio", systemImage: "map.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AtlasPalette.secondary)
            }
            if let message {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(AtlasPalette.accent)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 16).fill(AtlasPalette.secondary.opacity(0.15)))
            }
            actionButtons
            if stored != nil {
                statusPicker
                atlasPanel(title: "Compass rating") {
                    Slider(value: $ratingEditor, in: 0...5, step: 1)
                        .tint(AtlasPalette.accent)
                        .onChange(of: ratingEditor) { _, v in onRatingChange(v) }
                    Text("\(Int(ratingEditor)) of 5 bearings")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AtlasPalette.text.opacity(0.6))
                }
                atlasPanel(title: "Field journal") {
                    TextEditor(text: $reviewText)
                        .frame(minHeight: 120)
                        .onChange(of: reviewText) { _, _ in onReviewChange() }
                }
                atlasPanel(title: "Survey notes") {
                    TextEditor(text: $notesText)
                        .frame(minHeight: 120)
                        .onChange(of: notesText) { _, _ in onNotesChange() }
                }
                atlasPanel(title: "Expedition dates") {
                    DatePicker("Started", selection: $startedAt, displayedComponents: .date)
                        .onChange(of: startedAt) { _, d in onStartedChange(d) }
                    DatePicker("Finished", selection: $finishedAt, displayedComponents: .date)
                        .onChange(of: finishedAt) { _, d in onFinishedChange(d) }
                }
            }
        }
    }

    private var hero: some View {
        let sh = AtlasPalette.elevationShadow(reduceMotion: reduceMotion)
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 18) {
                CoverPlateView(coverURL: preview.coverURL(size: "L"), cornerRadius: 18)
                    .frame(width: 118, height: 176)
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(AtlasPalette.contourStroke, lineWidth: 2))
                VStack(alignment: .leading, spacing: 10) {
                    MeridianBanner(text: "Volume chart")
                    Text(preview.title).font(AtlasPalette.chartTitle(.title2))
                    Text(preview.authors.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundStyle(AtlasPalette.text.opacity(0.7))
                    metaChips
                }
            }
            CompassRoseIndicator(spokes: 6, accent: AtlasPalette.accent)
                .frame(height: 44)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: AtlasPalette.radiusPanel, style: .continuous)
                .fill(AtlasPalette.surface)
                .shadow(color: sh.color, radius: sh.radius, y: sh.y)
        )
    }

    private var metaChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let year = preview.firstPublishYear {
                chip(icon: "calendar", text: "First charted \(year)")
            }
            if let isbn = preview.isbn {
                chip(icon: "barcode", text: isbn)
            }
        }
    }

    private func chip(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption2)
            Text(text).font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(AtlasPalette.secondary.opacity(0.2)))
    }

    @ViewBuilder
    private var actionButtons: some View {
        if stored == nil {
            HStack(spacing: 10) {
                Button("Add to Folio", action: onAddLibrary)
                    .buttonStyle(.borderedProminent)
                    .tint(AtlasPalette.primary)
                Button("Add Waypoint", action: onAddPlan)
                    .buttonStyle(.bordered)
                    .tint(AtlasPalette.accent)
            }
        } else if let stored, !stored.isInReadingPlan {
            Button("Add Waypoint", action: onAddPlan)
                .buttonStyle(.borderedProminent)
                .tint(AtlasPalette.accent)
        }
    }

    private var statusPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Expedition status").font(.headline.weight(.bold))
            HStack {
                ForEach(ExpeditionStatus.allCases) { status in
                    Button(status.title) { onStatusChange(status) }
                        .font(.caption.weight(.semibold))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .background(
                            Capsule().fill(
                                stored?.expeditionStatus == status
                                    ? AtlasPalette.accent.opacity(0.2) : AtlasPalette.background
                            )
                        )
                }
            }
        }
    }

    private func atlasPanel<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline.weight(.bold))
            content()
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: AtlasPalette.radiusChip, style: .continuous)
                        .fill(AtlasPalette.surface)
                        .overlay(RoundedRectangle(cornerRadius: AtlasPalette.radiusChip).stroke(AtlasPalette.gridStroke))
                )
        }
    }
}
