import Foundation
import ArgumentParser

@main
struct PodcatcherCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "podcatcher",
        abstract: "A Swift command-line tool to download podcast episodes from RSS feeds."
    )
    
    @Argument(help: "The RSS feed URL of the podcast")
    var rssURL: String
    
    @Argument(help: "The output directory where episodes will be saved")
    var outputDirectory: String
    
    @Option(help: "Only download episodes published on or after this date (YYYY-MM-DD format)")
    var notBeforeDate: String?
    
    @Option(name: .shortAndLong, help: "Maximum number of concurrent downloads")
    var maxConcurrentDownloads: Int = 3
    
    func run() async throws {
        guard let url = URL(string: rssURL) else {
            throw ValidationError("Invalid RSS URL: \(rssURL)")
        }
        
        let outputURL = URL(fileURLWithPath: outputDirectory)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let notBefore: Date? = notBeforeDate.flatMap { dateFormatter.date(from: $0) }
        
        let podcatcher = Podcatcher(
            maxConcurrentDownloads: maxConcurrentDownloads
        )
        
        try await podcatcher.downloadPodcast(
            from: url,
            to: outputURL,
            notBeforeDate: notBefore
        )
    }
}