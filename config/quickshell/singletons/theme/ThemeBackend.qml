pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../"

Item {
    id: root

    property string fontFamily: "Adwaita Mono"
    property int borderRadius: 8
    property int clampedBorderRadius: {
        const r = borderRadius;
        return Math.floor(
            r <= 24
                ? r
                : 24 + Math.pow(r - 24, 0.55)
        );
    }

    property real elementOpacity: 1.0
    property bool blurBackground: false
    property string blurStyle: "blur"
    readonly property real liquidGlassOpacity: 0.1
    readonly property bool glassActive: blurBackground && elementOpacity < 0.999
    readonly property bool liquidGlass: blurBackground && blurStyle === "liquid"

    property bool colorAnimationsEnabled: false

    property color base: "#140c0c"
    property color mantle: "#231919"
    property color crust: "#1a1111"
    property color _text: "#f0dedd"
    property color _subtext0: "#d7c1c0"
    property color _subtext1: "#a08c8b"
    readonly property color text: liquidGlass ? "#ffffff" : _text
    readonly property color subtext0: liquidGlass ? "#ffffff" : _subtext0
    readonly property color subtext1: liquidGlass ? "#ffffff" : _subtext1
    property color surface0: "#271d1d"
    property color surface1: "#322827"
    property color surface2: "#3d3232"
    property color overlay0: "#f0dedd"
    property color overlay1: "#f0dedd"
    property color overlay2: "#f0dedd"
    property color blue: "#ffb3b1"
    readonly property color primary: blue
    property color sapphire: "#733334"
    property color peach: "#e4c18d"
    property color green: "#e6bdbb"
    property color red: "#ffb4ab"
    property color mauve: "#ffb3b1"
    property color pink: "#5a4319"
    property color yellow: "#5d3f3e"
    property color maroon: "#93000a"
    property color teal: "#e6bdbb"

    Behavior on base { enabled: root.colorAnimationsEnabled; ColorAnimation { duration: 800; easing.type: Easing.InOutCubic } }
    Behavior on mantle { enabled: root.colorAnimationsEnabled; ColorAnimation { duration: 800; easing.type: Easing.InOutCubic } }
    Behavior on crust { enabled: root.colorAnimationsEnabled; ColorAnimation { duration: 800; easing.type: Easing.InOutCubic } }
    Behavior on _text { enabled: root.colorAnimationsEnabled; ColorAnimation { duration: 800; easing.type: Easing.InOutCubic } }
    Behavior on _subtext0 { enabled: root.colorAnimationsEnabled; ColorAnimation { duration: 800; easing.type: Easing.InOutCubic } }
    Behavior on _subtext1 { enabled: root.colorAnimationsEnabled; ColorAnimation { duration: 800; easing.type: Easing.InOutCubic } }
    Behavior on surface0 { enabled: root.colorAnimationsEnabled; ColorAnimation { duration: 800; easing.type: Easing.InOutCubic } }
    Behavior on surface1 { enabled: root.colorAnimationsEnabled; ColorAnimation { duration: 800; easing.type: Easing.InOutCubic } }
    Behavior on surface2 { enabled: root.colorAnimationsEnabled; ColorAnimation { duration: 800; easing.type: Easing.InOutCubic } }
    Behavior on overlay0 { enabled: root.colorAnimationsEnabled; ColorAnimation { duration: 800; easing.type: Easing.InOutCubic } }
    Behavior on overlay1 { enabled: root.colorAnimationsEnabled; ColorAnimation { duration: 800; easing.type: Easing.InOutCubic } }
    Behavior on overlay2 { enabled: root.colorAnimationsEnabled; ColorAnimation { duration: 800; easing.type: Easing.InOutCubic } }
    Behavior on blue { enabled: root.colorAnimationsEnabled; ColorAnimation { duration: 800; easing.type: Easing.InOutCubic } }
    Behavior on sapphire { enabled: root.colorAnimationsEnabled; ColorAnimation { duration: 800; easing.type: Easing.InOutCubic } }
    Behavior on peach { enabled: root.colorAnimationsEnabled; ColorAnimation { duration: 800; easing.type: Easing.InOutCubic } }
    Behavior on green { enabled: root.colorAnimationsEnabled; ColorAnimation { duration: 800; easing.type: Easing.InOutCubic } }
    Behavior on red { enabled: root.colorAnimationsEnabled; ColorAnimation { duration: 800; easing.type: Easing.InOutCubic } }
    Behavior on mauve { enabled: root.colorAnimationsEnabled; ColorAnimation { duration: 800; easing.type: Easing.InOutCubic } }
    Behavior on pink { enabled: root.colorAnimationsEnabled; ColorAnimation { duration: 800; easing.type: Easing.InOutCubic } }
    Behavior on yellow { enabled: root.colorAnimationsEnabled; ColorAnimation { duration: 800; easing.type: Easing.InOutCubic } }
    Behavior on maroon { enabled: root.colorAnimationsEnabled; ColorAnimation { duration: 800; easing.type: Easing.InOutCubic } }
    Behavior on teal { enabled: root.colorAnimationsEnabled; ColorAnimation { duration: 800; easing.type: Easing.InOutCubic } }

    Timer {
        id: enableAnimTimer
        interval: 350
        running: true
        repeat: false
        onTriggered: root.colorAnimationsEnabled = true
    }

    property string configPath: Quickshell.env("QS_COLORS_JSON") ?? "~/.local/state/quickshell/qs_colors.json"
    property string matugenConfigPath: (typeof Caching !== "undefined" && Caching.stateDir ? Caching.stateDir : ((Quickshell.env("HOME") ?? "") + "/.local/state/quickshell")) + "/qs_matugen_colors.json"

    property bool _readInProgress: false
    property var matugenColors: null

    property var availableFontPaths: ({})
    property var bundledNames: []
    property string activeFontPath: ""

    FontLoader {
        id: iconFontLoader
        source: (typeof Caching !== "undefined" && Caching.quickshellDir && Caching.quickshellDir !== "")
            ? ("file://" + Caching.quickshellDir + "/assets/fonts/SymbolsNerdFontMono-Regular.ttf")
            : ""
    }

    readonly property string iconFont: (iconFontLoader.status === FontLoader.Ready && iconFontLoader.name !== "")
        ? iconFontLoader.name
        : (root.fontFamily !== "" ? root.fontFamily : "sans-serif")
    readonly property bool iconFontReady: iconFontLoader.status === FontLoader.Ready

    onFontFamilyChanged: {
        root.updateActiveFontLoader();
    }

    function isMatugenTheme() {
        if (typeof Matugen !== "undefined" && typeof Matugen.isMatugenTheme === "function") {
            return Matugen.isMatugenTheme();
        }
        let themeConfig = Config.getSetting("theme", { "matugen": true, "activePreset": "Matugen" });
        if (themeConfig.matugen !== undefined) {
            return themeConfig.matugen === true;
        }
        return themeConfig.theme === "matugen"
            || themeConfig.name === "matugen"
            || themeConfig.currentTheme === "matugen"
            || themeConfig.current === "matugen"
            || themeConfig.activePreset === "Matugen"
            || themeConfig.activePreset === undefined;
    }

    function updateActiveFontLoader() {
        if (!root.fontFamily || root.fontFamily === "") return;
        let key = root.fontFamily.toLowerCase();
        let path = root.availableFontPaths ? root.availableFontPaths[key] : "";

        if (path && root.activeFontPath !== path) {
            root.activeFontPath = path;
        }
    }

    FontLoader {
        id: staticFontLoader
        source: (root.activeFontPath && root.activeFontPath !== "") ? ("file://" + root.activeFontPath) : ""
        onStatusChanged: {
            if (status === FontLoader.Ready) {
                let cur = root.fontFamily;
                root.fontFamily = "";
                root.fontFamily = cur;
            }
        }
    }

    Process {
        id: fontFetcher
        property bool forceRescan: false

        command: {
            let sys = Caching.quickshellDir ? (Caching.quickshellDir + "/assets/fonts") : "";
            let usr = Caching.stateDir ? (Caching.stateDir + "/fonts") : (Caching.home + "/.local/state/quickshell/fonts");
            let cacheFile = Caching.stateDir ? (Caching.stateDir + "/fonts_cache.txt") : (Caching.home + "/.local/state/quickshell/fonts_cache.txt");
            let force = forceRescan ? "true" : "false";

            let cmd = "CACHE=\"" + cacheFile + "\"; ";
            cmd += "if [ \"" + force + "\" = \"true\" ] || [ ! -f \"$CACHE\" ]; then ";
            cmd += "mkdir -p \"$(dirname \"$CACHE\")\"; ";
            cmd += "find ";
            if (sys !== "") cmd += "\"" + sys + "\" ";
            cmd += "\"" + usr + "\" -type f \\( -iname \"*.ttf\" -o -iname \"*.otf\" -o -iname \"*.ttc\" \\) -print0 2>/dev/null | sort -z | ";
            cmd += "xargs -0 -r fc-scan -f '%{family[0]}\\t%{style[0]}\\t%{file}\\n' 2>/dev/null | ";
            cmd += "awk -F'\\t' '{ fam=$1; stl=$2; f=$3; if (fam==\"\") { n=split(f,a,\"/\"); fam=a[n]; sub(/\\.[^.]*$/,\"\",fam) } if (stl!=\"\" && stl!=\"Regular\") print fam \" \" stl \"|\" f; else print fam \"|\" f }' ";
            cmd += "> \"$CACHE.tmp\" || true; mv \"$CACHE.tmp\" \"$CACHE\"; ";
            cmd += "fi; ";
            cmd += "cat \"$CACHE\" || true";

            return ["bash", "-c", cmd];
        }
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                fontFetcher.forceRescan = false;

                let lines = this.text.trim().split('\n');
                let newPaths = {};
                let names = [];
                let seen = new Set();

                for (let i = 0; i < lines.length; i++) {
                    let line = lines[i].trim();
                    if (line === "") continue;

                    let idx = line.indexOf('|');
                    if (idx !== -1) {
                        let fName = line.substring(0, idx).trim();
                        if (fName.toLowerCase().indexOf("symbols nerd font") !== -1) continue;

                        let fPath = line.substring(idx + 1).trim();
                        let key = fName.toLowerCase();

                        newPaths[key] = fPath;

                        if (!seen.has(key)) {
                            seen.add(key);
                            names.push(fName);
                        }
                    }
                }

                root.availableFontPaths = newPaths;
                root.bundledNames = names;
                root.updateActiveFontLoader();
                if (staticFontLoader.status === FontLoader.Ready) {
                    let cur = root.fontFamily;
                    root.fontFamily = "";
                    root.fontFamily = cur;
                }
            }
        }
    }

    function scanFonts() {
        fontFetcher.running = false;
        fontFetcher.forceRescan = true;
        fontFetcher.running = true;
    }

    function reloadColors() {
        if (root._readInProgress) return;
        root._readInProgress = true;
        root.updateColors();
    }

    IpcHandler {
        target: "theme"

        function reloadColors() {
            root.reloadColors();
        }
    }

    IpcHandler {
        target: "fonts"
        function rescan() {
            root.scanFonts();
        }
    }

    Connections {
        target: Config
        function onSettingsLoaded() {
            root.updateColors();
        }
        function onRawSettingsChanged() {
            root.syncElementOpacity();
        }
    }

    Connections {
        target: typeof Matugen !== "undefined" ? Matugen : null
        function onGenerationFinished(success) {
            root._readInProgress = false;
            if (success) {
                if (root.isMatugenTheme()) {
                    matugenColorsWatcher.reload();
                } else {
                    themeWatcher.reload();
                }
            }
        }
    }

    function applyMatugenColors(): bool {
        if (root.matugenColors) {
            root.applyColorObject(root.matugenColors);
            return true;
        }
        return false;
    }

    function faded(c) {
        return Qt.alpha(c, root.elementOpacity);
    }

    function syncElementOpacity() {
        const themeConfig = Config.getSetting("theme", {});
        const pct = themeConfig.elementOpacity !== undefined ? Number(themeConfig.elementOpacity) : 100;
        root.blurBackground = themeConfig.blurBackground !== undefined ? Boolean(themeConfig.blurBackground) : false;
        root.blurStyle = themeConfig.blurStyle === "liquid" ? "liquid" : "blur";
        root.elementOpacity = root.liquidGlass ? root.liquidGlassOpacity : (isNaN(pct) ? 1.0 : Math.max(0, Math.min(1.0, pct / 100.0)));
    }

    function updateColors() {
        let themeConfig = Config.getSetting("theme", {});

        if (themeConfig.fontFamily !== undefined) {
            root.fontFamily = themeConfig.fontFamily;
        }
        if (themeConfig.borderRadius !== undefined) {
            root.borderRadius = themeConfig.borderRadius;
        }
        root.syncElementOpacity();

        let customColors = themeConfig.colors || themeConfig.palette || (themeConfig.base !== undefined ? themeConfig : null);

        if (root.isMatugenTheme()) {
            root.applyMatugenColors();
            let wp = themeConfig.wallpaper || Config.getSetting("wallpaper", "");
            if (typeof Matugen !== "undefined" && typeof Matugen.generate === "function") {
                Matugen.generate(wp, themeConfig.mode, themeConfig.schemeType);
            }
            root._readInProgress = false;
        } else {
            root._readInProgress = false;
            if (customColors) {
                root.applyColorObject(customColors);
                if (typeof Matugen !== "undefined" && typeof Matugen.generateFromStatic === "function") {
                    Matugen.generateFromStatic(customColors, themeConfig.mode);
                }
            } else {
                themeWatcher.reload();
            }
        }
    }

    function applyColorObject(c) {
        if (!c) return;

        let resolveHex = function(val) {
            if (!val) return "";
            if (typeof val === "string") return val;
            if (typeof val === "object") {
                if (val.hex) return val.hex;
                if (val.color) return val.color;
                if (val.default && val.default.hex) return val.default.hex;
            }
            return val.toString();
        };

        let names = ["base", "mantle", "crust", "surface0", "surface1", "surface2",
                     "overlay0", "overlay1", "overlay2", "text", "subtext0", "subtext1",
                     "blue", "sapphire", "peach", "green", "red", "mauve", "pink",
                     "yellow", "maroon", "teal"];

        for (let i = 0; i < names.length; i++) {
            let hexColor = resolveHex(c[names[i]]);
            if (!hexColor) continue;
            let nextColor = Qt.color(hexColor);
            let slot = (names[i] === "text" || names[i] === "subtext0" || names[i] === "subtext1") ? "_" + names[i] : names[i];
            if (root[slot].toString() !== nextColor.toString()) {
                root[slot] = nextColor;
            }
        }
    }

    FileView {
        id: matugenColorsWatcher
        path: root.matugenConfigPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            let txt = text().trim();
            if (txt !== "") {
                try {
                    let c = JSON.parse(txt);
                    let target = c && c.colors ? c.colors : c;
                    if (target) {
                        root.matugenColors = target;
                        if (root.isMatugenTheme()) {
                            root.applyColorObject(target);
                        }
                    }
                } catch(e) {}
            }
        }
    }

    FileView {
        id: themeWatcher
        path: root.configPath.startsWith("~") ? (Quickshell.env("HOME") ?? "") + root.configPath.slice(1) : root.configPath
        watchChanges: false

        onLoaded: {
            root._readInProgress = false;
            let txt = text().trim();
            if (txt !== "") {
                try {
                    let c = JSON.parse(txt);
                    let target = c && c.colors ? c.colors : c;
                    if (target) {
                        if (root.isMatugenTheme()) {
                            root.matugenColors = target;
                        }
                        root.applyColorObject(target);
                    }
                } catch(e) {}
            }
        }
    }

    Component.onCompleted: {
        root._readInProgress = true;
        root.updateColors();
        root.updateActiveFontLoader();
    }
}
