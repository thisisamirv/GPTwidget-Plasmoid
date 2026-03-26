/*
 *  SPDX-FileCopyrightText: 2024 Denys Madureira <denysmb@zoho.com>
 *  SPDX-FileCopyrightText: 2025 Bruno Gonçalves <bigbruno@gmail.com>
 *  SPDX-FileCopyrightText: 2026 Amir Valizadeh <thisisamirv@gmail.com>
 *
 *  SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import QtWebEngine

/**
 * Downloads bar component that displays active and completed downloads.
 * Renders at the bottom of the web view.
 */
Column {
    id: root

    // --- Properties ---
    property var activeDownloads: null
    property var activeDownloadCache: null
    property var targetWebView: null

    visible: activeDownloads && activeDownloads.count > 0
    spacing: Kirigami.Units.smallSpacing

    anchors {
        left: parent.left
        right: parent.right
        bottom: parent.bottom
    }

    // --- Download Item Delegate ---
    Repeater {
        model: activeDownloads

        delegate: Rectangle {
            width: parent.width
            height: Kirigami.Units.gridUnit * 2
            color: Kirigami.Theme.backgroundColor
            opacity: 0.95

            // Helper to format the status text
            function getStatusText() {
                if (model.state === WebEngineDownloadRequest.DownloadCompleted) {
                    return i18n("%1 - Completed", model.fileName);
                }
                
                if (model.isPdfExport) {
                    return i18n("%1 - Saving PDF...", model.fileName);
                }

                let progressValue = Math.round((model.progress || 0) * 100);
                let sizeInfo = "";
                
                if (model.totalBytes > 0) {
                    let receivedMb = (model.receivedBytes / 1048576).toFixed(1);
                    let totalMb = (model.totalBytes / 1048576).toFixed(1);
                    sizeInfo = ` (${receivedMb}/${totalMb} MB)`;
                }
                
                return i18n("%1 - %2%%3", model.fileName, progressValue, sizeInfo);
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.mediumSpacing

                PlasmaComponents3.Label {
                    text: getStatusText()
                    Layout.fillWidth: true
                    elide: Text.ElideMiddle
                }

                PlasmaComponents3.ProgressBar {
                    Layout.fillWidth: true
                    indeterminate: model.isPdfExport
                    from: 0
                    to: 1
                    value: model.progress || 0
                    visible: model.state === WebEngineDownloadRequest.DownloadInProgress
                }

                // --- Completed Actions ---
                RowLayout {
                    visible: model.state === WebEngineDownloadRequest.DownloadCompleted
                    spacing: Kirigami.Units.smallSpacing

                    PlasmaComponents3.Button {
                        icon.name: "document-open"
                        PlasmaComponents3.ToolTip.text: i18n("Open file")
                        PlasmaComponents3.ToolTip.visible: hovered
                        onClicked: {
                            if (model.fullPath) {
                                Qt.openUrlExternally(formatLocalPath(model.fullPath));
                            }
                        }
                    }

                    PlasmaComponents3.Button {
                        icon.name: "folder-open"
                        PlasmaComponents3.ToolTip.text: i18n("Open folder")
                        PlasmaComponents3.ToolTip.visible: hovered
                        onClicked: {
                            if (model.fullPath) {
                                let dirPath = model.fullPath.substring(0, model.fullPath.lastIndexOf("/"));
                                Qt.openUrlExternally(formatLocalPath(dirPath));
                            }
                        }
                    }

                    PlasmaComponents3.Button {
                        icon.name: "dialog-close"
                        PlasmaComponents3.ToolTip.text: i18n("Close")
                        PlasmaComponents3.ToolTip.visible: hovered
                        onClicked: activeDownloads.remove(model.index)
                    }
                }

                // --- Active Actions (Cancel) ---
                PlasmaComponents3.Button {
                    icon.name: "dialog-cancel"
                    visible: model.state === WebEngineDownloadRequest.DownloadInProgress && !model.isPdfExport
                    PlasmaComponents3.ToolTip.text: i18n("Cancel")
                    PlasmaComponents3.ToolTip.visible: hovered
                    onClicked: {
                        let downloadRef = activeDownloadCache && activeDownloadCache[model.downloadId];
                        if (downloadRef && downloadRef.download) {
                            downloadRef.download.receivedBytesChanged.disconnect(downloadRef.bytesConnection);
                            downloadRef.download.stateChanged.disconnect(downloadRef.stateConnection);
                            downloadRef.download.cancel();
                            delete activeDownloadCache[model.downloadId];
                            activeDownloads.remove(index);
                        }
                    }
                }
            }
        }
    }

    /**
     * Helper to format local file paths for different OS platforms.
     */
    function formatLocalPath(path) {
        // Qt 6 uses 'macos' not 'osx'; both need triple-slash for absolute paths
        return "file:///" + path.replace(/^\/+/, '');
    }
}