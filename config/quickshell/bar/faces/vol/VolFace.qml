import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import Quickshell.Services.Pipewire
import "../../../reusables"
import "../../../"
import "../../"

BarFaceBase {
    id: root

    property string volStyle: {
        if (widget && widget !== root && widget.volStyle !== undefined) return widget.volStyle;
        if (module && module.volStyle !== undefined) return module.volStyle;
        let dummy = configRevision;
        if (typeof Config !== "undefined" && Config.rawSettings && Config.rawSettings.bar) {
            let bs = Config.rawSettings.bar;
            if (bs.volStyle) return bs.volStyle;
            if (bs.vol && bs.vol.style) return bs.vol.style;
        }
        return "button";
    }

    property bool showIcon: {
        if (widget && widget !== root && widget.volShowIcon !== undefined) return widget.volShowIcon;
        if (widget && widget !== root && widget.showIcon !== undefined) return widget.showIcon;
        if (module && module.volShowIcon !== undefined) return module.volShowIcon;
        if (module && module.showIcon !== undefined) return module.showIcon;
        let dummy = configRevision;
        if (typeof Config !== "undefined" && Config.rawSettings && Config.rawSettings.bar) {
            let bs = Config.rawSettings.bar;
            if (bs.volShowIcon !== undefined) return Boolean(bs.volShowIcon);
            if (bs.vol && bs.vol.showIcon !== undefined) return Boolean(bs.vol.showIcon);
        }
        return true;
    }

    property bool showPercent: {
        if (widget && widget !== root && widget.volShowPercent !== undefined) return widget.volShowPercent;
        if (widget && widget !== root && widget.showPercent !== undefined) return widget.showPercent;
        if (module && module.volShowPercent !== undefined) return module.volShowPercent;
        if (module && module.showPercent !== undefined) return module.showPercent;
        let dummy = configRevision;
        if (typeof Config !== "undefined" && Config.rawSettings && Config.rawSettings.bar) {
            let bs = Config.rawSettings.bar;
            if (bs.volShowPercent !== undefined) return Boolean(bs.volShowPercent);
            if (bs.vol && bs.vol.showPercent !== undefined) return Boolean(bs.vol.showPercent);
        }
        return true;
    }

    property real sysVolume: isPreview ? 65 : (Audio.defaultSink && Audio.defaultSink.audio ? Math.round(Audio.defaultSink.audio.volume * 100) : 0)
    property bool isMuted: isPreview ? false : (Audio.defaultSink && Audio.defaultSink.audio ? Audio.defaultSink.audio.muted : false)
    property string volPercent: sysVolume + "%"
    property string volIcon: isMuted || sysVolume === 0 ? "󰖁" : (sysVolume > 50 ? "󰕾" : "󰖀")
    property bool sysMuted: isMuted

    property bool isDraggingVol: false
    property bool isSoundActive: !isMuted && sysVolume > 0
    property bool showLayout: (!barWindow || isPreview) ? true : (isVertical ? ((!module || module.moduleActive) && barWindow.isStartupReady && barWindow.isDataReady) : false)
    readonly property var volPill: pillLoader.item

    readonly property real pillLength: pillLoader.item ? (isVertical ? pillLoader.item.height : pillLoader.item.width) : 0
    readonly property real textLength: isVertical ? textLayout.implicitHeight : textLayout.implicitWidth

    property real targetLength: {
        if (module && !module.moduleActive) return 0;
        if (root.volStyle === "text") {
            return (textLength > 0) ? (textLength + s(root.isCompact ? (isVertical ? 14 : 12) : 16)) : 0;
        }
        return (pillLength > 0) ? (pillLength + s(root.isCompact ? 4 : 6)) : 0;
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
        enabled: root.volStyle === "text" && !root.isPreview
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                if (Audio.defaultSink) Audio.toggleMute(Audio.defaultSink)
            } else {
                Quickshell.execDetached(["bash", "-c", Caching.quickshellDir + "/scripts/qs_manager.sh toggle volume"])
            }
        }

        property real wheelAccumulator: 0
        Timer {
            id: textWheelTimer
            interval: 200
            onTriggered: textMouseArea.wheelAccumulator = 0
        }

        onWheel: wheel => {
            textWheelTimer.restart()
            textMouseArea.wheelAccumulator += wheel.angleDelta.y
            const threshold = 120
            if (Math.abs(textMouseArea.wheelAccumulator) >= threshold) {
                let steps = Math.trunc(textMouseArea.wheelAccumulator / threshold)
                textMouseArea.wheelAccumulator = textMouseArea.wheelAccumulator % threshold
                if (steps !== 0 && Audio.defaultSink) {
                    let newVol = Math.max(0, Math.min(100, root.sysVolume + (steps * 5)))
                    Audio.setVolume(Audio.defaultSink, newVol)
                }
            }
        }
    }

    AxisFlow {
        id: textLayout
        vertical: root.isVertical
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter
        visible: root.volStyle === "text"
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
                text: root.volIcon
                font.family: ThemeBackend.iconFont
                font.pixelSize: s(root.isCompact ? 14 : 15)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: textMouseArea.containsMouse ? Qt.lighter(ThemeBackend.mauve, 1.15) : (root.isSoundActive ? ThemeBackend.mauve : ThemeBackend.subtext0)
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }

        Text {
            visible: root.showPercent
            text: root.volPercent
            font.family: ThemeBackend.fontFamily
            font.pixelSize: root.isVertical ? s(root.isCompact ? 9 : 10) : s(root.isCompact ? 11 : 12)
            font.bold: true
            color: textMouseArea.containsMouse ? Qt.lighter(ThemeBackend.text, 1.15) : ThemeBackend.text
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    Loader {
        id: pillLoader
        visible: root.volStyle !== "text"
        anchors.centerIn: parent
        sourceComponent: root.isVertical ? sideButtonComponent : topButtonComponent
    }

    Component {
        id: topButtonComponent

        Rectangle {
            id: volPill
            property bool initAnimTrigger: root.isPreview
            property bool isActive: root.isSoundActive
            property real fillRatio: Math.max(0.0, Math.min(1.0, root.isMuted ? 0.0 : (root.sysVolume / 100.0)))
            property real animRatio: fillRatio
            Behavior on animRatio { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            height: s(root.isCompact ? 28 : 30)
            radius: Math.max(0, ThemeBackend.borderRadius - s(2))
            property color baseColor: root.isCompact ? Qt.lighter(ThemeBackend.surface0, 1.18) : ThemeBackend.surface0
            property color accentColor: root.isSoundActive ? (root.isCompact ? Qt.lighter(ThemeBackend.mauve, 1.08) : ThemeBackend.mauve) : ThemeBackend.surface1
            color: volPillGlass.active ? "transparent" : (volMa.pressed ? Qt.darker(baseColor, 1.15) : (volMa.containsMouse ? Qt.lighter(baseColor, 1.08) : baseColor))
            Behavior on color { ColorAnimation { duration: 150 } }
            clip: true

            scale: (volMa.pressed ? 0.96 : (volMa.containsMouse ? 1.03 : 1.0))
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            property real targetWidth: (root.showIcon || root.showPercent) ? Math.round(contentRow.implicitWidth + s(root.isCompact ? 20 : 24)) : 0
            width: targetWidth
            Behavior on width { NumberAnimation { duration: 480; easing.type: Easing.OutQuint } }

            Rectangle {
                id: fillBar
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Math.round(parent.width * volPill.animRatio)
                radius: parent.radius
                color: volPill.accentColor
                opacity: (root.isSoundActive && volPill.animRatio > 0.001) ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            GlassFill {
                id: volPillGlass
                anchors.fill: parent
                radius: parent.radius
                tintColor: parent.baseColor
                tintAmount: 0.3
                press: volMa.pressed ? 1 : (volMa.containsMouse ? 0.25 : 0)
                Behavior on press { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            }

            Row {
                id: contentRow
                anchors.centerIn: parent
                spacing: s(root.isCompact ? 6 : 7)

                Text {
                    id: volIconText
                    visible: root.showIcon
                    text: root.volIcon
                    font.family: ThemeBackend.iconFont
                    font.pixelSize: s(root.isCompact ? 14 : 15)
                    color: root.isSoundActive ? ThemeBackend.text : ThemeBackend.subtext0
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    id: volPercentText
                    visible: root.showPercent
                    text: root.volPercent
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
                visible: width > 0 && root.isSoundActive

                Row {
                    x: contentRow.x
                    y: contentRow.y
                    spacing: contentRow.spacing

                    Text {
                        visible: volIconText.visible
                        text: volIconText.text
                        font.family: volIconText.font.family
                        font.pixelSize: volIconText.font.pixelSize
                        color: ThemeBackend.base
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        visible: volPercentText.visible
                        text: volPercentText.text
                        font.family: volPercentText.font.family
                        font.pixelSize: volPercentText.font.pixelSize
                        font.bold: volPercentText.font.bold
                        color: ThemeBackend.base
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Timer { running: !root.isPreview && (!module || module.moduleActive) && root.showLayout && !volPill.initAnimTrigger; interval: 250; onTriggered: volPill.initAnimTrigger = true }
            opacity: initAnimTrigger ? 1.0 : 0.0
            transform: Translate { y: volPill.initAnimTrigger ? 0 : s(15); Behavior on y { NumberAnimation { duration: 620; easing.type: Easing.OutQuint } } }
            Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

            property real wheelAccumulator: 0
            Timer {
                id: volWheelTimer
                interval: 200
                onTriggered: volPill.wheelAccumulator = 0
            }

            MouseArea {
                id: volMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onClicked: mouse => {
                    if (root.isPreview) return;
                    if (mouse.button === Qt.RightButton) {
                        if (Audio.defaultSink) Audio.toggleMute(Audio.defaultSink);
                    } else {
                        Quickshell.execDetached(["bash", "-c", Caching.quickshellDir + "/scripts/qs_manager.sh toggle volume"]);
                    }
                }

                onWheel: wheel => {
                    if (root.isPreview) return;
                    volWheelTimer.restart();
                    volPill.wheelAccumulator += wheel.angleDelta.y;
                    const threshold = 120;
                    if (Math.abs(volPill.wheelAccumulator) >= threshold) {
                        let steps = Math.trunc(volPill.wheelAccumulator / threshold);
                        volPill.wheelAccumulator = volPill.wheelAccumulator % threshold;
                        if (steps !== 0 && Audio.defaultSink) {
                            let newVol = Math.max(0, Math.min(120, root.sysVolume + (steps * 5)));
                            Audio.setVolume(Audio.defaultSink, newVol);
                        }
                    }
                }
            }
        }
    }

    Component {
        id: sideButtonComponent

        Rectangle {
            id: volSidePill
            width: s(root.isCompact ? 28 : 30)
            height: (root.showIcon || root.showPercent) ? s(root.isCompact ? 28 : 30) : 0
            radius: Math.max(0, ThemeBackend.borderRadius - s(2))
            property color baseColor: root.isCompact ? Qt.lighter(ThemeBackend.surface0, 1.18) : ThemeBackend.surface0
            property color accentColor: root.isSoundActive ? (root.isCompact ? Qt.lighter(ThemeBackend.mauve, 1.08) : ThemeBackend.mauve) : ThemeBackend.surface1
            color: sideGlass.active ? "transparent" : (sideMa.pressed ? Qt.darker(baseColor, 1.15) : (sideMa.containsMouse ? Qt.lighter(baseColor, 1.08) : baseColor))
            clip: true

            property real fillRatio: Math.max(0.0, Math.min(1.0, root.isMuted ? 0.0 : (root.sysVolume / 100.0)))
            property real animRatio: fillRatio
            Behavior on animRatio { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: Math.round(parent.height * volSidePill.animRatio)
                radius: parent.radius
                color: volSidePill.accentColor
                opacity: (root.isSoundActive && height > 0) ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            GlassFill {
                id: sideGlass
                anchors.fill: parent
                radius: parent.radius
                tintColor: parent.baseColor
                tintAmount: 0.3
                press: sideMa.pressed ? 1 : (sideMa.containsMouse ? 0.25 : 0)
            }

            Text {
                id: sideIconText
                anchors.centerIn: parent
                text: root.volIcon
                font.family: ThemeBackend.iconFont
                font.pixelSize: s(root.isCompact ? 13 : 14)
                color: root.isSoundActive ? ThemeBackend.text : ThemeBackend.subtext0
            }

            Item {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: Math.round(parent.height * volSidePill.animRatio)
                clip: true
                visible: height > 0 && root.isSoundActive

                Text {
                    x: sideIconText.x
                    y: sideIconText.y
                    text: sideIconText.text
                    font.family: sideIconText.font.family
                    font.pixelSize: sideIconText.font.pixelSize
                    color: ThemeBackend.base
                }
            }

            MouseArea {
                id: sideMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    if (root.isPreview) return;
                    if (mouse.button === Qt.RightButton) {
                        if (Audio.defaultSink) Audio.toggleMute(Audio.defaultSink);
                    } else {
                        Quickshell.execDetached(["bash", "-c", Caching.quickshellDir + "/scripts/qs_manager.sh toggle volume"]);
                    }
                }
            }
        }
    }
}
