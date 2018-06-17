//
//  Parser.swift
//  Podcatcher
//
//  Created by Kai Schaller on 6/17/18.
//  Copyright © 2018 Kai Schaller. All rights reserved.
//

import Foundation

protocol ParserDelegate: class {
    func finishedParsing(episodes: [Episode])
}

class Parser: NSObject {
    
    weak var delegate: ParserDelegate?
    
    private let parser: XMLParser
    private var episodes = [Episode]()
    private var currentTitle: String?
    private var currentURL: URL?
    private var foundCharacters: String?
    private var inItem: Bool = false
    
    init?(url: URL) {
        if let parser = XMLParser(contentsOf: url) {
            self.parser = parser
            super.init()
            self.parser.delegate = self
            self.parser.parse()
        } else {
            return nil
        }
    }
    
}

extension Parser: XMLParserDelegate {
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        guard let element = Element(rawValue: elementName) else { return }
        
        switch element {
        case .item:
            inItem = true
        case .title:
            break
        case .date:
            break
        case .enclosure:
            if let urlString = attributeDict["url"] {
                currentURL = URL(string: urlString)
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        var characters = foundCharacters ?? ""
        let sanitizedString = String(string.filter { "\n\t\r".contains($0) == false })
        characters += sanitizedString
        self.foundCharacters = characters
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if let element = Element(rawValue: elementName), inItem {
            switch element {
            case .item:
                // We've reached the end of an episode, so if we have all of the
                // data we need, initialize the struct and append it to the episode
                // array.
                if let title = currentTitle, let url = currentURL {
                    let episode = Episode(title: title, url: url)
                    episodes.append(episode)
                }
                
                // Reset the values for the next episode.
                currentTitle = nil
                currentURL = nil
                inItem = false
            case .title:
                currentTitle = foundCharacters
            case .date:
                break
            case .enclosure:
                break
            }
        }
        
        foundCharacters = nil
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        // All done parsing the XML, so pass back the data via the delegate.
        delegate?.finishedParsing(episodes: episodes)
    }
    
}
