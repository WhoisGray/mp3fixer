#!/usr/bin/env bash

set -euo pipefail

INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="mp3fixer"

echo "📦 Installing mp3fixer..."

if ! command -v ffprobe >/dev/null 2>&1; then
  echo "❌ ffprobe not found."
  echo "Install ffmpeg first:"
  echo
  echo "Ubuntu/Debian:"
  echo "  sudo apt install ffmpeg"
  echo
  echo "macOS:"
  echo "  brew install ffmpeg"
  exit 1
fi

chmod +x mp3fixer.sh

sudo cp mp3fixer.sh "${INSTALL_DIR}/${SCRIPT_NAME}"

echo
echo "✅ Installed successfully!"
echo
echo "Usage:"
echo "  mp3fixer <file-or-folder>"
echo