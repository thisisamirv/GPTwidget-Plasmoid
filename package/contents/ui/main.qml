/*
 *  SPDX-FileCopyrightText: 2024 Denys Madureira <denysmb@zoho.com>
 *  SPDX-FileCopyrightText: 2025 Bruno Gonçalves <bigbruno@gmail.com>
 *  SPDX-FileCopyrightText: 2026 Amir Valizadeh <thisisamirv@gmail.com>
 *
 *  SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

/**
 * Entry point for the GPTwidget Plasmoid.
 * Handles the main layout, lazy engine loading, and window size persistence.
 */
PlasmoidItem {
    id: root

    // --- Initialization ---
    Component.onCompleted: {
        // Immediately expand and load the engine if configured to do so on startup
        if (plasmoid.configuration.loadOnStartup) {
            webEngineLoader.active = true;
            root.expanded = true;
        }
    }

    // --- Full Representation ---
    fullRepresentation: ColumnLayout {
        id: layoutContainer

        // --- Properties ---
        property alias webViewItem: webEngineLoader.item

        // Default dimensions (in grid units for proper HiDPI scaling)
        readonly property int defaultWidth: Kirigami.Units.gridUnit * 28
        readonly property int defaultHeight: Kirigami.Units.gridUnit * 39

        Layout.minimumWidth: Kirigami.Units.gridUnit * 20
        Layout.minimumHeight: Kirigami.Units.gridUnit * 28
        Layout.preferredWidth: plasmoid.configuration.lastWindowWidth > 0
            ? plasmoid.configuration.lastWindowWidth : defaultWidth
        Layout.preferredHeight: plasmoid.configuration.lastWindowHeight > 0
            ? plasmoid.configuration.lastWindowHeight : defaultHeight

        spacing: 0

        // Persist window dimensions with a brief debounce to avoid excess writes
        onWidthChanged: windowSizeTimer.restart()
        onHeightChanged: windowSizeTimer.restart()

        // --- Window Size Persistence ---
        Timer {
            id: windowSizeTimer
            interval: 500
            repeat: false
            onTriggered: {
                const w = Math.round(layoutContainer.width);
                const h = Math.round(layoutContainer.height);
                if (w > 0 && h > 0
                        && (w !== plasmoid.configuration.lastWindowWidth
                            || h !== plasmoid.configuration.lastWindowHeight)) {
                    plasmoid.configuration.lastWindowWidth = w;
                    plasmoid.configuration.lastWindowHeight = h;
                }
            }
        }

        // --- Web Engine Container (lazy-loaded) ---
        Loader {
            id: webEngineLoader

            // Activate the engine if the widget is expanded or was already loaded
            active: root.expanded || item !== null || plasmoid.configuration.loadOnStartup
            asynchronous: true
            source: "WebView.qml"

            Layout.fillWidth: true
            Layout.fillHeight: true

            onStatusChanged: {
                if (status === Loader.Error)
                    console.error("GPTwidget: Critical failure loading WebView.qml");
            }
        }

        // --- Expansion Listener ---
        // Activates the engine on first expand and notifies the view to update its focus
        Connections {
            target: root
            function onExpandedChanged() {
                if (root.expanded) {
                    webEngineLoader.active = true;
                    if (webEngineLoader.item)
                        webEngineLoader.item.forceFocus();
                }
            }
        }
    }
}
