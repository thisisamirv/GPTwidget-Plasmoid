#!/bin/bash
# Uninstall the Plasmoid from the system
plasmoidName="GPTwidget-Plasmoid"

echo "Uninstalling $plasmoidName..."
kpackagetool6 -t Plasma/Applet --remove "$plasmoidName"

echo "Removing application icon..."
rm -f ~/.local/share/icons/hicolor/scalable/apps/GPTwidget-Plasmoid.svg

echo "Done!"
