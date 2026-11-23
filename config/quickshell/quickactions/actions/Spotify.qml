import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "../../reusables"
import "../../"

Item {
    id: root

    property int requestedLayoutTemplate: 1
    property bool isActiveTab: typeof isCurrentTarget !== "undefined" ? isCurrentTarget : true
    property bool isDrawerOpen: typeof isExpandedState !== "undefined" ? isExpandedState : false
    property bool isRateLimited: false
    property string safeActiveEdge: typeof activeEdge !== "undefined" ? activeEdge : "left"

    function s(val) {
        return typeof scaleFunc === "function" ? scaleFunc(val) : val;
    }

    property real baseW: s(360)
    property real baseL: s(380)

    property real preferredWidth: (root.safeActiveEdge === "bottom" || root.safeActiveEdge === "top") ? baseL + s(40) : baseW
    property real preferredExtraLength: (root.safeActiveEdge === "bottom" || root.safeActiveEdge === "top") ? baseW : baseL

    property real counterRotation: {
        if (root.safeActiveEdge === "right") return 180;
        if (root.safeActiveEdge === "bottom") return 90;
        if (root.safeActiveEdge === "top") return -90;
        return 0;
    }

    // =========================================================================
    // SPOTIFY CLOUD API CREDENTIALS (Loaded from ~/.config/quickshell/spotify.json or env)
    // =========================================================================
    FileView {
        id: credsFile
        path: (typeof Caching !== "undefined" && Caching.quickshellDir ? Caching.quickshellDir : (Quickshell.env("HOME") + "/.config/quickshell")) + "/spotify.json"
        watchChanges: root.isDrawerOpen && root.isActiveTab
        onFileChanged: reload()
    }

    readonly property var _credsJson: {
        let t = typeof credsFile.text === "function" ? credsFile.text() : credsFile.text;
        if (t && t.trim().length > 0) {
            try { return JSON.parse(t); } catch(e) {}
        }
        return {};
    }

    readonly property string spotifyClientId: _credsJson.clientId || _credsJson.client_id || Quickshell.env("SPOTIFY_CLIENT_ID") || ""
    readonly property string spotifyClientSecret: _credsJson.clientSecret || _credsJson.client_secret || Quickshell.env("SPOTIFY_CLIENT_SECRET") || ""
    readonly property string spotifyRefreshToken: _credsJson.refreshToken || _credsJson.refresh_token || Quickshell.env("SPOTIFY_REFRESH_TOKEN") || ""
    readonly property bool hasCredentials: spotifyClientId !== "" && spotifyClientSecret !== "" && spotifyRefreshToken !== ""
    readonly property string spotifyApiBaseUrl: "https://api.spotify.com/v1"

    property string spotifyAccessToken: ""
    readonly property bool hasApiToken: spotifyAccessToken.trim().length > 0

    property bool isRefreshingToken: false
    property var refreshCallbacks: []
    property int apiRevision: 0

    onIsDrawerOpenChanged: {
        if (root.hasCredentials && root.isDrawerOpen && root.isActiveTab && !root.isRateLimited) {
            root.syncData();
        }
    }

    onIsActiveTabChanged: {
        if (root.hasCredentials && root.isDrawerOpen && root.isActiveTab && !root.isRateLimited) {
            root.syncData();
        }
    }

    Component.onCompleted: {
        if (root.hasCredentials && root.isActiveTab && root.isDrawerOpen && !root.isRateLimited) {
            root.syncData();
        }
    }

    // =========================================================================
    // SPOTIFY API CALLS
    // =========================================================================
    function refreshAccessToken(callback) {
        if (!hasCredentials) return;
        if (typeof callback === "function") {
            refreshCallbacks.push(callback);
        }
        if (isRefreshingToken) return;
        isRefreshingToken = true;

        let xhr = new XMLHttpRequest();
        xhr.open("POST", "https://accounts.spotify.com/api/token");
        xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
        xhr.setRequestHeader("Authorization", "Basic " + Qt.btoa(spotifyClientId + ":" + spotifyClientSecret));

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                root.isRefreshingToken = false;
                if (xhr.status === 200) {
                    try {
                        let res = JSON.parse(xhr.responseText);
                        if (res && res.access_token) {
                            root.spotifyAccessToken = res.access_token;
                            let cbs = root.refreshCallbacks.slice();
                            root.refreshCallbacks = [];
                            for (let i = 0; i < cbs.length; i++) {
                                try { cbs[i](); } catch(err) { console.warn("Spotify cb error:", err); }
                            }
                        }
                    } catch(e) {
                        console.warn("Spotify: token parse error", e);
                    }
                } else if (xhr.status === 429) {
                    root.isRateLimited = true;
                    console.warn("Spotify: token refresh rate limited (429)");
                } else {
                    console.warn("Spotify: token refresh failed:", xhr.status, xhr.responseText);
                }
            }
        };

        let body = "grant_type=refresh_token&refresh_token=" + encodeURIComponent(spotifyRefreshToken);
        xhr.send(body);
    }

    function fetchCurrentlyPlaying() {
        if (!hasCredentials) return;
        if (!spotifyAccessToken) {
            refreshAccessToken(fetchCurrentlyPlaying);
            return;
        }

        let xhr = new XMLHttpRequest();
        xhr.open("GET", spotifyApiBaseUrl + "/me/player/currently-playing");
        xhr.setRequestHeader("Authorization", "Bearer " + spotifyAccessToken);

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 && xhr.responseText) {
                    try {
                        let res = JSON.parse(xhr.responseText);
                        if (res && res.item) {
                            let artists = (res.item.artists || []).map(function(a) { return a.name; }).join(", ");
                            let art = (res.item.album && res.item.album.images && res.item.album.images.length > 0) ? res.item.album.images[0].url : "";
                            let spotifyUrl = (res.item.external_urls && res.item.external_urls.spotify) ? res.item.external_urls.spotify : "";
                            let previousTrackId = root.apiCurrentTrack ? root.apiCurrentTrack.id : "";
                            let currentTrackId = res.item.id || res.item.name || "";
                            let trackChanged = previousTrackId !== "" && previousTrackId !== currentTrackId;

                            root.apiCurrentTrack = {
                                id: currentTrackId,
                                title: res.item.name || "Unknown Track",
                                artist: artists || "Unknown Artist",
                                album: (res.item.album && res.item.album.name) || "",
                                artUrl: art,
                                spotifyUrl: spotifyUrl,
                                isPlaying: Boolean(res.is_playing),
                                progress: Math.floor((res.progress_ms || 0) / 1000),
                                duration: Math.floor((res.item.duration_ms || 0) / 1000)
                            };
                            root.apiRevision++;

                            if (trackChanged) {
                                root.fetchRecentlyPlayed(10);
                            }
                        }
                    } catch(e) {
                        console.warn("Spotify: current playing parse error", e);
                    }
                } else if (xhr.status === 204) {
                    // Idle (nothing currently streaming)
                    root.apiCurrentTrack = null;
                    root.apiRevision++;
                } else if (xhr.status === 401) {
                    root.spotifyAccessToken = "";
                    root.refreshAccessToken(root.fetchCurrentlyPlaying);
                } else if (xhr.status === 429) {
                    root.isRateLimited = true;
                    console.warn("Spotify: currently playing rate limited (429)");
                }
            }
        };

        xhr.send();
    }

    function fetchRecentlyPlayed(limit) {
        if (!hasCredentials) return;
        if (!spotifyAccessToken) {
            refreshAccessToken(function() { root.fetchRecentlyPlayed(limit); });
            return;
        }

        let count = limit || 10;
        let xhr = new XMLHttpRequest();
        xhr.open("GET", spotifyApiBaseUrl + "/me/player/recently-played?limit=" + count);
        xhr.setRequestHeader("Authorization", "Bearer " + spotifyAccessToken);

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 && xhr.responseText) {
                    try {
                        let res = JSON.parse(xhr.responseText);
                        if (res && res.items) {
                            let list = [];
                            for (let i = 0; i < res.items.length; i++) {
                                let item = res.items[i];
                                let trk = item.track;
                                if (!trk) continue;
                                let artists = (trk.artists || []).map(function(a) { return a.name; }).join(", ");
                                let art = (trk.album && trk.album.images && trk.album.images.length > 0) ? trk.album.images[0].url : "";
                                let spotifyUrl = (trk.external_urls && trk.external_urls.spotify) ? trk.external_urls.spotify : "";
                                let durSec = Math.floor((trk.duration_ms || 0) / 1000);
                                list.push({
                                    title: trk.name || "Unknown Track",
                                    artist: artists || "",
                                    album: (trk.album && trk.album.name) || "",
                                    duration: root.formatTime(durSec),
                                    durationSec: durSec,
                                    playedAt: root.formatRelativeTime(item.played_at),
                                    artUrl: art,
                                    spotifyUrl: spotifyUrl
                                });
                            }
                            root.apiRecentTracks = list;
                            root.apiRevision++;
                        }
                    } catch(e) {
                        console.warn("Spotify: recently played parse error", e);
                    }
                } else if (xhr.status === 401) {
                    root.spotifyAccessToken = "";
                    root.refreshAccessToken(function() { root.fetchRecentlyPlayed(limit); });
                } else if (xhr.status === 429) {
                    root.isRateLimited = true;
                    console.warn("Spotify: recently played rate limited (429)");
                }
            }
        };

        xhr.send();
    }

    function formatRelativeTime(isoStr) {
        if (!isoStr) return "";
        try {
            let d = new Date(isoStr);
            let diffMs = (new Date()).getTime() - d.getTime();
            let diffSec = Math.floor(diffMs / 1000);
            if (diffSec < 60) return "Just now";
            let diffMin = Math.floor(diffSec / 60);
            if (diffMin < 60) return diffMin + "m ago";
            let diffHour = Math.floor(diffMin / 60);
            if (diffHour < 24) return diffHour + "h ago";
            return Math.floor(diffHour / 24) + "d ago";
        } catch(e) {
            return "";
        }
    }

    function formatTime(sec) {
        sec = Math.max(0, Math.floor(sec || 0));
        let m = Math.floor(sec / 60);
        let s = sec % 60;
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
    }

    function openSpotifyUrl(url) {
        if (!url) return;
        Quickshell.execDetached(["xdg-open", url]);
    }

    function syncData() {
        root.isRateLimited = false;
        fetchCurrentlyPlaying();
        fetchRecentlyPlayed(10);
    }

    // Live poller (polls Spotify cloud every 15 seconds while drawer tab is open)
    Timer {
        id: apiPollTimer
        interval: 15000
        repeat: true
        running: root.hasCredentials && root.isActiveTab && root.isDrawerOpen && !root.isRateLimited
        onTriggered: root.fetchCurrentlyPlaying()
    }

    // Local smooth progress bar ticker (increments 1s each second while playing)
    Timer {
        id: progressTicker
        interval: 1000
        repeat: true
        running: root.hasCredentials && root.currentIsPlaying && root.isActiveTab && root.isDrawerOpen
        onTriggered: {
            if (root.apiCurrentTrack && root.apiCurrentTrack.isPlaying) {
                root.apiCurrentTrack.progress = Math.min(root.apiCurrentTrack.duration, root.apiCurrentTrack.progress + 1);
                root.apiRevision++;
            }
        }
    }

    // =========================================================================
    // STATE PROPERTIES (PURE SPOTIFY CLOUD DATA)
    // =========================================================================
    property var apiCurrentTrack: null
    property var apiRecentTracks: []

    readonly property bool currentIsPlaying: {
        let _ = root.apiRevision;
        return apiCurrentTrack ? Boolean(apiCurrentTrack.isPlaying) : false;
    }

    readonly property string currentTitle: {
        let _ = root.apiRevision;
        if (apiCurrentTrack) return apiCurrentTrack.title || "";
        if (apiRecentTracks && apiRecentTracks.length > 0) return apiRecentTracks[0].title || "";
        return "Nothing playing";
    }

    readonly property string currentArtist: {
        let _ = root.apiRevision;
        if (apiCurrentTrack) return apiCurrentTrack.artist || "";
        if (apiRecentTracks && apiRecentTracks.length > 0) return apiRecentTracks[0].artist || "";
        return "";
    }

    readonly property string currentAlbum: {
        let _ = root.apiRevision;
        if (apiCurrentTrack) return apiCurrentTrack.album || "";
        if (apiRecentTracks && apiRecentTracks.length > 0) return apiRecentTracks[0].album || "";
        return "";
    }

    readonly property string currentArtUrl: {
        let _ = root.apiRevision;
        if (apiCurrentTrack) return apiCurrentTrack.artUrl || "";
        if (apiRecentTracks && apiRecentTracks.length > 0) return apiRecentTracks[0].artUrl || "";
        return "";
    }

    readonly property string currentSpotifyUrl: {
        let _ = root.apiRevision;
        if (apiCurrentTrack && apiCurrentTrack.spotifyUrl) return apiCurrentTrack.spotifyUrl;
        if (apiRecentTracks && apiRecentTracks.length > 0 && apiRecentTracks[0].spotifyUrl) return apiRecentTracks[0].spotifyUrl;
        return "";
    }

    readonly property real currentPosition: {
        let _ = root.apiRevision;
        return apiCurrentTrack ? (apiCurrentTrack.progress || 0) : 0;
    }

    readonly property real currentDuration: {
        let _ = root.apiRevision;
        if (apiCurrentTrack) return apiCurrentTrack.duration || 180;
        if (apiRecentTracks && apiRecentTracks.length > 0) return apiRecentTracks[0].durationSec || 180;
        return 180;
    }

    readonly property var displayRecentTracks: {
        let _ = root.apiRevision;
        if (root.apiRecentTracks && root.apiRecentTracks.length > 0) return root.apiRecentTracks.slice(0, 10);
        return [];
    }

    // =========================================================================
    // UI LAYOUT
    // =========================================================================
    Item {
        id: orientedRoot
        anchors.centerIn: parent
        width: (root.counterRotation % 180 !== 0) ? parent.height : parent.width
        height: (root.counterRotation % 180 !== 0) ? parent.width : parent.height
        rotation: root.counterRotation
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.s(12)
            spacing: root.s(8)

            // -----------------------------------------------------------------
            // HEADER BAR: Status Badge & Controls
            // -----------------------------------------------------------------
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: root.s(32)
                spacing: root.s(8)

                // Remote status pill
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: statusRow.implicitWidth + root.s(20)
                    implicitHeight: root.s(24)
                    Layout.preferredWidth: implicitWidth
                    Layout.preferredHeight: implicitHeight
                    radius: 0
                    color: !root.hasCredentials ? Qt.alpha(ThemeBackend.surface0, 0.8) : (root.isRateLimited ? Qt.alpha(ThemeBackend.red, 0.15) : (root.currentIsPlaying ? Qt.alpha("#1db954", 0.15) : Qt.alpha(ThemeBackend.surface0, 0.8)))
                    border.width: 1
                    border.color: !root.hasCredentials ? ThemeBackend.surface1 : (root.isRateLimited ? ThemeBackend.red : (root.currentIsPlaying ? "#1db954" : ThemeBackend.surface1))

                    Row {
                        id: statusRow
                        anchors.centerIn: parent
                        spacing: root.s(6)

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: root.s(6)
                            height: width
                            radius: 0
                            color: !root.hasCredentials ? ThemeBackend.overlay0 : (root.isRateLimited ? ThemeBackend.red : (root.currentIsPlaying ? "#1db954" : ThemeBackend.overlay0))

                            SequentialAnimation on opacity {
                                running: root.hasCredentials && (root.currentIsPlaying || root.isRateLimited)
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.3; duration: 800 }
                                NumberAnimation { to: 1.0; duration: 800 }
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: !root.hasCredentials ? "Not Configured" : ((root.currentIsPlaying ? "Listening Now" : "Last Played") + (root.isRateLimited ? " (Hit Rate Limit)" : ""))
                            font.family: ThemeBackend.fontFamily
                            font.pixelSize: root.s(10)
                            font.bold: true
                            color: !root.hasCredentials ? ThemeBackend.overlay1 : (root.isRateLimited ? ThemeBackend.red : (root.currentIsPlaying ? "#1db954" : ThemeBackend.subtext0))
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Sync / Refresh button
                IconButton {
                    Layout.alignment: Qt.AlignVCenter
                    size: root.s(26)
                    cornerRadius: 0
                    buttonIcon: "󰑐"
                    iconFontSize: root.s(11)
                    accentColor: ThemeBackend.surface0
                    textColor: ThemeBackend.subtext0
                    enabled: root.hasCredentials
                    opacity: root.hasCredentials ? 1.0 : 0.4
                    onClicked: root.syncData()
                }
            }

            // -----------------------------------------------------------------
            // SETUP NOTICE (Shown when credentials are not configured)
            // -----------------------------------------------------------------
            Rectangle {
                id: setupNoticeCard
                visible: !root.hasCredentials
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 0
                color: ThemeBackend.surface0
                border.width: 1
                border.color: Qt.alpha(ThemeBackend.surface1, 0.8)

                ColumnLayout {
                    anchors.centerIn: parent
                    width: parent.width - root.s(32)
                    spacing: root.s(12)

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "󰝚"
                        font.family: ThemeBackend.iconFont
                        font.pixelSize: root.s(36)
                        color: "#1db954"
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Spotify Not Configured"
                        font.family: ThemeBackend.fontFamily
                        font.pixelSize: root.s(13)
                        font.bold: true
                        color: ThemeBackend.text
                    }

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        text: "To view currently playing and recent Spotify tracks, copy spotify.json.example to spotify.json and provide your Spotify developer credentials."
                        font.family: ThemeBackend.fontFamily
                        font.pixelSize: root.s(10)
                        color: ThemeBackend.subtext0
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: setupCodeText.implicitWidth + root.s(16)
                        implicitHeight: setupCodeText.implicitHeight + root.s(10)
                        radius: 0
                        color: ThemeBackend.surface1
                        border.width: 1
                        border.color: ThemeBackend.surface2

                        Text {
                            id: setupCodeText
                            anchors.centerIn: parent
                            text: "cp ~/.config/quickshell/spotify.json.example ~/.config/quickshell/spotify.json"
                            font.family: ThemeBackend.fontFamily
                            font.pixelSize: root.s(9)
                            color: ThemeBackend.subtext1
                        }
                    }
                }
            }

            // -----------------------------------------------------------------
            // CURRENTLY PLAYING / LAST PLAYED CARD
            // -----------------------------------------------------------------
            Rectangle {
                id: playingCard
                visible: root.hasCredentials
                Layout.fillWidth: true
                Layout.preferredHeight: root.s(140)
                radius: 0
                color: ThemeBackend.surface0
                border.width: 1
                border.color: root.currentIsPlaying ? Qt.alpha("#1db954", 0.45) : Qt.alpha(ThemeBackend.surface1, 0.8)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: root.s(10)
                    spacing: root.s(12)

                    // LEFT: Sleek Modern Boxy Album Cover
                    Rectangle {
                        id: albumCoverFrame
                        Layout.preferredWidth: root.s(76)
                        Layout.preferredHeight: root.s(76)
                        Layout.alignment: Qt.AlignVCenter
                        radius: 0
                        color: "#181825"
                        border.width: 1
                        border.color: root.currentIsPlaying ? "#1db954" : Qt.alpha("#313244", 0.7)
                        clip: true

                        BoundedImage {
                            id: trackCoverImg
                            anchors.fill: parent
                            source: root.currentArtUrl || ""
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                            visible: Boolean(root.currentArtUrl && root.currentArtUrl !== "") && status === Image.Ready
                        }

                        // Fallback icon when no artwork
                        Item {
                            anchors.fill: parent
                            visible: !root.currentArtUrl || trackCoverImg.status !== Image.Ready

                            Text {
                                anchors.centerIn: parent
                                text: "󰓇"
                                font.family: ThemeBackend.iconFont
                                font.pixelSize: root.s(24)
                                color: "#1db954"
                            }
                        }

                        // Mini Equalizer Indicator in bottom corner
                        Row {
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            anchors.margins: root.s(3)
                            spacing: root.s(2)
                            visible: root.currentIsPlaying

                            Rectangle {
                                width: root.s(3)
                                height: root.s(8)
                                radius: 0
                                color: "#1db954"
                                SequentialAnimation on height {
                                    running: root.currentIsPlaying
                                    loops: Animation.Infinite
                                    NumberAnimation { to: root.s(3); duration: 350; easing.type: Easing.InOutQuad }
                                    NumberAnimation { to: root.s(10); duration: 350; easing.type: Easing.InOutQuad }
                                }
                            }
                            Rectangle {
                                width: root.s(3)
                                height: root.s(5)
                                radius: 0
                                color: "#1db954"
                                SequentialAnimation on height {
                                    running: root.currentIsPlaying
                                    loops: Animation.Infinite
                                    NumberAnimation { to: root.s(12); duration: 250; easing.type: Easing.InOutQuad }
                                    NumberAnimation { to: root.s(4); duration: 300; easing.type: Easing.InOutQuad }
                                }
                            }
                            Rectangle {
                                width: root.s(3)
                                height: root.s(10)
                                radius: 0
                                color: "#1db954"
                                SequentialAnimation on height {
                                    running: root.currentIsPlaying
                                    loops: Animation.Infinite
                                    NumberAnimation { to: root.s(4); duration: 400; easing.type: Easing.InOutQuad }
                                    NumberAnimation { to: root.s(11); duration: 300; easing.type: Easing.InOutQuad }
                                }
                            }
                        }

                        // Clicking cover opens track on Spotify
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openSpotifyUrl(root.currentSpotifyUrl)
                        }
                    }

                    // RIGHT: Track Metadata, Progress Bar & Listen Along
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: root.s(4)

                        // Title
                        Text {
                            Layout.fillWidth: true
                            text: root.currentTitle
                            font.family: ThemeBackend.fontFamily
                            font.bold: true
                            font.pixelSize: root.s(12)
                            color: ThemeBackend.text
                            elide: Text.ElideRight
                        }

                        // Artist & Album
                        Text {
                            Layout.fillWidth: true
                            text: root.currentArtist + (root.currentAlbum ? " • " + root.currentAlbum : "")
                            font.family: ThemeBackend.fontFamily
                            font.pixelSize: root.s(10)
                            color: ThemeBackend.subtext0
                            elide: Text.ElideRight
                        }

                        Item { Layout.preferredHeight: root.s(3) }

                        // Progress Slider & Timestamps
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: root.s(2)

                            // Track bar
                            Rectangle {
                                id: progressBarBg
                                Layout.fillWidth: true
                                height: root.s(4)
                                radius: 0
                                color: ThemeBackend.surface1
                                clip: true

                                Rectangle {
                                    id: progressFill
                                    height: parent.height
                                    radius: 0
                                    color: "#1db954"
                                    width: {
                                        let dur = root.currentDuration;
                                        if (dur <= 0) return 0;
                                        let frac = Math.max(0, Math.min(1, root.currentPosition / dur));
                                        return frac * progressBarBg.width;
                                    }
                                }
                            }

                            // Time Labels
                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: root.formatTime(root.currentPosition)
                                    font.family: ThemeBackend.fontFamily
                                    font.pixelSize: root.s(9)
                                    color: ThemeBackend.subtext1
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: root.formatTime(root.currentDuration)
                                    font.family: ThemeBackend.fontFamily
                                    font.pixelSize: root.s(9)
                                    color: ThemeBackend.subtext1
                                }
                            }
                        }

                        // Action Row: "Listen along" button & Open Track
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: root.s(4)
                            spacing: root.s(8)

                            // Listen Along / Open on Spotify Button
                            Rectangle {
                                id: listenAlongBtn
                                Layout.preferredHeight: root.s(26)
                                Layout.preferredWidth: listenRow.implicitWidth + root.s(16)
                                radius: 0
                                color: listenMa.containsMouse ? "#1db954" : ThemeBackend.surface1
                                border.width: 1
                                border.color: listenMa.containsMouse ? "#1db954" : Qt.alpha("#1db954", 0.4)

                                Behavior on color { ColorAnimation { duration: 150 } }

                                Row {
                                    id: listenRow
                                    anchors.centerIn: parent
                                    spacing: root.s(6)

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "󰓇"
                                        font.family: ThemeBackend.iconFont
                                        font.pixelSize: root.s(11)
                                        color: listenMa.containsMouse ? "#11111b" : "#1db954"
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Listen along"
                                        font.family: ThemeBackend.fontFamily
                                        font.bold: true
                                        font.pixelSize: root.s(10)
                                        color: listenMa.containsMouse ? "#11111b" : ThemeBackend.text
                                    }
                                }

                                MouseArea {
                                    id: listenMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.openSpotifyUrl(root.currentSpotifyUrl)
                                }
                            }

                            // Copy Spotify Link Button
                            IconButton {
                                size: root.s(26)
                                cornerRadius: 0
                                buttonIcon: "󰌹"
                                iconFontSize: root.s(11)
                                accentColor: ThemeBackend.surface1
                                textColor: ThemeBackend.subtext0
                                onClicked: {
                                    if (root.currentSpotifyUrl) {
                                        Quickshell.execDetached(["bash", "-c", "echo -n '" + root.currentSpotifyUrl + "' | wl-copy"]);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // -----------------------------------------------------------------
            // SECTION DIVIDER: Last 10 Played Songs Header
            // -----------------------------------------------------------------
            RowLayout {
                visible: root.hasCredentials
                Layout.fillWidth: true
                Layout.preferredHeight: root.s(22)
                spacing: root.s(6)

                Text {
                    text: "󰋋"
                    font.family: ThemeBackend.iconFont
                    font.pixelSize: root.s(13)
                    color: ThemeBackend.subtext0
                }

                Text {
                    text: "Recently Played"
                    font.family: ThemeBackend.fontFamily
                    font.bold: true
                    font.pixelSize: root.s(11)
                    color: ThemeBackend.subtext0
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "Last 10"
                    font.family: ThemeBackend.fontFamily
                    font.pixelSize: root.s(10)
                    color: ThemeBackend.overlay1
                }
            }

            // -----------------------------------------------------------------
            // LAST 10 PLAYED SONGS LIST (Fills remaining height, even spacing)
            // -----------------------------------------------------------------
            ListView {
                id: recentTracksList
                visible: root.hasCredentials
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: root.s(4)
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: root.displayRecentTracks

                ScrollBar.vertical: ScrollBar {
                    active: recentTracksList.moving || recentTracksList.movingVertically
                    width: root.s(4)
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: root.s(4)
                        radius: 0
                        color: ThemeBackend.surface2
                    }
                }

                delegate: Rectangle {
                    id: trackRow
                    width: recentTracksList.width
                    height: root.s(36)
                    radius: 0
                    color: rowMouse.containsMouse ? Qt.alpha(ThemeBackend.surface1, 0.6) : Qt.alpha(ThemeBackend.surface0, 0.4)
                    border.width: 1
                    border.color: rowMouse.containsMouse ? Qt.alpha("#1db954", 0.3) : "transparent"

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: root.s(8)
                            anchors.rightMargin: root.s(8)
                            spacing: root.s(8)

                            // Index badge / Album art thumbnail
                            Rectangle {
                                Layout.preferredWidth: root.s(26)
                                Layout.preferredHeight: root.s(26)
                                radius: 0
                                color: rowMouse.containsMouse ? Qt.alpha("#1db954", 0.2) : Qt.alpha(ThemeBackend.surface1, 0.6)
                                clip: true

                                BoundedImage {
                                    id: rowThumbImg
                                    anchors.fill: parent
                                    source: modelData.artUrl || ""
                                    fillMode: Image.PreserveAspectCrop
                                    visible: Boolean(modelData.artUrl && modelData.artUrl !== "") && status === Image.Ready && !rowMouse.containsMouse
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: rowMouse.containsMouse ? "󰐊" : ((rowThumbImg.status === Image.Ready && modelData.artUrl) ? "" : (index + 1))
                                    font.family: rowMouse.containsMouse ? ThemeBackend.iconFont : ThemeBackend.fontFamily
                                    font.pixelSize: root.s(10)
                                    font.bold: true
                                    color: rowMouse.containsMouse ? "#1db954" : ThemeBackend.subtext1
                                }
                            }

                            // Song Title & Artist
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.title || "Unknown Title"
                                    font.family: ThemeBackend.fontFamily
                                    font.bold: true
                                    font.pixelSize: root.s(11)
                                    color: rowMouse.containsMouse ? "#1db954" : ThemeBackend.text
                                    elide: Text.ElideRight

                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: (modelData.artist || "") + (modelData.album ? " • " + modelData.album : "")
                                    font.family: ThemeBackend.fontFamily
                                    font.pixelSize: root.s(9)
                                    color: ThemeBackend.subtext0
                                    elide: Text.ElideRight
                                }
                            }

                            // Duration / Time ago
                            Text {
                                text: modelData.duration || modelData.playedAt || ""
                                font.family: ThemeBackend.fontFamily
                                font.pixelSize: root.s(9)
                                color: ThemeBackend.subtext1
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.spotifyUrl) {
                                    root.openSpotifyUrl(modelData.spotifyUrl);
                                }
                            }
                        }
                    }
                }
            }
    }
}
