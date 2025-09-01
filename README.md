# Podcatcher

A modern Swift command-line tool to download podcast episodes from RSS feeds.

## Features

- ✨ **Modern Swift**: Built with Swift 5.9+ using async/await concurrency
- 🚀 **Fast Downloads**: Concurrent downloads with configurable limits
- 📱 **Smart Filtering**: Skip existing files and filter by publication date
- 🎯 **Robust Parsing**: Reliable RSS/XML parsing with error handling
- 🧪 **Well Tested**: Comprehensive unit test suite
- 💻 **Cross-platform**: Works on macOS 13+

## Installation

### Using Swift Package Manager

```bash
git clone https://github.com/your-username/podcatcher.git
cd podcatcher
swift build -c release
cp .build/release/podcatcher /usr/local/bin/
```

## Usage

```bash
podcatcher <rss-url> <output-directory> [options]
```

### Arguments

- `rss-url`: The RSS feed URL of the podcast
- `output-directory`: Directory where episodes will be saved

### Options

- `--not-before-date <date>`: Only download episodes published on or after this date (YYYY-MM-DD format)
- `-m, --max-concurrent-downloads <count>`: Maximum number of concurrent downloads (default: 3)
- `--show-progress`: Show ASCII progress bars for concurrent downloads
- `--help`: Show help information

### Examples

Download all episodes:
```bash
podcatcher "https://example.com/podcast/rss" ~/Downloads/Podcasts/
```

Download only recent episodes:
```bash
podcatcher "https://example.com/podcast/rss" ~/Downloads/Podcasts/ --not-before-date 2024-01-01
```

Download with custom concurrency:
```bash
podcatcher "https://example.com/podcast/rss" ~/Downloads/Podcasts/ -m 5
```

Download with progress bars:
```bash
podcatcher "https://example.com/podcast/rss" ~/Downloads/Podcasts/ --show-progress
```

## File Organization

Episodes are saved with the following naming convention:
```
YYYY-MM-DD_Episode Title.extension
```

For example: `2024-03-15_How to Build Great Software.mp3`

Note: Forward slashes in episode titles are replaced with colons to ensure valid filenames.

## Development

### Building

```bash
swift build
```

### Testing

```bash
swift test
```

### Requirements

- Swift 5.9+
- macOS 13+

## Architecture

- **PodcatcherCommand**: Command-line interface using ArgumentParser
- **Podcatcher**: Main coordinator using actor isolation for thread safety
- **Parser**: Async RSS/XML parsing
- **Episode**: Data model with modern Swift features
- **AsyncSemaphore**: Custom concurrency control

## License

Copyright © 2018-2024 Kai Schaller. All rights reserved.