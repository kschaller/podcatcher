//
//  ProgressBar.swift
//  Podcatcher
//
//  Created by Claude on 3/1/2025.
//

import Foundation

/// A console progress bar for displaying download progress
class ProgressBar {
    // ANSI escape codes for terminal control
    private enum ANSI {
        static let clearLine = "\u{001B}[2K"
        static let cursorUp = "\u{001B}[1A"
        static let cursorToLineStart = "\u{001B}[0G"
    }
    
    private let width: Int
    private let title: String
    
    init(title: String, width: Int = 30) {
        self.title = title
        self.width = width
    }
    
    /// Update and redraw the progress bar
    func update(progress: Double) {
        ProgressManager.shared.performWithLock {
            // Calculate filled width
            let filledWidth = Int(Double(width) * min(max(progress, 0), 1))
            let emptyWidth = width - filledWidth
            
            // Format percentage
            let percent = Int(progress * 100)
            
            // Clear current line
            print(ANSI.clearLine + ANSI.cursorToLineStart, terminator: "")
            
            // Print progress bar
            let bar = "[\(String(repeating: "=", count: filledWidth))\(String(repeating: " ", count: emptyWidth))] \(percent)%"
            print("\(title): \(bar)", terminator: "")
            
            // Flush output to ensure immediate display
            fflush(stdout)
        }
    }
    
    /// Complete the progress bar and move to the next line
    func complete(message: String = "Complete") {
        ProgressManager.shared.performWithLock {
            // Clear current line and print completion message
            print(ANSI.clearLine + ANSI.cursorToLineStart, terminator: "")
            print("\(title): \(message)")
        }
    }
    
    /// Clear the progress bar without printing anything
    func clear() {
        ProgressManager.shared.performWithLock {
            // Clear current line
            print(ANSI.clearLine + ANSI.cursorToLineStart, terminator: "")
            fflush(stdout)
        }
    }
}

/// A simple progress manager to ensure only one progress bar prints at a time
class ProgressManager {
    static let shared = ProgressManager()
    private let lock = NSLock()
    
    func performWithLock(_ action: () -> Void) {
        lock.lock()
        defer { lock.unlock() }
        action()
    }
}