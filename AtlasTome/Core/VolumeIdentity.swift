import Foundation

enum VolumeIdentity: Sendable {
    static func dedupeKey(for preview: AtlasVolumePreview) -> String {
        if let isbn = preview.isbn, !isbn.isEmpty {
            let digits = isbn.filter(\.isNumber)
            if digits.count >= 10 { return "isbn:\(digits)" }
        }
        if let workKey = preview.workKey, !workKey.isEmpty { return "work:\(workKey)" }
        let authorKey = preview.authors.map { $0.lowercased() }.sorted().joined(separator: "|")
        return "title:\(preview.title.lowercased())|authors:\(authorKey)"
    }
}
