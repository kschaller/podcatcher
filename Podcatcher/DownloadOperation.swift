//
//  DownloadOperation.swift
//  Podcatcher
//
//  Created by Kai Schaller on 5/25/18.
//  Copyright © 2018 Kai Schaller. All rights reserved.
//

import Foundation

protocol DownloadDelegate: AnyObject {
    func didFinishDownloading(episode: Episode, temporaryURL: URL)
}

// Using actor for thread safety with shared mutable state
actor DownloadManager {
    private(set) var downloadCount: (new: Int, skipped: Int) = (0, 0)
    weak var delegate: DownloadDelegate?
    
    func incrementNewCount() {
        downloadCount.new += 1
    }
    
    func incrementSkippedCount() {
        downloadCount.skipped += 1
    }
    
    func download(episode: Episode) async throws -> URL {
        print(episode.url)
        return try await URLSession.shared.download(from: episode.url).0
    }
}
