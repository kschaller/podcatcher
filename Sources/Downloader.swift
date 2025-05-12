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
    private let outputDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private enum DownloadResult {
        case downloaded
        case skipped
        case failed(Error)
    }
    
    func run(feedURL: URL, outputDir: URL, concurrentDownloads: Int, since: Date) async throws {
        let parser = Parser(url: feedURL)
        let episodes = try await parser.parse()
        await downloadEpisodes(episodes, outputDir: outputDir, concurrentDownloads: concurrentDownloads, since: since)
    }
    
    private func downloadEpisodes(_ episodes: [Episode], outputDir: URL, concurrentDownloads: Int, since: Date) async {
        var downloadedCount: Int = 0
        var skippedCount: Int = 0
        var errorCount: Int = 0
        
        await withTaskGroup(of: DownloadResult.self) { group in
            for episode in episodes {
                group.addTask {
                    await self.downloadEpisode(episode, outputDir: outputDir, since: since)
                }
            }
            
            for await result in group {
                switch result {
                case .downloaded:
                    downloadedCount += 1
                case .skipped:
                    skippedCount += 1
                case .failed(let error):
                    errorCount += 1
                    print("Error: \(error)")
                }
            }
        }
        
        consoleIO.writeMessage("Done! Downloaded \(downloadedCount) new episodes and skipped \(skippedCount).")
    }
    
    private func downloadEpisode(_ episode: Episode, outputDir: URL, since: Date) async -> DownloadResult {
        guard episode.date > since else {
            return .skipped
        }

        let outputURL = self.outputURL(for: episode, outputDir: outputDir)
        
        guard fileExists(outputURL) == false else {
            return .skipped
        }
        
        do {
            let (tempURL, _) = try await URLSession.shared.download(from: episode.url)
            try FileManager.default.copyItem(at: tempURL, to: outputURL)
            return .downloaded
        } catch {
            return .failed(error)
        }
    }
    
    private func fileExists(_ url: URL) -> Bool {
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    private func outputURL(for episode: Episode, outputDir: URL) -> URL {
        let dateString = outputDateFormatter.string(from: episode.date)
        // https://stackoverflow.com/questions/36064907/swift-using-slash-in-filename-with-createdirectoryatpath
        let encodedTitle = episode.title.replacingOccurrences(of: "/", with: ":")
        let filename = "\(dateString)_\(encodedTitle).\(episode.fileExtension)"
        return outputDir.appendingPathComponent(filename)
    }
    
}
