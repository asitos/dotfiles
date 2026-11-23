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

    readonly property bool isActive: RecorderState.isActive
    readonly property bool isRecording: RecorderState.isRecording
    readonly property bool bannerActive: RecorderState.bannerActive

    property bool showIcon: true
    property bool showText: true

    property bool showLayout: (!barWindow || isPreview) ? true : (isVertical ? ((!module || module.moduleActive) && barWindow.isStartupReady && barWindow.isDataReady) : false)
    readonly property var recorderPill: pillLoader.item ? pillLoader.item.pill : null
    readonly property int pillHeight: s(root.isCompact ? 28 : 30)

    readonly property real pillLength: pillLoader.item ? (isVertical ? pillLoader.item.height : pillLoader.item.width) : 0

    property real targetLength: {
        if (module && !module.moduleActive) return 0;
        if (!root.isActive) return 0;
        return (pillLength > 0) ? (pillLength + s(root.isCompact ? 8 : 10)) : 0;
    }
    property bool isFaceVisible: showLayout && root.isActive && targetLength > 0

    function syncImplicitSize() {
        let cross = module ? module.thickness : (parent ? (isVertical ? parent.width : parent.height) : 0);
        implicitWidth = isVertical ? cross : targetLength;
        implicitHeight = isVertical ? targetLength : cross;
    }

    onTargetLengthChanged: syncImplicitSize()
    onIsVerticalChanged: syncImplicitSize()
    onModuleChanged: syncImplicitSize()
    onParentChanged: syncImplicitSize()
    onIsActiveChanged: syncImplicitSize()

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

    Loader {
        id: pillLoader
        anchors.centerIn: parent
        sourceComponent: root.isVertical ? sideLayoutComponent : topLayoutComponent
    }

    Component {
        id: topLayoutComponent

        Item {
            id: topItem
            readonly property var pill: recPill
            implicitWidth: recPill.width
            implicitHeight: recPill.height

            Rectangle {
                id: recPill
                property bool initAnimTrigger: root.isPreview

                height: root.pillHeight
                property real targetWidth: (root.isActive && (root.showIcon || root.showText)) ? (contentRow.implicitWidth + s(root.isCompact ? 16 : 20)) : 0
                width: targetWidth
                Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutQuint } }

                scale: recMouseArea.pressed ? 0.94 : (recMouseArea.containsMouse ? 1.04 : 1.0)
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                radius: Math.max(0, ThemeBackend.borderRadius - s(2))
                property color baseColor: root.isCompact ? Qt.lighter(ThemeBackend.surface0, 1.18) : ThemeBackend.surface0
                color: recPillGlass.active ? "transparent" : (recMouseArea.pressed ? Qt.darker(baseColor, 1.15) : (recMouseArea.containsMouse ? Qt.lighter(baseColor, 1.08) : baseColor))
                Behavior on color { ColorAnimation { duration: 150 } }
                border.color: root.isRecording ? Qt.alpha(ThemeBackend.red, 0.6) : (root.isCompact ? ThemeBackend.surface2 : ThemeBackend.surface1)
                border.width: 1

                GlassFill {
                    id: recPillGlass
                    anchors.fill: parent
                    radius: parent.radius
                    tintColor: parent.baseColor
                    tintAmount: 0.3
                    press: recMouseArea.pressed ? 1 : (recMouseArea.containsMouse ? 0.25 : 0)
                    Behavior on press { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                }
                clip: true

                Timer {
                    running: !root.isPreview && (!module || module.moduleActive) && root.showLayout && !recPill.initAnimTrigger
                    interval: 100
                    onTriggered: recPill.initAnimTrigger = true
                }

                opacity: (initAnimTrigger && root.isActive) ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                Row {
                    id: contentRow
                    anchors.centerIn: parent
                    height: parent.height
                    spacing: s(root.isCompact ? 6 : 8)

                    // Banner Notification View
                    Row {
                        id: bannerRow
                        visible: RecorderState.bannerActive
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: s(root.isCompact ? 5 : 6)

                        Text {
                            text: RecorderState.bannerIcon
                            font.family: ThemeBackend.iconFont
                            font.pixelSize: s(root.isCompact ? 13 : 14)
                            color: RecorderState.bannerColor
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: RecorderState.bannerBody ? RecorderState.bannerBody : RecorderState.bannerTitle
                            font.family: ThemeBackend.fontFamily
                            font.pixelSize: s(root.isCompact ? 11 : 12)
                            font.bold: true
                            color: ThemeBackend.text
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Recording Live View
                    Row {
                        id: liveRow
                        visible: !RecorderState.bannerActive && RecorderState.isRecording
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: s(root.isCompact ? 6 : 7)

                        // Pulsing Red Dot
                        Rectangle {
                            width: s(root.isCompact ? 8 : 10)
                            height: width
                            radius: width / 2
                            color: ThemeBackend.red
                            anchors.verticalCenter: parent.verticalCenter

                            SequentialAnimation on opacity {
                                running: RecorderState.isRecording
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.25; duration: 600; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                            }
                        }

                        // Text "REC"
                        Text {
                            text: "REC"
                            font.family: ThemeBackend.fontFamily
                            font.pixelSize: s(root.isCompact ? 10 : 11)
                            font.bold: true
                            color: ThemeBackend.red
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Timer Display
                        Text {
                            text: RecorderState.recTimeFormatted
                            font.family: ThemeBackend.fontFamily
                            font.pixelSize: s(root.isCompact ? 11 : 12.5)
                            font.bold: true
                            color: ThemeBackend.text
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Audio Mode Tag
                        Rectangle {
                            height: s(root.isCompact ? 18 : 20)
                            radius: s(4)
                            color: Qt.alpha(RecorderState.audioColor, 0.16)
                            border.color: Qt.alpha(RecorderState.audioColor, 0.45)
                            border.width: 1
                            anchors.verticalCenter: parent.verticalCenter
                            implicitWidth: audioRow.implicitWidth + s(root.isCompact ? 8 : 10)

                            Row {
                                id: audioRow
                                anchors.centerIn: parent
                                spacing: s(3)

                                Text {
                                    text: RecorderState.audioIcon
                                    font.family: ThemeBackend.iconFont
                                    font.pixelSize: s(root.isCompact ? 10 : 11)
                                    color: RecorderState.audioColor
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: RecorderState.audioLabel
                                    font.family: ThemeBackend.fontFamily
                                    font.pixelSize: s(root.isCompact ? 9 : 10)
                                    font.bold: true
                                    color: RecorderState.audioColor
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }
                }

                MouseArea {
                    id: recMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (!root.isPreview) {
                            if (mouse.button === Qt.RightButton) {
                                RecorderState.toggleAudio();
                            } else {
                                RecorderState.toggleRecording();
                            }
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
                height: (root.isActive && (root.showIcon || root.showText)) ? (sideCol.implicitHeight + s(root.isCompact ? 10 : 12)) : 0
                Behavior on height { NumberAnimation { duration: 320; easing.type: Easing.OutQuint } }

                radius: Math.max(0, ThemeBackend.borderRadius - s(2))
                property color baseColor: root.isCompact ? Qt.lighter(ThemeBackend.surface0, 1.18) : ThemeBackend.surface0
                color: sideMouseArea.pressed ? Qt.darker(baseColor, 1.15) : (sideMouseArea.containsMouse ? Qt.lighter(baseColor, 1.08) : baseColor)
                border.color: root.isRecording ? Qt.alpha(ThemeBackend.red, 0.6) : (root.isCompact ? ThemeBackend.surface2 : ThemeBackend.surface1)
                border.width: 1
                clip: true

                property bool initAnimTrigger: root.isPreview
                Timer {
                    running: !root.isPreview && (!module || module.moduleActive) && root.showLayout && !sideBtn.initAnimTrigger
                    interval: 100
                    onTriggered: sideBtn.initAnimTrigger = true
                }

                opacity: (initAnimTrigger && root.isActive) ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                Column {
                    id: sideCol
                    anchors.centerIn: parent
                    width: parent.width
                    spacing: s(2)

                    Rectangle {
                        width: s(root.isCompact ? 7 : 8)
                        height: width
                        radius: width / 2
                        color: ThemeBackend.red
                        anchors.horizontalCenter: parent.horizontalCenter
                        SequentialAnimation on opacity {
                            running: RecorderState.isRecording
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.25; duration: 600; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                        }
                    }

                    Text {
                        text: RecorderState.bannerActive ? RecorderState.bannerIcon : (RecorderState.recSeconds > 0 ? (RecorderState.recSeconds + "s") : "REC")
                        font.family: RecorderState.bannerActive ? ThemeBackend.iconFont : ThemeBackend.fontFamily
                        font.pixelSize: s(root.isCompact ? 9 : 10)
                        font.bold: true
                        color: RecorderState.bannerActive ? RecorderState.bannerColor : ThemeBackend.text
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: RecorderState.audioIcon
                        font.family: ThemeBackend.iconFont
                        font.pixelSize: s(root.isCompact ? 9 : 10)
                        color: RecorderState.audioColor
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                MouseArea {
                    id: sideMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (!root.isPreview) {
                            if (mouse.button === Qt.RightButton) {
                                RecorderState.toggleAudio();
                            } else {
                                RecorderState.toggleRecording();
                            }
                        }
                    }
                }
            }
        }
    }
}
