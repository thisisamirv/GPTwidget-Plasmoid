#!/bin/bash
# Lint the QML and XML code in the package directory

# Function to check for qmllint
check_qmllint() {
    if command -v qmllint &> /dev/null; then
        echo "qmllint"
    elif command -v qmllint-qt6 &> /dev/null; then
        echo "qmllint-qt6"
    elif command -v qmllint6 &> /dev/null; then
        echo "qmllint6"
    else
        echo ""
    fi
}

# Get the directory where the script is located
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR="$SCRIPT_DIR/.."

QMLLINT=$(check_qmllint)


# --- QML Linting ---
if [ -n "$QMLLINT" ]; then
    echo "Running $QMLLINT on $ROOT_DIR/package/contents/ui/..."
    find "$ROOT_DIR/package/contents/ui/" -name "*.qml" -exec "$QMLLINT" {} +
else
    echo "Warning: qmllint not found. Skipping QML validation."
fi

# --- XML Linting (KConfig) ---
if command -v xmllint &> /dev/null; then
    echo "Running xmllint on $ROOT_DIR/package/contents/config/main.xml..."
    xmllint --noout "$ROOT_DIR/package/contents/config/main.xml"
else
    echo "Warning: xmllint not found. Skipping XML validation."
fi

echo "Done!"

