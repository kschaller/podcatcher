//
//  Episode.swift
//  Podcatcher
//
//  Created by Kai Schaller on 6/17/18.
//  Copyright © 2018 Kai Schaller. All rights reserved.
//

import Foundation

struct Episode: Sendable {
    let title: String
    let url: URL
    let date: Date
    let fileExtension: String
}
