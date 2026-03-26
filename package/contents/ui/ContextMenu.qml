/*
 *  SPDX-FileCopyrightText: 2024 Denys Madureira <denysmb@zoho.com>
 *  SPDX-FileCopyrightText: 2025 Bruno Gonçalves <bigbruno@gmail.com>
 *  SPDX-FileCopyrightText: 2026 Amir Valizadeh <thisisamirv@gmail.com>
 *
 *  SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.kde.plasma.extras as PlasmaExtras
import QtWebEngine

/**
 * Custom Context Menu for the GPTwidget web view.
 * Provides navigation, page saving, and link-specific actions.
 */
PlasmaExtras.Menu {
    id: root

    // --- Properties ---
    property string activeLink: ""
    property var targetWebView: null
    
    // Computed states for navigation buttons
    property bool canGoBack: targetWebView ? targetWebView.canGoBack : false
    property bool canGoForward: targetWebView ? targetWebView.canGoForward : false

    // --- Signals ---
    signal reloadRequested()
    signal savePdfRequested()
    signal saveMhtmlRequested()

    visualParent: targetWebView

    // --- Navigation Actions ---
    PlasmaExtras.MenuItem {
        text: i18n("Back")
        icon: "go-previous"
        enabled: root.canGoBack
        onClicked: if (targetWebView) targetWebView.goBack()
    }

    PlasmaExtras.MenuItem {
        text: i18n("Forward")
        icon: "go-next"
        enabled: root.canGoForward
        onClicked: if (targetWebView) targetWebView.goForward()
    }

    PlasmaExtras.MenuItem {
        text: i18n("Reload")
        icon: "view-refresh"
        onClicked: root.reloadRequested()
    }

    // --- Page Actions (Visible when not right-clicking a link) ---
    PlasmaExtras.MenuItem {
        separator: true
        visible: !root.activeLink
    }

    PlasmaExtras.MenuItem {
        text: i18n("Save as PDF")
        icon: "document-save-as"
        visible: !root.activeLink
        onClicked: root.savePdfRequested()
    }

    PlasmaExtras.MenuItem {
        text: i18n("Save as MHTML")
        icon: "document-save"
        visible: !root.activeLink
        onClicked: root.saveMhtmlRequested()
    }

    // --- Link Actions (Visible when right-clicking a hyperlink) ---
    PlasmaExtras.MenuItem {
        separator: true
        visible: root.activeLink !== ""
    }

    PlasmaExtras.MenuItem {
        text: i18n("Open Link in Browser")
        icon: "internet-web-browser"
        visible: root.activeLink !== ""
        onClicked: Qt.openUrlExternally(root.activeLink)
    }

    PlasmaExtras.MenuItem {
        text: i18n("Copy Link Address")
        icon: "edit-copy"
        visible: root.activeLink !== ""
        onClicked: {
            if (targetWebView) {
                targetWebView.triggerWebAction(WebEngineView.CopyLinkToClipboard);
            }
        }
    }
}