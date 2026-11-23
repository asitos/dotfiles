import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../../reusables"
import "../../../"
import "../../"

BarFaceBase {
    id: root

    property string powerProfileStyle: {
        if (widget && widget !== root && widget.powerProfileStyle !== undefined) return widget.powerProfileStyle;
        if (module && module.powerProfileStyle !== undefined) return module.powerProfileStyle;
        let dummy = configRevision;
        if (typeof Config !== "undefined" && Config.rawSettings && Config.rawSettings.bar) {
            let bs = Config.rawSettings.bar;
            if (bs.powerProfileStyle) return bs.powerProfileStyle;
            if (bs.powerprofile && bs.powerprofile.style) return bs.powerprofile.style;
        }
        return "button";
    }

    property bool showIcon: {
        if (widget && widget !== root && widget.powerProfileShowIcon !== undefined) return widget.powerProfileShowIcon;
        if (widget && widget !== root && widget.showIcon !== undefined) return widget.showIcon;
        if (module && module.powerProfileShowIcon !== undefined) return module.powerProfileShowIcon;
        if (module && module.showIcon !== undefined) return module.showIcon;
        let dummy = configRevision;
        if (typeof Config !== "undefined" && Config.rawSettings && Config.rawSettings.bar) {
            let bs = Config.rawSettings.bar;
            if (bs.powerProfileShowIcon !== undefined) return Boolean(bs.powerProfileShowIcon);
            if (bs.powerprofile && bs.powerprofile.showIcon !== undefined) return Boolean(bs.powerprofile.showIcon);
        }
        return true;
    }

    property bool showName: {
        if (widget && widget !== root && widget.powerProfileShowName !== undefined) return widget.powerProfileShowName;
        if (widget && widget !== root && widget.showName !== undefined) return widget.showName;
        if (module && module.powerProfileShowName !== undefined) return module.powerProfileShowName;
        if (module && module.showName !== undefined) return module.showName;
        let dummy = configRevision;
        if (typeof Config !== "undefined" && Config.rawSettings && Config.rawSettings.bar) {
            let bs = Config.rawSettings.bar;
            if (bs.powerProfileShowName !== undefined) return Boolean(bs.powerProfileShowName);
            if (bs.powerprofile && bs.powerprofile.showName !== undefined) return Boolean(bs.powerprofile.showName);
        }
        return false;
    }

    property string profileMode: "balanced"

    readonly property string profileIcon: {
        if (profileMode === "performance") return "";
        if (profileMode === "power-saver") return "";
        return "";
    }

    readonly property color profileColor: {
        if (profileMode === "performance") return ThemeBackend.red;
        if (profileMode === "power-saver") return ThemeBackend.green;
        return ThemeBackend.primary;
    }

    readonly property string profileText: {
        if (profileMode === "performance") return "Perf";
        if (profileMode === "power-saver") return "Save";
        return "Bal";
    }

    Process {
        id: profileProc
        running: false
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                let m = this.text.trim();
                if (m) root.profileMode = m;
            }
        }
    }

    function fetch() {
        if (!profileProc.running) {
            profileProc.running = true;
        }
    }

    function toggle() {
        Quickshell.execDetached(["bash", "-c", "~/.config/Scripts/power_toggle.sh"]);
        toggleDelayTimer.restart();
    }

    Timer {
        id: toggleDelayTimer
        interval: 180
        repeat: false
        onTriggered: root.fetch()
    }

    Timer {
        id: pollTimer
        interval: 2000
        repeat: true
        running: root.visible && (!barWindow || barWindow.isDataReady)
        onTriggered: root.fetch()
    }

    IpcHandler {
        target: "powerprofile"
        function refresh(): void {
            root.fetch();
        }
        function toggle(): void {
            root.toggle();
        }
    }

    Component.onCompleted: {
        root.fetch();
    }

    property bool showLayout: (!barWindow || isPreview) ? true : (isVertical ? ((!module || module.moduleActive) && barWindow.isStartupReady && barWindow.isDataReady) : false)
    readonly property var powerProfilePill: pillLoader.item

    readonly property real pillLength: pillLoader.item ? (isVertical ? pillLoader.item.height : pillLoader.item.width) : 0
    readonly property real textLength: isVertical ? textLayout.implicitHeight : textLayout.implicitWidth

    property real targetLength: {
        if (module && !module.moduleActive) return 0;
        if (root.powerProfileStyle === "text") {
            return (textLength > 0) ? (textLength + s(root.isCompact ? (isVertical ? 14 : 12) : 16)) : 0;
        }
        return (pillLength > 0) ? (pillLength + s(root.isCompact ? 8 : 10)) : 0;
    }
    property bool isFaceVisible: showLayout && targetLength > 0

    function syncImplicitSize() {
        let cross = module ? module.thickness : (parent ? (isVertical ? parent.width : parent.height) : 0);
        implicitWidth = isVertical ? cross : targetLength;
        implicitHeight = isVertical ? targetLength : cross;
    }

    onTargetLengthChanged: syncImplicitSize()
    onIsVerticalChanged: syncImplicitSize()
    onModuleChanged: syncImplicitSize()
    onParentChanged: syncImplicitSize()

    Timer {
        running: true
        interval: 0
        onTriggered: root.syncImplicitSize()
    }

    Timer {
        running: !root.isVertical && !root.isPreview && (!module || module.moduleActive) && barWindow && barWindow.isStartupReady && barWindow.isDataReady
        interval: 100
        onTriggered: root.showLayout = true
    }

    transform: Translate {
        x: (root.isVertical || root.showLayout) ? 0 : s(60)
        Behavior on x { NumberAnimation { duration: 800; easing.type: Easing.OutQuint } }
    }

    MouseArea {
        id: textMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        enabled: root.powerProfileStyle === "text" && !root.isPreview
        onClicked: root.toggle()
    }

    AxisFlow {
        id: textLayout
        vertical: root.isVertical
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter
        visible: root.powerProfileStyle === "text"
        anchors.centerIn: parent
        spacing: root.isVertical ? s(root.isCompact ? 2 : 3) : s(root.isCompact ? 5 : 6)
        opacity: root.showLayout ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

        Item {
            visible: root.showIcon
            width: root.isVertical ? textIcon.implicitWidth : s(root.isCompact ? 18 : 20)
            height: root.isVertical ? textIcon.implicitHeight : width

            Text {
                id: textIcon
                anchors.centerIn: parent
                text: root.profileIcon
                font.family: ThemeBackend.iconFont
                font.pixelSize: s(root.isCompact ? 14 : 15)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: textMouseArea.containsMouse ? Qt.lighter(root.profileColor, 1.15) : root.profileColor
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }

        Text {
            visible: root.showName
            text: root.profileText
            font.family: ThemeBackend.fontFamily
            font.pixelSize: root.isVertical ? s(root.isCompact ? 9 : 10) : s(root.isCompact ? 11 : 12)
            font.bold: true
            color: textMouseArea.containsMouse ? Qt.lighter(root.profileColor, 1.15) : root.profileColor
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    Loader {
        id: pillLoader
        visible: root.powerProfileStyle !== "text"
        anchors.centerIn: parent
        sourceComponent: root.isVertical ? sideButtonComponent : topButtonComponent
    }

    Component {
        id: topButtonComponent

        ClickButton {
            id: powerProfilePill
            property bool initAnimTrigger: root.showLayout

            height: s(root.isCompact ? 28 : 30)
            maxWidth: s(root.isCompact ? 96 : 100)
            cornerRadius: Math.max(0, ThemeBackend.borderRadius - s(2))
            horizontalPadding: s(root.isCompact ? 8 : 10)
            buttonIcon: root.showIcon ? root.profileIcon : ""
            iconFontSize: s(root.isCompact ? 14 : 15)
            buttonText: root.showName ? root.profileText : ""
            textFontSize: s(root.isCompact ? 11 : 12)
            accentColor: Qt.lighter(ThemeBackend.surface0, root.isCompact ? 1.18 : 1.28)
            textColor: root.profileColor

            property real targetWidth: (root.showIcon || root.showName) ? implicitWidth : 0
            width: targetWidth
            Behavior on width { NumberAnimation { duration: 480; easing.type: Easing.OutQuint } }

            opacity: initAnimTrigger ? 1.0 : 0.0
            transform: Translate { y: powerProfilePill.initAnimTrigger ? 0 : s(15); Behavior on y { NumberAnimation { duration: 620; easing.type: Easing.OutQuint } } }
            Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

            onClicked: {
                if (!root.isPreview) {
                    root.toggle();
                }
            }
        }
    }

    Component {
        id: sideButtonComponent

        ClickButton {
            width: s(root.isCompact ? 28 : 30)
            height: (root.showIcon || root.showName) ? s(root.isCompact ? 28 : 30) : 0
            cornerRadius: Math.max(0, ThemeBackend.borderRadius - s(2))
            horizontalPadding: 0
            buttonIcon: root.showIcon ? root.profileIcon : ""
            iconFontSize: s(root.isCompact ? 14 : 15)
            buttonText: (!root.showIcon && root.showName) ? root.profileText : ""
            textFontSize: s(root.isCompact ? 9 : 10)
            accentColor: Qt.lighter(ThemeBackend.surface0, root.isCompact ? 1.18 : 1.28)
            textColor: root.profileColor
            onClicked: {
                if (!root.isPreview) {
                    root.toggle();
                }
            }
        }
    }
}
