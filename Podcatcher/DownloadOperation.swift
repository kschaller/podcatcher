//
//  DownloadOperation.swift
//  Podcatcher
//
//  Created by Kai Schaller on 5/25/18.
//  Copyright © 2018 Kai Schaller. All rights reserved.
//

import Foundation
import ObjectiveC

protocol DownloadDelegate: AnyObject {
    func didFinishDownloading(episode: Episode, temporaryURL: URL)
}

// Progress reporter protocol for download progress
protocol DownloadProgressReporter: AnyObject {
    func reportProgress(for episode: Episode, bytesReceived: Int64, totalBytes: Int64) async
    func downloadStarted(episode: Episode) async
    func downloadFinished(episode: Episode) async
}

// Using actor for thread safety with shared mutable state
actor DownloadManager {
    private(set) var downloadCount: (new: Int, skipped: Int) = (0, 0)
    weak var delegate: DownloadDelegate?
    private weak var progressReporter: DownloadProgressReporter?
    
    func setProgressReporter(_ reporter: DownloadProgressReporter) {
        self.progressReporter = reporter
    }
    
    func incrementNewCount() {
        downloadCount.new += 1
    }
    
    func incrementSkippedCount() {
        downloadCount.skipped += 1
    }
    
    func download(episode: Episode) async throws -> URL {
        // Report download started
        await progressReporter?.downloadStarted(episode: episode)
        
        // Use URLSession with delegate for progress reporting
        return try await withCheckedThrowingContinuation { continuation in
            let task = URLSession.shared.downloadTask(with: episode.url) { (fileURL, response, error) in
                // Report download finished regardless of success/failure
                Task {
                    await self.progressReporter?.downloadFinished(episode: episode)
                    
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let fileURL = fileURL else {
                        continuation.resume(throwing: NSError(domain: "DownloadManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Download failed with no error"]))
                        return
                    }
                    
                    continuation.resume(returning: fileURL)
                }
            }
            
            // Add progress observation
            task.addProgressObserver(forEpisode: episode, manager: self)
            
            // Start the download
            task.resume()
        }
    }
}

// Extension to add progress observation to URLSessionDownloadTask
extension URLSessionDownloadTask {
    func addProgressObserver(forEpisode episode: Episode, manager: DownloadManager) {
        let observation = self.progress.observe(\.fractionCompleted) { progress, _ in
            // Report progress on main thread
            Task {
                await manager.reportProgress(forEpisode: episode, progress: progress)
            }
        }
        
        // Store observation in associated object to keep it alive
        objc_setAssociatedObject(self, "progressObservation", observation, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

// Extension for progress reporting
extension DownloadManager {
    func reportProgress(forEpisode episode: Episode, progress: Progress) async {
        let bytesReceived = progress.completedUnitCount
        let totalBytes = progress.totalUnitCount
        await progressReporter?.reportProgress(for: episode, bytesReceived: bytesReceived, totalBytes: totalBytes)
    }
}
