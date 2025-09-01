import XCTest
@testable import Podcatcher

final class ParserTests: XCTestCase {
    
    func testParseEpisodesFromMockData() async throws {
        let mockRSSContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
            <channel>
                <title>Test Podcast</title>
                <description>A test podcast</description>
                <item>
                    <title>Episode 1</title>
                    <pubDate>Wed, 01 Jan 2021 12:00:00 +0000</pubDate>
                    <enclosure url="https://example.com/episode1.mp3" type="audio/mpeg" length="12345"/>
                </item>
                <item>
                    <title>Episode 2</title>
                    <pubDate>Thu, 02 Jan 2021 12:00:00 +0000</pubDate>
                    <enclosure url="https://example.com/episode2.mp3" type="audio/mpeg" length="23456"/>
                </item>
            </channel>
        </rss>
        """
        
        // Create a temporary file with mock RSS content
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("xml")
        
        try mockRSSContent.write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        let parser = Parser()
        let episodes = try await parser.parseEpisodes(from: tempURL)
        
        XCTAssertEqual(episodes.count, 2)
        
        let episode1 = episodes[0]
        XCTAssertEqual(episode1.title, "Episode 1")
        XCTAssertEqual(episode1.url.absoluteString, "https://example.com/episode1.mp3")
        XCTAssertEqual(episode1.fileExtension, "mp3")
        
        let episode2 = episodes[1]
        XCTAssertEqual(episode2.title, "Episode 2")
        XCTAssertEqual(episode2.url.absoluteString, "https://example.com/episode2.mp3")
        XCTAssertEqual(episode2.fileExtension, "mp3")
    }
    
    func testParseEpisodesWithInvalidXML() async {
        let invalidRSSContent = "This is not valid XML"
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("xml")
        
        do {
            try invalidRSSContent.write(to: tempURL, atomically: true, encoding: .utf8)
            defer { try? FileManager.default.removeItem(at: tempURL) }
            
            let parser = Parser()
            _ = try await parser.parseEpisodes(from: tempURL)
            
            XCTFail("Expected parsing to fail with invalid XML")
        } catch {
            // Expected to throw an error
            XCTAssertTrue(error is ParserError)
        }
    }
    
    func testParseEpisodesWithMissingFields() async throws {
        let incompleteRSSContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
            <channel>
                <title>Test Podcast</title>
                <item>
                    <title>Complete Episode</title>
                    <pubDate>Wed, 01 Jan 2021 12:00:00 +0000</pubDate>
                    <enclosure url="https://example.com/episode1.mp3" type="audio/mpeg" length="12345"/>
                </item>
                <item>
                    <title>Incomplete Episode</title>
                    <!-- Missing pubDate and enclosure -->
                </item>
            </channel>
        </rss>
        """
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("xml")
        
        try incompleteRSSContent.write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        let parser = Parser()
        let episodes = try await parser.parseEpisodes(from: tempURL)
        
        // Should only parse the complete episode
        XCTAssertEqual(episodes.count, 1)
        XCTAssertEqual(episodes[0].title, "Complete Episode")
    }
}