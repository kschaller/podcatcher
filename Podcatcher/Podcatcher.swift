//
//  Podcatcher.swift
//  Podcatcher
//
//  Created by Kai Schaller on 6/17/18.
//  Copyright © 2018 Kai Schaller. All rights reserved.
//

import Foundation

actor Podcatcher {
    
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
        
        // Use the new async parse method
        let episodes = await parser.parseAsync()
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
        
        // Use Swift concurrency with TaskGroup for parallel downloads
        await withTaskGroup(of: Void.self) { group in
            for episode in episodes {
                guard let destinationURL = outputURL(for: episode) else {
                    continue
                }
                
                if !fileManager.fileExists(atPath: destinationURL.path) && notBeforeDate < episode.date {
                    // Add each download as a child task
                    group.addTask {
                        await self.downloadAndSaveEpisode(episode, to: destinationURL)
                    }
                } else {
                    // Count skipped episodes
                    Task {
                        await self.downloadManager.incrementSkippedCount()
                    }
                }
            }
            
            // Wait for all child tasks to complete
            await group.waitForAll()
        }
        
        // Report final counts
        let counts = await downloadManager.downloadCount
        consoleIO.writeMessage("Done! Downloaded \(counts.new) new episodes and skipped \(counts.skipped).")
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
}
