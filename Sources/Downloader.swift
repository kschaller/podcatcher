//
//  Downloader.swift
//  Podcatcher
//
//  Created by Kai Schaller on 6/17/18.
//  Copyright © 2018 Kai Schaller. All rights reserved.
//

import Foundation

actor Downloader {

    internal var feedURL: URL?
    internal var outputURL: URL?
    internal var notBeforeDate: Date?

    private let consoleIO = ConsoleIO()
    private let outputDateFormatter: DateFormatter = {
       let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private actor DownloadManager {
        private(set) var newCount = 0
        private(set) var skippedCount = 0
        
        func incrementNew() {
            newCount += 1
        }
        
        func incrementSkipped() {
            skippedCount += 1
        }
        
        func counts() -> (new: Int, skipped: Int) {
            return (newCount, skippedCount)
        }
    }
    
    private let downloadManager = DownloadManager()

    func run(feedURL: URL, outputDir: URL, since: Date) async throws {
        self.outputURL = outputDir
        self.notBeforeDate = since
        
        let parser = Parser(url: feedURL)
        let episodes = try await parser.parse()
        
        await downloadEpisodes(episodes)
    }
    
    private func downloadEpisodes(_ episodes: [Episode]) async {
        let notBefore = notBeforeDate ?? .distantPast
        
        await withTaskGroup { group in
            for episode in episodes {
                group.addTask { [weak self] in
                    guard episode.date > notBefore, let outputURL = await self?.outputURL(for: episode) else {
                        await self?.downloadManager.incrementSkipped()
                        return
                    }
                    
                    do {
                        let (localURL, _) = try await URLSession.shared.download(from: episode.url)
                        try FileManager.default.copyItem(at: localURL, to: outputURL)
                        await self?.downloadManager.incrementNew()
                    } catch {
                        await self?.downloadManager.incrementSkipped()
                    }
                }
            }
        }
        
        let counts = await downloadManager.counts()
        consoleIO.writeMessage("Done! Downloaded \(counts.new) new episodes and skipped \(counts.skipped).")
    }
    
    fileprivate func outputURL(for episode: Episode) -> URL? {
        let dateString = outputDateFormatter.string(from: episode.date)
        // https://stackoverflow.com/questions/36064907/swift-using-slash-in-filename-with-createdirectoryatpath
        let encodedTitle = episode.title.replacingOccurrences(of: "/", with: ":")
        let filename = "\(dateString)_\(encodedTitle).\(episode.fileExtension)"
        return outputURL?.appendingPathComponent(filename)
    }
    
}
