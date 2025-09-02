#!/bin/bash

# Create Distribution Package Script
# Creates a complete distribution package with installer

set -e

echo "📦 Creating Podcatcher Distribution Package..."
echo

# Build the binaries first
./scripts/build-release.sh

# Create distribution directory structure
echo "📁 Creating distribution package structure..."
rm -rf dist/podcatcher-dist/
mkdir -p dist/podcatcher-dist/

# Copy files to distribution directory
cp dist/podcatcher dist/podcatcher-dist/
cp scripts/install.sh dist/podcatcher-dist/
cp DISTRIBUTION.md dist/podcatcher-dist/README.md

# Create the final distribution archive
echo "🗜️  Creating final distribution archive..."
cd dist/
tar -czf podcatcher-macos-distribution.tar.gz podcatcher-dist/
cd ..

# Show final package info
echo
echo "✅ Distribution package created!"
echo "📁 Contents:"
echo "   • dist/podcatcher-dist/podcatcher (universal binary)"
echo "   • dist/podcatcher-dist/install.sh (installation script)"  
echo "   • dist/podcatcher-dist/README.md (distribution guide)"
echo
echo "📦 Distribution archive:"
echo "   • dist/podcatcher-macos-distribution.tar.gz"
echo
echo "🎯 To distribute:"
echo "   1. Share the .tar.gz file"
echo "   2. Users extract and run: ./install.sh"
echo "   3. Or users can manually copy the binary"
echo