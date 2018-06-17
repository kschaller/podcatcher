//
//  ConsoleIO.swift
//  Podcatcher
//
//  Created by Kai Schaller on 6/17/18.
//  Copyright © 2018 Kai Schaller. All rights reserved.
//

import Foundation

enum OutputType {
    case error
    case standard
}

class ConsoleIO {
    
    func printUsage() {
        let name = (CommandLine.arguments.first! as NSString).lastPathComponent
        writeMessage("usage:")
        writeMessage("\(name) [feed url] [output path]")
    }
    
    func writeMessage(_ message: String, to: OutputType = .standard) {
        switch to {
        case .standard:
            print(message)
        case .error:
            fputs("Error: \(message)\n", stderr)
        }
    }
    
}
