import Foundation
import SwiftData

enum ExpeditionStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case wantToRead, reading, finished, abandoned

    var id: String { rawValue }

    var title: String {
        switch self {
        case .wantToRead: "Want to read"
        case .reading: "Reading"
        case .finished: "Finished"
        case .abandoned: "Abandoned"
        }
    }
}

@Model
final class ExpeditionVolume {
    @Attribute(.unique) var dedupeKey: String
    var title: String
    var authorsText: String
    var isbn: String?
    var workKey: String?
    var editionKey: String?
    var coverId: Int?
    var firstPublishYear: Int?
    var statusRaw: String
    var rating: Int
    var review: String
    var notes: String
    var startedAt: Date?
    var finishedAt: Date?
    var createdAt: Date
    var modifiedAt: Date
    var isInReadingPlan: Bool
    var plannedFor: Date?
    var planSortIndex: Int

    init(
        dedupeKey: String, title: String, authorsText: String,
        isbn: String? = nil, workKey: String? = nil, editionKey: String? = nil,
        coverId: Int? = nil, firstPublishYear: Int? = nil,
        status: ExpeditionStatus = .wantToRead, rating: Int = 0,
        review: String = "", notes: String = "",
        startedAt: Date? = nil, finishedAt: Date? = nil,
        createdAt: Date = .now, modifiedAt: Date = .now,
        isInReadingPlan: Bool = false, plannedFor: Date? = nil, planSortIndex: Int = 0
    ) {
        self.dedupeKey = dedupeKey
        self.title = title
        self.authorsText = authorsText
        self.isbn = isbn
        self.workKey = workKey
        self.editionKey = editionKey
        self.coverId = coverId
        self.firstPublishYear = firstPublishYear
        self.statusRaw = status.rawValue
        self.rating = rating
        self.review = review
        self.notes = notes
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.isInReadingPlan = isInReadingPlan
        self.plannedFor = plannedFor
        self.planSortIndex = planSortIndex
    }

    var expeditionStatus: ExpeditionStatus {
        get { ExpeditionStatus(rawValue: statusRaw) ?? .wantToRead }
        set { statusRaw = newValue.rawValue }
    }

    var authorsArray: [String] { authorsText.split(separator: "\n").map(String.init) }

    func apply(preview: AtlasVolumePreview) {
        title = preview.title
        authorsText = preview.authors.joined(separator: "\n")
        isbn = preview.isbn ?? isbn
        workKey = preview.workKey ?? workKey
        editionKey = preview.editionKey ?? editionKey
        coverId = preview.coverId ?? coverId
        firstPublishYear = preview.firstPublishYear ?? firstPublishYear
        modifiedAt = .now
    }

    func coverURL(size: String = "M") -> URL? {
        guard let coverId else { return nil }
        return URL(string: "https://covers.openlibrary.org/b/id/\(coverId)-\(size).jpg")
    }
}

enum FolioActions: Sendable {
    static func fetchStored(dedupeKey: String, context: ModelContext) throws -> ExpeditionVolume? {
        var descriptor = FetchDescriptor<ExpeditionVolume>(predicate: #Predicate { $0.dedupeKey == dedupeKey })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    static func nextPlanSortIndex(context: ModelContext) throws -> Int {
        var descriptor = FetchDescriptor<ExpeditionVolume>(
            predicate: #Predicate { $0.isInReadingPlan == true },
            sortBy: [SortDescriptor(\.planSortIndex, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return (try context.fetch(descriptor).first?.planSortIndex ?? -1) + 1
    }

    static func upsertFromFolio(preview: AtlasVolumePreview, context: ModelContext) throws -> ExpeditionVolume {
        let key = preview.dedupeKey()
        if let existing = try fetchStored(dedupeKey: key, context: context) {
            existing.apply(preview: preview)
            return existing
        }
        let volume = ExpeditionVolume(
            dedupeKey: key, title: preview.title,
            authorsText: preview.authors.joined(separator: "\n"),
            isbn: preview.isbn, workKey: preview.workKey, editionKey: preview.editionKey,
            coverId: preview.coverId, firstPublishYear: preview.firstPublishYear
        )
        context.insert(volume)
        return volume
    }

    static func addToWaypointPlan(preview: AtlasVolumePreview, context: ModelContext) throws -> ExpeditionVolume {
        let volume = try upsertFromFolio(preview: preview, context: context)
        if !volume.isInReadingPlan {
            volume.isInReadingPlan = true
            volume.planSortIndex = try nextPlanSortIndex(context: context)
        }
        volume.modifiedAt = .now
        return volume
    }

    static func removeFromWaypointPlan(_ volume: ExpeditionVolume, context: ModelContext) {
        volume.isInReadingPlan = false
        volume.plannedFor = nil
        volume.modifiedAt = .now
    }

    static func clearAllVolumes(context: ModelContext) throws {
        for volume in try context.fetch(FetchDescriptor<ExpeditionVolume>()) {
            context.delete(volume)
        }
    }
}
