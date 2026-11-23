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

    property string briStyle: {
        if (widget && widget !== root && widget.briStyle !== undefined) return widget.briStyle;
        if (module && module.briStyle !== undefined) return module.briStyle;
        let dummy = configRevision;
        if (typeof Config !== "undefined" && Config.rawSettings && Config.rawSettings.bar) {
            let bs = Config.rawSettings.bar;
            if (bs.brightnessStyle) return bs.brightnessStyle;
            if (bs.briStyle) return bs.briStyle;
            if (bs.brightness && bs.brightness.style) return bs.brightness.style;
        }
        return "button";
    }

    property bool showIcon: {
        if (widget && widget !== root && widget.briShowIcon !== undefined) return widget.briShowIcon;
        if (widget && widget !== root && widget.showIcon !== undefined) return widget.showIcon;
        if (module && module.briShowIcon !== undefined) return module.briShowIcon;
        if (module && module.showIcon !== undefined) return module.showIcon;
        let dummy = configRevision;
        if (typeof Config !== "undefined" && Config.rawSettings && Config.rawSettings.bar) {
            let bs = Config.rawSettings.bar;
            if (bs.brightnessShowIcon !== undefined) return Boolean(bs.brightnessShowIcon);
            if (bs.briShowIcon !== undefined) return Boolean(bs.briShowIcon);
            if (bs.brightness && bs.brightness.showIcon !== undefined) return Boolean(bs.brightness.showIcon);
        }
        return true;
    }

    property bool showPercent: {
        if (widget && widget !== root && widget.briShowPercent !== undefined) return widget.briShowPercent;
        if (widget && widget !== root && widget.showPercent !== undefined) return widget.showPercent;
        if (module && module.briShowPercent !== undefined) return module.briShowPercent;
        if (module && module.showPercent !== undefined) return module.showPercent;
        let dummy = configRevision;
        if (typeof Config !== "undefined" && Config.rawSettings && Config.rawSettings.bar) {
            let bs = Config.rawSettings.bar;
            if (bs.brightnessShowPercent !== undefined) return Boolean(bs.brightnessShowPercent);
            if (bs.briShowPercent !== undefined) return Boolean(bs.briShowPercent);
            if (bs.brightness && bs.brightness.showPercent !== undefined) return Boolean(bs.brightness.showPercent);
        }
        return true;
    }

    property int initBri: 100
    property int sysBrightness: isPreview ? 80 : (OsdController.brightnessInitialized ? OsdController.sysBrightness : initBri)
    property string briPercent: sysBrightness + "%"
    property string briIcon: sysBrightness > 70 ? "󰃠" : (sysBrightness > 35 ? "󰃟" : "󰃞")
    property bool isBrightActive: sysBrightness > 0

    property bool showLayout: (!barWindow || isPreview) ? true : (isVertical ? ((!module || module.moduleActive) && barWindow.isStartupReady && barWindow.isDataReady) : false)
    readonly property var briPill: pillLoader.item

    readonly property real pillLength: pillLoader.item ? (isVertical ? pillLoader.item.height : pillLoader.item.width) : 0
    readonly property real textLength: isVertical ? textLayout.implicitHeight : textLayout.implicitWidth

    property real targetLength: {
        if (module && !module.moduleActive) return 0;
        if (root.briStyle === "text") {
            return (textLength > 0) ? (textLength + s(root.isCompact ? (isVertical ? 14 : 12) : 16)) : 0;
        }
        return (pillLength > 0) ? (pillLength + s(root.isCompact ? 4 : 6)) : 0;
    }
    readonly property alias targetWidth: root.targetLength
    readonly property alias targetHeight: root.targetLength
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

    Process {
        id: quickInitBri
        running: !root.isPreview && !OsdController.brightnessInitialized
        command: ["sh", "-c", "if command -v brightnessctl >/dev/null 2>&1; then brightnessctl -m | cut -d, -f4 | tr -d '%'; elif command -v jalpari-core >/dev/null 2>&1; then jalpari-core brightness get; fi"]
        stdout: SplitParser {
            onRead: data => {
                let val = parseInt(data.trim());
                if (!isNaN(val) && val >= 0) {
                    root.initBri = val;
                    if (!OsdController.brightnessInitialized) {
                        OsdController.sysBrightness = val;
                    }
                }
            }
        }
    }

    property real wheelAccumulator: 0
    Timer {
        id: briWheelTimer
        interval: 200
        onTriggered: root.wheelAccumulator = 0
    }

    function setBrightness(val) {
        let target = Math.max(5, Math.min(100, Math.round(val)));
        root.initBri = target;
        OsdController.sysBrightness = target;
        OsdController.briVal = target;
        Quickshell.execDetached(["sh", "-c", "if command -v brightnessctl >/dev/null 2>&1; then brightnessctl s " + target + "%; elif command -v jalpari-core >/dev/null 2>&1; then jalpari-core brightness set " + target + "; fi"]);
        OsdController.show("brightness", target);
    }

    MouseArea {
        id: textMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        enabled: root.briStyle === "text" && !root.isPreview
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                root.setBrightness(root.sysBrightness > 50 ? 30 : 100);
            } else {
                OsdController.show("brightness", root.sysBrightness);
            }
        }

        onWheel: wheel => {
            briWheelTimer.restart();
            root.wheelAccumulator += wheel.angleDelta.y;
            const threshold = 120;
            if (Math.abs(root.wheelAccumulator) >= threshold) {
                let steps = Math.trunc(root.wheelAccumulator / threshold);
                root.wheelAccumulator = root.wheelAccumulator % threshold;
                if (steps !== 0) {
                    let newBri = Math.max(5, Math.min(100, root.sysBrightness + (steps * 5)));
                    root.setBrightness(newBri);
                }
            }
        }
    }

    AxisFlow {
        id: textLayout
        vertical: root.isVertical
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter
        visible: root.briStyle === "text"
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
                text: root.briIcon
                font.family: ThemeBackend.iconFont
                font.pixelSize: s(root.isCompact ? 14 : 15)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: textMouseArea.containsMouse ? Qt.lighter(ThemeBackend.mauve, 1.15) : (root.isBrightActive ? ThemeBackend.mauve : ThemeBackend.subtext0)
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }

        Text {
            visible: root.showPercent
            text: root.briPercent
            font.family: ThemeBackend.fontFamily
            font.pixelSize: root.isVertical ? s(root.isCompact ? 9 : 10) : s(root.isCompact ? 11 : 12)
            font.bold: true
            color: textMouseArea.containsMouse ? Qt.lighter(ThemeBackend.text, 1.15) : ThemeBackend.text
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    Loader {
        id: pillLoader
        visible: root.briStyle !== "text"
        anchors.centerIn: parent
        sourceComponent: root.isVertical ? sideButtonComponent : topButtonComponent
    }

    Component {
        id: topButtonComponent

        Rectangle {
            id: briPill
            property bool initAnimTrigger: root.isPreview
            property bool isActive: root.isBrightActive
            property real fillRatio: Math.max(0.0, Math.min(1.0, root.sysBrightness / 100.0))
            property real animRatio: fillRatio
            Behavior on animRatio { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            height: s(root.isCompact ? 28 : 30)
            radius: Math.max(0, ThemeBackend.borderRadius - s(2))
            property color baseColor: root.isCompact ? Qt.lighter(ThemeBackend.surface0, 1.18) : ThemeBackend.surface0
            property color accentColor: root.isBrightActive ? (root.isCompact ? Qt.lighter(ThemeBackend.mauve, 1.08) : ThemeBackend.mauve) : ThemeBackend.surface1
            color: briPillGlass.active ? "transparent" : (briMa.pressed ? Qt.darker(baseColor, 1.15) : (briMa.containsMouse ? Qt.lighter(baseColor, 1.08) : baseColor))
            Behavior on color { ColorAnimation { duration: 150 } }
            clip: true

            scale: (briMa.pressed ? 0.96 : (briMa.containsMouse ? 1.03 : 1.0))
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            property real targetWidth: (root.showIcon || root.showPercent) ? Math.round(contentRow.implicitWidth + s(root.isCompact ? 20 : 24)) : 0
            width: targetWidth
            Behavior on width { NumberAnimation { duration: 480; easing.type: Easing.OutQuint } }

            Rectangle {
                id: fillBar
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Math.round(parent.width * briPill.animRatio)
                radius: parent.radius
                color: briPill.accentColor
                opacity: (root.isBrightActive && briPill.animRatio > 0.001) ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            GlassFill {
                id: briPillGlass
                anchors.fill: parent
                radius: parent.radius
                tintColor: parent.baseColor
                tintAmount: 0.3
                press: briMa.pressed ? 1 : (briMa.containsMouse ? 0.25 : 0)
                Behavior on press { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            }

            Row {
                id: contentRow
                anchors.centerIn: parent
                spacing: s(root.isCompact ? 6 : 7)

                Text {
                    id: briIconText
                    visible: root.showIcon
                    text: root.briIcon
                    font.family: ThemeBackend.iconFont
                    font.pixelSize: s(root.isCompact ? 14 : 15)
                    color: root.isBrightActive ? ThemeBackend.text : ThemeBackend.subtext0
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    id: briPercentText
                    visible: root.showPercent
                    text: root.briPercent
                    font.family: ThemeBackend.fontFamily
                    font.pixelSize: s(root.isCompact ? 11 : 12)
                    font.bold: true
                    color: ThemeBackend.text
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Item {
                id: textClipBox
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: fillBar.width
                clip: true
                visible: width > 0 && root.isBrightActive

                Row {
                    x: contentRow.x
                    y: contentRow.y
                    spacing: contentRow.spacing

                    Text {
                        visible: briIconText.visible
                        text: briIconText.text
                        font.family: briIconText.font.family
                        font.pixelSize: briIconText.font.pixelSize
                        color: ThemeBackend.base
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        visible: briPercentText.visible
                        text: briPercentText.text
                        font.family: briPercentText.font.family
                        font.pixelSize: briPercentText.font.pixelSize
                        font.bold: briPercentText.font.bold
                        color: ThemeBackend.base
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Timer { running: !root.isPreview && (!module || module.moduleActive) && root.showLayout && !briPill.initAnimTrigger; interval: 250; onTriggered: briPill.initAnimTrigger = true }
            opacity: initAnimTrigger ? 1.0 : 0.0
            transform: Translate { y: briPill.initAnimTrigger ? 0 : s(15); Behavior on y { NumberAnimation { duration: 620; easing.type: Easing.OutQuint } } }
            Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

            MouseArea {
                id: briMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onClicked: mouse => {
                    if (root.isPreview) return;
                    if (mouse.button === Qt.RightButton) {
                        root.setBrightness(root.sysBrightness > 50 ? 30 : 100);
                    } else {
                        OsdController.show("brightness", root.sysBrightness);
                    }
                }

                onWheel: wheel => {
                    if (root.isPreview) return;
                    briWheelTimer.restart();
                    root.wheelAccumulator += wheel.angleDelta.y;
                    const threshold = 120;
                    if (Math.abs(root.wheelAccumulator) >= threshold) {
                        let steps = Math.trunc(root.wheelAccumulator / threshold);
                        root.wheelAccumulator = root.wheelAccumulator % threshold;
                        if (steps !== 0) {
                            let newBri = Math.max(5, Math.min(100, root.sysBrightness + (steps * 5)));
                            root.setBrightness(newBri);
                        }
                    }
                }
            }
        }
    }

    Component {
        id: sideButtonComponent

        Rectangle {
            id: briSidePill
            width: s(root.isCompact ? 28 : 30)
            height: (root.showIcon || root.showPercent) ? s(root.isCompact ? 28 : 30) : 0
            radius: Math.max(0, ThemeBackend.borderRadius - s(2))
            property color baseColor: root.isCompact ? Qt.lighter(ThemeBackend.surface0, 1.18) : ThemeBackend.surface0
            property color accentColor: root.isBrightActive ? (root.isCompact ? Qt.lighter(ThemeBackend.mauve, 1.08) : ThemeBackend.mauve) : ThemeBackend.surface1
            color: briSideGlass.active ? "transparent" : (briSideMa.pressed ? Qt.darker(baseColor, 1.15) : (briSideMa.containsMouse ? Qt.lighter(baseColor, 1.08) : baseColor))
            clip: true

            property real fillRatio: Math.max(0.0, Math.min(1.0, root.sysBrightness / 100.0))
            property real animRatio: fillRatio
            Behavior on animRatio { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: Math.round(parent.height * briSidePill.animRatio)
                radius: parent.radius
                color: briSidePill.accentColor
                opacity: (root.isBrightActive && height > 0) ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            GlassFill {
                id: briSideGlass
                anchors.fill: parent
                radius: parent.radius
                tintColor: parent.baseColor
                tintAmount: 0.3
                press: briSideMa.pressed ? 1 : (briSideMa.containsMouse ? 0.25 : 0)
            }

            Text {
                id: briSideIconText
                anchors.centerIn: parent
                text: root.briIcon
                font.family: ThemeBackend.iconFont
                font.pixelSize: s(root.isCompact ? 13 : 14)
                color: root.isBrightActive ? ThemeBackend.text : ThemeBackend.subtext0
            }

            Item {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: Math.round(parent.height * briSidePill.animRatio)
                clip: true
                visible: height > 0 && root.isBrightActive

                Text {
                    x: briSideIconText.x
                    y: briSideIconText.y
                    text: briSideIconText.text
                    font.family: briSideIconText.font.family
                    font.pixelSize: briSideIconText.font.pixelSize
                    color: ThemeBackend.base
                }
            }

            MouseArea {
                id: briSideMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    if (root.isPreview) return;
                    if (mouse.button === Qt.RightButton) {
                        root.setBrightness(root.sysBrightness > 50 ? 30 : 100);
                    } else {
                        OsdController.show("brightness", root.sysBrightness);
                    }
                }
            }
        }
    }
}
