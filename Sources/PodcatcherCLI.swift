//
//  main.swift
//  Podcatcher
//
//  Created by Kai Schaller on 5/25/18.
//  Copyright © 2018 Kai Schaller. All rights reserved.
//

import Foundation
import ArgumentParser

@main
struct PodcatcherCLI: AsyncParsableCommand {
    
    static let configuration = CommandConfiguration(
        commandName: "podcatcher",
        abstract: "A command-line tool for archiving podcast episodes."
    )
    
    @Option(name: .shortAndLong, help: "Feed URL to fetch.")
    var feedURL: String
    
    @Option(name: .shortAndLong, help: "Output directory for downloaded files.")
    var outputDir: String
    
    @Option(name: .shortAndLong, help: "Only download episodes since this date (yyyy-MM-dd).")
    var since: String?
    
    func run() async throws {
        // Validate the feed URL.
        guard let url = URL(string: feedURL) else {
            throw ValidationError("Invalid feed URL: \(feedURL)")
        }
        
        // Parse optional "since" date.
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let sinceDate = since.flatMap { formatter.date(from: $0) } ?? .distantPast

        let outputURL = URL(filePath: outputDir)
        
        let podcatcher = Podcatcher()
        try await podcatcher.run(feedURL: url, outputDir: outputURL, since: sinceDate)
    }
    
}
