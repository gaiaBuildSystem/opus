#!/usr/bin/env bash

# Opus installation script
# This script installs the opus command to a directory in PATH

set -e

# check if docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed. Please install Docker first."
    exit 1
fi

# check if wget is installed
if ! command -v wget &> /dev/null; then
    echo "Error: wget is not installed. Please install wget first."
    exit 1
fi

# check if the openssl command is available
if ! command -v openssl &> /dev/null; then
    echo "Error: openssl is not installed. Please install openssl first."
    exit 1
fi


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPUS_SCRIPT="$SCRIPT_DIR/opus"


# Check if opus script exists
if [ ! -f "$OPUS_SCRIPT" ]; then
    echo "Downloading $OPUS_SCRIPT ..."
    wget -q https://raw.githubusercontent.com/gaiaBuildSystem/opus/main/.scripts/opus -O opus
fi

# Determine installation directory
if [ -w "/usr/local/bin" ]; then
    INSTALL_DIR="/usr/local/bin"
elif [ -d "$HOME/.local/bin" ]; then
    INSTALL_DIR="$HOME/.local/bin"
    # Ensure it's in PATH
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo "Adding the following line to your ~/.bashrc ..."
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
        echo "If you are not using bash, please add this line to your shell configuration file."
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$HOME/.bashrc"
    fi
else
    # Create ~/.local/bin if it doesn't exist
    mkdir -p "$HOME/.local/bin"
    INSTALL_DIR="$HOME/.local/bin"
    # add the path to the .bashrc
    echo "Created $HOME/.local/bin"
    echo "Adding the following line to your ~/.bashrc ..."
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo "If you are not using bash, please add this line to your shell configuration file."
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$HOME/.bashrc"
fi

# Copy the opus script
echo "Installing opus command to $INSTALL_DIR ..."
cp "$OPUS_SCRIPT" "$INSTALL_DIR/opus"
chmod +x "$INSTALL_DIR/opus"

echo "✅ Opus command installed successfully!"
echo "You can now run 'opus' from anywhere in your terminal."
