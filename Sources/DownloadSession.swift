//
//  DownloadSession.swift
//  Podcatcher
//
//  Created by Kai Schaller on 5/18/25.
//

import Foundation

protocol DownloadSessionProtocol {
    func download(_ episode: Episode) async -> Downloader.DownloadResult
}

final class DownloadSession: NSObject, DownloadSessionProtocol, URLSessionDownloadDelegate, @unchecked Sendable {
    
    let renderer: ProgressRenderer
    let outputDir: URL
    
    var state = [Int: (episode: Episode, lineIndex: Int, continuation: CheckedContinuation<Downloader.DownloadResult, Never>)]()
    
    lazy var session: URLSession = {
        URLSession(configuration: .default, delegate: self, delegateQueue: delegateQueue)
    }()
    
    private lazy var delegateQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.kaischaller.podcatcher.download-session"
        queue.maxConcurrentOperationCount = 3
        return queue
    }()
    
    init(renderer: ProgressRenderer, outputDir: URL) {
        self.renderer = renderer
        self.outputDir = outputDir
    }
    
    func download(_ episode: Episode) async -> Downloader.DownloadResult {
        let lineIndex = await renderer.registerLine(title: episode.title)
        return await withCheckedContinuation { continuation in
            let task = session.downloadTask(with: episode.url)
            state[task.taskIdentifier] = (episode, lineIndex, continuation)
            print("BEGIN -- \(episode.title)")
            task.resume()
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let (_, lineIndex, _) = state[downloadTask.taskIdentifier], totalBytesExpectedToWrite > 0 else { return }
        let percent = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        Task {
            await renderer.updateLine(index: lineIndex, percent: percent)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let (episode, lineIndex, continuation) = state.removeValue(forKey: downloadTask.taskIdentifier) else { return }
        print("DONE -- \(episode.title)")

        let outputURL = outputDir.appendingPathComponent(episode.outputFilename())
        try? FileManager.default.moveItem(at: location, to: outputURL)
        
        Task {
            await renderer.updateLine(index: lineIndex, percent: 1.0)
        }
        
        continuation.resume(returning: .downloaded)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        guard let (episode, lineIndex, continuation) = state.removeValue(forKey: task.taskIdentifier) else { return }
        print("ERROR -- \(episode.title)")
        
        let message = error?.localizedDescription ?? "Unknown error"
        ConsoleIO().writeMessage("Error downloading \(episode.title): \(message)")
        Task {
            await renderer.updateLine(index: lineIndex, percent: 1.0)
        }
        continuation.resume(returning: .failed(message))
    }
        
}
