import Foundation

actor Podcatcher {
    private let maxConcurrentDownloads: Int
    private let outputDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    private let progressManager: ProgressManager?
    private let showProgress: Bool
    
    init(maxConcurrentDownloads: Int = 3, showProgress: Bool = false) {
        self.maxConcurrentDownloads = maxConcurrentDownloads
        self.showProgress = showProgress
        self.progressManager = showProgress ? ProgressManager(maxConcurrentDownloads: maxConcurrentDownloads) : nil
    }
    
    func downloadPodcast(
        from rssURL: URL,
        to outputDirectory: URL,
        notBeforeDate: Date? = nil
    ) async throws {
        print("Parsing RSS feed from: \(rssURL)")
        
        let parser = Parser()
        let episodes = try await parser.parseEpisodes(from: rssURL)
        
        print("Found \(episodes.count) episodes")
        
        let filteredEpisodes = filterEpisodes(
            episodes,
            outputDirectory: outputDirectory,
            notBeforeDate: notBeforeDate
        )
        
        let (toDownload, skipped) = filteredEpisodes
        print("Will download \(toDownload.count) new episodes, skipping \(skipped) existing/old episodes")
        
        if !toDownload.isEmpty {
            if showProgress {
                await progressManager?.startDisplay()
            }
            
            let downloadedCount = await downloadEpisodes(
                toDownload,
                to: outputDirectory
            )
            
            if showProgress {
                // Wait a moment to show final results
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await progressManager?.stopDisplay()
            }
            
            print("Done! Downloaded \(downloadedCount) new episodes and skipped \(skipped).")
        } else {
            print("No new episodes to download.")
        }
    }
    
    private func filterEpisodes(
        _ episodes: [Episode],
        outputDirectory: URL,
        notBeforeDate: Date?
    ) -> (toDownload: [Episode], skipped: Int) {
        let notBefore = notBeforeDate ?? Date.distantPast
        var toDownload: [Episode] = []
        var skipped = 0
        
        for episode in episodes {
            let outputURL = outputURL(for: episode, in: outputDirectory)
            
            if !FileManager.default.fileExists(atPath: outputURL.path) && episode.date >= notBefore {
                toDownload.append(episode)
            } else {
                skipped += 1
            }
        }
        
        return (toDownload, skipped)
    }
    
    private func downloadEpisodes(_ episodes: [Episode], to outputDirectory: URL) async -> Int {
        var downloadedCount = 0
        
        await withTaskGroup(of: Bool.self) { group in
            let semaphore = AsyncSemaphore(value: maxConcurrentDownloads)
            
            for episode in episodes {
                group.addTask {
                    await semaphore.waitForSignal()
                    defer { Task { await semaphore.signal() } }
                    
                    return await self.downloadEpisode(episode, to: outputDirectory)
                }
            }
            
            for await success in group {
                if success {
                    downloadedCount += 1
                }
            }
        }
        
        return downloadedCount
    }
    
    private func downloadEpisode(_ episode: Episode, to outputDirectory: URL) async -> Bool {
        let outputURL = outputURL(for: episode, in: outputDirectory)
        let episodeId = episode.id.uuidString
        
        // Add progress bar for this episode
        if showProgress {
            await progressManager?.addProgressBar(id: episodeId, title: episode.title)
        } else {
            print("Downloading: \(episode.title)")
        }
        
        do {
            // Create directory if needed
            try FileManager.default.createDirectory(
                at: outputDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
            
            // Use custom URLSession with progress tracking
            let success = await downloadWithProgress(
                from: episode.url,
                to: outputURL,
                episodeId: episodeId
            )
            
            if showProgress {
                await progressManager?.completeDownload(id: episodeId, success: success)
                // Remove immediately after logging completion
                await progressManager?.removeProgressBar(id: episodeId)
            } else {
                let status = success ? "✓" : "✗"
                let message = success ? "Downloaded" : "Failed to download"
                print("\(status) \(message): \(episode.title)")
            }
            
            return success
            
        } catch {
            if showProgress {
                await progressManager?.completeDownload(id: episodeId, success: false)
                // Remove immediately after logging completion
                await progressManager?.removeProgressBar(id: episodeId)
            } else {
                print("✗ Failed to download: \(episode.title)")
            }
            return false
        }
    }
    
    private func downloadWithProgress(
        from url: URL,
        to destinationURL: URL,
        episodeId: String
    ) async -> Bool {
        if showProgress {
            return await downloadWithProgressTracking(from: url, to: destinationURL, episodeId: episodeId)
        } else {
            return await downloadSimple(from: url, to: destinationURL)
        }
    }
    
    private func downloadSimple(from url: URL, to destinationURL: URL) async -> Bool {
        do {
            let (tempURL, _) = try await URLSession.shared.download(from: url)
            
            // Remove existing file if present
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            // Move downloaded file to final location
            try FileManager.default.moveItem(at: tempURL, to: destinationURL)
            return true
            
        } catch {
            return false
        }
    }
    
    private func downloadWithProgressTracking(from url: URL, to destinationURL: URL, episodeId: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            let session = URLSession.shared
            let task = session.downloadTask(with: url) { tempURL, response, error in
                if let error = error {
                    continuation.resume(returning: false)
                    return
                }
                
                guard let tempURL = tempURL else {
                    continuation.resume(returning: false)
                    return
                }
                
                do {
                    // Remove existing file if present
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                    
                    // Move downloaded file to final location
                    try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                    continuation.resume(returning: true)
                } catch {
                    continuation.resume(returning: false)
                }
            }
            
            // Set up progress observation
            let observation = task.progress.observe(\.fractionCompleted, options: [.new]) { progress, change in
                Task {
                    await self.progressManager?.updateProgress(
                        id: episodeId,
                        progress: progress.fractionCompleted,
                        downloadedBytes: progress.completedUnitCount,
                        totalBytes: progress.totalUnitCount,
                        state: .downloading
                    )
                }
            }
            
            // Start download
            task.resume()
            
            // Clean up when task completes
            Task {
                while task.state == .running || task.state == .suspended {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                }
                observation.invalidate()
            }
        }
    }
    
    private func outputURL(for episode: Episode, in directory: URL) -> URL {
        let dateString = outputDateFormatter.string(from: episode.date)
        let encodedTitle = episode.title.replacingOccurrences(of: "/", with: ":")
        let filename = "\(dateString)_\(encodedTitle).\(episode.fileExtension)"
        return directory.appendingPathComponent(filename)
    }
}

actor AsyncSemaphore {
    private var count: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []
    
    init(value: Int) {
        self.count = value
    }
    
    func waitForSignal() async {
        if count > 0 {
            count -= 1
        } else {
            await withCheckedContinuation { continuation in
                waiters.append(continuation)
            }
        }
    }
    
    func signal() async {
        if waiters.isEmpty {
            count += 1
        } else {
            let waiter = waiters.removeFirst()
            waiter.resume()
        }
    }
}