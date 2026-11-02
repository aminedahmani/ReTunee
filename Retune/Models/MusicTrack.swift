import Foundation
import AVFoundation

struct MusicTrack: Identifiable, Hashable {
    let mood: Mood
    let number: Int
    let duration: TimeInterval
    var id: String { "\(mood.rawValue)-\(number)" }
    var title: String {
        let titles: [String]
        switch mood {
        case .anxiety: titles = ["Stillness", "Drift", "Quiet Sky"]
        case .anger: titles = ["Cool Air", "Soft Ember", "Release"]
        case .sadness: titles = ["First Light", "Daybreak", "Open Sky"]
        case .disappointment: titles = ["New Leaf", "Small Steps", "Begin Again"]
        }
        return titles[number - 1]
    }
    var url: URL? { Bundle.main.url(forResource: id, withExtension: "mp3") }
    var durationLabel: String {
        let seconds = Int(duration.rounded())
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
    static let all: [MusicTrack] = Mood.allCases.flatMap { mood in
        (1...3).map { number in
            let url = Bundle.main.url(forResource: "\(mood.rawValue)-\(number)", withExtension: "mp3")
            let duration = url.flatMap { try? AVAudioPlayer(contentsOf: $0).duration } ?? 0
            return MusicTrack(mood: mood, number: number, duration: duration)
        }
    }
    static func tracks(for mood: Mood) -> [MusicTrack] { all.filter { $0.mood == mood } }
    static func preferred(for mood: Mood, store: UserDefaults = .standard) -> MusicTrack {
        let tracks = tracks(for: mood)
        return tracks.first { $0.number == store.integer(forKey: "music.\(mood.rawValue)") } ?? tracks[0]
    }
    func remember(in store: UserDefaults = .standard) {
        store.set(number, forKey: "music.\(mood.rawValue)")
    }
}
