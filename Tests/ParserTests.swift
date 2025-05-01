//
//  ParserTests.swift
//  Podcatcher
//
//  Created by Kai Schaller on 4/30/25.
//

import XCTest
@testable import Podcatcher

final class ParserTests: XCTestCase {

    func testParseSingleEpisode() async throws {
        // A minimal RSS feed with one episode
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss>
          <channel>
            <item>
              <title>Test Episode</title>
              <enclosure url="https://example.com/test.mp3" length="12345" type="audio/mpeg"/>
              <pubDate>Wed, 29 Apr 2025 12:34:56 GMT</pubDate>
            </item>
          </channel>
        </rss>
        """
        
        // Write the XML to a temporary file.
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("testfeed.xml")
        try xml.write(to: tempURL, atomically: true, encoding: .utf8)
        
        // Parse the XML.
        let parser = Parser(url: tempURL)
        let episodes = try await parser.parse()
        
        // Verify the episode parsed correctly.
        XCTAssertEqual(episodes.count, 1)
        let episode = episodes[0]
        XCTAssertEqual(episode.title, "Test Episode")
        XCTAssertEqual(episode.url.absoluteString, "https://example.com/test.mp3")
        
        // Verify the date parsing.
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        let expectedDate = formatter.date(from: "Wed, 29 Apr 2025 12:34:56 GMT")
        XCTAssertEqual(episode.date, expectedDate)
    }
    
}
