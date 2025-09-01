//
//  Downloader.swift
//  Podcatcher
//
//  Created by Kai Schaller on 6/17/18.
//  Copyright © 2018 Kai Schaller. All rights reserved.
//

import Foundation

actor Downloader {
    
    private let consoleIO = ConsoleIO()
    
    enum DownloadResult: Sendable {
        case downloaded
        case failed(String)
    }
    
    private typealias ProgressClosure = @Sendable (Double) -> Void
    
    func run(feedURL: URL, outputDir: URL, concurrentDownloads: Int, since: Date) async throws {
        let parser = Parser(url: feedURL)
        let episodes = try await parser.parse()
        await downloadEpisodes(episodes, outputDir: outputDir, concurrentDownloads: concurrentDownloads, since: since)
    }
    
    private func downloadEpisodes(_ episodes: [Episode], outputDir: URL, concurrentDownloads: Int, since: Date) async {
        var downloadedCount: Int = 0
        var errorCount: Int = 0
        var skippedCount: Int = 0
        var episodesToDownload: [Episode] = []

        // Filter out any episodes we need to skip.
        for episode in episodes {
            let exists = fileExists(outputURL(for: episode, outputDir: outputDir))
            if episode.date > since && exists == false {
                episodesToDownload.append(episode)
            } else {
                skippedCount += 1
            }
        }
        
        let progressRenderer = ProgressRenderer()
        let downloadSession = DownloadSession(renderer: progressRenderer, outputDir: outputDir)
        
        await withTaskGroup(of: DownloadResult.self) { group in
            let maxDownloads: Int = min(concurrentDownloads, episodesToDownload.count)
            
            for i in 0..<maxDownloads {
                let episode = episodesToDownload[i]
                group.addTask { @Sendable in
                    await downloadSession.download(episode)
                }
            }
            
            var nextIndex = maxDownloads
            for await result in group {
                if nextIndex < episodesToDownload.count {
                    let episode = episodesToDownload[nextIndex]
                    group.addTask { @Sendable in
                        await downloadSession.download(episode)
                    }
                    nextIndex += 1
                }
                
                switch result {
                case .downloaded:
                    downloadedCount += 1
                case .failed(let errorString):
                    errorCount += 1
                    print("Error: \(errorString)")
                }
            }
        }
        
        consoleIO.writeMessage("Done! Downloaded \(downloadedCount) new episodes and skipped \(skippedCount).")
    }
    
    private func fileExists(_ url: URL) -> Bool {
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    func outputURL(for episode: Episode, outputDir: URL) -> URL {
        return outputDir.appendingPathComponent(episode.outputFilename())
    }
    
}
