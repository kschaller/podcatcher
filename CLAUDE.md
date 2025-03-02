# Podcatcher - Claude Helper Guide

## Build Commands
- Build & Run: Use Xcode's run button or `swift build && swift run`
- Command usage: `Podcatcher [feed url] [output path] [optional: not-before-date]`

## Code Style
- Classes/Protocols: PascalCase (AsynchronousOperation, ParserDelegate)
- Variables/Methods: camelCase (staticMode, finishedParsing)
- Indentation: 4 spaces
- Whitespace: Blank line between methods
- Comments above class/method definitions

## Error Handling
- Console errors via ConsoleIO class
- Try-catch for file operations
- Guard statements and if-let for optionals
- Delegate pattern for async operations

## Architecture
- Command-line tool using operation queue for concurrent downloads
- Delegate pattern for component communication
- XML parsing for podcast feeds
- Structured around Episode model and Parser/DownloadOperation classes