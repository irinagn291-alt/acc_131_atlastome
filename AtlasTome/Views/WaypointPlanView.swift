import SwiftData
import SwiftUI

struct WaypointPlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<ExpeditionVolume> { $0.isInReadingPlan == true },
        sort: \ExpeditionVolume.planSortIndex
    )
    private var planned: [ExpeditionVolume]
    @State private var editMode = EditMode.inactive

    var body: some View {
        NavigationStack {
            ZStack {
                AtlasPalette.background.ignoresSafeArea()
                if planned.isEmpty {
                    ContentUnavailableView(
                        "No waypoints plotted",
                        systemImage: "point.topleft.down.curvedto.point.bottomright.up",
                        description: Text("Tap Add Waypoint on a volume to chart your reading route.")
                    )
                } else {
                    List {
                        Section {
                            CompassRoseIndicator(spokes: min(planned.count, 8), accent: AtlasPalette.accent)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowBackground(Color.clear)
                        }
                        ForEach(planned) { volume in
                            waypointRow(volume)
                                .listRowBackground(AtlasPalette.surface)
                        }
                        .onMove(perform: move)
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.insetGrouped)
                }
            }
            .navigationBarHidden(true)
            .environment(\.editMode, $editMode)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { EditButton() }
            }
        }
    }

    private func waypointRow(_ volume: ExpeditionVolume) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                CoverPlateView(coverURL: volume.coverURL(size: "S"))
                    .frame(width: 52, height: 78)
                VStack(alignment: .leading, spacing: 6) {
                    Text(volume.title).font(.headline)
                    Text(volume.authorsText.replacingOccurrences(of: "\n", with: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    DatePicker("Planned for", selection: Binding(
                        get: { volume.plannedFor ?? .now },
                        set: { newValue in
                            volume.plannedFor = newValue
                            volume.modifiedAt = .now
                            try? modelContext.save()
                        }
                    ), displayedComponents: .date)
                    .font(.caption)
                    HStack {
                        Button("Mark reading") {
                            volume.expeditionStatus = .reading
                            volume.modifiedAt = .now
                            try? modelContext.save()
                        }
                        .buttonStyle(.bordered)
                        Button("Mark finished") {
                            volume.expeditionStatus = .finished
                            volume.finishedAt = .now
                            volume.modifiedAt = .now
                            try? modelContext.save()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AtlasPalette.primary)
                        Spacer()
                        Button(role: .destructive) {
                            FolioActions.removeFromWaypointPlan(volume, context: modelContext)
                            try? modelContext.save()
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                    .font(.caption.weight(.semibold))
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func move(from offsets: IndexSet, to destination: Int) {
        var reordered = planned
        reordered.move(fromOffsets: offsets, toOffset: destination)
        for (idx, volume) in reordered.enumerated() { volume.planSortIndex = idx }
        try? modelContext.save()
    }
}
