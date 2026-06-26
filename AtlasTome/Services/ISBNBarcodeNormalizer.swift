import Foundation

enum ISBNBarcodeNormalizer {
    static func canonicalISBN(_ raw: String) -> String? {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }
        let only = s.filter(\.isNumber)
        if (10...13).contains(only.count) { return only }
        return longestDigitRun(in: s)
    }

    static func lookupCandidates(for raw: String) -> [String] {
        let resolved = canonicalISBN(raw) ?? raw.filter(\.isNumber)
        guard resolved.count >= 10 else { return [] }
        var candidates = [resolved]
        if resolved.count == 13, resolved.hasPrefix("0") {
            candidates.append(String(resolved.dropFirst()))
        }
        var seen = Set<String>()
        return candidates.filter { seen.insert($0).inserted }
    }

    private static func longestDigitRun(in s: String) -> String? {
        var best = "", current = ""
        for ch in s {
            if ch.isNumber { current.append(ch) }
            else {
                if current.count > best.count { best = current }
                current = ""
            }
        }
        if current.count > best.count { best = current }
        return best.isEmpty ? nil : best
    }
}
