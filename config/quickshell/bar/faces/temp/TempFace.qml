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

    property string tempStyle: {
        if (widget && widget !== root && widget.tempStyle !== undefined) return widget.tempStyle;
        if (module && module.tempStyle !== undefined) return module.tempStyle;
        let dummy = configRevision;
        if (typeof Config !== "undefined" && Config.rawSettings && Config.rawSettings.bar) {
            let bs = Config.rawSettings.bar;
            if (bs.tempStyle) return bs.tempStyle;
            if (bs.temp && bs.temp.style) return bs.temp.style;
        }
        return "minimal";
    }

    property bool showIcon: {
        if (widget && widget !== root && widget.tempShowIcon !== undefined) return widget.tempShowIcon;
        if (widget && widget !== root && widget.showIcon !== undefined) return widget.showIcon;
        if (module && module.tempShowIcon !== undefined) return module.tempShowIcon;
        if (module && module.showIcon !== undefined) return module.showIcon;
        let dummy = configRevision;
        if (typeof Config !== "undefined" && Config.rawSettings && Config.rawSettings.bar) {
            let bs = Config.rawSettings.bar;
            if (bs.tempShowIcon !== undefined) return Boolean(bs.tempShowIcon);
            if (bs.temp && bs.temp.showIcon !== undefined) return Boolean(bs.temp.showIcon);
        }
        return true;
    }

    property bool showText: {
        if (widget && widget !== root && widget.tempShowText !== undefined) return widget.tempShowText;
        if (widget && widget !== root && widget.showText !== undefined) return widget.showText;
        if (module && module.tempShowText !== undefined) return module.tempShowText;
        if (module && module.showText !== undefined) return module.showText;
        let dummy = configRevision;
        if (typeof Config !== "undefined" && Config.rawSettings && Config.rawSettings.bar) {
            let bs = Config.rawSettings.bar;
            if (bs.tempShowText !== undefined) return Boolean(bs.tempShowText);
            if (bs.temp && bs.temp.showText !== undefined) return Boolean(bs.temp.showText);
        }
        return true;
    }

    SubscriptionGate {
        target: SysData
        wanted: root.visible
    }

    property int fallbackTemp: 0
    readonly property int tempVal: (typeof SysData !== "undefined" && SysData.temp > 0) ? SysData.temp : fallbackTemp
    readonly property string tempText: (tempVal > 0 ? tempVal : "--") + "°C"

    property real animTemp: tempVal
    Behavior on animTemp {
        NumberAnimation { duration: 600; easing.type: Easing.OutQuint }
    }
    readonly property real tempRatio: Math.max(0.0, Math.min(1.0, isNaN(animTemp) ? 0.0 : animTemp / 100.0))

    readonly property color tempColor: {
        if (tempVal >= 80) return ThemeBackend.red;
        if (tempVal >= 60) return ThemeBackend.peach;
        return ThemeBackend.green;
    }

    Process {
        id: fallbackProc
        running: false
        command: ["bash", "-c", "cat /sys/devices/platform/coretemp.0/hwmon/hwmon*/temp1_input 2>/dev/null || cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                let v = parseInt(this.text.trim());
                if (!isNaN(v) && v > 0) {
                    root.fallbackTemp = (v > 1000) ? Math.round(v / 1000) : v;
                }
            }
        }
    }

    function checkFallback() {
        if ((typeof SysData === "undefined" || SysData.temp <= 0) && !fallbackProc.running) {
            fallbackProc.running = true;
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: root.visible && (typeof SysData === "undefined" || SysData.temp <= 0)
        onTriggered: root.checkFallback()
    }

    Component.onCompleted: {
        if (typeof SysData !== "undefined" && typeof SysData.prewarm === "function") {
            SysData.prewarm();
        }
        root.checkFallback();
    }

    component DynamicTempIcon : Item {
        id: dIcon
        property real ratio: root.tempRatio
        property color iconColor: root.tempColor
        property color borderColor: iconColor
        property color bgColor: Qt.alpha(iconColor, 0.18)

        width: s(root.isCompact ? 9 : 11)
        height: s(root.isCompact ? 15 : 17)

        Rectangle {
            id: outerBox
            anchors.fill: parent
            radius: s(3)
            color: dIcon.bgColor
            border.color: dIcon.borderColor
            border.width: s(1.2)
            clip: true

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: s(1)
                anchors.rightMargin: s(1)
                anchors.bottomMargin: s(1)
                height: Math.max(s(1.5), Math.round((parent.height - s(2)) * Math.max(0.0, Math.min(1.0, dIcon.ratio))))
                radius: s(1.5)
                color: dIcon.iconColor
                Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
            }
        }
    }

    property bool showLayout: (!barWindow || isPreview) ? true : (isVertical ? ((!module || module.moduleActive) && barWindow.isStartupReady && barWindow.isDataReady) : false)
    readonly property var tempPill: pillLoader.item ? pillLoader.item.pill : null
    readonly property int pillHeight: s(root.isCompact ? 28 : 30)

    readonly property real pillLength: pillLoader.item ? (isVertical ? pillLoader.item.height : pillLoader.item.width) : 0
    readonly property real textLength: isVertical ? textLayout.implicitHeight : textLayout.implicitWidth

    property real targetLength: {
        if (module && !module.moduleActive) return 0;
        if (root.tempStyle === "text") {
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
        enabled: root.tempStyle === "text" && !root.isPreview
        onClicked: {
            Quickshell.execDetached(["bash", "-c", "kitty -e btop 2>/dev/null || foot -e btop 2>/dev/null || btop 2>/dev/null || true"]);
        }
    }

    AxisFlow {
        id: textLayout
        vertical: root.isVertical
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter
        visible: root.tempStyle === "text"
        anchors.centerIn: parent
        spacing: root.isVertical ? s(root.isCompact ? 2 : 3) : s(root.isCompact ? 5 : 6)
        opacity: root.showLayout ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

        DynamicTempIcon {
            visible: root.showIcon
            ratio: root.tempRatio
            iconColor: textMouseArea.containsMouse ? Qt.lighter(root.tempColor, 1.15) : root.tempColor
        }

        Text {
            visible: root.showText
            text: root.isVertical ? (root.tempVal > 0 ? (root.tempVal + "°") : "--°") : root.tempText
            font.family: ThemeBackend.fontFamily
            font.pixelSize: root.isVertical ? s(root.isCompact ? 9 : 10) : s(root.isCompact ? 11 : 12)
            font.bold: true
            color: textMouseArea.containsMouse ? Qt.lighter(root.tempColor, 1.15) : root.tempColor
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    Loader {
        id: pillLoader
        visible: root.tempStyle !== "text"
        anchors.centerIn: parent
        sourceComponent: root.isVertical ? sideLayoutComponent : topLayoutComponent
    }

    Component {
        id: topLayoutComponent

        Item {
            id: topItem
            readonly property var pill: tempPill
            implicitWidth: tempPill.width
            implicitHeight: tempPill.height

            Rectangle {
                id: tempPill
                property bool initAnimTrigger: root.isPreview

                height: root.pillHeight
                property real targetWidth: (root.showIcon || root.showText) ? (contentRow.implicitWidth + s(root.isCompact ? 16 : 20)) : 0
                width: targetWidth
                Behavior on width { NumberAnimation { duration: 480; easing.type: Easing.OutQuint } }

                scale: tempMouseArea.pressed ? 0.94 : (tempMouseArea.containsMouse ? 1.04 : 1.0)
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                radius: Math.max(0, ThemeBackend.borderRadius - s(2))
                property color baseColor: root.isCompact ? Qt.lighter(ThemeBackend.surface0, 1.18) : ThemeBackend.surface0
                color: tempPillGlass.active ? "transparent" : (tempMouseArea.pressed ? Qt.darker(baseColor, 1.15) : (tempMouseArea.containsMouse ? Qt.lighter(baseColor, 1.08) : baseColor))
                Behavior on color { ColorAnimation { duration: 150 } }
                border.color: root.isCompact ? ThemeBackend.surface2 : ThemeBackend.surface1
                border.width: 1

                GlassFill {
                    id: tempPillGlass
                    anchors.fill: parent
                    radius: parent.radius
                    tintColor: parent.baseColor
                    tintAmount: 0.3
                    press: tempMouseArea.pressed ? 1 : (tempMouseArea.containsMouse ? 0.25 : 0)
                    Behavior on press { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                }
                clip: true

                Timer {
                    running: !root.isPreview && (!module || module.moduleActive) && root.showLayout && !tempPill.initAnimTrigger
                    interval: 150
                    onTriggered: tempPill.initAnimTrigger = true
                }

                opacity: initAnimTrigger ? 1.0 : 0.0
                transform: Translate {
                    y: tempPill.initAnimTrigger ? 0 : s(15)
                    Behavior on y { NumberAnimation { duration: 620; easing.type: Easing.OutQuint } }
                }
                Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

                Row {
                    id: contentRow
                    anchors.centerIn: parent
                    height: parent.height
                    spacing: s(root.isCompact ? 5 : 6)

                    DynamicTempIcon {
                        visible: root.showIcon
                        ratio: root.tempRatio
                        iconColor: root.tempColor
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        id: tempTextLabel
                        visible: root.showText
                        text: root.tempText
                        font.family: ThemeBackend.fontFamily
                        font.pixelSize: s(root.isCompact ? 11 : 12.6)
                        font.bold: true
                        color: root.tempColor
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: tempMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!root.isPreview) {
                            Quickshell.execDetached(["bash", "-c", "kitty -e btop 2>/dev/null || foot -e btop 2>/dev/null || btop 2>/dev/null || true"]);
                        }
                    }
                }
            }
        }
    }

    Component {
        id: sideLayoutComponent

        Item {
            id: sideItem
            readonly property var pill: sideBtn
            implicitWidth: sideBtn.width
            implicitHeight: sideBtn.height

            Rectangle {
                id: sideBtn
                width: s(root.isCompact ? 28 : 30)
                height: (root.showIcon || root.showText) ? (sideCol.implicitHeight + s(root.isCompact ? 10 : 12)) : 0
                radius: Math.max(0, ThemeBackend.borderRadius - s(2))
                property color baseColor: root.isCompact ? Qt.lighter(ThemeBackend.surface0, 1.18) : ThemeBackend.surface0
                color: sideMouseArea.pressed ? Qt.darker(baseColor, 1.15) : (sideMouseArea.containsMouse ? Qt.lighter(baseColor, 1.08) : baseColor)
                border.color: root.isCompact ? ThemeBackend.surface2 : ThemeBackend.surface1
                border.width: 1
                clip: true

                property bool initAnimTrigger: root.isPreview
                Timer {
                    running: !root.isPreview && (!module || module.moduleActive) && root.showLayout && !sideBtn.initAnimTrigger
                    interval: 150
                    onTriggered: sideBtn.initAnimTrigger = true
                }

                opacity: initAnimTrigger ? 1.0 : 0.0
                transform: Translate {
                    x: sideBtn.initAnimTrigger ? 0 : s(15)
                    Behavior on x { NumberAnimation { duration: 620; easing.type: Easing.OutQuint } }
                }
                Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

                Column {
                    id: sideCol
                    anchors.centerIn: parent
                    width: parent.width
                    spacing: s(2)

                    DynamicTempIcon {
                        visible: root.showIcon
                        ratio: root.tempRatio
                        iconColor: root.tempColor
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        visible: root.showText
                        text: root.tempVal > 0 ? (root.tempVal + "°") : "--°"
                        font.family: ThemeBackend.fontFamily
                        font.pixelSize: s(root.isCompact ? 9 : 10)
                        font.bold: true
                        color: root.tempColor
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                MouseArea {
                    id: sideMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!root.isPreview) {
                            Quickshell.execDetached(["bash", "-c", "kitty -e btop 2>/dev/null || foot -e btop 2>/dev/null || btop 2>/dev/null || true"]);
                        }
                    }
                }
            }
        }
    }
}
