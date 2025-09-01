import Foundation

enum Element: String, CaseIterable {
    case item
    case title
    case date = "pubDate"
    case enclosure
}