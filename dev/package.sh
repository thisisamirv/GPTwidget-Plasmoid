#!/bin/bash
# Package the GPTwidget into a .plasmoid file for KDE Store publication

# Get the directory where the script is located
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT="$SCRIPT_DIR/.."
PACKAGE_DIR="$PROJECT_ROOT/package"
OUTPUT_DIR="$PROJECT_ROOT/build"
VERSION=$(grep -Po '"Version": *\K"[^"]*"' "$PACKAGE_DIR/metadata.json" | tr -d '"')

# Default version if not found
if [ -z "$VERSION" ]; then
    VERSION="1.0.0"
fi

OUTPUT_FILE="$OUTPUT_DIR/gptwidget-v$VERSION.plasmoid"

echo "=== GPTwidget Packaging Tool ==="
echo "Version: $VERSION"

# Create build directory
mkdir -p "$OUTPUT_DIR"

# Clean old packages
rm -f "$OUTPUT_DIR"/*.plasmoid

echo "Validating package structure..."
if ! command -v kpackagetool6 &> /dev/null; then
    echo "Warning: kpackagetool6 not found. Skipping validation."
else
    kpackagetool6 -t Plasma/Applet --verify "$PACKAGE_DIR"
fi

echo "Creating .plasmoid package..."
cd "$PACKAGE_DIR" || exit
zip -r "$OUTPUT_FILE" . -x "*.DS_Store*" "*__pycache__*" "*.swp" ".*"

echo ""
echo "Success! Package created at:"
echo "$OUTPUT_FILE"
echo ""
echo "Next steps for KDE Store (store.kde.org):"
echo "1. Upload this .plasmoid file."
echo "2. Upload the logo: ./metadata/icon-256x256.png (or 512x512)"
echo "3. Add screenshots from: ./metadata/screenshots/"
echo "4. Copy the description from: ./dev/DESCRIPTION.md"
