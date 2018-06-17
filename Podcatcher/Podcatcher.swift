//
//  Podcatcher.swift
//  Podcatcher
//
//  Created by Kai Schaller on 6/17/18.
//  Copyright © 2018 Kai Schaller. All rights reserved.
//

import Foundation

class Podcatcher {
    
    let consoleIO = ConsoleIO()
    var parser: Parser?
    
    func staticMode() {
//        consoleIO.printUsage()
        guard let url = URL(string: CommandLine.arguments[1]) else {
            consoleIO.writeMessage("Unable to read URL", to: .error)
            return
        }
        parser = Parser(url: url)
        parser?.delegate = self
        parser?.parse()
    }
    
}

extension Podcatcher: ParserDelegate {
    
    func finishedParsing(episodes: [Episode]) {
        // Load the episodes into a download queue.
    }
    
}
