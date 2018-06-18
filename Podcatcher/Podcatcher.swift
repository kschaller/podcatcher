//
//  Podcatcher.swift
//  Podcatcher
//
//  Created by Kai Schaller on 6/17/18.
//  Copyright © 2018 Kai Schaller. All rights reserved.
//

import Foundation

class Podcatcher {
    
    private let consoleIO = ConsoleIO()
    private let downloadQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .utility
        queue.maxConcurrentOperationCount = 3
        return queue
    }()
    private let outputDateFormatter: DateFormatter = {
       let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private var parser: Parser?
    private var outputURL: URL?
    private var downloadCount: (new: Int, skipped: Int) = (0, 0)

    func staticMode() {
//        consoleIO.printUsage()
        guard let url = URL(string: CommandLine.arguments[1]) else {
            consoleIO.writeMessage("Unable to read URL", to: .error)
            return
        }
        
        outputURL = URL(fileURLWithPath: CommandLine.arguments[2]) // TODO: Add some checking so we don't get OOB error
        
        parser = Parser(url: url)
        parser?.delegate = self
        parser?.parse()
    }
    
    fileprivate func outputURL(for episode: Episode) -> URL? {
        let dateString = outputDateFormatter.string(from: episode.date)
        // https://stackoverflow.com/questions/36064907/swift-using-slash-in-filename-with-createdirectoryatpath
        let encodedTitle = episode.title.replacingOccurrences(of: "/", with: ":")
        let filename = "\(dateString)_\(encodedTitle).\(episode.fileExtension)"
        return outputURL?.appendingPathComponent(filename)
    }
    
}

extension Podcatcher: ParserDelegate {
    
    func finishedParsing(episodes: [Episode]) {
        // Load the episodes into a download queue.
        for episode in episodes {
            guard let outputURL = outputURL(for: episode) else {
                continue
            }
            
            if FileManager.default.fileExists(atPath: outputURL.path) == false {
                let operation = DownloadOperation(episode: episode)
                operation.delegate = self
                downloadQueue.addOperation(operation)
            } else {
                downloadCount.skipped += 1
            }
        }
        downloadQueue.waitUntilAllOperationsAreFinished()
        consoleIO.writeMessage("Done! Downloaded \(downloadCount.new) new episodes and skipped \(downloadCount.skipped) that had already been saved.")
    }
    
}

extension Podcatcher: DownloadOperationDelegate {
    
    func didFinishDownloading(episode: Episode, temporaryURL: URL) {
        guard let outputFileURL = outputURL(for: episode) else { return }

        do {
            try FileManager.default.copyItem(at: temporaryURL, to: outputFileURL)
            downloadCount.new += 1
        } catch(let error) {
            print("Error writing to \(outputFileURL.absoluteString): \(error.localizedDescription)")
        }
    }
    
}
