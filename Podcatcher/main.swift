//
//  main.swift
//  Podcatcher
//
//  Created by Kai Schaller on 5/25/18.
//  Copyright © 2018 Kai Schaller. All rights reserved.
//

import Foundation

// Run the podcatcher with Swift concurrency
Task {
    let podcatcher = Podcatcher()
    await podcatcher.staticMode()
}

// Keep the main thread alive until all tasks complete
RunLoop.main.run(until: Date(timeIntervalSinceNow: 60 * 60)) // 1 hour timeout
