import Foundation

/// ANSI escape codes and terminal control utilities
enum TerminalControl {
    // ANSI Escape Codes
    static let escape = "\u{001B}["
    static let clearLine = "\(escape)2K"
    static let clearScreen = "\(escape)2J"
    static let hideCursor = "\(escape)?25l"
    static let showCursor = "\(escape)?25h"
    static let saveCursor = "\(escape)s"
    static let restoreCursor = "\(escape)u"
    
    /// Move cursor up by n lines
    static func cursorUp(_ lines: Int) -> String {
        return "\(escape)\(lines)A"
    }
    
    /// Move cursor down by n lines  
    static func cursorDown(_ lines: Int) -> String {
        return "\(escape)\(lines)B"
    }
    
    /// Move cursor to beginning of line
    static func cursorToLineStart() -> String {
        return "\(escape)G"
    }
    
    /// Move cursor to specific line and column (1-indexed)
    static func cursorTo(line: Int, column: Int) -> String {
        return "\(escape)\(line);\(column)H"
    }
    
    /// Clear from cursor to end of line
    static func clearToEndOfLine() -> String {
        return "\(escape)K"
    }
}

/// Represents a single progress bar
struct ProgressBar {
    let id: String
    let title: String
    var progress: Double = 0.0 // 0.0 to 1.0
    var totalBytes: Int64 = 0
    var downloadedBytes: Int64 = 0
    var state: DownloadState = .waiting
    
    enum DownloadState {
        case waiting
        case downloading
        case completed
        case failed
    }
    
    /// Renders the progress bar as a string
    func render(width: Int = 50) -> String {
        let titleWidth = min(30, title.count)
        let truncatedTitle = title.count > 30 ? String(title.prefix(27)) + "..." : title.ljust(width: 30)
        
        let barWidth = width - 10 // Leave space for percentage and brackets
        let filledWidth = Int(Double(barWidth) * progress)
        let emptyWidth = barWidth - filledWidth
        
        let filled = String(repeating: "█", count: filledWidth)
        let empty = String(repeating: "░", count: emptyWidth)
        let percentage = String(format: "%5.1f%%", progress * 100)
        
        let stateIcon = switch state {
        case .waiting: "⏳"
        case .downloading: "⬇️"
        case .completed: "✅"
        case .failed: "❌"
        }
        
        let sizeInfo = if totalBytes > 0 {
            " \(formatBytes(downloadedBytes))/\(formatBytes(totalBytes))"
        } else {
            ""
        }
        
        return "\(stateIcon) \(truncatedTitle) [\(filled)\(empty)] \(percentage)\(sizeInfo)"
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }
}

extension String {
    func ljust(width: Int, fillChar: Character = " ") -> String {
        if count >= width {
            return self
        }
        return self + String(repeating: fillChar, count: width - count)
    }
}