import Foundation

actor Podcatcher {
    private let maxConcurrentDownloads: Int
    private let outputDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    init(maxConcurrentDownloads: Int = 3) {
        self.maxConcurrentDownloads = maxConcurrentDownloads
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
            let downloadedCount = await downloadEpisodes(
                toDownload,
                to: outputDirectory
            )
            
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
        
        do {
            print("Downloading: \(episode.title)")
            
            let (tempURL, _) = try await URLSession.shared.download(from: episode.url)
            
            try FileManager.default.createDirectory(
                at: outputDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
            
            if FileManager.default.fileExists(atPath: outputURL.path) {
                try FileManager.default.removeItem(at: outputURL)
            }
            
            try FileManager.default.moveItem(at: tempURL, to: outputURL)
            
            print("✓ Downloaded: \(outputURL.lastPathComponent)")
            return true
            
        } catch {
            print("✗ Failed to download \(episode.title): \(error.localizedDescription)")
            return false
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