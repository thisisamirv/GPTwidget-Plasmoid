#!/bin/bash
# Install or upgrade the Plasmoid to the system
plasmoidName="GPTwidget-Plasmoid"

# Get the directory where the script is located
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PACKAGE_DIR="$SCRIPT_DIR/../package"

if kpackagetool6 -t Plasma/Applet --list | grep -q "$plasmoidName"; then
    echo "Upgrading existing widget..."
    kpackagetool6 -t Plasma/Applet --upgrade "$PACKAGE_DIR"
else
    echo "Installing new widget..."
    kpackagetool6 -t Plasma/Applet --install "$PACKAGE_DIR"
fi

echo "Installing application icon..."
mkdir -p ~/.local/share/icons/hicolor/scalable/apps
cp "$PACKAGE_DIR/icon.svg" ~/.local/share/icons/hicolor/scalable/apps/GPTwidget-Plasmoid.svg

echo "Done!"
