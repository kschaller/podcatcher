import Foundation

/// Manages multiple progress bars for concurrent downloads
actor ProgressManager {
    private var progressBars: [String: ProgressBar] = [:]
    private var isDisplaying = false
    private var displayTask: Task<Void, Never>?
    private let maxConcurrentDownloads: Int
    
    init(maxConcurrentDownloads: Int) {
        self.maxConcurrentDownloads = maxConcurrentDownloads
    }
    
    /// Starts the display system
    func startDisplay() {
        guard !isDisplaying else { return }
        
        isDisplaying = true
        
        // Hide cursor
        print(TerminalControl.hideCursor, terminator: "")
        fflush(stdout)
        
        displayTask = Task {
            await runDisplayLoop()
        }
    }
    
    /// Stops the display system and shows cursor
    func stopDisplay() async {
        isDisplaying = false
        displayTask?.cancel()
        await displayTask?.value
        
        // Clean up terminal - just print a newline to move past progress area
        print()
        print(TerminalControl.showCursor, terminator: "")
        fflush(stdout)
    }
    
    /// Adds a new progress bar for tracking
    func addProgressBar(id: String, title: String) {
        progressBars[id] = ProgressBar(
            id: id,
            title: title,
            state: .waiting
        )
    }
    
    /// Updates progress for a specific download
    func updateProgress(
        id: String,
        progress: Double,
        downloadedBytes: Int64 = 0,
        totalBytes: Int64 = 0,
        state: ProgressBar.DownloadState = .downloading
    ) {
        guard var progressBar = progressBars[id] else { return }
        
        progressBar.progress = progress
        progressBar.downloadedBytes = downloadedBytes
        progressBar.totalBytes = totalBytes
        progressBar.state = state
        
        progressBars[id] = progressBar
    }
    
    /// Marks a download as completed
    func completeDownload(id: String, success: Bool) {
        guard var progressBar = progressBars[id] else { return }
        
        progressBar.progress = 1.0
        progressBar.state = success ? .completed : .failed
        
        progressBars[id] = progressBar
        
        // Immediately log the completion above the progress bars
        logCompletedDownload(progressBar: progressBar)
    }
    
    /// Logs a completed download above the progress bars
    private func logCompletedDownload(progressBar: ProgressBar) {
        // Clear current progress display temporarily
        if renderedLineCount > 0 {
            for _ in 0..<renderedLineCount {
                print(TerminalControl.cursorUp(1), terminator: "")
                print(TerminalControl.clearLine, terminator: "")
            }
            print("\r", terminator: "")
        }
        
        // Print the completion message
        let icon = progressBar.state == .completed ? "✅" : "❌"
        let action = progressBar.state == .completed ? "Downloaded" : "Failed"
        print("\(icon) \(action): \(progressBar.title)")
        
        // Reset line count since we've cleared the progress area
        renderedLineCount = 0
    }
    
    /// Removes a progress bar immediately (used after logging completion)
    func removeProgressBar(id: String) {
        progressBars.removeValue(forKey: id)
    }
    
    private var renderedLineCount = 0
    
    private func runDisplayLoop() async {
        while isDisplaying {
            renderProgressBars()
            
            // Update every 200ms for smooth animation
            try? await Task.sleep(nanoseconds: 200_000_000)
        }
    }
    
    private func renderProgressBars() {
        // Only show bars for downloads that are in progress (not completed/failed)
        let activeBars = Array(progressBars.values
            .filter { $0.state == .waiting || $0.state == .downloading }
            .prefix(maxConcurrentDownloads))
        
        // Clear previously rendered lines
        if renderedLineCount > 0 {
            // Move cursor up and clear each line
            for _ in 0..<renderedLineCount {
                print(TerminalControl.cursorUp(1), terminator: "")
                print(TerminalControl.clearLine, terminator: "")
            }
            print("\r", terminator: "") // Move to start of current line
        }
        
        // Render progress bars
        renderedLineCount = 0
        for bar in activeBars {
            print(bar.render())
            renderedLineCount += 1
        }
        
        // Ensure we have at least one line rendered to avoid cursor issues
        if renderedLineCount == 0 {
            print("Preparing downloads...")
            renderedLineCount = 1
        }
        
        fflush(stdout)
    }
    
    /// Gets current status for logging
    func getStatus() -> (active: Int, completed: Int, failed: Int) {
        let bars = Array(progressBars.values)
        let active = bars.filter { $0.state == .downloading || $0.state == .waiting }.count
        let completed = bars.filter { $0.state == .completed }.count
        let failed = bars.filter { $0.state == .failed }.count
        
        return (active, completed, failed)
    }
}