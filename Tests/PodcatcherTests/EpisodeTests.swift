import XCTest
@testable import Podcatcher

final class EpisodeTests: XCTestCase {
    
    func testEpisodeInitialization() {
        let url = URL(string: "https://example.com/episode.mp3")!
        let date = Date()
        
        let episode = Episode(
            title: "Test Episode",
            url: url,
            date: date,
            fileExtension: "mp3"
        )
        
        XCTAssertEqual(episode.title, "Test Episode")
        XCTAssertEqual(episode.url, url)
        XCTAssertEqual(episode.date, date)
        XCTAssertEqual(episode.fileExtension, "mp3")
    }
    
    func testEpisodeInitializationWithEmptyFileExtension() {
        let url = URL(string: "https://example.com/episode")!
        let date = Date()
        
        let episode = Episode(
            title: "Test Episode",
            url: url,
            date: date,
            fileExtension: ""
        )
        
        XCTAssertEqual(episode.fileExtension, "mp3") // Should default to mp3
    }
    
    func testEpisodeEquality() {
        let url = URL(string: "https://example.com/episode.mp3")!
        let date = Date()
        
        let episode1 = Episode(
            title: "Test Episode",
            url: url,
            date: date,
            fileExtension: "mp3"
        )
        
        let episode2 = Episode(
            title: "Test Episode",
            url: url,
            date: date,
            fileExtension: "mp3"
        )
        
        // Episodes should be equal based on content, not ID
        XCTAssertEqual(episode1.title, episode2.title)
        XCTAssertEqual(episode1.url, episode2.url)
        XCTAssertEqual(episode1.date, episode2.date)
        XCTAssertEqual(episode1.fileExtension, episode2.fileExtension)
        XCTAssertNotEqual(episode1.id, episode2.id) // IDs should be different
    }
    
    func testEpisodeDescription() {
        let url = URL(string: "https://example.com/episode.mp3")!
        let date = Date(timeIntervalSince1970: 1609459200) // Jan 1, 2021
        
        let episode = Episode(
            title: "Test Episode",
            url: url,
            date: date,
            fileExtension: "mp3"
        )
        
        let description = episode.description
        XCTAssertTrue(description.contains("Test Episode"))
        // Just check that date formatting works, don't rely on specific locale
        XCTAssertTrue(description.contains(" - "))
    }
}