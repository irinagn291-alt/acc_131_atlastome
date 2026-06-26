import SwiftUI

enum AtlasPalette {
    static let primary = Color(red: 27 / 255, green: 73 / 255, blue: 101 / 255)
    static let secondary = Color(red: 95 / 255, green: 168 / 255, blue: 211 / 255)
    static let accent = Color(red: 202 / 255, green: 103 / 255, blue: 2 / 255)
    static let background = Color(red: 237 / 255, green: 242 / 255, blue: 244 / 255)
    static let surface = Color.white
    static let text = Color(red: 20 / 255, green: 33 / 255, blue: 61 / 255)

    static let gridStroke = primary.opacity(0.18)
    static let contourStroke = secondary.opacity(0.45)

    static let radiusCard: CGFloat = 18
    static let radiusPanel: CGFloat = 22
    static let radiusChip: CGFloat = 14

    static var chartGradient: LinearGradient {
        LinearGradient(
            colors: [background, secondary.opacity(0.12), surface],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var meridianGradient: LinearGradient {
        LinearGradient(
            colors: [surface, background, secondary.opacity(0.08)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static func elevationShadow(reduceMotion: Bool) -> (color: Color, radius: CGFloat, y: CGFloat) {
        (text.opacity(0.1), reduceMotion ? 2 : 12, 6)
    }

    static func chartTitle(_ style: Font.TextStyle = .title2) -> Font {
        .system(style, design: .serif).weight(.bold)
    }
}
