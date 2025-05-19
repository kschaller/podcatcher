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
    
    private enum DownloadResult: Sendable {
        case downloaded
        case skipped
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
        
        // Filter out any episodes we need to skip.
        let (episodesToDownload, skippedCount) = episodes.reduce(into: ([Episode](), 0)) { result, episode in
            let exists = fileExists(self.outputURL(for: episode, outputDir: outputDir))
            if episode.date > since && exists == false {
                // Add it to the array of episodes we want to download.
                result.0.append(episode)
            } else {
                // Tally a skip.
                result.1 += 1
            }
        }
        
        let progressRenderer = ProgressRenderer()
        
        await withTaskGroup(of: DownloadResult.self) { group in
            let maxDownloads: Int = min(concurrentDownloads, episodesToDownload.count)
            
            for i in 0..<maxDownloads {
                let episode = episodesToDownload[i]
                let lineIndex = await progressRenderer.registerLine(title: episode.title)
                group.addTask { @Sendable in
                    await self.downloadEpisode(episode, outputDir: outputDir, since: since) { percent in
                        Task {
                            await progressRenderer.updateLine(index: lineIndex, percent: percent)
                        }
                    }
                }
            }
            
            var nextIndex = maxDownloads
            for await result in group {
                if nextIndex < episodesToDownload.count {
                    let episode = episodesToDownload[nextIndex]
                    let lineIndex = await progressRenderer.registerLine(title: episode.title)
                    group.addTask { @Sendable in
                        await self.downloadEpisode(episode, outputDir: outputDir, since: since) { percent in
                            Task {
                                await progressRenderer.updateLine(index: lineIndex, percent: percent)
                            }
                        }
                    }
                    nextIndex += 1
                }
                
                switch result {
                case .downloaded:
                    downloadedCount += 1
                case .skipped:
                    break // can probably remove this entirely now
                case .failed(let errorString):
                    errorCount += 1
                    print("Error: \(errorString)")
                }
            }
        }
        
        consoleIO.writeMessage("Done! Downloaded \(downloadedCount) new episodes and skipped \(skippedCount).")
    }
    
    private func downloadEpisode(_ episode: Episode, outputDir: URL, since: Date, onProgress: @escaping ProgressClosure = {_ in }) async -> DownloadResult {
        // Skip if the episode is too old.
        guard episode.date > since else {
            return .skipped
        }

        let outputURL = self.outputURL(for: episode, outputDir: outputDir)
        
        // Skip if the episode was already downloaded.
        guard fileExists(outputURL) == false else {
            return .skipped
        }
        
        // Stream the download so we can report progress.
        do {
            let (byteStream, response) = try await URLSession.shared.bytes(from: episode.url)
            if response.expectedContentLength > 0 {
                FileManager.default.createFile(atPath: outputURL.path, contents: nil)
                guard let stream = OutputStream(url: outputURL, append: true) else {
                    consoleIO.writeMessage("Failed to open output stream for \(outputURL)")
                    return .failed("Failed to open output stream")
                }
                stream.open()
                defer { stream.close() }
                
                var bytesReceived: Int64 = 0
                
                var writeBuffer = Data()
                let bufferThreshold = 64 * 1024 // 64 KB
                
                for try await byte in byteStream {
                    writeBuffer.append(byte)
                    
                    // Flush the buffer once we hit the threshold.
                    if writeBuffer.count >= bufferThreshold {
                        let written = writeBuffer.withUnsafeBytes { ptr in
                            stream.write(ptr.baseAddress!, maxLength: writeBuffer.count)
                        }
                        bytesReceived += Int64(written)
                        writeBuffer.removeAll(keepingCapacity: true)
                        
                        onProgress(Double(bytesReceived) / Double(response.expectedContentLength))
                    }
                }
                
                // Flush any remainder.
                if writeBuffer.isEmpty == false {
                    let written = writeBuffer.withUnsafeBytes { ptr in
                        stream.write(ptr.baseAddress!, maxLength: writeBuffer.count)
                    }
                    bytesReceived += Int64(written)
                    onProgress(1.0)
                }
            } else {
                // Server didn't give an expected length, so use a non-reporting download.
                let (tempURL, _) = try await URLSession.shared.download(from: episode.url)
                try FileManager.default.copyItem(at: tempURL, to: outputURL)
                onProgress(1.0)
            }
            return .downloaded
        } catch {
            consoleIO.writeMessage("\(episode.title): \(error.localizedDescription)")
            return .failed(error.localizedDescription)
        }
    }
    
    private func fileExists(_ url: URL) -> Bool {
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    private func outputURL(for episode: Episode, outputDir: URL) -> URL {
        let filename = outputFilename(for: episode)
        return outputDir.appendingPathComponent(filename)
    }
    
    private func outputFilename(for episode: Episode) -> String {
        let dateString = outputDateFormatter.string(from: episode.date)
        // https://stackoverflow.com/questions/36064907/swift-using-slash-in-filename-with-createdirectoryatpath
        let encodedTitle = episode.title.replacingOccurrences(of: "/", with: ":")
        return "\(dateString)_\(encodedTitle).\(episode.fileExtension)"
    }
    
}
