import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import Quickshell.Services.Mpris
import "../../../reusables"
import "../../../"

Item {
    id: root

    property var module: null
    property var widget: module

    property string orientation: (activeTarget && activeTarget.orientation !== undefined) ? activeTarget.orientation : "horizontal"
    readonly property bool isVertical: orientation === "vertical"

    readonly property var activeTarget: widget || module
    readonly property bool isCompact: activeTarget ? activeTarget.isCompact : false
    readonly property var barWindow: activeTarget ? activeTarget.barWindow : null
    readonly property bool isPreview: activeTarget ? Boolean(activeTarget.isPreview) : false
    readonly property bool isRightBar: module ? module.isRightBar : (barWindow ? (barWindow.barPosition === "right") : false)
    readonly property real barOpacity: (module && module.barOpacity !== undefined) ? module.barOpacity : ((barWindow && barWindow.barOpacity !== undefined) ? barWindow.barOpacity : ThemeBackend.elementOpacity)

    property int configRevision: 0

    Connections {
        target: (typeof Config !== "undefined") ? Config : null
        function onSettingsLoaded() { root.configRevision++; }
        function onRawSettingsChanged() { root.configRevision++; }
    }

    function readBool(widgetKey, configKey) {
        if (widget && widget !== root && widget[widgetKey] !== undefined) return Boolean(widget[widgetKey]);
        if (module && module[widgetKey] !== undefined) return Boolean(module[widgetKey]);
        let dummy = configRevision;
        if (typeof Config !== "undefined" && Config.rawSettings && Config.rawSettings.bar) {
            let bs = Config.rawSettings.bar;
            if (bs[configKey] !== undefined) return Boolean(bs[configKey]);
        }
        return true;
    }

    function readValue(widgetKey, configKey, fallback) {
        if (widget && widget !== root && widget[widgetKey] !== undefined) return widget[widgetKey];
        if (module && module[widgetKey] !== undefined) return module[widgetKey];
        let dummy = configRevision;
        if (typeof Config !== "undefined" && Config.rawSettings && Config.rawSettings.bar) {
            let bs = Config.rawSettings.bar;
            if (bs[configKey] !== undefined) return bs[configKey];
        }
        return fallback;
    }

    readonly property string infoMode: readValue("mediaInfoMode", "mediaInfoMode", "duration")
    readonly property real configuredWidth: Number(readValue("mediaWidth", "mediaWidth", 120))
    readonly property bool showControls: readBool("mediaShowControls", "mediaShowControls")
    readonly property bool hideWhenIdle: Boolean(readValue("mediaHideWhenIdle", "mediaHideWhenIdle", false))
    readonly property bool idleHidden: hideWhenIdle && !isPreview && !isMediaActive
    readonly property bool isFaceVisible: !idleHidden
    readonly property bool showIcon: isVertical ? (readBool("mediaShowIcon", "mediaShowIcon") || !showControls) : readBool("mediaShowIcon", "mediaShowIcon")

    property var player: MprisController.activePlayer
    readonly property bool hasArt: !isPreview && isMediaActive && !!MprisController.artUrl

    property var playerList: {
        if (!Mpris.players || !Mpris.players.values) return [];
        let list = [];
        let vals = Mpris.players.values;
        for (let i = 0; i < vals.length; i++) {
            if (vals[i]) list.push(vals[i]);
        }
        return list;
    }

    property var manualPlayer: null

    property var targetPlayer: {
        if (manualPlayer) {
            for (let i = 0; i < playerList.length; i++) {
                if (playerList[i] === manualPlayer) return manualPlayer;
            }
        }
        return MprisController.activePlayer;
    }

    property bool hasTargetPlayer: targetPlayer !== null
    property bool isMediaActive: isVertical
        ? (targetPlayer !== null && targetPlayer.playbackState !== MprisPlaybackState.Stopped && targetPlayer.trackTitle !== "")
        : (isPreview || (player !== null && player.playbackState !== MprisPlaybackState.Stopped && player.trackTitle !== ""))
    readonly property bool isPlaying: isVertical
        ? (targetPlayer ? (targetPlayer.playbackState === MprisPlaybackState.Playing || targetPlayer.isPlaying) : false)
        : (isPreview || (isMediaActive && (player ? (player.playbackState === MprisPlaybackState.Playing || player.isPlaying) : MprisController.isPlaying)))

    property string rawArtUrl: {
        if (!targetPlayer) return "";
        if (targetPlayer === MprisController.activePlayer) {
            return MprisController.artUrl;
        }
        return targetPlayer.trackArtUrl || "";
    }

    property string activeArtUrl: {
        if (isPreview || !rawArtUrl) return "";
        if (rawArtUrl.startsWith("file://") || rawArtUrl.startsWith("http")) return rawArtUrl;
        return "file://" + rawArtUrl;
    }

    function sc(v) { return barWindow ? barWindow.cs(v) : v; }

    readonly property string singleLineMediaText: {
        if (root.isPreview) return "Song title • Song author";
        if (!isMediaActive) return I18n.t("music.nothing_playing", "Nothing playing");
        let title = (player && player.trackTitle) ? player.trackTitle.trim() : "";
        let artist = (player && player.trackArtist) ? player.trackArtist.trim() : "";
        if (title && artist) return title + " • " + artist;
        return title || artist || "";
    }

    TextMetrics {
        id: mediaTextMetrics
        font.family: ThemeBackend.fontFamily
        font.weight: Font.Normal
        font.pixelSize: barWindow ? barWindow.cs(root.isCompact ? 11 : 12) : (root.isCompact ? 11 : 12)
        text: root.singleLineMediaText
    }

    readonly property real maxMediaWidth: barWindow ? barWindow.cs(350) : 350
    readonly property real minMediaWidth: barWindow ? barWindow.cs(40) : 40
    property real dynamicColWidth: Math.max(minMediaWidth, Math.min(maxMediaWidth, Math.ceil(mediaTextMetrics.width) + (barWindow ? barWindow.cs(6) : 6)))

    property real colWidth: isVertical ? (barWindow ? barWindow.cs(configuredWidth - (isCompact ? 4 : 0)) : (configuredWidth - (isCompact ? 4 : 0))) : dynamicColWidth
    property real innerSpacing: barWindow ? barWindow.cs(isCompact ? 6 : 8) : (isCompact ? 6 : 8)
    property real btnSpacing: barWindow ? barWindow.cs(isCompact ? 3 : 4) : (isCompact ? 3 : 4)
    property real sidePadding: barWindow ? barWindow.cs(isCompact ? 6 : 8) : (isCompact ? 6 : 8)

    property real baseHeight: {
        let h = sc(isCompact ? 8 : 9);
        if (showIcon) h += sc(isCompact ? 26 : 28);
        if (showIcon && showControls) h += sc(isCompact ? 4 : 5);
        if (showControls) h += sc(isCompact ? 74 : 80) + sc(isCompact ? 6 : 8);
        return h;
    }

    property real targetLength: {
        if (module && !module.moduleActive) return 0;
        if (idleHidden) return 0;
        if (isVertical) return baseHeight;
        let iconW = 0;
        if (showIcon) {
            let thumbW = barWindow ? barWindow.cs(root.isCompact ? 26 : 28) : (root.isCompact ? 26 : 28);
            let gapInfo = barWindow ? barWindow.cs(root.isCompact ? 6 : 8) : (root.isCompact ? 6 : 8);
            iconW = thumbW + gapInfo;
        }
        let btnW = 0;
        if (showControls) {
            btnW = (barWindow ? barWindow.cs(isCompact ? 28 : 30) : (isCompact ? 28 : 30)) * 3 + btnSpacing * 2 + innerSpacing;
        }
        let margins = sidePadding * 2;
        return iconW + colWidth + btnW + margins;
    }

    implicitWidth: isVertical ? (isPreview ? (barWindow ? barWindow.cs(56) : 56) : (activeTarget ? activeTarget.width : 0)) : targetLength
    implicitHeight: isVertical ? targetLength : (barWindow ? barWindow.cs(isCompact ? 40 : 44) : (isCompact ? 40 : 44))

    function formatTime(sec) {
        sec = Math.floor(sec || 0);
        let m = Math.floor(sec / 60), s = sec % 60;
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
    }

    function togglePlayPause() {
        let p = root.targetPlayer || root.player;
        if (p) {
            if (p.canTogglePlaying) {
                p.togglePlaying();
            } else if (p.isPlaying && p.canPause) {
                p.pause();
            } else if (!p.isPlaying && p.canPlay) {
                p.play();
            } else if (typeof p.togglePlaying === "function") {
                p.togglePlaying();
            } else {
                Quickshell.execDetached(["playerctl", "play-pause"]);
            }
        } else {
            Quickshell.execDetached(["playerctl", "play-pause"]);
        }
    }

    Loader {
        anchors.fill: parent
        sourceComponent: root.isVertical ? verticalBody : horizontalBody
    }

    Component {
        id: horizontalBody

        Item {
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton || mouse.button === Qt.MiddleButton) {
                        if (Caching.quickshellDir) {
                            Quickshell.execDetached(["bash", "-c", Caching.quickshellDir + "/scripts/qs_manager.sh toggle music"]);
                        }
                    } else {
                        root.togglePlayPause();
                    }
                }
            }

            Item {
                id: mediaLayoutContainer
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: root.sidePadding
                anchors.right: parent.right
                anchors.rightMargin: root.sidePadding
                height: parent.height
                clip: true

                Row {
                    id: innerMediaLayout
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: root.innerSpacing

                    MouseArea {
                        id: mediaInfoMouse
                        width: root.showControls ? infoLayout.implicitWidth : mediaLayoutContainer.width
                        height: mediaLayoutContainer.height
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton || mouse.button === Qt.MiddleButton) {
                                if (Caching.quickshellDir) {
                                    Quickshell.execDetached(["bash", "-c", Caching.quickshellDir + "/scripts/qs_manager.sh toggle music"]);
                                }
                            } else {
                                root.togglePlayPause();
                            }
                        }

                        Row {
                            id: infoLayout
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: barWindow ? barWindow.cs(root.isCompact ? 8 : 10) : (root.isCompact ? 8 : 10)
                            transformOrigin: Item.Left

                            scale: mediaInfoMouse.containsMouse ? 1.01 : 1.0
                            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

                            Item {
                                id: mediaThumbBox
                                visible: root.showIcon
                                width: barWindow ? barWindow.cs(root.isCompact ? 26 : 28) : (root.isCompact ? 26 : 28)
                                height: width
                                anchors.verticalCenter: parent.verticalCenter
                                opacity: root.isPlaying ? 1.0 : 0.6
                                Behavior on opacity { NumberAnimation { duration: 250 } }

                                Item {
                                    id: albumArtDisc
                                    anchors.fill: parent
                                    transformOrigin: Item.Center
                                    layer.enabled: true
                                    layer.smooth: true

                                    NumberAnimation on rotation {
                                        from: 0
                                        to: 360
                                        duration: 12000
                                        loops: Animation.Infinite
                                        running: root.isMediaActive
                                        paused: running && !root.isPlaying
                                    }

                                    Rectangle {
                                        id: discBase
                                        anchors.fill: parent
                                        radius: width / 2
                                        color: ThemeBackend.surface1 || "#313244"
                                        antialiasing: true
                                        smooth: true
                                    }

                                    Rectangle {
                                        id: discMask
                                        anchors.fill: parent
                                        radius: width / 2
                                        visible: false
                                        layer.enabled: true
                                    }

                                    Item {
                                        id: mediaArtContainer
                                        anchors.fill: parent
                                        layer.enabled: true
                                        layer.effect: MultiEffect {
                                            maskEnabled: true
                                            maskSource: discMask
                                        }

                                        Image {
                                            id: mediaArtImg
                                            anchors.fill: parent
                                            source: root.hasArt ? (MprisController.artUrl.startsWith("file://") || MprisController.artUrl.startsWith("http") ? MprisController.artUrl : "file://" + MprisController.artUrl) : ""
                                            fillMode: Image.PreserveAspectCrop
                                            antialiasing: true
                                            smooth: true
                                            asynchronous: true
                                            cache: true
                                            opacity: root.hasArt && status === Image.Ready ? 1.0 : 0.0
                                            Behavior on opacity { NumberAnimation { duration: 250 } }
                                        }
                                    }

                                    Rectangle {
                                        id: discBorderOverlay
                                        anchors.fill: parent
                                        radius: width / 2
                                        color: "transparent"
                                        border.width: 1.5
                                        border.color: root.isPlaying ? ThemeBackend.mauve : Qt.alpha(ThemeBackend.mauve, 0.35)
                                        antialiasing: true
                                        smooth: true
                                        z: 3

                                        Behavior on border.color { ColorAnimation { duration: 300 } }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰎈"
                                        font.family: ThemeBackend.iconFont
                                        font.pixelSize: barWindow ? barWindow.cs(root.isCompact ? 12 : 13) : (root.isCompact ? 12 : 13)
                                        color: root.isPlaying ? ThemeBackend.mauve : Qt.alpha(ThemeBackend.mauve, 0.5)
                                        visible: !root.hasArt || (mediaArtImg.status !== Image.Ready)
                                        z: 2
                                    }
                                }
                            }

                            MarqueeText {
                                id: singleLineMarquee
                                anchors.verticalCenter: parent.verticalCenter
                                width: root.colWidth
                                text: root.singleLineMediaText
                                color: root.isPlaying ? ThemeBackend.mauve : Qt.alpha(ThemeBackend.mauve, 0.5)
                                opacity: root.isPlaying ? 1.0 : 0.6
                                font.family: ThemeBackend.fontFamily
                                font.weight: Font.Normal
                                font.pixelSize: barWindow ? barWindow.cs(root.isCompact ? 11 : 12) : (root.isCompact ? 11 : 12)
                                marqueeSpacing: barWindow ? barWindow.cs(40) : 40
                                speed: 30
                                active: Boolean(root.visible && (!barWindow || barWindow.visible) && (!module || module.moduleActive) && root.isPlaying)

                                Behavior on color { ColorAnimation { duration: 250 } }
                                Behavior on opacity { NumberAnimation { duration: 250 } }
                            }
                        }
                    }

                    Row {
                        id: buttonRow
                        visible: root.showControls
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: root.btnSpacing

                        IconButton {
                            id: prevMediaButton
                            height: barWindow ? barWindow.cs(root.isCompact ? 28 : 30) : (root.isCompact ? 28 : 30)
                            width: barWindow ? barWindow.cs(root.isCompact ? 28 : 30) : (root.isCompact ? 28 : 30)
                            cornerRadius: barWindow ? barWindow.cs(root.isCompact ? 9 : 10) : (root.isCompact ? 9 : 10)
                            buttonIcon: "󰒮"
                            iconFontSize: barWindow ? barWindow.cs(root.isCompact ? 7 : 8) : (root.isCompact ? 7 : 8)
                            accentColor: root.isCompact ? Qt.lighter(ThemeBackend.surface0, 1.18) : ThemeBackend.surface0
                            bgOpacity: ThemeBackend.liquidGlass ? 1.0 : root.barOpacity
                            textColor: isHoveredOrHighlighted ? ThemeBackend.text : (root.isCompact ? ThemeBackend.subtext0 : ThemeBackend.overlay2)
                            anchors.verticalCenter: parent.verticalCenter
                            onClicked: if (player && player.canGoPrevious) player.previous()
                        }

                        IconButton {
                            id: playMediaButton
                            height: barWindow ? barWindow.cs(root.isCompact ? 28 : 30) : (root.isCompact ? 28 : 30)
                            width: barWindow ? barWindow.cs(root.isCompact ? 28 : 30) : (root.isCompact ? 28 : 30)
                            cornerRadius: barWindow ? barWindow.cs(root.isCompact ? 9 : 10) : (root.isCompact ? 9 : 10)
                            buttonIcon: root.isPlaying ? "󰏤" : "󰐊"
                            iconFontSize: barWindow ? barWindow.cs(root.isCompact ? 9 : 10) : (root.isCompact ? 9 : 10)
                            accentColor: root.isCompact ? Qt.lighter(ThemeBackend.surface0, 1.18) : ThemeBackend.surface0
                            bgOpacity: ThemeBackend.liquidGlass ? 1.0 : root.barOpacity
                            textColor: isHoveredOrHighlighted ? ThemeBackend.green : (root.isCompact ? Qt.lighter(ThemeBackend.text, 1.1) : ThemeBackend.text)
                            anchors.verticalCenter: parent.verticalCenter
                            onClicked: if (player && player.canTogglePlaying) player.togglePlaying()
                        }

                        IconButton {
                            id: nextMediaButton
                            height: barWindow ? barWindow.cs(root.isCompact ? 28 : 30) : (root.isCompact ? 28 : 30)
                            width: barWindow ? barWindow.cs(root.isCompact ? 28 : 30) : (root.isCompact ? 28 : 30)
                            cornerRadius: barWindow ? barWindow.cs(root.isCompact ? 9 : 10) : (root.isCompact ? 9 : 10)
                            buttonIcon: "󰒭"
                            iconFontSize: barWindow ? barWindow.cs(root.isCompact ? 7 : 8) : (root.isCompact ? 7 : 8)
                            accentColor: root.isCompact ? Qt.lighter(ThemeBackend.surface0, 1.18) : ThemeBackend.surface0
                            bgOpacity: ThemeBackend.liquidGlass ? 1.0 : root.barOpacity
                            textColor: isHoveredOrHighlighted ? ThemeBackend.text : (root.isCompact ? ThemeBackend.subtext0 : ThemeBackend.overlay2)
                            anchors.verticalCenter: parent.verticalCenter
                            onClicked: if (player && player.canGoNext) player.next()
                        }
                    }
                }
            }
        }
    }

    Component {
        id: verticalBody

        Item {
            MouseArea {
                id: widgetMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: {
                    let targetItem = module ? module : root;
                    let pt = targetItem.mapToItem(null, 0, 0);
                    let globX = root.isRightBar ? pt.x : (pt.x + targetItem.width);
                    let globY = pt.y + (targetItem.height / 2);
                    SideMusicController.itemEntered(barWindow ? barWindow.screen : null, globX, globY, root.isRightBar, false, true);
                }
                onExited: {
                    SideMusicController.itemExited();
                }
                onClicked: {
                    let targetItem = module ? module : root;
                    let pt = targetItem.mapToItem(null, 0, 0);
                    let globX = root.isRightBar ? pt.x : (pt.x + targetItem.width);
                    let globY = pt.y + (targetItem.height / 2);
                    SideMusicController.toggle(barWindow ? barWindow.screen : null, globX, globY, root.isRightBar, false, true);
                }
            }

            Column {
                id: baseCol
                anchors.centerIn: parent
                spacing: barWindow ? barWindow.cs(root.isCompact ? 4 : 5) : (root.isCompact ? 4 : 5)

                Rectangle {
                    id: thumbBox
                    visible: root.showIcon
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: barWindow ? barWindow.cs(root.isCompact ? 26 : 28) : (root.isCompact ? 26 : 28)
                    height: barWindow ? barWindow.cs(root.isCompact ? 26 : 28) : (root.isCompact ? 26 : 28)
                    radius: barWindow ? barWindow.cs(root.isCompact ? 7 : 8) : (root.isCompact ? 7 : 8)
                    color: sideThumbGlass.active ? "transparent" : (root.isCompact ? Qt.lighter(ThemeBackend.surface1, 1.1) : ThemeBackend.surface1)
                    clip: !sideThumbGlass.active

                    GlassFill {
                        id: sideThumbGlass
                        anchors.fill: parent
                        radius: parent.radius
                        tintColor: ThemeBackend.surface1
                        tintAmount: 0.3
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "󰎈"
                        font.family: ThemeBackend.fontFamily
                        font.pixelSize: barWindow ? barWindow.cs(root.isCompact ? 12 : 13) : (root.isCompact ? 12 : 13)
                        color: root.isCompact ? ThemeBackend.text : ThemeBackend.subtext0
                        visible: !isMediaActive || root.activeArtUrl === "" || (sideArtImg.status !== Image.Ready)
                    }

                    Rectangle {
                        id: sideArtMask
                        anchors.fill: parent
                        radius: thumbBox.radius
                        visible: false
                        layer.enabled: true
                    }

                    Item {
                        id: sideArtContainer
                        anchors.fill: parent
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskSource: sideArtMask
                        }

                        Image {
                            id: sideArtImg
                            anchors.fill: parent
                            source: isMediaActive ? root.activeArtUrl : ""
                            fillMode: Image.PreserveAspectCrop
                            antialiasing: true
                            smooth: true
                            asynchronous: true
                            cache: true
                            opacity: isMediaActive && root.activeArtUrl !== "" && status === Image.Ready ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 250 } }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: ThemeBackend.surface0
                        opacity: 0.15
                        visible: isMediaActive && root.activeArtUrl !== "" && sideArtImg.status === Image.Ready
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton || mouse.button === Qt.MiddleButton) {
                                if (Caching.quickshellDir) {
                                    Quickshell.execDetached(["bash", "-c", Caching.quickshellDir + "/scripts/qs_manager.sh toggle music"]);
                                }
                            } else {
                                root.togglePlayPause();
                            }
                        }
                    }
                }

                Column {
                    visible: root.showControls
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: barWindow ? barWindow.cs(root.isCompact ? 3 : 4) : (root.isCompact ? 3 : 4)

                    IconButton {
                        width: barWindow ? barWindow.cs(root.isCompact ? 24 : 26) : (root.isCompact ? 24 : 26)
                        height: barWindow ? barWindow.cs(root.isCompact ? 24 : 26) : (root.isCompact ? 24 : 26)
                        cornerRadius: barWindow ? barWindow.cs(root.isCompact ? 7 : 8) : (root.isCompact ? 7 : 8)
                        buttonIcon: "󰒮"
                        iconFontSize: barWindow ? barWindow.cs(root.isCompact ? 6 : 7) : (root.isCompact ? 6 : 7)
                        accentColor: root.isCompact ? Qt.lighter(ThemeBackend.surface0, 1.18) : ThemeBackend.surface0
                        bgOpacity: ThemeBackend.liquidGlass ? 1.0 : root.barOpacity
                        textColor: isHoveredOrHighlighted ? ThemeBackend.text : (root.isCompact ? ThemeBackend.subtext0 : ThemeBackend.overlay2)
                        anchors.horizontalCenter: parent.horizontalCenter
                        onClicked: if (targetPlayer && targetPlayer.canGoPrevious) targetPlayer.previous()
                    }

                    IconButton {
                        width: barWindow ? barWindow.cs(root.isCompact ? 26 : 28) : (root.isCompact ? 26 : 28)
                        height: barWindow ? barWindow.cs(root.isCompact ? 26 : 28) : (root.isCompact ? 26 : 28)
                        cornerRadius: barWindow ? barWindow.cs(root.isCompact ? 7 : 8) : (root.isCompact ? 7 : 8)
                        buttonIcon: (isMediaActive && isPlaying) ? "󰏤" : "󰐊"
                        iconFontSize: barWindow ? barWindow.cs(root.isCompact ? 8 : 9) : (root.isCompact ? 8 : 9)
                        accentColor: root.isCompact ? Qt.lighter(ThemeBackend.surface0, 1.18) : ThemeBackend.surface0
                        bgOpacity: ThemeBackend.liquidGlass ? 1.0 : root.barOpacity
                        textColor: isHoveredOrHighlighted ? ThemeBackend.green : (root.isCompact ? Qt.lighter(ThemeBackend.text, 1.1) : ThemeBackend.text)
                        anchors.horizontalCenter: parent.horizontalCenter
                        onClicked: if (targetPlayer && targetPlayer.canTogglePlaying) targetPlayer.togglePlaying()
                    }

                    IconButton {
                        width: barWindow ? barWindow.cs(root.isCompact ? 24 : 26) : (root.isCompact ? 24 : 26)
                        height: barWindow ? barWindow.cs(root.isCompact ? 24 : 26) : (root.isCompact ? 24 : 26)
                        cornerRadius: barWindow ? barWindow.cs(root.isCompact ? 7 : 8) : (root.isCompact ? 7 : 8)
                        buttonIcon: "󰒭"
                        iconFontSize: barWindow ? barWindow.cs(root.isCompact ? 6 : 7) : (root.isCompact ? 6 : 7)
                        accentColor: root.isCompact ? Qt.lighter(ThemeBackend.surface0, 1.18) : ThemeBackend.surface0
                        bgOpacity: ThemeBackend.liquidGlass ? 1.0 : root.barOpacity
                        textColor: isHoveredOrHighlighted ? ThemeBackend.text : (root.isCompact ? ThemeBackend.subtext0 : ThemeBackend.overlay2)
                        anchors.horizontalCenter: parent.horizontalCenter
                        onClicked: if (targetPlayer && targetPlayer.canGoNext) targetPlayer.next()
                    }
                }
            }
        }
    }
}
