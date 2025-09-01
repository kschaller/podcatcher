import Foundation

struct Episode: Hashable, Identifiable {
    let id = UUID()
    let title: String
    let url: URL
    let date: Date
    let fileExtension: String
    
    init(title: String, url: URL, date: Date, fileExtension: String) {
        self.title = title
        self.url = url
        self.date = date
        self.fileExtension = fileExtension.isEmpty ? "mp3" : fileExtension
    }
}

extension Episode: CustomStringConvertible {
    var description: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: date)) - \(title)"
    }
}