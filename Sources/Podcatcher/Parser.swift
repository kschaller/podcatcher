import Foundation

enum ParserError: Error, LocalizedError {
    case invalidURL
    case parseFailure(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid RSS URL"
        case .parseFailure(let message):
            return "Failed to parse RSS feed: \(message)"
        }
    }
}

class Parser: NSObject {
    
    func parseEpisodes(from url: URL) async throws -> [Episode] {
        return try await withCheckedThrowingContinuation { continuation in
            parseEpisodesWithCompletion(from: url) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    private func parseEpisodesWithCompletion(from url: URL, completion: @escaping (Result<[Episode], Error>) -> Void) {
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                
                let parser = XMLParser(data: data)
                let delegate = ParserDelegate()
                parser.delegate = delegate
                
                if parser.parse() {
                    completion(.success(delegate.episodes))
                } else if let error = parser.parserError {
                    completion(.failure(ParserError.parseFailure(error.localizedDescription)))
                } else {
                    completion(.failure(ParserError.parseFailure("Unknown parsing error")))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
}

private class ParserDelegate: NSObject, XMLParserDelegate {
    var episodes = [Episode]()
    private var currentTitle: String?
    private var currentURL: URL?
    private var currentDate: Date?
    private var foundCharacters: String?
    private var inItem: Bool = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return formatter
    }()
    
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
        let sanitizedString = String(string.filter { !"\n\t\r".contains($0) })
        characters += sanitizedString
        self.foundCharacters = characters
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if let element = Element(rawValue: elementName), inItem {
            switch element {
            case .item:
                if let title = currentTitle, let url = currentURL, let date = currentDate {
                    let episode = Episode(title: title, url: url, date: date, fileExtension: url.pathExtension)
                    episodes.append(episode)
                }
                
                currentTitle = nil
                currentURL = nil
                currentDate = nil
                inItem = false
            case .title:
                currentTitle = foundCharacters?.trimmingCharacters(in: .whitespacesAndNewlines)
            case .date:
                if let foundCharacters = foundCharacters {
                    currentDate = dateFormatter.date(from: foundCharacters)
                }
            case .enclosure:
                break
            }
        }
        
        foundCharacters = nil
    }
}