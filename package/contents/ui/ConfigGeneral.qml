/*
 *  SPDX-FileCopyrightText: 2024 Denys Madureira <denysmb@zoho.com>
 *  SPDX-FileCopyrightText: 2025 Bruno Gonçalves <bigbruno@gmail.com>
 *  SPDX-FileCopyrightText: 2026 Amir Valizadeh <thisisamirv@gmail.com>
 *
 *  SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import QtQuick.Layouts
import QtWebEngine
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import Qt.labs.platform 1.1

/**
 * Configuration page for GPTwidget settings.
 * Synchronized with the KConfig schema in main.xml.
 */
KCM.SimpleKCM {
    id: root

    QQC2.ScrollView {
        id: viewContainer
        anchors.fill: parent

        // Standard ScrollBar policy
        Component.onCompleted: {
            QQC2.ScrollBar.vertical.policy = QQC2.ScrollBar.AlwaysOn;
        }

        Item {
            width: viewContainer.width
            implicitHeight: configForm.implicitHeight

            Kirigami.FormLayout {
                id: configForm
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    leftMargin: Kirigami.Units.largeSpacing
                    rightMargin: Kirigami.Units.largeSpacing
                }

                // --- Section: General Browser Settings ---
                QQC2.Label {
                    Kirigami.FormData.isSection: true
                    text: i18n("General Settings")
                }

                QQC2.CheckBox {
                    id: loadOnStartupToggle
                    text: i18n("Load website on Plasma startup")
                    checked: plasmoid.configuration.loadOnStartup
                    onCheckedChanged: plasmoid.configuration.loadOnStartup = checked
                    Layout.fillWidth: true
                }

                QQC2.CheckBox {
                    id: keepOpenToggle
                    text: i18n("Keep window open when focus is lost")
                    checked: plasmoid.configuration.shouldKeepOpen
                    onCheckedChanged: plasmoid.configuration.shouldKeepOpen = checked
                    Layout.fillWidth: true
                }

                QQC2.CheckBox {
                    id: pinToggle
                    text: i18n("Pin window on top of other windows")
                    checked: plasmoid.configuration.isPinned
                    onCheckedChanged: plasmoid.configuration.isPinned = checked
                    Layout.fillWidth: true
                }

                // --- Section: Privacy & Permissions ---
                QQC2.Label {
                    Kirigami.FormData.isSection: true
                    text: i18n("Privacy & Permissions")
                }

                QQC2.CheckBox {
                    id: geoAccessToggle
                    text: i18n("Allow geolocation access")
                    checked: plasmoid.configuration.geolocationEnabled
                    onCheckedChanged: plasmoid.configuration.geolocationEnabled = checked
                    Layout.fillWidth: true
                }

                QQC2.CheckBox {
                    id: micAccessToggle
                    text: i18n("Allow using microphone")
                    checked: plasmoid.configuration.microphoneEnabled
                    onCheckedChanged: plasmoid.configuration.microphoneEnabled = checked
                    Layout.fillWidth: true
                }

                // --- Section: Advanced Browser Behavior ---
                QQC2.Label {
                    Kirigami.FormData.isSection: true
                    text: i18n("Advanced Behavior")
                }

                QQC2.CheckBox {
                    id: spatialNavToggle
                    text: i18n("Enable spatial navigation")
                    checked: plasmoid.configuration.spatialNavigationEnabled
                    onCheckedChanged: plasmoid.configuration.spatialNavigationEnabled = checked
                    Layout.fillWidth: true
                    
                    QQC2.ToolTip.text: i18n("Navigate through links using arrow keys.")
                    QQC2.ToolTip.visible: hovered
                }

                QQC2.CheckBox {
                    id: jsPasteToggle
                    text: i18n("Allow JavaScript to paste")
                    checked: plasmoid.configuration.javascriptCanPaste
                    onCheckedChanged: plasmoid.configuration.javascriptCanPaste = checked
                    Layout.fillWidth: true
                }

                QQC2.CheckBox {
                    id: jsWindowToggle
                    text: i18n("Allow JavaScript to open windows")
                    checked: plasmoid.configuration.javascriptCanOpenWindows
                    onCheckedChanged: plasmoid.configuration.javascriptCanOpenWindows = checked
                    Layout.fillWidth: true
                }

                QQC2.CheckBox {
                    id: jsClipboardToggle
                    text: i18n("Allow JavaScript clipboard access")
                    checked: plasmoid.configuration.javascriptCanAccessClipboard
                    onCheckedChanged: plasmoid.configuration.javascriptCanAccessClipboard = checked
                    Layout.fillWidth: true
                }

                QQC2.CheckBox {
                    id: mediaGestureToggle
                    text: i18n("Require user gesture for media")
                    checked: plasmoid.configuration.playbackRequiresUserGesture
                    onCheckedChanged: plasmoid.configuration.playbackRequiresUserGesture = checked
                    Layout.fillWidth: true
                }

                QQC2.CheckBox {
                    id: focusNavToggle
                    text: i18n("Enable focus on navigation")
                    checked: plasmoid.configuration.focusOnNavigationEnabled
                    onCheckedChanged: plasmoid.configuration.focusOnNavigationEnabled = checked
                    Layout.fillWidth: true
                }

                // --- Section: Storage & Maintenance ---
                QQC2.Label {
                    Kirigami.FormData.isSection: true
                    text: i18n("Storage & Maintenance")
                }

                RowLayout {
                    Kirigami.FormData.label: i18n("Download Path:")
                    Layout.fillWidth: true
                    
                    QQC2.TextField {
                        id: downloadPathField
                        Layout.fillWidth: true
                        text: plasmoid.configuration.downloadDirectory || StandardPaths.writableLocation(StandardPaths.DownloadLocation)
                        placeholderText: StandardPaths.writableLocation(StandardPaths.DownloadLocation)
                        onTextChanged: if (text) plasmoid.configuration.downloadDirectory = text
                    }

                    QQC2.Button {
                        icon.name: "folder-open"
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.text: i18n("Select Folder")
                        onClicked: downloadDirDialog.open()
                    }
                }

                RowLayout {
                    Kirigami.FormData.label: i18n("Cache Path:")
                    Layout.fillWidth: true
                    
                    QQC2.TextField {
                        id: cachePathField
                        Layout.fillWidth: true
                        text: plasmoid.configuration.cacheDirectory
                        onTextChanged: if (text) plasmoid.configuration.cacheDirectory = text
                        placeholderText: i18n("Default Profile Cache")
                    }

                    QQC2.Button {
                        icon.name: "folder-open"
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.text: i18n("Select Folder")
                        onClicked: cacheDirDialog.open()
                    }
                }

                QQC2.CheckBox {
                    id: clearCacheToggle
                    text: i18n("Clear cache automatically on exit")
                    checked: plasmoid.configuration.clearCacheOnExit
                    onCheckedChanged: plasmoid.configuration.clearCacheOnExit = checked
                    Layout.fillWidth: true
                }
            }
        }
    }

    // --- Dialogs ---
    FolderDialog {
        id: downloadDirDialog
        title: i18n("Select Download Folder")
        currentFolder: downloadPathField.text
        onAccepted: {
            downloadPathField.text = selectedFolder.toString().replace(/^file:\/\//, "");
            plasmoid.configuration.downloadDirectory = downloadPathField.text;
        }
    }

    FolderDialog {
        id: cacheDirDialog
        title: i18n("Select Cache Folder")
        onAccepted: {
            cachePathField.text = selectedFolder.toString().replace(/^file:\/\//, "");
            plasmoid.configuration.cacheDirectory = cachePathField.text;
        }
    }
}

