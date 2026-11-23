pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../"

Singleton {
    id: root

    property bool isRecording: false
    property int recSeconds: 0
    property real recStartEpoch: 0
    readonly property string recTimeFormatted: String(Math.floor(recSeconds / 60)).padStart(2, "0") + ":" + String(recSeconds % 60).padStart(2, "0")

    property string audioMode: "system"
    readonly property string audioIcon: {
        if (audioMode === "mic") return "󰍬";
        if (audioMode === "none") return "󰝟";
        return "󰕾";
    }
    readonly property string audioLabel: {
        if (audioMode === "mic") return "Mic";
        if (audioMode === "none") return "Muted";
        return "System";
    }
    readonly property color audioColor: {
        if (audioMode === "mic") return ThemeBackend.green;
        if (audioMode === "none") return ThemeBackend.red;
        return ThemeBackend.primary;
    }

    property bool bannerActive: false
    property string bannerTitle: ""
    property string bannerBody: ""
    property string bannerIcon: "󰻃"
    property color bannerColor: ThemeBackend.primary

    readonly property bool isActive: isRecording || bannerActive

    readonly property string pidFilePath: "/tmp/wfr.pid"
    readonly property string statusFilePath: "/tmp/wfr_status.json"
    readonly property string epochFilePath: "/tmp/wfr_start_epoch"
    readonly property string audioModeFilePath: (Quickshell.env("HOME") || "") + "/.cache/screen_recorder_audio_mode"

    function postNotification(title, body, audio) {
        bannerTitle = title || "";
        bannerBody = body || "";
        if (audio) audioMode = audio;

        let cleanTitle = bannerTitle.toLowerCase();
        let cleanBody = bannerBody.toLowerCase();

        if (cleanTitle.indexOf("mic") !== -1 || cleanBody.indexOf("mic") !== -1) {
            bannerIcon = "󰍬";
            bannerColor = ThemeBackend.green;
        } else if (cleanTitle.indexOf("mute") !== -1 || cleanBody.indexOf("mute") !== -1) {
            bannerIcon = "󰝟";
            bannerColor = ThemeBackend.red;
        } else if (cleanTitle.indexOf("system") !== -1 || cleanBody.indexOf("system") !== -1) {
            bannerIcon = "󰕾";
            bannerColor = ThemeBackend.primary;
        } else if (cleanTitle.indexOf("saved") !== -1 || cleanTitle.indexOf("✅") !== -1) {
            bannerIcon = "󰄬";
            bannerColor = ThemeBackend.green;
        } else if (cleanTitle.indexOf("failed") !== -1 || cleanTitle.indexOf("❌") !== -1 || cleanTitle.indexOf("stopped") !== -1) {
            bannerIcon = "󰅚";
            bannerColor = ThemeBackend.red;
        } else {
            bannerIcon = "󰻃";
            bannerColor = ThemeBackend.red;
        }

        bannerActive = true;
        bannerTimer.running = false;
        bannerTimer.running = true;
    }

    Timer {
        id: bannerTimer
        interval: 3500
        repeat: false
        onTriggered: {
            root.bannerActive = false;
        }
    }

    function toggleRecording() {
        Quickshell.execDetached(["bash", "-c", "~/.config/Scripts/screen_recorder.sh"]);
    }

    function toggleAudio() {
        Quickshell.execDetached(["bash", "-c", "~/.config/Scripts/screen_recorder.sh --toggle-audio"]);
    }

    function checkProcess() {
        if (!checkProc.running) {
            checkProc.running = true;
        }
    }

    Process {
        id: checkProc
        command: [
            "bash", "-c",
            "if [ -f '/tmp/wfr.pid' ]; then p=$(cat /tmp/wfr.pid 2>/dev/null); if [ -n \"$p\" ] && kill -0 \"$p\" 2>/dev/null; then ep=$(cat /tmp/wfr_start_epoch 2>/dev/null); echo \"RECORDING $p ${ep:-0}\"; else echo 'NONE'; fi; else echo 'NONE'; fi"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt.startsWith("RECORDING")) {
                    let parts = txt.split(" ");
                    let epoch = parts.length >= 3 ? parseInt(parts[2]) : 0;
                    if (!isNaN(epoch) && epoch > 0) {
                        root.recStartEpoch = epoch;
                    } else if (root.recStartEpoch === 0) {
                        root.recStartEpoch = Math.floor(Date.now() / 1000);
                    }
                    root.isRecording = true;
                } else {
                    root.isRecording = false;
                    root.recStartEpoch = 0;
                    root.recSeconds = 0;
                }
            }
        }
    }

    FileView {
        path: root.statusFilePath
        printErrors: false
        watchChanges: true
        onFileChanged: {
            try {
                let content = text();
                if (content && content.trim().length > 0) {
                    let data = JSON.parse(content);
                    if (data.title || data.body) {
                        root.postNotification(data.title || "", data.body || "", data.audio || "");
                    }
                    if (data.active !== undefined) {
                        root.isRecording = Boolean(data.active);
                    }
                    if (data.startEpoch && data.startEpoch > 0) {
                        root.recStartEpoch = data.startEpoch;
                    }
                    if (data.audio) {
                        root.audioMode = data.audio;
                    }
                }
            } catch (e) {}
            root.checkProcess();
        }
    }

    FileView {
        path: root.pidFilePath
        printErrors: false
        watchChanges: true
        onFileChanged: root.checkProcess()
    }

    FileView {
        path: root.audioModeFilePath
        printErrors: false
        watchChanges: true
        onFileChanged: {
            let m = text().trim();
            if (m) root.audioMode = m;
        }
    }

    Timer {
        id: secondTimer
        interval: 1000
        running: root.isRecording
        repeat: true
        onTriggered: {
            if (root.recStartEpoch > 0) {
                root.recSeconds = Math.max(0, Math.floor(Date.now() / 1000 - root.recStartEpoch));
            } else {
                root.recSeconds++;
            }
            if (root.recSeconds % 3 === 0) root.checkProcess();
        }
    }

    IpcHandler {
        target: "recorder"

        function notify(title: string, body: string, audio: string) {
            root.postNotification(title, body, audio);
        }

        function toggle() {
            root.toggleRecording();
        }

        function toggleAudio() {
            root.toggleAudio();
        }

        function check() {
            root.checkProcess();
        }
    }

    Component.onCompleted: {
        root.checkProcess();
    }
}
