import XCTest
@testable import Podcatcher

final class PodcatcherTests: XCTestCase {

    func testRunWithEmptyFeedCreatesNoFiles() async throws {
        // Create a temporary directory.
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // Write a minimal feed with no items.
        let feedURL = tempDir.appendingPathComponent("empty.xml")
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss>
          <channel></channel>
        </rss>
        """
        try xml.write(to: feedURL, atomically: true, encoding: .utf8)

        // Create output directory.
        let outputDir = tempDir.appendingPathComponent("out")
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        // Call `run`.
        let downloader = Downloader()
        try await downloader.run(feedURL: feedURL, outputDir: outputDir, concurrentDownloads: 3, since: .distantPast)

        // Verify no files were written.
        let files = try FileManager.default.contentsOfDirectory(atPath: outputDir.path)
        XCTAssertTrue(files.isEmpty, "Expected no files for an empty feed, but found \(files)")
    }

    func testRunThrowsOnInvalidFeed() async throws {
        // Nonexistent file URL.
        let invalidFeed = URL(fileURLWithPath: "/nonexistent/feed.xml")
        let outputDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        let downloader = Downloader()
        do {
            try await downloader.run(feedURL: invalidFeed, outputDir: outputDir, concurrentDownloads: 3, since: .distantPast)
            XCTFail("Expected run() to throw for invalid feed URL")
        } catch {
            // Success: an error should be thrown
        }
    }
}
