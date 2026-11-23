import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../reusables"
import "../../"

Item {
    id: root

    property int requestedLayoutTemplate: 1
    property bool isActiveTab: typeof isCurrentTarget !== "undefined" ? isCurrentTarget : true
    property string safeActiveEdge: typeof activeEdge !== "undefined" ? activeEdge : "left"

    function s(val) {
        return typeof scaleFunc === "function" ? scaleFunc(val) : val;
    }

    property real baseW: s(330)
    property real baseL: s(320)

    property real preferredWidth: (root.safeActiveEdge === "bottom" || root.safeActiveEdge === "top") ? baseL + s(60) : baseW
    property real preferredExtraLength: (root.safeActiveEdge === "bottom" || root.safeActiveEdge === "top") ? baseW : baseL

    property real counterRotation: {
        if (root.safeActiveEdge === "right") return 180;
        if (root.safeActiveEdge === "bottom") return 90;
        if (root.safeActiveEdge === "top") return -90;
        return 0;
    }

    property bool widgetVisible: parent !== null && parent.visible !== undefined ? parent.visible : true

    property int totalSeconds: 0
    property string peakUsageStr: ""
    property var appsList: []
    property bool statsLoaded: false

    readonly property var themePalette: [
        ThemeBackend.mauve,
        ThemeBackend.sapphire,
        ThemeBackend.blue,
        ThemeBackend.teal,
        ThemeBackend.green,
        ThemeBackend.peach,
        ThemeBackend.yellow,
        ThemeBackend.red
    ]

    function getPaletteColor(index) {
        return themePalette[index % themePalette.length];
    }

    function formatTime(secs) {
        if (!secs || secs <= 0) return "0m";
        let h = Math.floor(secs / 3600);
        let m = Math.floor((secs % 3600) / 60);
        let remS = secs % 60;
        if (h > 0) {
            return m > 0 ? (h + "h " + m + "m") : (h + "h");
        }
        if (m > 0) {
            return remS > 0 ? (m + "m " + remS + "s") : (m + "m");
        }
        return remS + "s";
    }

    function formatAppName(name, cls) {
        let raw = (name && name.length > 0 && name !== cls) ? name : cls;
        if (!raw || raw.length === 0) return "Unknown";
        let str = raw.replace(/[-_.]/g, " ");
        return str.charAt(0).toUpperCase() + str.slice(1);
    }

    function getAppIcon(appClass, appName) {
        let c = ((appClass || "") + " " + (appName || "")).toLowerCase();
        if (c.indexOf("zen") !== -1 || c.indexOf("firefox") !== -1 || c.indexOf("chrome") !== -1 || c.indexOf("browser") !== -1) return "󰈹";
        if (c.indexOf("kitty") !== -1 || c.indexOf("terminal") !== -1 || c.indexOf("alacritty") !== -1 || c.indexOf("foot") !== -1 || c.indexOf("wezterm") !== -1) return "󰆍";
        if (c.indexOf("spotify") !== -1 || c.indexOf("music") !== -1) return "󰓇";
        if (c.indexOf("code") !== -1 || c.indexOf("nvim") !== -1 || c.indexOf("vim") !== -1 || c.indexOf("emacs") !== -1) return "󰨞";
        if (c.indexOf("discord") !== -1 || c.indexOf("vesktop") !== -1) return "󰙯";
        if (c.indexOf("telegram") !== -1) return "󰏲";
        if (c.indexOf("obsidian") !== -1 || c.indexOf("notes") !== -1) return "󰈙";
        if (c.indexOf("beeper") !== -1) return "󰍡";
        if (c.indexOf("yazi") !== -1 || c.indexOf("thunar") !== -1 || c.indexOf("nautilus") !== -1 || c.indexOf("files") !== -1) return "󰉋";
        if (c.indexOf("steam") !== -1 || c.indexOf("game") !== -1 || c.indexOf("lutris") !== -1) return "󰓓";
        return "󰣆";
    }

    Process {
        id: screentimePoller
        command: ["jalpari-core", "screentime", "stats"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let out = this.text.trim();
                    if (out.length > 0) {
                        let data = JSON.parse(out);
                        root.totalSeconds = data.total || 0;
                        root.peakUsageStr = data.peak_usage_str || "";
                        root.appsList = data.apps || [];
                        root.statsLoaded = true;
                    }
                } catch (e) {}
            }
        }
    }

    Process {
        id: trackerStarter
        command: ["sh", "-c", "pgrep -f 'jalpari-core screentime track' >/dev/null || nohup jalpari-core screentime track >/dev/null 2>&1 &"]
        running: false
    }

    Timer {
        id: pollTimer
        interval: 2500
        repeat: true
        running: root.isActiveTab && root.widgetVisible
        onTriggered: {
            if (!screentimePoller.running) screentimePoller.running = true;
        }
    }

    onWidgetVisibleChanged: {
        if (root.widgetVisible && root.isActiveTab) {
            trackerStarter.running = true;
            screentimePoller.running = true;
        }
    }

    onIsActiveTabChanged: {
        if (root.isActiveTab && root.widgetVisible) {
            trackerStarter.running = true;
            screentimePoller.running = true;
        }
    }

    Component.onCompleted: {
        trackerStarter.running = true;
        screentimePoller.running = true;
    }

    Item {
        id: orientedRoot
        anchors.centerIn: parent
        width: (root.counterRotation % 180 !== 0) ? parent.height : parent.width
        height: (root.counterRotation % 180 !== 0) ? parent.width : parent.height
        rotation: root.counterRotation
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.s(10)
            spacing: root.s(8)

            // Header Hero Card
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: root.s(68)
                radius: Math.min(ThemeBackend.borderRadius, root.s(12))
                color: ThemeBackend.surface0
                border.width: 1
                border.color: ThemeBackend.surface1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: root.s(10)
                    spacing: root.s(10)

                    Rectangle {
                        Layout.preferredWidth: root.s(42)
                        Layout.preferredHeight: root.s(42)
                        radius: root.s(10)
                        color: Qt.alpha(ThemeBackend.mauve, 0.18)

                        Text {
                            anchors.centerIn: parent
                            text: "󰄉"
                            font.family: ThemeBackend.iconFont
                            font.pixelSize: root.s(22)
                            color: ThemeBackend.mauve
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: root.s(2)

                        Text {
                            text: typeof I18n !== "undefined" ? I18n.t("quickactions.tabs.wellbeing", "Screen Time") : "Screen Time"
                            font.family: ThemeBackend.fontFamily
                            font.pixelSize: root.s(11)
                            font.weight: Font.DemiBold
                            color: ThemeBackend.subtext0
                        }

                        Text {
                            text: root.formatTime(root.totalSeconds)
                            font.family: ThemeBackend.fontFamily
                            font.pixelSize: root.s(18)
                            font.weight: Font.Bold
                            color: ThemeBackend.text
                        }
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredHeight: root.s(24)
                        Layout.preferredWidth: badgeRow.implicitWidth + root.s(12)
                        radius: root.s(12)
                        color: ThemeBackend.surface1
                        visible: root.appsList.length > 0

                        RowLayout {
                            id: badgeRow
                            anchors.centerIn: parent
                            spacing: root.s(4)

                            Text {
                                text: "󰍛"
                                font.family: ThemeBackend.iconFont
                                font.pixelSize: root.s(10)
                                color: ThemeBackend.subtext0
                            }

                            Text {
                                text: root.appsList.length + " " + (root.appsList.length === 1 ? "app" : "apps")
                                font.family: ThemeBackend.fontFamily
                                font.pixelSize: root.s(10)
                                font.weight: Font.Medium
                                color: ThemeBackend.text
                            }
                        }
                    }
                }
            }

            // App List Section
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Empty State
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: root.s(8)
                    visible: root.statsLoaded && root.appsList.length === 0

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "󰄉"
                        font.family: ThemeBackend.iconFont
                        font.pixelSize: root.s(32)
                        color: ThemeBackend.subtext0
                        opacity: 0.5
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "No active screen time today"
                        font.family: ThemeBackend.fontFamily
                        font.pixelSize: root.s(12)
                        font.weight: Font.Medium
                        color: ThemeBackend.subtext0
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Tracking active in-focus windows"
                        font.family: ThemeBackend.fontFamily
                        font.pixelSize: root.s(10)
                        color: ThemeBackend.surface2
                    }
                }

                // Apps ListView
                ListView {
                    id: appListView
                    anchors.fill: parent
                    clip: true
                    spacing: root.s(6)
                    model: root.appsList
                    visible: root.appsList.length > 0
                    boundsBehavior: Flickable.StopAtBounds

                    ScrollBar.vertical: ScrollBar {
                        active: appListView.moving || appListView.movingVertically
                        policy: ScrollBar.AsNeeded
                    }

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        width: appListView.width - (appListView.contentHeight > appListView.height ? root.s(8) : 0)
                        height: root.s(44)
                        radius: Math.min(ThemeBackend.borderRadius, root.s(8))
                        color: ThemeBackend.surface0

                        readonly property color appColor: root.getPaletteColor(index)
                        readonly property real appPercent: (modelData.percent !== undefined) ? modelData.percent : (root.totalSeconds > 0 ? ((modelData.seconds || 0) / root.totalSeconds * 100) : 0)

                        // Subtle progress fill background
                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: Math.max(0, parent.width * Math.min(1.0, appPercent / 100.0))
                            radius: parent.radius
                            color: Qt.alpha(appColor, 0.12)
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: root.s(8)
                            anchors.rightMargin: root.s(10)
                            spacing: root.s(8)

                            // App Icon Box
                            Rectangle {
                                Layout.preferredWidth: root.s(28)
                                Layout.preferredHeight: root.s(28)
                                radius: root.s(6)
                                color: Qt.alpha(appColor, 0.22)

                                Text {
                                    anchors.centerIn: parent
                                    text: root.getAppIcon(modelData.class, modelData.name)
                                    font.family: ThemeBackend.iconFont
                                    font.pixelSize: root.s(15)
                                    color: appColor
                                }
                            }

                            // App Name & Progress Indicator
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: root.s(2)

                                RowLayout {
                                    Layout.fillWidth: true

                                    Text {
                                        Layout.fillWidth: true
                                        text: root.formatAppName(modelData.name, modelData.class)
                                        font.family: ThemeBackend.fontFamily
                                        font.pixelSize: root.s(12)
                                        font.weight: Font.DemiBold
                                        color: ThemeBackend.text
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: root.formatTime(modelData.seconds || 0)
                                        font.family: ThemeBackend.fontFamily
                                        font.pixelSize: root.s(11)
                                        font.weight: Font.Bold
                                        color: appColor
                                    }
                                }

                                // Thin progress bar line
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: root.s(3)
                                    radius: root.s(1.5)
                                    color: ThemeBackend.surface1

                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        width: Math.max(root.s(3), parent.width * Math.min(1.0, appPercent / 100.0))
                                        radius: parent.radius
                                        color: appColor
                                    }
                                }
                            }

                            // Percent Badge
                            Text {
                                text: Math.round(appPercent) + "%"
                                font.family: ThemeBackend.fontFamily
                                font.pixelSize: root.s(10)
                                font.weight: Font.Medium
                                color: ThemeBackend.subtext0
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                    }
                }
            }
        }
    }
}
