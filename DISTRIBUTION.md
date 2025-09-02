# Podcatcher - Distribution Guide

A modern Swift command-line tool to download podcast episodes from RSS feeds.

## Quick Install (Recommended)

### Option 1: Automatic Installation
```bash
# Download and extract the package
curl -L -o podcatcher.tar.gz [URL_TO_RELEASE]
tar -xzf podcatcher.tar.gz
cd podcatcher-dist/

# Run the installer (requires sudo for /usr/local/bin)
./install.sh
```

### Option 2: Manual Installation
```bash
# Download and extract the package
curl -L -o podcatcher.tar.gz [URL_TO_RELEASE] 
tar -xzf podcatcher.tar.gz

# Copy binary to a directory in your PATH
sudo cp podcatcher /usr/local/bin/
sudo chmod +x /usr/local/bin/podcatcher
```

## Architecture Support

This distribution includes binaries for:
- **Universal**: Works on both Apple Silicon and Intel Macs
- **ARM64**: Optimized for Apple Silicon (M1/M2/M3)
- **x86_64**: Intel-based Macs

The installer automatically uses the universal binary for maximum compatibility.

## Requirements

- macOS 13.0 or later
- No additional dependencies required

## Usage

After installation, you can use podcatcher from anywhere in your terminal:

```bash
# Show help
podcatcher --help

# Download all episodes from a podcast
podcatcher "https://example.com/podcast/rss" ~/Downloads/Podcasts/

# Download with progress bars
podcatcher "https://example.com/podcast/rss" ~/Downloads/Podcasts/ --show-progress

# Download only recent episodes  
podcatcher "https://example.com/podcast/rss" ~/Downloads/Podcasts/ --not-before-date 2024-01-01

# Limit concurrent downloads
podcatcher "https://example.com/podcast/rss" ~/Downloads/Podcasts/ -m 2
```

## Features

- ✨ **Modern Swift**: Built with Swift 5.9+ using async/await concurrency
- 🚀 **Fast Downloads**: Concurrent downloads with configurable limits
- 📱 **Smart Filtering**: Skip existing files and filter by publication date  
- 🎯 **Robust Parsing**: Reliable RSS/XML parsing with error handling
- 📊 **Progress Bars**: Optional ASCII progress bars with completion log
- 💻 **Cross-platform**: Universal binary works on all modern Macs

## File Organization

Episodes are saved with the naming convention:
```
YYYY-MM-DD_Episode Title.extension
```

Forward slashes in titles are replaced with colons for valid filenames.

## Troubleshooting

### "Command not found" after installation
- Restart your terminal
- Or manually add to your PATH: `export PATH="/usr/local/bin:$PATH"`

### Permission denied when running installer
- Make sure the installer script is executable: `chmod +x install.sh`
- Use `sudo` when prompted for system directory access

### Binary won't run on older macOS versions
- This tool requires macOS 13.0+
- Use the appropriate architecture-specific binary if universal doesn't work

## Uninstall

To remove podcatcher:
```bash
sudo rm /usr/local/bin/podcatcher
```

## Source Code

Full source code available at: https://github.com/[your-username]/podcatcher

## License

Copyright © 2018-2024 Kai Schaller. All rights reserved.