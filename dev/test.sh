#!/bin/bash
# Get the directory where the script is located
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Run the Plasmoid locally in an isolated viewer
plasmoidviewer -a "$SCRIPT_DIR/../package"

