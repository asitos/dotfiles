import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Window
import QtCore
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Networking
import "../"
import "../reusables"

Item {
    required property var window
    anchors.fill: parent
    z: 100

    Rectangle {
        id: keyHintBar
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: window.s(9)
        height: window.s(26)
        width: Math.min(parent.width - window.s(24), hintRow.implicitWidth + window.s(24))
        radius: height / 2
        visible: window.visible
        opacity: window.easeOut(window.animWin(window.introState, 0.25, 0.50))
        color: hintGlass.active ? "transparent" : Qt.alpha(ThemeBackend.base, Math.min(0.92, ThemeBackend.elementOpacity))
        border.width: hintGlass.active ? 0 : 1
        border.color: Qt.alpha(window.activeColor, 0.4)

        GlassFill {
            id: hintGlass
            anchors.fill: parent
            radius: parent.radius
            tintColor: ThemeBackend.surface0
            tintAmount: 0.28
        }

        readonly property var keyHints: {
            if (window.pendingWifiId !== "") {
                return [
                    { key: [], raw: "Enter", text: "connect", act: "" },
                    { key: [], raw: "Esc", text: "cancel", act: "cancel_pwd" }
                ];
            }
            let h = [
                { key: ["h", "l"], text: "h/l tab", act: "tab" }
            ];
            if (window.currentPower && window.orbitModel.count > 0) {
                h.push({ key: ["j", "k"], text: "j/k nav", act: "nav" });
                h.push({ key: "c", text: "connect", act: "connect" });
            }
            if (window.currentConn) {
                h.push({ key: "d", text: "disconnect", act: "disconnect" });
                if (window.showInfoView) {
                    h.push({ key: "s", text: "scan", act: "scan" });
                    h.push({ key: "y", text: "yank ip", act: "yank" });
                    if (window.activeMode === "bt") h.push({ key: "u", text: "unpair", act: "unpair" });
                } else {
                    h.push({ key: "i", text: "info", act: "info" });
                    h.push({ key: "r", text: "rescan", act: "rescan" });
                }
            } else if (window.currentPower) {
                h.push({ key: "r", text: "rescan", act: "rescan" });
            }
            h.push({ key: "p", text: "power", act: "power" });
            h.push({ key: "q", text: "quit", act: "quit" });
            return h;
        }

        Row {
            id: hintRow
            anchors.centerIn: parent
            spacing: window.s(9)

            Repeater {
                model: keyHintBar.keyHints
                Row {
                    id: hintSlot
                    required property var modelData
                    required property int index
                    spacing: window.s(9)
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        visible: hintSlot.index > 0
                        text: "·"
                        font.family: ThemeBackend.fontFamily
                        font.pixelSize: window.s(11)
                        color: Qt.alpha(ThemeBackend.subtext1, 0.5)
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        readonly property color hlCol: ThemeBackend.liquidGlass ? Qt.lighter(window.activeColor, 1.25) : window.activeColor
                        readonly property color restCol: hintMa.containsMouse ? ThemeBackend.text : Qt.alpha(ThemeBackend.subtext0, 0.62)
                        textFormat: Text.StyledText
                        text: hintSlot.modelData.raw
                            ? ("<font color=\"" + hlCol + "\"><u><b>" + hintSlot.modelData.raw + "</b></u></font> <font color=\"" + restCol + "\">" + window.escapeHtml(hintSlot.modelData.text) + "</font>")
                            : window.formatMnemonic(hintSlot.modelData.text, hintSlot.modelData.key, hlCol, restCol)
                        font.family: ThemeBackend.fontFamily
                        font.pixelSize: window.s(11.5)
                        color: restCol
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            id: hintMa
                            anchors.fill: parent
                            anchors.margins: -window.s(3)
                            hoverEnabled: true
                            enabled: hintSlot.modelData.act !== ""
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                let a = hintSlot.modelData.act;
                                if (a === "tab") window.nextTab();
                                else if (a === "nav") window.stepSelection(1);
                                else if (a === "connect") window.triggerSelected();
                                else if (a === "disconnect") window.disconnectCurrentDevice();
                                else if (a === "scan") window.handleScanKey();
                                else if (a === "info") window.showInfoView = !window.showInfoView;
                                else if (a === "rescan") window.rescanCurrent();
                                else if (a === "yank") window.yankIp();
                                else if (a === "unpair") window.unpairTargetedBtDevice();
                                else if (a === "power") window.toggleCurrentPower();
                                else if (a === "quit") window.closePopup();
                                else if (a === "cancel_pwd") { window.pendingWifiId = ""; window.pendingWifiSsid = ""; window.forceActiveFocus(); }
                            }
                        }
                    }
                }
            }
        }
    }

    Switch {
        id: bottomSwitch
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: window.s(18)
        implicitWidth: window.s(320)
        implicitHeight: window.s(42)
        opacity: window.easeOut(window.animWin(window.introState, 0.25, 0.50))
        scale: 0.9 + 0.1 * window.easeBack(window.animWin(window.introState, 0.25, 0.50))
        transform: Translate { y: (1 - window.easeOut(window.animWin(window.introState, 0.25, 0.50))) * window.s(26) }
        fontPixelSize: window.s(14)
        cornerRadius: ThemeBackend.borderRadius
        accentColor: window.activeColor
        baseColor: "#1affffff"
        textColor: ThemeBackend.text
        activeTextColor: ThemeBackend.crust
        switchSound: "network/switch.wav"
        visible: window.visible && availableModes.length > 0
        enabled: window.visible

        readonly property var availableModes: {
            let m = [];
            if (window.ethPresent) m.push({ mode: "eth", key: "e", label: "󰈀  " + (I18n.t("network.tabs.ethernet") || "Ethernet") });
            if (window.wifiPresent) m.push({ mode: "wifi", key: "w", label: "󰤨  " + (I18n.t("network.tabs.wifi") || "Wi-fi") });
            if (window.btPresent) m.push({ mode: "bt", key: "b", label: "󰂯 " + (I18n.t("network.tabs.bluetooth") || "Bluetooth") });
            return m;
        }

        options: {
            let opts = [];
            for (let i = 0; i < availableModes.length; i++) {
                if (availableModes[i] && availableModes[i].label) {
                    opts.push(availableModes[i].label);
                }
            }
            return opts;
        }

        optionDisplayTexts: {
            let arr = [];
            let modes = availableModes;
            for (let i = 0; i < modes.length; i++) {
                if (modes[i] && modes[i].label) {
                    let isSel = (i === bottomSwitch.currentIndex);
                    let hlCol = isSel
                        ? (ThemeBackend.liquidGlass ? Qt.lighter(window.activeColor, 1.35) : ThemeBackend.crust)
                        : (ThemeBackend.liquidGlass ? Qt.lighter(window.activeColor, 1.25) : window.activeColor);
                    let restCol = isSel
                        ? (ThemeBackend.liquidGlass ? Qt.alpha(ThemeBackend.text, 0.72) : Qt.alpha(ThemeBackend.crust, 0.74))
                        : Qt.alpha(ThemeBackend.text, 0.65);
                    arr.push(window.formatMnemonic(modes[i].label, modes[i].key, hlCol, restCol));
                }
            }
            return arr;
        }

        Binding on currentIndex {
            value: {
                let modes = bottomSwitch.availableModes;
                for (let i = 0; i < modes.length; i++) {
                    if (modes[i] && modes[i].mode === window.activeMode) return i;
                }
                return 0;
            }
        }

        onToggled: val => {
            if (window.pendingWifiId !== "") { window.pendingWifiId = ""; window.pendingWifiSsid = ""; }
            let modes = bottomSwitch.availableModes;
            if (!modes || modes.length === 0) return;
            let chosen = "";
            if (typeof val === "number") {
                if (val >= 0 && val < modes.length && modes[val]) {
                    chosen = modes[val].mode;
                }
            } else if (typeof val === "string") {
                for (let i = 0; i < modes.length; i++) {
                    if (modes[i] && (modes[i].label === val || modes[i].mode === val)) {
                        chosen = modes[i].mode;
                        break;
                    }
                }
            }
            if (chosen && chosen !== "" && window.activeMode !== chosen) {
                window.powerAnimAllowed = false;
                window.powerAnimBlockerTimer.restart();
                window.activeMode = chosen;
            }
        }
    }

    Item {
        id: powerToggleContainer
        z: 100

        property real pwrIntroProg: window.easeOut(window.animWin(window.introState, 0.10, 0.35))
        opacity: pwrIntroProg
        scale: window.easeBack(window.animWin(window.introState, 0.10, 0.35))

        property real pwrMorph: window.currentPower ? 1.0 : 0.0
        Behavior on pwrMorph {
            enabled: window.powerAnimAllowed && window.visible;
            NumberAnimation { duration: 800; easing.type: Easing.InOutQuint }
        }

        width: window.s(140) + (window.s(42) - window.s(140)) * pwrMorph
        height: width

        x: ((parent.width / 2) - window.s(70)) + ((parent.width - window.s(24) - window.s(42)) - ((parent.width / 2) - window.s(70))) * pwrMorph
        y: (((parent.height - window.s(65)) / 2) - window.s(70)) + ((parent.height - window.s(24) - window.s(42)) - (((parent.height - window.s(65)) / 2) - window.s(70))) * pwrMorph

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: window.s(2)
            anchors.bottomMargin: -window.s(2)
            radius: width / 2
            color: Qt.rgba(0, 0, 0, 0.16)
            visible: !powerGlass.active
            z: -1
        }

        Rectangle {
            id: powerBtnRect
            anchors.fill: parent
            radius: width / 2

            scale: pwrMa.pressed ? 0.95 : (pwrMa.containsMouse ? 1.05 : 1.0)
            Behavior on scale { enabled: window.visible; NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

            color: (window.currentPower || powerGlass.active) ? "transparent" : Qt.alpha(pwrMa.containsMouse ? Qt.lighter(ThemeBackend.base, 1.6) : Qt.lighter(ThemeBackend.base, 1.3), ThemeBackend.elementOpacity)
            Behavior on color { enabled: window.visible; ColorAnimation { duration: 250 } }


            GlassFill {
                id: powerGlass
                anchors.fill: parent
                radius: parent.radius
                shadow: 1
                tintColor: window.currentPower ? window.activeColor : ThemeBackend.surface0
                tintAmount: window.currentPower ? 0.45 : 0.3
                press: pwrMa.pressed ? 0.8 : (pwrMa.containsMouse ? 0.25 : 0)
                Behavior on press { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                Behavior on tintAmount { NumberAnimation { duration: 800; easing.type: Easing.InOutQuint } }
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                visible: !powerGlass.active
                opacity: window.currentPower ? ThemeBackend.elementOpacity : 0.0
                Behavior on opacity { enabled: window.powerAnimAllowed && window.visible; NumberAnimation { duration: 800; easing.type: Easing.InOutQuint } }
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.lighter(window.activeColor, 1.15) }
                    GradientStop { position: 1.0; color: window.activeColor }
                }
            }

            Text {
                id: pwrIcon
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -(1.0 - powerToggleContainer.pwrMorph) * window.s(9)
                font.family: ThemeBackend.fontFamily
                font.pixelSize: window.s(54)
                scale: 1.0 + ((20.0 / 54.0) - 1.0) * powerToggleContainer.pwrMorph
                color: powerGlass.active ? ThemeBackend.text : (window.currentPower ? ThemeBackend.crust : ThemeBackend.subtext0)
                text: window.currentPowerPending ? "󰑮" : ""
                Behavior on color { enabled: window.powerAnimAllowed && window.visible; ColorAnimation { duration: 800; easing.type: Easing.InOutQuint } }

                RotationAnimation {
                    target: pwrIcon
                    property: "rotation"
                    from: 0; to: 360
                    duration: 800
                    loops: Animation.Infinite
                    running: window.visible && window.currentPowerPending
                    onRunningChanged: {
                        if (!running) pwrIcon.rotation = 0;
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: pwrIcon.bottom
                anchors.topMargin: window.s(2)
                opacity: Math.max(0, 1.0 - powerToggleContainer.pwrMorph * 2.0)
                visible: opacity > 0.01
                textFormat: Text.StyledText
                text: window.formatMnemonic("Power", "p", ThemeBackend.liquidGlass ? Qt.lighter(window.activeColor, 1.3) : window.activeColor, Qt.alpha(ThemeBackend.subtext0, 0.68))
                font.family: ThemeBackend.fontFamily
                font.pixelSize: window.s(11)
                font.weight: Font.Bold
                color: ThemeBackend.subtext1
            }

            MouseArea {
                id: pwrMa
                anchors.fill: parent
                enabled: window.visible
                hoverEnabled: window.visible
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    window.toggleCurrentPower();
                }
            }
        }

        Rectangle {
            id: pwrKeyBadge
            anchors.top: powerBtnRect.top
            anchors.right: powerBtnRect.right
            anchors.topMargin: -window.s(4)
            anchors.rightMargin: -window.s(4)
            width: window.s(18)
            height: window.s(18)
            radius: width / 2
            color: ThemeBackend.mantle
            border.width: 1
            border.color: window.activeColor
            opacity: Math.max(0, (powerToggleContainer.pwrMorph - 0.65) / 0.35)
            visible: opacity > 0.01
            z: 5

            Text {
                anchors.centerIn: parent
                textFormat: Text.StyledText
                text: window.formatMnemonic("P", "p", Qt.lighter(window.activeColor, ThemeBackend.liquidGlass ? 1.35 : 1.15))
                font.family: ThemeBackend.fontFamily
                font.pixelSize: window.s(10)
                color: window.activeColor
            }
        }
    }
}
