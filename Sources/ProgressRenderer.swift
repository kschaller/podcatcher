//
//  ProgressRenderer.swift
//  Podcatcher
//
//  Created by Kai Schaller on 5/18/25.
//

import Foundation

actor ProgressRenderer {
    
    private var lines: [(title: String, percent: Double)] = []
    private var hasDrawn: Bool = false
    private var lastDrawnCount: Int = 0
    
    /// Call once at the beginning to reserve a slot and print the initial zero progress.
    func registerLine(title: String) -> Int {
        lines.append((title: title, percent: 0.0))
        redraw()
        return lines.count - 1
    }
    
    /// Call when progress changes (0.0 to 1.0) to update the slot, but only when the
    /// integer percentage changes to avoid excessive writes to the console.
    func updateLine(index: Int, percent: Double) {
        // Only update every 5%.
        let newPercentInt = Int(round(percent * 100) / 5)
        let oldPercentInt = Int(round(lines[index].percent * 100) / 5)
        
        guard newPercentInt != oldPercentInt else {
            return
        }
        
        lines[index].percent = percent
        redraw()
    }
    
    /// Redraw all the lines in place using ANSI escape sequences.
    private func redraw() {
        return;
        // Move the cursor up, if needed.
        if hasDrawn {
            print("\u{001B}[\(lastDrawnCount)A", terminator: "")
        }
        
        // Mark that we've drawn at least once.
        hasDrawn = true
        
        // Redraw each line.
        for (title, percent) in lines {
            let bar = buildBar(percent: percent)
            // Clear the line and reprint.
            print("\u{001B}[2K\(bar)  \(title)")
        }
        lastDrawnCount = lines.count
    }
    
    /// Build a 20-char bar, ex: "[#####---------------] 25%".
    private func buildBar(percent: Double) -> String {
        let totalChars = 20
        let filled = Int(round(Double(totalChars) * percent))
        let empty = totalChars - filled
        let hashes = String(repeating: "#", count: filled)
        let dashes = String(repeating: "-", count: empty)
        let percent = Int(round(percent * 100))
        return "[\(hashes)\(dashes)] \(String(format: "%3d", percent))%"
    }
    
}
