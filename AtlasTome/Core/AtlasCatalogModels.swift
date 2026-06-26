import Foundation

enum MeridianQueryMode: String, CaseIterable, Identifiable, Sendable {
    case general, title, author, subject, isbn

    var id: String { rawValue }

    var label: String {
        switch self {
        case .general: "All"
        case .title: "Title"
        case .author: "Author"
        case .subject: "Subject"
        case .isbn: "ISBN"
        }
    }
}

struct AtlasVolumePreview: Identifiable, Hashable, Sendable {
    var id: String { workKey ?? "ed:\(editionKey ?? "")-\(title)-\(authors.prefix(1).joined())" }
    var title: String
    var authors: [String]
    var isbn: String?
    var coverId: Int?
    var workKey: String?
    var editionKey: String?
    var firstPublishYear: Int?
    var subjects: [String]?

    func coverURL(size: String = "M") -> URL? {
        guard let coverId else { return nil }
        return URL(string: "https://covers.openlibrary.org/b/id/\(coverId)-\(size).jpg")
    }

    func dedupeKey() -> String { VolumeIdentity.dedupeKey(for: self) }
}

struct AtlasSearchResponse: Decodable, Sendable {
    let docs: [AtlasSearchDoc]?
}

struct AtlasSearchDoc: Decodable, Sendable {
    let key: String?
    let title: String?
    let authorName: [String]?
    let coverI: Int?
    let firstPublishYear: Int?
    let isbn: [String]?
    let subject: [String]?

    enum CodingKeys: String, CodingKey {
        case key, title, isbn, subject
        case authorName = "author_name"
        case coverI = "cover_i"
        case firstPublishYear = "first_publish_year"
    }

    func asPreview() -> AtlasVolumePreview? {
        guard let title, !title.isEmpty else { return nil }
        return AtlasVolumePreview(
            title: title,
            authors: authorName ?? [],
            isbn: isbn?.first,
            coverId: coverI,
            workKey: key,
            editionKey: nil,
            firstPublishYear: firstPublishYear,
            subjects: subject
        )
    }
}

struct AtlasSubjectResponse: Decodable, Sendable {
    let works: [AtlasSubjectWork]?
}

struct AtlasSubjectWork: Decodable, Sendable {
    let key: String?
    let title: String?
    let coverId: Int?
    let authors: [AtlasSubjectAuthor]?

    enum CodingKeys: String, CodingKey {
        case key, title, authors
        case coverId = "cover_id"
    }

    func asPreview() -> AtlasVolumePreview? {
        guard let title, !title.isEmpty else { return nil }
        return AtlasVolumePreview(
            title: title,
            authors: authors?.compactMap(\.name) ?? [],
            isbn: nil,
            coverId: coverId,
            workKey: key,
            editionKey: nil,
            firstPublishYear: nil,
            subjects: nil
        )
    }
}

struct AtlasSubjectAuthor: Decodable, Sendable { let name: String? }

struct AtlasEditionISBNResponse: Decodable, Sendable {
    let title: String?
    let fullTitle: String?
    let covers: [Int]?
    let authors: [AtlasEditionAuthorRef]?
    let works: [AtlasEditionWorkRef]?
    let key: String?
    let isbn10: [String]?
    let isbn13: [String]?
    let byStatement: String?

    enum CodingKeys: String, CodingKey {
        case title, covers, authors, works, key
        case fullTitle = "full_title"
        case isbn10 = "isbn_10"
        case isbn13 = "isbn_13"
        case byStatement = "by_statement"
    }

    func asPreview(fallbackISBN: String) -> AtlasVolumePreview {
        let t = title ?? fullTitle ?? "Unknown title"
        let parsedAuthors: [String] = {
            if let bs = byStatement, bs.lowercased().hasPrefix("by ") {
                return String(bs.dropFirst(3))
                    .split(separator: ";")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            }
            return []
        }()
        return AtlasVolumePreview(
            title: t,
            authors: parsedAuthors,
            isbn: isbn13?.first ?? isbn10?.first ?? fallbackISBN,
            coverId: covers?.first,
            workKey: works?.first?.key,
            editionKey: key,
            firstPublishYear: nil,
            subjects: nil
        )
    }
}

struct AtlasEditionAuthorRef: Decodable, Sendable { let key: String? }
struct AtlasEditionWorkRef: Decodable, Sendable { let key: String? }

struct ChartedExplorer: Identifiable, Hashable, Sendable {
    var id: String { displayName }
    let displayName: String
    let searchQuery: String
    let region: String
}

enum ChartedExplorers {
    static let list: [ChartedExplorer] = [
        ChartedExplorer(displayName: "Rebecca Solnit", searchQuery: "Rebecca Solnit", region: "Atlas"),
        ChartedExplorer(displayName: "Robert Macfarlane", searchQuery: "Robert Macfarlane", region: "Landscape"),
        ChartedExplorer(displayName: "Bill Bryson", searchQuery: "Bill Bryson", region: "Journey"),
        ChartedExplorer(displayName: "Mary Beard", searchQuery: "Mary Beard", region: "History"),
        ChartedExplorer(displayName: "Yuval Noah Harari", searchQuery: "Yuval Noah Harari", region: "Civilization"),
        ChartedExplorer(displayName: "Jared Diamond", searchQuery: "Jared Diamond", region: "Geography"),
        ChartedExplorer(displayName: "Oliver Sacks", searchQuery: "Oliver Sacks", region: "Mind"),
        ChartedExplorer(displayName: "David Attenborough", searchQuery: "David Attenborough", region: "Nature")
    ]
}
