//
//  Parser.swift
//  Podcatcher
//
//  Created by Kai Schaller on 6/17/18.
//  Copyright © 2018 Kai Schaller. All rights reserved.
//

import Foundation

protocol ParserProtocol {
    init(url: URL)
    func parse() async throws -> [Episode]
}

enum ParserError: Error {
    case failedToParse
}

class Parser: ParserProtocol {
    
    private let feedURL: URL

    required init(url: URL) {
        self.feedURL = url
    }
    
    func parse() async throws -> [Episode] {
        let data = try Data(contentsOf: feedURL)
        
        let xmlParser = XMLParser(data: data)
        let collector = EpisodeCollector()
        xmlParser.delegate = collector
        
        guard xmlParser.parse() else {
            if let error = xmlParser.parserError {
                throw error
            }
            throw ParserError.failedToParse
        }
        
        return collector.episodes
    }
    
}

private class EpisodeCollector: NSObject, XMLParserDelegate {

    private(set) var episodes: [Episode] = []
    private var currentElement: Element?
    private var foundCharacters: String = ""

    private var currentTitle: String?
    private var currentURL: URL?
    private var currentDate: Date?

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return formatter
    }()

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        guard let element = Element(rawValue: elementName) else {
            currentElement = nil
            return
        }
        
        currentElement = element
        
        switch element {
        case .item:
            // Reset state.
            currentTitle = nil
            currentURL = nil
            currentDate = nil
        case .enclosure:
            if let urlString = attributeDict["url"], let url = URL(string: urlString) {
                currentURL = url
            }
        default:
            break
        }
        
        foundCharacters = ""
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        foundCharacters += string.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        guard let element = Element(rawValue: elementName) else {
            currentElement = nil
            return
        }
        
        switch element {
        case .title:
            currentTitle = foundCharacters
        case .date:
            currentDate = dateFormatter.date(from: foundCharacters)
        case .item:
            // We've reached the end of an episode, so if we have all of the
            // data we need, initialize the struct and append it to the episode
            // array.
            if let title = currentTitle, let url = currentURL, let date = currentDate {
                let episode = Episode(title: title, url: url, date: date, fileExtension: url.pathExtension)
                episodes.append(episode)
            }
        default:
            break
        }
        
        foundCharacters = ""
        currentElement = nil
    }
    
}
