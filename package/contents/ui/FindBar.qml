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
 * Inline Find Bar for searching text within the WebEngineView.
 */
Rectangle {
    id: root

    // --- Properties ---
    property bool findBarVisible: false
    property var targetWebView: null
    property alias findText: findField.text

    signal closeRequested()

    visible: findBarVisible
    height: visible ? layoutContainer.height + Kirigami.Units.smallSpacing * 2 : 0
    color: Kirigami.Theme.backgroundColor
    z: 5

    anchors {
        top: parent.top
        left: parent.left
        right: parent.right
    }

    RowLayout {
        id: layoutContainer
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Kirigami.Units.smallSpacing
        }
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents3.TextField {
            id: findField
            Layout.fillWidth: true
            placeholderText: i18n("Find in page...")
            
            onTextChanged: {
                if (text && targetWebView) {
                    targetWebView.findText(text);
                }
            }
            
            onAccepted: {
                if (targetWebView) {
                    targetWebView.findText(text);
                }
            }
            
            Keys.onEscapePressed: root.findBarVisible = false

            Component.onCompleted: {
                if (findBarVisible) {
                    forceActiveFocus();
                }
            }
        }

        PlasmaComponents3.Button {
            icon.name: "go-up"
            display: PlasmaComponents3.AbstractButton.IconOnly
            PlasmaComponents3.ToolTip.text: i18n("Find previous")
            PlasmaComponents3.ToolTip.visible: hovered
            enabled: findField.text !== ""
            onClicked: {
                if (targetWebView) {
                    targetWebView.findText(findField.text, WebEngineView.FindBackward);
                }
            }
        }

        PlasmaComponents3.Button {
            icon.name: "go-down"
            display: PlasmaComponents3.AbstractButton.IconOnly
            PlasmaComponents3.ToolTip.text: i18n("Find next")
            PlasmaComponents3.ToolTip.visible: hovered
            enabled: findField.text !== ""
            onClicked: {
                if (targetWebView) {
                    targetWebView.findText(findField.text);
                }
            }
        }

        PlasmaComponents3.Button {
            icon.name: "dialog-close"
            display: PlasmaComponents3.AbstractButton.IconOnly
            PlasmaComponents3.ToolTip.text: i18n("Close")
            PlasmaComponents3.ToolTip.visible: hovered
            onClicked: root.closeRequested()
        }
    }

    Behavior on height {
        NumberAnimation {
            duration: Kirigami.Units.shortDuration
            easing.type: Easing.InOutQuad
        }
    }

    /**
     * Focuses the search field and selects all existing text.
     */
    function focusAndSelect() {
        findField.forceActiveFocus();
        findField.selectAll();
    }

    /**
     * Clears the search field and resets the WebEngine search state.
     */
    function clearSearch() {
        findField.text = "";
        if (targetWebView) {
            targetWebView.findText("");
        }
    }
}