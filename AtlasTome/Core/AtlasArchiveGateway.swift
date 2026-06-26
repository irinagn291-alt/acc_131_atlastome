import Foundation

enum ChartTrendPeriod: String, Sendable {
    case daily, weekly
}

actor AtlasArchiveGateway {
    static let shared = AtlasArchiveGateway()

    private let session: URLSession
    private let userAgent = "AtlasTome/1.0 (iOS; +https://openlibrary.org/developers/api)"

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 25
        config.timeoutIntervalForResource = 45
        config.waitsForConnectivity = true
        session = URLSession(configuration: config)
    }

    private func data(for url: URL, allow429Retry: Bool = true) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        let (payload, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if http.statusCode == 429, allow429Retry {
            try await Task.sleep(nanoseconds: 1_200_000_000)
            return try await data(for: url, allow429Retry: false)
        }
        guard (200...299).contains(http.statusCode) else {
            throw NSError(domain: NSURLErrorDomain, code: URLError.badServerResponse.rawValue, userInfo: [
                NSLocalizedDescriptionKey: "Open Library returned HTTP \(http.statusCode)."
            ])
        }
        return payload
    }

    func search(mode: MeridianQueryMode, query: String, limit: Int = 30) async throws -> [AtlasVolumePreview] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        if mode == .isbn { return try await fetchByISBN(trimmed) }
        var components = URLComponents(string: "https://openlibrary.org/search.json")!
        let qItem: URLQueryItem = switch mode {
        case .general: URLQueryItem(name: "q", value: trimmed)
        case .title: URLQueryItem(name: "title", value: trimmed)
        case .author: URLQueryItem(name: "author", value: trimmed)
        case .subject: URLQueryItem(name: "subject", value: trimmed)
        case .isbn: URLQueryItem(name: "q", value: trimmed)
        }
        components.queryItems = [qItem, URLQueryItem(name: "limit", value: String(limit))]
        guard let url = components.url else { return [] }
        let decoded = try JSONDecoder().decode(AtlasSearchResponse.self, from: await data(for: url))
        return (decoded.docs ?? []).compactMap { $0.asPreview() }
    }

    func fetchByISBN(_ raw: String) async throws -> [AtlasVolumePreview] {
        let digits = raw.filter(\.isNumber)
        guard digits.count >= 10 else { return [] }
        let url = URL(string: "https://openlibrary.org/isbn/\(digits).json")!
        let edition = try JSONDecoder().decode(AtlasEditionISBNResponse.self, from: await data(for: url))
        var preview = edition.asPreview(fallbackISBN: digits)
        if preview.authors.isEmpty {
            let names = await resolveAuthorNames(refs: edition.authors ?? [])
            if !names.isEmpty {
                preview = AtlasVolumePreview(
                    title: preview.title, authors: names, isbn: preview.isbn,
                    coverId: preview.coverId, workKey: preview.workKey,
                    editionKey: preview.editionKey, firstPublishYear: preview.firstPublishYear,
                    subjects: preview.subjects
                )
            }
        }
        return [preview]
    }

    private func resolveAuthorNames(refs: [AtlasEditionAuthorRef]) async -> [String] {
        var names: [String] = []
        for ref in refs.prefix(4) {
            guard let key = ref.key, key.hasPrefix("/authors/") else { continue }
            if let name = await fetchAuthorName(path: key) { names.append(name) }
        }
        return names
    }

    private func fetchAuthorName(path: String) async -> String? {
        let url = URL(string: "https://openlibrary.org\(path).json")!
        do {
            struct A: Decodable { let name: String? }
            return try JSONDecoder().decode(A.self, from: await data(for: url)).name
        } catch { return nil }
    }

    func fetchSubjectWorks(subject: String, limit: Int = 20) async throws -> [AtlasVolumePreview] {
        let encoded = subject.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? subject
        let url = URL(string: "https://openlibrary.org/subjects/\(encoded).json?limit=\(limit)")!
        let decoded = try JSONDecoder().decode(AtlasSubjectResponse.self, from: await data(for: url))
        return (decoded.works ?? []).compactMap { $0.asPreview() }
    }

    func fetchTrending(period: ChartTrendPeriod) async throws -> [AtlasVolumePreview] {
        let url = URL(string: "https://openlibrary.org/trending/\(period.rawValue).json?limit=20")!
        do {
            let payload = try await data(for: url)
            if let summaries = try decodeTrendingWorks(from: payload), !summaries.isEmpty {
                return summaries
            }
        } catch {}
        let subjects = ["geography", "history", "science", "travel", "nature"]
        return try await fetchSubjectWorks(subject: subjects.randomElement() ?? "geography", limit: 20)
    }

    private func decodeTrendingWorks(from data: Data) throws -> [AtlasVolumePreview]? {
        guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        if let works = dict["works"] as? [[String: Any]] {
            return works.compactMap { w in
                guard let title = w["title"] as? String, !title.isEmpty else { return nil }
                return AtlasVolumePreview(
                    title: title,
                    authors: w["author_name"] as? [String] ?? [],
                    isbn: nil,
                    coverId: (w["cover_i"] as? NSNumber)?.intValue,
                    workKey: w["key"] as? String,
                    editionKey: nil,
                    firstPublishYear: (w["first_publish_year"] as? NSNumber)?.intValue,
                    subjects: w["subject"] as? [String]
                )
            }
        }
        return nil
    }
}
