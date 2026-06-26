import SwiftUI

enum AtlasMotion {
    @MainActor
    static func expeditionSlide(reduceMotion: Bool) -> Animation {
        reduceMotion ? .linear(duration: 0.12) : .spring(response: 0.52, dampingFraction: 0.86)
    }

    @MainActor
    static func chartReveal(reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.44, dampingFraction: 0.84)
    }

    @MainActor
    static func drawerSlide(reduceMotion: Bool) -> Animation {
        reduceMotion ? .linear(duration: 0.12) : .easeOut(duration: 0.22)
    }
}
