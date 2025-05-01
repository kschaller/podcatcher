//
//  DownloadOperation.swift
//  Podcatcher
//
//  Created by Kai Schaller on 5/25/18.
//  Copyright © 2018 Kai Schaller. All rights reserved.
//

import Foundation

protocol DownloadOperationDelegate: class {
    func didFinishDownloading(episode: Episode, temporaryURL: URL)
}

class DownloadOperation: AsynchronousOperation {

    weak var delegate: DownloadOperationDelegate?
    
    private let episode: Episode
    private let semaphore = DispatchSemaphore(value: 0)
    
    init(episode: Episode) {
        self.episode = episode
    }
    
    override func main() {
        super.main()
        
        print(episode.url)
        let task = URLSession.shared.downloadTask(with: episode.url) { (fileURL, response, error) in
            guard let fileURL = fileURL else { return }
            self.delegate?.didFinishDownloading(episode: self.episode, temporaryURL: fileURL)
            self.semaphore.signal()
            self.state = .finished
        }
        task.resume()
        semaphore.wait()
    }
    
}
