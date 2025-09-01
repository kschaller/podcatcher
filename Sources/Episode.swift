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
    
    func outputFilename() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let dateString = dateFormatter.string(from: date)
        // https://stackoverflow.com/questions/36064907/swift-using-slash-in-filename-with-createdirectoryatpath
        let encodedTitle = title.replacingOccurrences(of: "/", with: ":")
        return "\(dateString)_\(encodedTitle).\(fileExtension)"
    }

}
