//
//  Podcatcher.swift
//  Podcatcher
//
//  Created by Kai Schaller on 6/17/18.
//  Copyright © 2018 Kai Schaller. All rights reserved.
//

import Foundation

actor Podcatcher: DownloadProgressReporter {
    
    private let consoleIO = ConsoleIO()
    private let downloadManager = DownloadManager()
    private let outputDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private var outputURL: URL?
    private var notBeforeDate: Date?
    
    // Make this async to use structured concurrency
    func staticMode() async {
        guard let url = URL(string: CommandLine.arguments[1]) else {
            consoleIO.writeMessage("Unable to read URL", to: .error)
            return
        }
        
        outputURL = URL(fileURLWithPath: CommandLine.arguments[2]) // TODO: Add some checking so we don't get OOB error
        
        if CommandLine.arguments.indices.contains(3) {
            let dateString = CommandLine.arguments[3]
            self.notBeforeDate = outputDateFormatter.date(from: dateString)
        }
        
        guard let parser = Parser(url: url) else {
            consoleIO.writeMessage("Failed to initialize parser", to: .error)
            return
        }
        
        // Set up download manager with progress reporter
        await downloadManager.setProgressReporter(self)
        
        // Parse feed
        consoleIO.writeMessage("Parsing feed...")
        let episodes = await parser.parseAsync()
        
        // Download episodes
        await processEpisodes(episodes)
    }
    
    private func outputURL(for episode: Episode) -> URL? {
        let dateString = outputDateFormatter.string(from: episode.date)
        // https://stackoverflow.com/questions/36064907/swift-using-slash-in-filename-with-createdirectoryatpath
        let encodedTitle = episode.title.replacingOccurrences(of: "/", with: ":")
        let filename = "\(dateString)_\(encodedTitle).\(episode.fileExtension)"
        return outputURL?.appendingPathComponent(filename)
    }
    
    private func processEpisodes(_ episodes: [Episode]) async {
        let notBeforeDate = self.notBeforeDate ?? Date.distantPast
        let fileManager = FileManager.default
        
        // Create a list of episodes to download
        var downloadQueue: [(episode: Episode, destination: URL)] = []
        
        // Filter episodes that need downloading
        for episode in episodes {
            guard let destinationURL = outputURL(for: episode) else {
                continue
            }
            
            if !fileManager.fileExists(atPath: destinationURL.path) && notBeforeDate < episode.date {
                downloadQueue.append((episode: episode, destination: destinationURL))
            } else {
                // Count skipped episodes
                await downloadManager.incrementSkippedCount()
            }
        }
        
        // Create a TaskGroup with a token-based approach for limiting concurrency
        if downloadQueue.isEmpty {
            // No episodes to download
            return
        }
        
        // Create a semaphore-like actor for limiting concurrency
        actor DownloadTokens {
            private var availableTokens: Int
            private var waitingTasks: [(CheckedContinuation<Void, Never>)] = []
            
            init(tokens: Int) {
                self.availableTokens = tokens
            }
            
            func acquireToken() async {
                if availableTokens > 0 {
                    availableTokens -= 1
                    return
                }
                
                await withCheckedContinuation { continuation in
                    waitingTasks.append(continuation)
                }
            }
            
            func releaseToken() async {
                if let nextTask = waitingTasks.first {
                    waitingTasks.removeFirst()
                    nextTask.resume()
                } else {
                    availableTokens += 1
                }
            }
        }
        
        let tokens = DownloadTokens(tokens: 3)
        
        // Process all downloads with a concurrent limit
        await withTaskGroup(of: Void.self) { group in
            // Start a dispatcher task that manages the download queue
            for download in downloadQueue {
                group.addTask {
                    // Acquire token before starting download (blocks if no tokens available)
                    await tokens.acquireToken()
                    
                    // Perform download
                    await self.downloadAndSaveEpisode(download.episode, to: download.destination)
                    
                    // Release token when done (regardless of success or failure)
                    do {
                        try await Task.sleep(for: .milliseconds(10)) // Small delay to avoid potential race conditions
                        await tokens.releaseToken()
                    } catch {
                        // Ensure token is released even if sleep is cancelled
                        await tokens.releaseToken()
                    }
                }
            }
            
            // Wait for all downloads to complete
            await group.waitForAll()
        }
        
        // Report final counts
        let counts = await downloadManager.downloadCount
        consoleIO.writeMessage("Done! Downloaded \(counts.new) new episodes and skipped \(counts.skipped).")
    }
    
    // Helper method to adjust active downloads count and start new downloads
    private func adjustActiveDownloads(_ activeDownloads: inout Int, group: TaskGroup<Void>) async {
        // This method is deliberately limited to just decrementing the count
        // TaskGroup doesn't allow adding new tasks from within a child task in Swift's structured concurrency
        // The parent context will handle starting new downloads when this task completes
        activeDownloads -= 1
    }
    
    private func downloadAndSaveEpisode(_ episode: Episode, to destinationURL: URL) async {
        do {
            // Download the episode
            let temporaryURL = try await downloadManager.download(episode: episode)
            
            // Save to final destination
            try FileManager.default.copyItem(at: temporaryURL, to: destinationURL)
            await downloadManager.incrementNewCount()
        } catch {
            consoleIO.writeMessage("Error downloading \(episode.title): \(error.localizedDescription)", to: .error)
        }
    }
    
    // MARK: - DownloadProgressReporter Implementation
    
    func reportProgress(for episode: Episode, bytesReceived: Int64, totalBytes: Int64) async {
        // Skip if we don't have valid total bytes
        guard totalBytes > 0 else { return }
        
        // Calculate progress percentage
        let progress = Double(bytesReceived) / Double(totalBytes)
        
        // Format title to keep it short
        let title = episode.title.count > 30 ? episode.title.prefix(27) + "..." : episode.title
        
        // Using a temporary progress bar for each update
        
        // Create and update progress bar
        let bar = ProgressBar(title: String(title))
        bar.update(progress: progress)
    }
    
    func downloadStarted(episode: Episode) async {
        // Prepare for a new download progress display
        let title = episode.title.count > 30 ? episode.title.prefix(27) + "..." : episode.title
        
        // Create a new progress bar and show initial state
        let bar = ProgressBar(title: String(title))
        bar.update(progress: 0)
    }
    
    func downloadFinished(episode: Episode) async {
        // Clear the progress bar when download is completed
        let title = episode.title.count > 30 ? episode.title.prefix(27) + "..." : episode.title
        let bar = ProgressBar(title: String(title))
        bar.clear()
    }
}
