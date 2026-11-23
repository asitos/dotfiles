import QtQuick
import "../../"
import "../../../"

Item {
    id: root

    property var scaleFn: null
    property real cornerRadius: -1
    readonly property real effRadius: cornerRadius >= 0 ? cornerRadius : ThemeBackend.borderRadius
    property string leftIcon: ""
    property color leftTextColor: ThemeBackend.text
    property string playIcon: ""
    property color playAccent: ThemeBackend.mauve
    property bool showRight: false
    property string rightIcon: ""

    signal leftClicked()
    signal playClicked()
    signal rightClicked()

    function s(val) {
        return typeof scaleFn === "function" ? scaleFn(val) : val;
    }

    implicitHeight: s(64)

    IconButton {
        size: root.s(50)
        cornerRadius: root.effRadius
        buttonIcon: root.leftIcon
        iconFontSize: root.s(16)
        accentColor: ThemeBackend.surface0
        bgOpacity: ThemeBackend.elementOpacity
        textColor: root.leftTextColor
        anchors.right: playButton.left
        anchors.rightMargin: root.s(20)
        anchors.verticalCenter: playButton.verticalCenter
        onClicked: root.leftClicked()
    }

    IconButton {
        id: playButton
        size: root.s(64)
        cornerRadius: root.effRadius
        buttonIcon: root.playIcon
        iconFontSize: root.s(24)
        accentColor: root.playAccent
        bgOpacity: ThemeBackend.elementOpacity
        textColor: ThemeBackend.mantle
        anchors.centerIn: parent
        onClicked: root.playClicked()
    }

    IconButton {
        visible: root.showRight
        size: root.s(50)
        cornerRadius: root.effRadius
        buttonIcon: root.rightIcon
        iconFontSize: root.s(16)
        accentColor: ThemeBackend.surface0
        bgOpacity: ThemeBackend.elementOpacity
        textColor: ThemeBackend.text
        anchors.left: playButton.right
        anchors.leftMargin: root.s(20)
        anchors.verticalCenter: playButton.verticalCenter
        onClicked: root.rightClicked()
    }
}
