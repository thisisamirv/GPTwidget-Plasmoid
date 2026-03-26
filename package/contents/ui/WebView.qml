/*
 *  SPDX-FileCopyrightText: 2024 Denys Madureira <denysmb@zoho.com>
 *  SPDX-FileCopyrightText: 2025 Bruno Gonçalves <bigbruno@gmail.com>
 *  SPDX-FileCopyrightText: 2026 Amir Valizadeh <thisisamirv@gmail.com>
 *
 *  SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtCore
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtWebEngine
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.notification 1.0
import Qt.labs.platform 1.1
import "."

/**
 * Core WebView component for GPTwidget.
 * Manages the WebEngine instance, downloads, permissions, and browser overlays.
 */
Item {
    id: root

    // --- Public Properties ---
    property bool findBarVisible: false

    Layout.fillWidth: true
    Layout.fillHeight: true

    // --- Internal State ---
    property int loadingRetryCount: 0
    property bool hasLoadError: false

    // --- Public API ---
    function goBackToHomePage() {
        webView.url = "https://chatgpt.com";
    }

    function goBack() {
        if (webView) webView.goBack();
    }

    function goForward() {
        if (webView) webView.goForward();
    }

    function reloadPage() {
        if (webView) webView.reloadAndBypassCache();
    }

    function forceFocus() {
        if (webView) {
            webView.forceActiveFocus();
            webView.runJavaScript("window.dispatchEvent(new Event('resize'));");
        }
    }

    function printPage() {
        webView.runJavaScript("document.title", (title) => {
            const downloadDir = _resolveDownloadDir();
            const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
            const safeName = title.replace(/[^a-z0-9]/gi, '-').toLowerCase();
            const filename = `${downloadDir}/${safeName}-${timestamp}.pdf`;
            webView.downloads.addDownload(null, `${safeName}-${timestamp}.pdf`, filename, true);
            webView.printToPdf(filename, WebEngineView.A4, WebEngineView.Portrait);
        });
    }

    function saveMHTML() {
        webView.runJavaScript("document.title", (title) => {
            const downloadDir = _resolveDownloadDir();
            const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
            const safeName = title.replace(/[^a-z0-9]/gi, '-').toLowerCase();
            const filename = `${downloadDir}/${safeName}-${timestamp}.mhtml`;
            webView.triggerWebAction(WebEngineView.SavePage, filename);
        });
    }

    // --- Private Helpers ---
    function _resolveDownloadDir() {
        const configured = plasmoid.configuration.downloadDirectory;
        return configured
            ? configured.toString().replace(/^file:\/\//, '')
            : StandardPaths.writableLocation(StandardPaths.DownloadLocation);
    }

    function _isAuthUrl(url) {
        const target = url.toString().toLowerCase();
        const authDomains = [
            'accounts.google.com', 'appleid.apple.com', 'login.live.com',
            'github.com/login', 'auth.openai.com', 'auth0.openai.com',
            'microsoftonline.com', 'okta.com'
        ];
        return authDomains.some(domain => target.includes(domain));
    }

    // --- Notifications ---
    Notification {
        id: notificationSystem
        componentName: "gptwidget_plasmoid"
        eventId: "notification"
        title: i18n("GPTwidget")
        iconName: "dialog-information"
    }

    function showNotification(title, message, icon) {
        notificationSystem.title = title || i18n("GPTwidget");
        notificationSystem.text = message || "";
        notificationSystem.iconName = icon || "dialog-information";
        notificationSystem.sendEvent();
    }

    // --- Shortcuts ---
    Shortcut {
        sequence: StandardKey.Find
        onActivated: root.findBarVisible = true
    }

    // --- Context Menu ---
    ContextMenu {
        id: linkContextMenu
        targetWebView: webView
        onReloadRequested: reloadPage()
        onSavePdfRequested: printPage()
        onSaveMhtmlRequested: saveMHTML()
    }

    // --- Browser Profile ---
    // Declared as a sibling (before WebEngineView) to ensure the profile is fully
    // initialized with disk-based storage before the view loads any page.
    // When nested inside WebEngineView, Qt 6.9 initializes the profile as
    // off-the-record first, breaking cookie persistence for OAuth login flows.
    WebEngineProfile {
        id: browserProfile
        storageName: "gptwidget-v1"
        offTheRecord: false
        httpCacheType: WebEngineProfile.DiskHttpCache
        httpCacheMaximumSize: 500 * 1024 * 1024   // 500 MB
        persistentCookiesPolicy: WebEngineProfile.ForcePersistentCookies
        persistentPermissionsPolicy: WebEngineProfile.AskEveryTime

        // Respect user-configured cache path if set; otherwise use Qt's default profile path
        cachePath: plasmoid.configuration.cacheDirectory || ""

        downloadPath: _resolveDownloadDir()

        Component.onDestruction: {
            // Clear disk cache on exit if the user has opted in
            if (plasmoid.configuration.clearCacheOnExit) {
                browserProfile.clearHttpCache();
            }
        }


        onPresentNotification: (notif) => {
            showNotification(notif.title, notif.message);
            notif.show();
        }

        onDownloadRequested: (download) => {
            const downloadDir = _resolveDownloadDir();
            if (!plasmoid.configuration.downloadDirectory)
                plasmoid.configuration.downloadDirectory = downloadDir;
            download.downloadDirectory = downloadDir;

            // Prevent duplicate active downloads
            for (let i = 0; i < webView.downloads.count; i++) {
                const d = webView.downloads.get(i);
                if (d.state === WebEngineDownloadRequest.DownloadInProgress
                        && d.fileName === download.downloadFileName
                        && !d.isPdfExport) {
                    showNotification(
                        i18n("Download in progress"),
                        i18n("The file '%1' is already being downloaded", download.downloadFileName),
                        "dialog-warning"
                    );
                    download.cancel();
                    return;
                }
            }

            const downloadId = Date.now().toString() + Math.random().toString(36).substring(7);
            const downloadIndex = webView.downloads.addDownload(
                download, download.downloadFileName,
                downloadDir + "/" + download.downloadFileName, false
            );

            const onBytesChanged = () => {
                if (downloadIndex >= 0 && downloadIndex < webView.downloads.count) {
                    webView.downloads.setProperty(downloadIndex, "progress", download.receivedBytes / download.totalBytes);
                    webView.downloads.setProperty(downloadIndex, "receivedBytes", download.receivedBytes);
                    webView.downloads.setProperty(downloadIndex, "totalBytes", download.totalBytes);
                }
            };

            const onStateChanged = (state) => {
                if (downloadIndex >= 0 && downloadIndex < webView.downloads.count) {
                    webView.downloads.setProperty(downloadIndex, "state", state);
                    if (state === WebEngineDownloadRequest.DownloadCompleted)
                        webView.downloads.setProperty(downloadIndex, "progress", 1.0);
                    if (state === WebEngineDownloadRequest.DownloadCompleted
                            || state === WebEngineDownloadRequest.DownloadCancelled) {
                        download.receivedBytesChanged.disconnect(onBytesChanged);
                        download.stateChanged.disconnect(onStateChanged);
                        delete webView.downloadCache[downloadId];
                    }
                }
            };

            download.receivedBytesChanged.connect(onBytesChanged);
            download.stateChanged.connect(onStateChanged);
            webView.downloadCache[downloadId] = {
                download: download, index: downloadIndex,
                bytesConnection: onBytesChanged, stateConnection: onStateChanged
            };
            webView.downloads.setProperty(downloadIndex, "downloadId", downloadId);
            download.accept();
        }
    }

    // --- Main Web Engine ---
    WebEngineView {
        id: webView
        anchors.fill: parent
        // Match Plasma theme background to prevent white flash before first paint
        backgroundColor: Kirigami.Theme.backgroundColor
        profile: browserProfile

        // Download reference cache (keyed by downloadId)
        property var downloadCache: ({})

        // Download list model
        property var downloads: ListModel {
            function addDownload(downloadItem, fileName, path, isPdf) {
                const downloadId = Date.now().toString();
                const entry = {
                    "downloadId": downloadId,
                    "fileName": fileName,
                    "fullPath": path,
                    "progress": 0,
                    "receivedBytes": 0,
                    "totalBytes": downloadItem ? downloadItem.totalBytes : 0,
                    "isPdfExport": isPdf,
                    "state": WebEngineDownloadRequest.DownloadInProgress
                };
                if (downloadItem) webView.downloadCache[downloadId] = downloadItem;
                this.append(entry);
                return this.count - 1;
            }

            function removeDownload(index) {
                const item = this.get(index);
                if (item && item.downloadId) delete webView.downloadCache[item.downloadId];
                this.remove(index);
            }
        }

        // --- Event Handlers ---

        onLinkHovered: (hoveredUrl) => {
            if (hoveredUrl === "") {
                hideStatusTimer.start();
            } else {
                statusTextDisplay.text = hoveredUrl;
                statusBubble.visible = true;
                hideStatusTimer.stop();
            }
        }

        onContextMenuRequested: (request) => {
            // Fall back to native menu for input fields, text selection, and media
            if (request.isContentEditable || request.selectedText
                    || request.mediaType !== ContextMenuRequest.MediaTypeNone) {
                request.accepted = false;
                return;
            }
            linkContextMenu.activeLink = request.linkUrl.toString() || "";
            linkContextMenu.open(request.position.x, request.position.y);
            request.accepted = true;
        }

        onPermissionRequested: (request) => {
            switch (request.permissionType) {
            case WebEnginePermission.Geolocation:
                plasmoid.configuration.geolocationEnabled ? request.grant() : request.deny();
                break;
            case WebEnginePermission.Notifications:
                // Deny notifications — the widget uses its own system notification path
                request.deny();
                break;
            default:
                request.grant();
            }
        }

        onFeaturePermissionRequested: (securityOrigin, feature) => {
            if (feature === WebEngineView.MediaAudioCapture)
                grantFeaturePermission(securityOrigin, feature, plasmoid.configuration.microphoneEnabled);
            else if (feature === WebEngineView.MediaVideoCapture
                     || feature === WebEngineView.DesktopAudioVideoCapture)
                grantFeaturePermission(securityOrigin, feature, false);
        }

        onLoadingChanged: (loadRequest) => {
            if (webView.loading) {
                root.hasLoadError = false;
                return;
            }
            if (loadRequest.status === WebEngineView.LoadSucceededStatus) {
                root.loadingRetryCount = 0;
                root.hasLoadError = false;
            } else if (loadRequest.status === WebEngineView.LoadFailedStatus) {
                if (root.loadingRetryCount < 1) {
                    root.loadingRetryCount++;
                    retryTimer.start();
                } else {
                    root.hasLoadError = true;
                }
            }
        }

        onRenderProcessTerminated: (terminationStatus, exitCode) => {
            if (terminationStatus !== WebEngineView.NormalTerminationStatus) {
                console.warn("GPTwidget: Render process crashed (status=" + terminationStatus
                             + ", code=" + exitCode + "). Reloading...");
                root.showNotification(
                    i18n("Engine Recovery"),
                    i18n("The browser engine crashed and restarted automatically."),
                    "view-refresh"
                );
                root.reloadPage();
            }
        }

        onNewWindowRequested: (request) => {
            const url = request.requestedUrl.toString();
            // Keep auth flows (OAuth popups) inside the widget; open everything else externally
            if (_isAuthUrl(url)) {
                webView.url = url;
            } else {
                Qt.openUrlExternally(request.requestedUrl);
            }
            request.action = WebEngineNewWindowRequest.IgnoreRequest;
        }

        // Only intercept user-initiated navigations aimed at a NEW TAB or WINDOW.
        // Same-tab navigations and form POST redirects must be left alone — intercepting
        // them discards the POST body and silently breaks login flows.
        onNavigationRequested: (request) => {
            if (request.navigationType === WebEngineNavigationRequest.NavigationTypeRedirect
                    || request.navigationType === WebEngineNavigationRequest.NavigationTypeLinkClicked) {
                if (request.userInitiated
                        && request.disposition !== WebEngineNavigationRequest.CurrentTabDisposition) {
                    const url = request.url.toString();
                    if (_isAuthUrl(url)) {
                        webView.url = url;
                    } else {
                        Qt.openUrlExternally(request.url);
                    }
                    request.action = WebEngineNavigationRequest.IgnoreRequest;
                }
            }
        }

        onPdfPrintingFinished: (filePath, success) => {
            for (let i = 0; i < downloads.count; i++) {
                if (downloads.get(i).fullPath === filePath) {
                    if (success)
                        downloads.setProperty(i, "state", WebEngineDownloadRequest.DownloadCompleted);
                    else
                        downloads.remove(i);
                    break;
                }
            }
        }

        settings {
            // Wired to user config — changes in ConfigGeneral immediately take effect
            spatialNavigationEnabled: plasmoid.configuration.spatialNavigationEnabled
            allowWindowActivationFromJavaScript: true
            javascriptCanAccessClipboard: plasmoid.configuration.javascriptCanAccessClipboard
            javascriptCanOpenWindows: plasmoid.configuration.javascriptCanOpenWindows
            javascriptCanPaste: plasmoid.configuration.javascriptCanPaste
            unknownUrlSchemePolicy: WebEngineSettings.AllowAllUnknownUrlSchemes
            localContentCanAccessRemoteUrls: true
            allowRunningInsecureContent: false
            dnsPrefetchEnabled: true
            playbackRequiresUserGesture: plasmoid.configuration.playbackRequiresUserGesture
            focusOnNavigationEnabled: plasmoid.configuration.focusOnNavigationEnabled
            forceDarkMode: {
                const color = Kirigami.Theme.backgroundColor;
                const luma = 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b;
                return luma < 0.5;
            }
        }
    }

    // --- Progress Bar ---
    PlasmaComponents3.ProgressBar {
        id: loadingProgressBar
        z: 10
        visible: webView.loading && webView.loadProgress < 100
        height: visible ? 3 : 0
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        from: 0
        to: 100
        value: webView.loadProgress
        Behavior on height {
            NumberAnimation {
                duration: Kirigami.Units.shortDuration
                easing.type: Easing.InOutQuad
            }
        }
    }

    // --- URL Status Bubble ---
    Rectangle {
        id: statusBubble
        color: Kirigami.Theme.backgroundColor
        visible: false
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: statusTextDisplay.paintedWidth + 16
        height: statusTextDisplay.paintedHeight + 16

        Text {
            id: statusTextDisplay
            anchors.centerIn: parent
            elide: Qt.ElideMiddle
            color: Kirigami.Theme.textColor
        }

        Timer {
            id: hideStatusTimer
            interval: 750
            onTriggered: {
                statusTextDisplay.text = "";
                statusBubble.visible = false;
            }
        }
    }

    // --- Download Manager Bar ---
    DownloadBar {
        activeDownloads: webView.downloads
        activeDownloadCache: webView.downloadCache
        targetWebView: webView
    }

    // --- Find Bar ---
    FindBar {
        id: findBar
        findBarVisible: root.findBarVisible
        targetWebView: webView
        onCloseRequested: root.findBarVisible = false
        onFindBarVisibleChanged: findBarVisible ? findBar.focusAndSelect() : findBar.clearSearch()
    }

    // --- Stability Timers ---

    // Defer the initial page load slightly to guarantee the profile and engine are ready
    Timer {
        id: startupTimer
        interval: 250
        running: true
        repeat: false
        onTriggered: root.goBackToHomePage()
    }

    // Brief delay before retrying a failed page load
    Timer {
        id: retryTimer
        interval: 1500
        running: false
        repeat: false
        onTriggered: root.reloadPage()
    }

    // Watchdog: detect and recover from hung page loads (> 30 s at < 100%)
    Timer {
        id: watchdogTimer
        interval: 30000
        running: webView.loading
        repeat: false
        onTriggered: {
            if (webView.loadProgress < 100) {
                console.warn("GPTwidget: Load watchdog triggered at " + webView.loadProgress + "%. Recovering...");
                root.reloadPage();
            }
        }
    }

    // --- Error Overlay ---
    Rectangle {
        id: errorOverlay
        anchors.fill: parent
        color: Kirigami.Theme.backgroundColor
        visible: root.hasLoadError && !webView.loading
        z: 100

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Kirigami.Units.largeSpacing

            Kirigami.Icon {
                source: "network-error"
                Layout.preferredWidth: Kirigami.Units.iconSizes.huge
                Layout.preferredHeight: Kirigami.Units.iconSizes.huge
                Layout.alignment: Qt.AlignHCenter
            }

            QQC2.Label {
                text: i18n("Unable to load ChatGPT")
                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.2
                Layout.alignment: Qt.AlignHCenter
            }

            QQC2.Button {
                text: i18n("Retry Connection")
                icon.name: "view-refresh"
                Layout.alignment: Qt.AlignHCenter
                onClicked: {
                    root.loadingRetryCount = 0;
                    root.reloadPage();
                }
            }
        }
    }
}
