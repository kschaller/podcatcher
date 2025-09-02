#!/bin/bash

# Build Release Script for Podcatcher
# Creates optimized binaries for distribution

set -e  # Exit on any error

echo "🔨 Building Podcatcher Release Binaries..."
echo

# Clean previous builds
echo "🧹 Cleaning previous builds..."
swift package clean
rm -rf dist/
mkdir -p dist/

# Build for ARM64 (Apple Silicon)
echo "🍎 Building for ARM64 (Apple Silicon)..."
swift build --configuration release --arch arm64
cp .build/arm64-apple-macosx/release/podcatcher dist/podcatcher-arm64

# Build for x86_64 (Intel)
echo "💻 Building for x86_64 (Intel)..."
swift build --configuration release --arch x86_64
cp .build/x86_64-apple-macosx/release/podcatcher dist/podcatcher-x86_64

# Create universal binary
echo "🌍 Creating universal binary..."
lipo -create -output dist/podcatcher dist/podcatcher-arm64 dist/podcatcher-x86_64

# Verify universal binary
echo "✅ Verifying universal binary..."
lipo -info dist/podcatcher
file dist/podcatcher

# Get binary sizes
echo
echo "📊 Binary sizes:"
ls -lh dist/podcatcher*

# Create tarball for distribution
echo
echo "📦 Creating distribution tarball..."
cd dist/
tar -czf podcatcher-macos-universal.tar.gz podcatcher
tar -czf podcatcher-macos-arm64.tar.gz podcatcher-arm64
tar -czf podcatcher-macos-x86_64.tar.gz podcatcher-x86_64
cd ..

echo
echo "✅ Release build complete!"
echo "📁 Binaries available in dist/"
echo "   • dist/podcatcher (universal)"
echo "   • dist/podcatcher-arm64 (Apple Silicon)"
echo "   • dist/podcatcher-x86_64 (Intel)"
echo "   • dist/*.tar.gz (distribution packages)"
echo