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
    
    init?(url: URL) {
        if let parser = XMLParser(contentsOf: url) {
            self.parser = parser
        } else {
            return nil
        }
    }
    
}

extension Parser: XMLParserDelegate {
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        // All done parsing the XML, so pass back the data via the delegate.
        delegate?.finishedParsing(episodes: episodes)
    }
    
}
