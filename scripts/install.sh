#!/bin/bash

# Podcatcher Installation Script
# Installs podcatcher to /usr/local/bin

set -e

INSTALL_DIR="/usr/local/bin"
BINARY_NAME="podcatcher"

echo "📦 Podcatcher Installation Script"
echo

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ Error: This installer is for macOS only"
    exit 1
fi

# Check if binary exists in current directory
if [ ! -f "$BINARY_NAME" ]; then
    echo "❌ Error: $BINARY_NAME binary not found in current directory"
    echo "💡 Make sure you've extracted the distribution package and are running this script from the same directory"
    exit 1
fi

# Check if install directory exists
if [ ! -d "$INSTALL_DIR" ]; then
    echo "📁 Creating $INSTALL_DIR..."
    sudo mkdir -p "$INSTALL_DIR"
fi

# Check if already installed
if [ -f "$INSTALL_DIR/$BINARY_NAME" ]; then
    echo "⚠️  $BINARY_NAME is already installed at $INSTALL_DIR/$BINARY_NAME"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
fi

# Install binary
echo "🔧 Installing $BINARY_NAME to $INSTALL_DIR..."
sudo cp "$BINARY_NAME" "$INSTALL_DIR/"
sudo chmod +x "$INSTALL_DIR/$BINARY_NAME"

# Verify installation
echo "✅ Verifying installation..."
if command -v $BINARY_NAME &> /dev/null; then
    echo "🎉 Success! $BINARY_NAME is now installed and available in your PATH"
    echo
    echo "📋 Try it out:"
    echo "   $BINARY_NAME --help"
    echo
    $BINARY_NAME --help
else
    echo "⚠️  Installation completed but $BINARY_NAME is not in your PATH"
    echo "💡 You may need to restart your terminal or add $INSTALL_DIR to your PATH"
    echo "   Add this to your ~/.zshrc or ~/.bash_profile:"
    echo "   export PATH=\"$INSTALL_DIR:\$PATH\""
fi