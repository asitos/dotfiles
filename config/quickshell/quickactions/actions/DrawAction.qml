import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../"
import "../../reusables"

Item {
    id: root

    property int requestedLayoutTemplate: 2

    property bool isActiveTab: typeof isCurrentTarget !== "undefined" ? isCurrentTarget : true

    property string iconFont: ThemeBackend.iconFont
    property string safeActiveEdge: typeof activeEdge !== "undefined" ? activeEdge : "left"

    function s(val) {
        return typeof scaleFunc !== "undefined" ? scaleFunc(val) : val;
    }

    property bool isEnlarged: false
    property real baseW: s(isEnlarged ? 720 : 420)
    property real baseL: s(isEnlarged ? 540 : 350)

    property real preferredWidth: (root.safeActiveEdge === "bottom" || root.safeActiveEdge === "top") ? (isEnlarged ? s(580) : s(400)) : baseW
    property real preferredExtraLength: (root.safeActiveEdge === "bottom" || root.safeActiveEdge === "top") ? baseW : baseL

    property real counterRotation: {
        if (root.safeActiveEdge === "right") return 180;
        if (root.safeActiveEdge === "bottom") return 90;
        if (root.safeActiveEdge === "top") return -90;
        return 0;
    }

    property string currentTool: "pen"
    property var toolKeys: ["pen", "brush", "fill", "eraser"]
    property int currentToolIndex: Math.max(0, toolKeys.indexOf(currentTool))

    property bool showSizeConfig: false
    property bool showColorPicker: false
    property bool showBrushDropdown: false

    property var primaryHSV: ({ h: 0.74, s: 0.33, v: 0.97 })
    property var secondaryHSV: ({ h: 0.0, s: 0.0, v: 0.10 })
    property int activeColorSlot: 0

    property color primaryColor: Qt.hsva(primaryHSV.h, primaryHSV.s, primaryHSV.v, 1.0)
    property color secondaryColor: Qt.hsva(secondaryHSV.h, secondaryHSV.s, secondaryHSV.v, 1.0)
    property color currentColor: activeColorSlot === 0 ? primaryColor : secondaryColor

    property real penSizeRatio: 0.3
    property real brushSizeRatio: 0.4
    property real eraserSizeRatio: 0.6

    property real currentSizeRatio: {
        if (currentTool === "eraser") return eraserSizeRatio;
        if (currentTool === "brush") return brushSizeRatio;
        return penSizeRatio;
    }

    property real actualToolSize: {
        if (currentTool === "eraser") return s(8) + (currentSizeRatio * s(60));
        if (currentTool === "brush") return s(4) + (currentSizeRatio * s(40));
        return s(2) + (currentSizeRatio * s(30));
    }

    property color baseTextColor: ThemeBackend.text
    property color solidBgColor: ThemeBackend.mantle
    property color themeBaseColor: ThemeBackend.base

    property color panelBgColor: Qt.rgba(themeBaseColor.r, themeBaseColor.g, themeBaseColor.b, ThemeBackend.glassActive ? ThemeBackend.elementOpacity : 0.85)
    property color popupBgColor: Qt.rgba(themeBaseColor.r, themeBaseColor.g, themeBaseColor.b, ThemeBackend.glassActive ? ThemeBackend.elementOpacity : 0.98)
    property color panelBorderColor: Qt.rgba(baseTextColor.r, baseTextColor.g, baseTextColor.b, 0.15)

    property real minZoom: 0.1
    property real maxZoom: 5.0
    property real worldSize: 2048

    property var actionHistory: []
    property int historyStep: -1
    property int maxHistory: 100
    property int lockedCount: 0
    readonly property bool canUndo: historyStep >= lockedCount
    readonly property bool canRedo: historyStep < actionHistory.length - 1
    property var currentAction: null

    property var colorPalettes: [
        {
            name: "Default",
            colors: [
                ThemeBackend.red.toString(),
                ThemeBackend.peach.toString(),
                ThemeBackend.yellow.toString(),
                ThemeBackend.green.toString(),
                ThemeBackend.sapphire.toString(),
                ThemeBackend.blue.toString(),
                ThemeBackend.mauve.toString(),
                ThemeBackend.text.toString()
            ]
        }
    ]
    property int activePaletteIndex: 0
    property string picturesDir: ""

    Process {
        id: getPicturesDir
        command: ["xdg-user-dir", "PICTURES"]
        running: true
        stdout: SplitParser {
            onRead: data => { root.picturesDir = data.trim() }
        }
    }

    FileView {
        id: palettesFile
        path: Caching.getStateDir("quickactions") + "/palettes.json"
        printErrors: false
        onLoaded: {
            try {
                let parsed = JSON.parse(text());
                if (parsed && parsed.length > 0) {
                    root.colorPalettes = parsed;
                }
            } catch(e) {}
        }
    }

    Timer {
        id: paletteSaveTimer
        interval: 500
        onTriggered: {
            palettesFile.setText(JSON.stringify(root.colorPalettes) + "\n");
        }
    }

    function addColorToPalette(colorStr) {
        let p = root.colorPalettes;
        if (!p[root.activePaletteIndex]) return;
        p[root.activePaletteIndex].colors.push(colorStr);
        root.colorPalettes = p;
        paletteSaveTimer.restart();
    }

    function commitAction(action) {
        var newHistory = root.actionHistory.slice(0, root.historyStep + 1);
        newHistory.push(action);

        root.actionHistory = newHistory;
        root.historyStep = root.actionHistory.length - 1;
        root.lockedCount = Math.max(root.lockedCount, root.actionHistory.length - root.maxHistory);
    }

    function finishStroke() {
        if (!root.currentAction) return;
        root.commitAction(root.currentAction);
        root.currentAction = null;
    }

    function undo() {
        if (root.canUndo) {
            root.historyStep--;
            triggerReplay();
        }
    }

    function redo() {
        if (root.canRedo) {
            root.historyStep++;
            triggerReplay();
        }
    }

    function triggerReplay() {
        if (orientedRoot.children.length > 0) {
            drawCanvas._replayPending = true;
            drawCanvas.requestPaint();
        }
    }

    function exportDrawing(targetPath, callback) {
        if (typeof drawCanvas.grabToImage === "function") {
            var initiated = drawCanvas.grabToImage(function(result) {
                var success = false;
                try {
                    success = result.saveToFile(targetPath);
                } catch (e) {
                    success = false;
                }
                if (!success && typeof drawCanvas.save === "function") {
                    try {
                        success = drawCanvas.save(targetPath, Qt.size(drawCanvas.width, drawCanvas.height));
                    } catch (e) {}
                    if (!success) {
                        try {
                            success = drawCanvas.save(targetPath);
                        } catch (e) {}
                    }
                }
                if (callback) callback(success);
            });
            if (!initiated) {
                var fallbackSuccess = false;
                if (typeof drawCanvas.save === "function") {
                    try {
                        fallbackSuccess = drawCanvas.save(targetPath, Qt.size(drawCanvas.width, drawCanvas.height));
                    } catch (e) {}
                    if (!fallbackSuccess) {
                        try {
                            fallbackSuccess = drawCanvas.save(targetPath);
                        } catch (e) {}
                    }
                }
                if (callback) callback(fallbackSuccess);
            }
        } else if (typeof drawCanvas.save === "function") {
            var res = false;
            try {
                res = drawCanvas.save(targetPath, Qt.size(drawCanvas.width, drawCanvas.height));
            } catch (e) {}
            if (!res) {
                try {
                    res = drawCanvas.save(targetPath);
                } catch (e) {}
            }
            if (callback) callback(res);
        } else {
            if (callback) callback(false);
        }
    }

    Shortcut { enabled: root.visible && root.isActiveTab; sequence: "Ctrl+Z"; onActivated: root.undo() }
    Shortcut { enabled: root.visible && root.isActiveTab; sequence: "Ctrl+Shift+Z"; onActivated: root.redo() }

    Item {
        id: orientedRoot
        anchors.centerIn: parent

        width: (root.counterRotation % 180 !== 0) ? parent.height : parent.width
        height: (root.counterRotation % 180 !== 0) ? parent.width : parent.height
        rotation: root.counterRotation
        clip: true

        Rectangle {
            anchors.fill: parent
            color: root.solidBgColor
            z: -1
        }

        Item {
            id: cameraRig
            anchors.fill: parent
            clip: true

            function zoomBy(factor) {
                zoomContainer.scale = Math.max(root.minZoom, Math.min(zoomContainer.scale * factor, root.maxZoom));
            }

            PinchHandler {
                target: zoomContainer
                enabled: root.isActiveTab
                minimumScale: root.minZoom
                maximumScale: root.maxZoom
            }

            Item {
                id: zoomContainer
                width: root.worldSize
                height: root.worldSize

                x: (cameraRig.width - width) / 2
                y: (cameraRig.height - height) / 2

                transformOrigin: Item.Center
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

                DragHandler {
                    target: zoomContainer
                    enabled: root.isActiveTab
                    acceptedButtons: Qt.MiddleButton
                    cursorShape: active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                }

                Image {
                    anchors.fill: parent
                    fillMode: Image.Tile

                    property real dotRadius: s(1.2)
                    property real dotSpacing: s(12)
                    property color dotC: root.baseTextColor

                    source: `data:image/svg+xml;utf8,<svg width='${dotSpacing}' height='${dotSpacing}' xmlns='http://www.w3.org/2000/svg'><circle cx='${dotSpacing/2}' cy='${dotSpacing/2}' r='${dotRadius}' fill='rgb(${dotC.r*255},${dotC.g*255},${dotC.b*255})' fill-opacity='0.15'/></svg>`
                }

                Canvas {
                    id: drawCanvas
                    anchors.fill: parent
                    z: 1

                    renderTarget: Canvas.FramebufferObject

                    property real lastX: -1
                    property real lastY: -1

                    property var _queue: []
                    property bool _clearPending: false
                    property bool _replayPending: false

                    function renderBrushLine(ctx, s, isLive) {
                        var bSize = s.penSize || root.s(18);
                        var segments = isLive ? [{x1: s.x1, y1: s.y1, x2: s.x2, y2: s.y2}] : s.segments;

                        var bristleCount = Math.max(6, Math.floor(bSize * 0.6));

                        ctx.globalCompositeOperation = "source-over";
                        ctx.lineCap = "round";
                        ctx.lineJoin = "round";

                        var col = s.color;

                        for (var b = 0; b < bristleCount; b++) {
                            var t = b / bristleCount;
                            var angle = t * Math.PI * 2;
                            var radius = (0.3 + (((b * 7 + 3) % 11) / 11) * 0.7) * (bSize / 2);
                            var offX = Math.cos(angle) * radius * 0.5;
                            var offY = Math.sin(angle) * radius * 0.5;
                            var alpha = 0.25 + (((b * 13 + 5) % 17) / 17) * 0.45;
                            var width = root.s(0.8) + (((b * 3 + 1) % 5) / 5) * root.s(1.6);

                            ctx.globalAlpha = alpha;
                            ctx.lineWidth = width;
                            ctx.strokeStyle = col;

                            ctx.beginPath();
                            ctx.moveTo(segments[0].x1 + offX, segments[0].y1 + offY);
                            for (var j = 0; j < segments.length; j++) {
                                ctx.lineTo(segments[j].x2 + offX, segments[j].y2 + offY);
                            }
                            ctx.stroke();
                        }

                        ctx.globalAlpha = 1.0;
                    }

                    function applyToolStyle(ctx, tool, color, customSize) {
                        ctx.lineCap = "round";
                        ctx.lineJoin = "round";

                        if (tool === "eraser") {
                            ctx.globalCompositeOperation = "destination-out";
                            ctx.lineWidth = customSize || root.actualToolSize;
                            ctx.strokeStyle = "rgba(0,0,0,1)";
                            ctx.globalAlpha = 1.0;
                            ctx.shadowBlur = 0;
                            ctx.shadowColor = "transparent";
                        } else {
                            ctx.globalCompositeOperation = "source-over";
                            ctx.strokeStyle = color;
                            ctx.lineWidth = customSize || root.actualToolSize;
                            ctx.shadowBlur = 0;
                            ctx.shadowColor = "transparent";
                            ctx.globalAlpha = 1.0;
                        }
                    }

                    onPaint: {
                        var ctx = getContext("2d");

                        if (_replayPending) {
                            ctx.clearRect(0, 0, width, height);
                            var replayStart = 0;
                            for (var c = root.historyStep; c >= 0; c--) {
                                if (root.actionHistory[c] && root.actionHistory[c].type === "clear") {
                                    replayStart = c;
                                    break;
                                }
                            }
                            for (var h = replayStart; h <= root.historyStep; h++) {
                                var action = root.actionHistory[h];
                                if (!action) continue;

                                if (action.type === "clear") {
                                    ctx.clearRect(0, 0, width, height);
                                } else if (action.type === "fill_bg") {
                                    ctx.globalCompositeOperation = "destination-over";
                                    ctx.fillStyle = action.color;
                                    ctx.fillRect(0, 0, width, height);
                                    ctx.globalCompositeOperation = "source-over";
                                } else if (action.type === "stroke") {
                                    if (action.tool === "brush") {
                                        renderBrushLine(ctx, action, false);
                                    } else {
                                        ctx.beginPath();
                                        applyToolStyle(ctx, action.tool, action.color, action.penSize);

                                        if (action.segments && action.segments.length > 0) {
                                            ctx.moveTo(action.segments[0].x1, action.segments[0].y1);
                                            for (var k = 0; k < action.segments.length; k++) {
                                                ctx.lineTo(action.segments[k].x2, action.segments[k].y2);
                                            }
                                            ctx.stroke();
                                        }
                                    }
                                }
                            }
                            _replayPending = false;
                            _queue = [];
                            return;
                        }

                        if (_clearPending) {
                            ctx.clearRect(0, 0, width, height);
                            _clearPending = false;
                        }

                        for (var i = 0; i < _queue.length; i++) {
                            var q = _queue[i];

                            if (q.type === "fill_bg") {
                                ctx.globalCompositeOperation = "destination-over";
                                ctx.fillStyle = q.color;
                                ctx.fillRect(0, 0, width, height);
                                ctx.globalCompositeOperation = "source-over";
                            } else if (q.tool === "brush") {
                                renderBrushLine(ctx, q, true);
                            } else {
                                ctx.beginPath();
                                applyToolStyle(ctx, q.tool, q.color, q.penSize);
                                ctx.moveTo(q.x1, q.y1);
                                ctx.lineTo(q.x2, q.y2);
                                ctx.stroke();
                            }
                        }

                        _queue = [];
                    }

                    MouseArea {
                        id: drawArea
                        anchors.fill: parent
                        enabled: root.isActiveTab
                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        onWheel: (wheel) => {
                            let deltaY = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : (wheel.pixelDelta ? wheel.pixelDelta.y : 0);
                            let deltaX = wheel.angleDelta.x !== 0 ? wheel.angleDelta.x : (wheel.pixelDelta ? wheel.pixelDelta.x : 0);

                            if (deltaY === 0 && deltaX === 0) {
                                wheel.accepted = false;
                                return;
                            }

                            wheel.accepted = true;

                            if (wheel.modifiers & Qt.ControlModifier) {
                                let delta = deltaY !== 0 ? deltaY : deltaX;
                                let zoomFactor = delta > 0 ? 1.15 : (1.0 / 1.15);
                                cameraRig.zoomBy(zoomFactor);
                            } else {
                                zoomContainer.x = Math.max(cameraRig.width - root.worldSize * zoomContainer.scale, Math.min(0, zoomContainer.x + deltaX));
                                zoomContainer.y = Math.max(cameraRig.height - root.worldSize * zoomContainer.scale, Math.min(0, zoomContainer.y + deltaY));
                            }
                        }

                        function isTouchSynth(mouse) {
                            return mouse.source !== undefined && mouse.source !== Qt.MouseEventNotSynthesized;
                        }

                        function beginStroke(mouse) {
                            root.showSizeConfig = false;
                            root.showColorPicker = false;
                            root.showBrushDropdown = false;

                            let useColor = mouse.button === Qt.RightButton ? root.secondaryColor : root.primaryColor;
                            let freezeCol = useColor.toString();

                            if (root.currentTool === "fill") {
                                root.commitAction({ type: "fill_bg", color: freezeCol });
                                drawCanvas._queue.push({ type: "fill_bg", color: freezeCol });

                                drawCanvas.markDirty(Qt.rect(0, 0, drawCanvas.width, drawCanvas.height));
                                drawCanvas.requestPaint();
                                return;
                            }

                            root.finishStroke();
                            drawCanvas.lastX = mouse.x;
                            drawCanvas.lastY = mouse.y;

                            root.currentAction = {
                                type: "stroke",
                                tool: root.currentTool,
                                color: freezeCol,
                                penSize: root.actualToolSize,
                                segments: []
                            };
                            var initialSegment = { x1: mouse.x, y1: mouse.y, x2: mouse.x + 0.1, y2: mouse.y };
                            root.currentAction.segments.push(initialSegment);

                            drawCanvas._queue.push({
                                type: "stroke",
                                tool: root.currentTool,
                                color: freezeCol,
                                penSize: root.actualToolSize,
                                x1: initialSegment.x1, y1: initialSegment.y1,
                                x2: initialSegment.x2, y2: initialSegment.y2
                            });

                            var rad = s(20);
                            drawCanvas.markDirty(Qt.rect(mouse.x - rad, mouse.y - rad, rad*2, rad*2));
                            drawCanvas.requestPaint();
                        }

                        function extendStroke(mouse) {
                            if (root.currentAction && root.currentTool !== "fill") {
                                var segment = {
                                    x1: drawCanvas.lastX, y1: drawCanvas.lastY,
                                    x2: mouse.x, y2: mouse.y
                                };

                                if (root.currentAction) {
                                    root.currentAction.segments.push(segment);
                                }

                                drawCanvas._queue.push({
                                    type: "stroke",
                                    tool: root.currentTool,
                                    color: root.currentAction.color,
                                    penSize: root.actualToolSize,
                                    x1: segment.x1, y1: segment.y1,
                                    x2: segment.x2, y2: segment.y2
                                });

                                var rad = s(20);
                                var minX = Math.min(drawCanvas.lastX, mouse.x) - rad;
                                var minY = Math.min(drawCanvas.lastY, mouse.y) - rad;
                                var w = Math.abs(mouse.x - drawCanvas.lastX) + rad*2;
                                var h = Math.abs(mouse.y - drawCanvas.lastY) + rad*2;

                                drawCanvas.lastX = mouse.x;
                                drawCanvas.lastY = mouse.y;

                                drawCanvas.markDirty(Qt.rect(minX, minY, w, h));
                                drawCanvas.requestPaint();
                            }
                        }

                        onPressed: (mouse) => { if (!isTouchSynth(mouse)) beginStroke(mouse) }
                        onPositionChanged: (mouse) => { if (pressed && !isTouchSynth(mouse)) extendStroke(mouse) }
                        onReleased: (mouse) => { if (!isTouchSynth(mouse)) root.finishStroke() }
                        onCanceled: root.finishStroke()
                    }

                    DragHandler {
                        id: touchDraw
                        target: null
                        enabled: root.isActiveTab
                        acceptedDevices: PointerDevice.TouchScreen | PointerDevice.Stylus
                        dragThreshold: 0
                        minimumPointCount: 1
                        maximumPointCount: 1

                        onActiveChanged: {
                            if (active) {
                                var p = centroid.position;
                                drawArea.beginStroke({ x: p.x, y: p.y, button: Qt.LeftButton });
                            } else {
                                root.finishStroke();
                            }
                        }

                        onCentroidChanged: {
                            if (active) {
                                var p = centroid.position;
                                drawArea.extendStroke({ x: p.x, y: p.y });
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: sizeToggleButton
            z: 10
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.topMargin: s(20)
            anchors.leftMargin: s(20)
            width: s(44)
            height: s(44)
            radius: 0
            color: root.panelBgColor

            WallpaperBlur {
                z: -1
                anchors.fill: parent
                radius: 0
            }

            IconButton {
                anchors.centerIn: parent
                width: root.s(32)
                height: root.s(32)
                cornerRadius: 0
                buttonIcon: root.isEnlarged ? "\uF066" : "\uF065"
                iconFontSize: root.s(14)
                accentColor: isHoveredOrHighlighted ? ThemeBackend.surface0 : "transparent"
                textColor: root.isEnlarged ? ThemeBackend.mauve : root.baseTextColor
                onClicked: root.isEnlarged = !root.isEnlarged
            }
        }

        Row {
            id: topActionsLayout
            z: 10
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: s(20)
            anchors.rightMargin: s(20)
            spacing: s(12)

            Rectangle {
                width: zoomRow.width + s(24)
                height: s(44)
                radius: 0
                color: root.panelBgColor

                WallpaperBlur {
                    z: -1
                    anchors.fill: parent
                    radius: 0
                }

                Row {
                    id: zoomRow
                    anchors.centerIn: parent
                    spacing: s(6)

                    IconButton {
                        width: root.s(32)
                        height: root.s(32)
                        cornerRadius: 0
                        buttonIcon: "\uF068"
                        iconFontSize: root.s(14)
                        accentColor: isHoveredOrHighlighted ? ThemeBackend.surface0 : "transparent"
                        textColor: root.baseTextColor
                        onClicked: cameraRig.zoomBy(1.0 / 1.25)
                    }

                    Item {
                        width: s(48); height: s(32)
                        Rectangle {
                            anchors.fill: parent; radius: 0; z:-1
                            color: zoomResetMouse.containsMouse ? ThemeBackend.surface0 : "transparent"
                        }
                        Text {
                            anchors.centerIn: parent; text: Math.round(zoomContainer.scale * 100) + "%"; font.pixelSize: s(12); color: root.baseTextColor; font.bold: true
                        }
                        MouseArea {
                            id: zoomResetMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                zoomContainer.scale = 1.0;
                                zoomContainer.x = (cameraRig.width - zoomContainer.width) / 2;
                                zoomContainer.y = (cameraRig.height - zoomContainer.height) / 2;
                            }
                        }
                    }

                    IconButton {
                        width: root.s(32)
                        height: root.s(32)
                        cornerRadius: 0
                        buttonIcon: "\uF067"
                        iconFontSize: root.s(14)
                        accentColor: isHoveredOrHighlighted ? ThemeBackend.surface0 : "transparent"
                        textColor: root.baseTextColor
                        onClicked: cameraRig.zoomBy(1.25)
                    }
                }
            }

            IconButton {
                width: root.s(44)
                height: root.s(44)
                cornerRadius: ThemeBackend.borderRadius
                buttonIcon: "\uF019"
                iconFontSize: root.s(14)
                accentColor: isHoveredOrHighlighted ? ThemeBackend.surface0 : root.panelBgColor
                textColor: root.baseTextColor
                onClicked: {
                    var outDir = root.picturesDir !== "" ? root.picturesDir : "/tmp";
                    Quickshell.execDetached(["mkdir", "-p", outDir]);
                    var outPath = outDir + "/drawing_" + Date.now() + ".png";
                    root.exportDrawing(outPath, function(success) {
                        if (success) {
                            Quickshell.execDetached(["notify-send", "-a", I18n.t("quickactions.draw.notification.app_name") || "DrawAction", I18n.t("quickactions.draw.notification.saved_title") || "Drawing saved", outPath]);
                        } else {
                            Quickshell.execDetached(["notify-send", "-a", I18n.t("quickactions.draw.notification.app_name") || "DrawAction", I18n.t("quickactions.draw.notification.failed_title") || "Export failed", I18n.t("quickactions.draw.notification.failed_body") || "Could not save drawing"]);
                        }
                    });
                }
            }

            IconButton {
                width: root.s(44)
                height: root.s(44)
                cornerRadius: ThemeBackend.borderRadius
                buttonIcon: "\uF0C5"
                iconFontSize: root.s(14)
                accentColor: isHoveredOrHighlighted ? ThemeBackend.surface0 : root.panelBgColor
                textColor: root.baseTextColor
                onClicked: {
                    var tempPath = Caching.getRunDir("quickactions") + "/drawing_clip.png";
                    root.exportDrawing(tempPath, function(success) {
                        if (success) {
                            Quickshell.execDetached(["sh", "-c", "if command -v wl-copy >/dev/null 2>&1; then wl-copy --type image/png < '" + tempPath + "'; fi"]);
                            Quickshell.execDetached(["notify-send", "-a", I18n.t("quickactions.draw.notification.app_name") || "DrawAction", I18n.t("quickactions.draw.notification.copied_title") || "Drawing copied", I18n.t("quickactions.draw.notification.copied_body") || "Drawing copied to clipboard"]);
                        } else {
                            Quickshell.execDetached(["notify-send", "-a", I18n.t("quickactions.draw.notification.app_name") || "DrawAction", I18n.t("quickactions.draw.notification.failed_title") || "Export failed", I18n.t("quickactions.draw.notification.failed_body") || "Could not save drawing"]);
                        }
                    });
                }
            }
        }

        Rectangle {
            id: sizeConfigPopup
            z: 20
            width: s(260)
            height: s(64)
            radius: 0
            color: root.popupBgColor

            WallpaperBlur {
                z: -1
                anchors.fill: parent
                radius: 0
            }

            anchors.bottom: toolbar.top
            anchors.bottomMargin: s(12)
            anchors.horizontalCenter: parent.horizontalCenter

            visible: root.showSizeConfig
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

            RowLayout {
                anchors.fill: parent
                anchors.margins: s(18)
                spacing: s(14)

                Text {
                    text: root.currentTool === "eraser" ? "\uF12D" : (root.currentTool === "brush" ? "\uF1FC" : "\uF040")
                    font.family: root.iconFont
                    color: root.baseTextColor
                    font.pixelSize: s(16)
                    opacity: 0.7
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: s(6)
                    radius: 0
                    color: Qt.rgba(ThemeBackend.text.r, ThemeBackend.text.g, ThemeBackend.text.b, 0.1)

                    Rectangle {
                        width: parent.width * root.currentSizeRatio
                        height: parent.height
                        radius: 0
                        color: ThemeBackend.mauve
                    }

                    Rectangle {
                        width: s(14); height: s(14)
                        radius: 0
                        color: ThemeBackend.mauve
                        x: (parent.width * root.currentSizeRatio) - (width/2)
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -s(16)
                        cursorShape: Qt.PointingHandCursor

                        function updateSize(mouse) {
                            let val = Math.max(0.0, Math.min(1.0, mouse.x / width));
                            if (root.currentTool === "eraser") root.eraserSizeRatio = val;
                            else if (root.currentTool === "brush") root.brushSizeRatio = val;
                            else root.penSizeRatio = val;
                        }

                        onPositionChanged: (mouse) => { if (pressed) updateSize(mouse) }
                        onPressed: (mouse) => updateSize(mouse)
                    }
                }

                Rectangle {
                    width: s(40)
                    height: s(28)
                    color: ThemeBackend.surface0
                    radius: 0

                    TextInput {
                        anchors.fill: parent
                        anchors.margins: s(2)
                        color: root.baseTextColor
                        text: Math.round(root.actualToolSize).toString()
                        font.pixelSize: s(13)
                        verticalAlignment: TextInput.AlignVCenter
                        horizontalAlignment: TextInput.AlignHCenter
                        validator: IntValidator { bottom: 1; top: 999 }

                        onEditingFinished: {
                            let px = parseFloat(text);
                            if (isNaN(px)) return;
                            if (root.currentTool === "eraser") {
                                root.eraserSizeRatio = Math.max(0, Math.min(1, (px - root.s(8)) / root.s(60)));
                            } else if (root.currentTool === "brush") {
                                root.brushSizeRatio = Math.max(0, Math.min(1, (px - root.s(4)) / root.s(40)));
                            } else {
                                root.penSizeRatio = Math.max(0, Math.min(1, (px - root.s(2)) / root.s(30)));
                            }
                        }
                    }
                }

                Item {
                    width: s(32)
                    height: s(32)
                    Rectangle {
                        anchors.centerIn: parent

                        width: {
                            let toolMax = 0;
                            if (root.currentTool === "eraser") toolMax = s(8) + s(60);
                            else if (root.currentTool === "brush") toolMax = s(4) + s(40);
                            else toolMax = s(2) + s(30);

                            let visualLimit = s(32);

                            if (toolMax <= visualLimit) {
                                return root.actualToolSize;
                            }

                            let minVisual = s(4);
                            return minVisual + (root.currentSizeRatio * (visualLimit - minVisual));
                        }

                        height: width
                        radius: width / 2
                        color: root.currentTool === "eraser" ? "transparent" : root.currentColor
                    }
                }
            }
        }

        Rectangle {
            id: colorPickerPopup
            z: 20
            width: s(320)
            height: s(400)
            radius: 0
            color: root.popupBgColor

            WallpaperBlur {
                z: -1
                anchors.fill: parent
                radius: 0
            }

            anchors.bottom: toolbar.top
            anchors.bottomMargin: s(12)
            anchors.horizontalCenter: parent.horizontalCenter

            visible: root.showColorPicker
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

            Column {
                anchors.centerIn: parent
                spacing: s(20)

                Row {
                    spacing: s(16)
                    anchors.horizontalCenter: parent.horizontalCenter

                    Rectangle {
                        width: s(220); height: s(200)
                        radius: 0
                        color: Qt.hsva(root.activeColorSlot === 0 ? root.primaryHSV.h : root.secondaryHSV.h, 1, 1, 1)
                        clip: true

                        Rectangle {
                            anchors.fill: parent
                            radius: 0
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "white" }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                        }
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            gradient: Gradient {
                                orientation: Gradient.Vertical
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 1.0; color: "black" }
                            }
                        }

                        Rectangle {
                            width: s(14); height: s(14)
                            radius: width / 2
                            border.width: s(2); border.color: "white"
                            color: "transparent"
                            x: ((root.activeColorSlot === 0 ? root.primaryHSV.s : root.secondaryHSV.s) * parent.width) - (width/2)
                            y: ((1.0 - (root.activeColorSlot === 0 ? root.primaryHSV.v : root.secondaryHSV.v)) * parent.height) - (height/2)
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.CrossCursor
                            function updateSV(mouse) {
                                let ns = Math.max(0, Math.min(1, mouse.x / width));
                                let nv = 1.0 - Math.max(0, Math.min(1, mouse.y / height));
                                if (root.activeColorSlot === 0) {
                                    root.primaryHSV = { h: root.primaryHSV.h, s: ns, v: nv };
                                } else {
                                    root.secondaryHSV = { h: root.secondaryHSV.h, s: ns, v: nv };
                                }
                            }
                            onPressed: (mouse) => updateSV(mouse)
                            onPositionChanged: (mouse) => { if (pressed) updateSV(mouse) }
                        }
                    }

                    Rectangle {
                        width: s(24); height: s(200)
                        radius: 0
                        clip: true
                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0.0; color: "#ff0000" }
                            GradientStop { position: 0.166; color: "#ffff00" }
                            GradientStop { position: 0.333; color: "#00ff00" }
                            GradientStop { position: 0.5; color: "#00ffff" }
                            GradientStop { position: 0.666; color: "#0000ff" }
                            GradientStop { position: 0.833; color: "#ff00ff" }
                            GradientStop { position: 1.0; color: "#ff0000" }
                        }

                        Rectangle {
                            width: parent.width; height: s(8)
                            radius: s(4)
                            border.width: 1; border.color: "black"
                            color: "white"
                            y: ((root.activeColorSlot === 0 ? root.primaryHSV.h : root.secondaryHSV.h) * parent.height) - (height/2)
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            function updateH(mouse) {
                                let nh = Math.max(0, Math.min(1, mouse.y / height));
                                if (root.activeColorSlot === 0) {
                                    root.primaryHSV = { h: nh, s: root.primaryHSV.s, v: root.primaryHSV.v };
                                } else {
                                    root.secondaryHSV = { h: nh, s: root.secondaryHSV.s, v: root.secondaryHSV.v };
                                }
                            }
                            onPressed: (mouse) => updateH(mouse)
                            onPositionChanged: (mouse) => { if (pressed) updateH(mouse) }
                        }
                    }
                }

                RowLayout {
                    width: parent.width
                    spacing: s(10)
                    layoutDirection: I18n.layoutDirection

                    Text {
                        text: {
                            let pName = root.colorPalettes[root.activePaletteIndex] ? root.colorPalettes[root.activePaletteIndex].name : "";
                            if (pName === "Default") return I18n.t("quickactions.draw.palette_default", "Default");
                            return pName || I18n.t("quickactions.draw.palette", "Palette");
                        }
                        color: root.baseTextColor
                        font.pixelSize: s(14)
                        font.bold: true
                        Layout.fillWidth: true
                        horizontalAlignment: I18n.textAlignment
                    }

                    IconButton {
                        width: root.s(24)
                        height: root.s(24)
                        buttonIcon: "\uF067"
                        iconFontSize: root.s(12)
                        accentColor: isHoveredOrHighlighted ? ThemeBackend.surface0 : "transparent"
                        textColor: root.baseTextColor
                        onClicked: root.addColorToPalette(root.currentColor.toString())
                    }
                }

                Grid {
                    columns: 8
                    spacing: s(12)
                    anchors.horizontalCenter: parent.horizontalCenter
                    layoutDirection: I18n.layoutDirection

                    Repeater {
                        model: root.colorPalettes[root.activePaletteIndex] ? root.colorPalettes[root.activePaletteIndex].colors : []

                        Rectangle {
                            width: s(20)
                            height: s(20)
                            radius: width / 2
                            color: modelData


                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    let c = parent.color;
                                    let hsv = { h: c.hsvHue, s: c.hsvSaturation, v: c.hsvValue };
                                    if (root.activeColorSlot === 0) root.primaryHSV = hsv;
                                    else root.secondaryHSV = hsv;
                                }
                            }
                        }
                    }
                }

                Row {
                    spacing: s(10)
                    anchors.horizontalCenter: parent.horizontalCenter
                    layoutDirection: I18n.layoutDirection

                    Text {
                        text: I18n.t("quickactions.draw.hex", "Hex")
                        color: Qt.rgba(root.baseTextColor.r, root.baseTextColor.g, root.baseTextColor.b, 0.6)
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: s(13)
                        font.bold: true
                    }

                    Rectangle {
                        width: s(120)
                        height: s(28)
                        color: ThemeBackend.surface0
                        radius: 0

                        TextInput {
                            id: hexInput
                            anchors.fill: parent
                            anchors.margins: s(4)
                            color: root.baseTextColor
                            text: root.currentColor.toString()
                            font.pixelSize: s(14)
                            verticalAlignment: TextInput.AlignVCenter
                            horizontalAlignment: TextInput.AlignHCenter
                            onEditingFinished: {
                                let c = Qt.color(text);
                                let hsv = { h: c.hsvHue, s: c.hsvSaturation, v: c.hsvValue };
                                if (root.activeColorSlot === 0) root.primaryHSV = hsv;
                                else root.secondaryHSV = hsv;
                            }
                        }
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            z: 24
            enabled: root.showBrushDropdown
            onClicked: root.showBrushDropdown = false
        }

        Rectangle {
            id: brushDropdownPopup
            z: 25
            width: s(124)
            height: s(126)
            radius: 0
            color: root.popupBgColor
            border.width: 1
            border.color: root.panelBorderColor
            anchors.bottom: toolbar.top
            anchors.bottomMargin: s(8)
            anchors.horizontalCenter: toolbar.horizontalCenter

            WallpaperBlur {
                z: -1
                anchors.fill: parent
                radius: 0
            }

            visible: root.showBrushDropdown
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutExpo } }

            Column {
                id: brushCol
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: root.s(4)
                spacing: root.s(2)

                Repeater {
                    model: [
                        { id: "pen", name: "Pen", icon: "\uF040" },
                        { id: "brush", name: "Brush", icon: "\uF1FC" },
                        { id: "fill", name: "Fill", icon: "\uF043" },
                        { id: "eraser", name: "Eraser", icon: "\uF12D" }
                    ]

                    delegate: Rectangle {
                        width: brushCol.width
                        height: root.s(28)
                        radius: 0
                        color: (itemMouse.containsMouse || root.currentTool === modelData.id) ? ThemeBackend.surface1 : "transparent"

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: root.s(8)
                            anchors.rightMargin: root.s(8)
                            spacing: root.s(8)

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                font.family: root.iconFont
                                font.pixelSize: root.s(12)
                                color: root.currentTool === modelData.id ? ThemeBackend.mauve : root.baseTextColor
                                text: modelData.icon
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - root.s(44)
                                font.family: ThemeBackend.fontFamily
                                font.pixelSize: root.s(11)
                                font.bold: root.currentTool === modelData.id
                                color: root.currentTool === modelData.id ? ThemeBackend.mauve : root.baseTextColor
                                text: modelData.name
                                elide: Text.ElideRight
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                font.family: root.iconFont
                                font.pixelSize: root.s(10)
                                color: ThemeBackend.mauve
                                text: "\uF00C"
                                visible: root.currentTool === modelData.id
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.currentTool = modelData.id;
                                root.showBrushDropdown = false;
                                if (modelData.id === "pen" || modelData.id === "brush" || modelData.id === "eraser") {
                                    root.showSizeConfig = true;
                                } else {
                                    root.showSizeConfig = false;
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: toolbar
            z: 10
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: s(12)

            width: toolRow.width + s(20)
            height: s(38)
            radius: 0

            color: root.panelBgColor

            WallpaperBlur {
                z: -1
                anchors.fill: parent
                radius: 0
            }

            Row {
                id: toolRow
                anchors.centerIn: parent
                spacing: s(8)

                IconButton {
                    width: root.s(26)
                    height: root.s(26)
                    cornerRadius: 0
                    buttonIcon: "\uF0E2"
                    iconFontSize: root.s(12)
                    enabled: root.canUndo
                    accentColor: isHoveredOrHighlighted && root.canUndo ? ThemeBackend.surface0 : "transparent"
                    textColor: root.baseTextColor
                    onClicked: root.undo()
                }

                IconButton {
                    width: root.s(26)
                    height: root.s(26)
                    cornerRadius: 0
                    buttonIcon: "\uF01E"
                    iconFontSize: root.s(12)
                    enabled: root.canRedo
                    accentColor: isHoveredOrHighlighted && root.canRedo ? ThemeBackend.surface0 : "transparent"
                    textColor: root.baseTextColor
                    onClicked: root.redo()
                }

                Rectangle {
                    width: 1
                    height: s(16)
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.panelBorderColor
                }

                // Dropdown picker for brushtype
                Rectangle {
                    id: brushDropdownButton
                    width: root.s(52)
                    height: root.s(26)
                    radius: 0
                    color: (brushMouse.containsMouse || root.showBrushDropdown) ? ThemeBackend.surface1 : "transparent"
                    border.width: 1
                    border.color: (root.showBrushDropdown || root.showSizeConfig) ? ThemeBackend.mauve : Qt.alpha(root.baseTextColor, 0.15)

                    Row {
                        anchors.centerIn: parent
                        spacing: root.s(4)

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: root.iconFont
                            font.pixelSize: root.s(12)
                            color: (root.showBrushDropdown || root.currentTool !== "pen") ? ThemeBackend.mauve : root.baseTextColor
                            text: {
                                if (root.currentTool === "pen") return "\uF040";
                                if (root.currentTool === "brush") return "\uF1FC";
                                if (root.currentTool === "fill") return "\uF043";
                                if (root.currentTool === "eraser") return "\uF12D";
                                return "\uF040";
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: root.iconFont
                            font.pixelSize: root.s(8)
                            color: ThemeBackend.subtext0
                            text: "\uF078"
                            rotation: root.showBrushDropdown ? 180 : 0
                            Behavior on rotation { NumberAnimation { duration: 150 } }
                        }
                    }

                    MouseArea {
                        id: brushMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.showBrushDropdown = !root.showBrushDropdown;
                            root.showColorPicker = false;
                        }
                    }
                }

                // Size config toggle button
                IconButton {
                    width: root.s(26)
                    height: root.s(26)
                    cornerRadius: 0
                    buttonIcon: "\uF1DE"
                    iconFontSize: root.s(11)
                    accentColor: root.showSizeConfig ? ThemeBackend.surface1 : (isHoveredOrHighlighted ? ThemeBackend.surface0 : "transparent")
                    textColor: root.showSizeConfig ? ThemeBackend.mauve : root.baseTextColor
                    action_highlight: root.showSizeConfig
                    visible: root.currentTool !== "fill"
                    onClicked: {
                        root.showSizeConfig = !root.showSizeConfig;
                        root.showBrushDropdown = false;
                        root.showColorPicker = false;
                    }
                }

                Rectangle {
                    width: 1
                    height: s(16)
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.panelBorderColor
                }

                Item {
                    width: s(68)
                    height: s(26)

                    Row {
                        anchors.centerIn: parent
                        spacing: s(4)

                        Rectangle {
                            width: s(20)
                            height: s(20)
                            radius: 0
                            color: root.primaryColor
                            anchors.verticalCenter: parent.verticalCenter

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.activeColorSlot = 0;
                                    root.showColorPicker = !root.showColorPicker;
                                    root.showSizeConfig = false;
                                    root.showBrushDropdown = false;
                                    if (root.currentTool === "eraser") {
                                        root.currentTool = "pen";
                                    }
                                }
                            }
                        }

                        IconButton {
                            width: root.s(20)
                            height: root.s(20)
                            cornerRadius: 0
                            buttonIcon: "\uF0EC"
                            iconFontSize: root.s(10)
                            accentColor: isHoveredOrHighlighted ? ThemeBackend.surface0 : "transparent"
                            textColor: root.baseTextColor
                            anchors.verticalCenter: parent.verticalCenter
                            onClicked: {
                                let temp = root.primaryHSV;
                                root.primaryHSV = root.secondaryHSV;
                                root.secondaryHSV = temp;
                            }
                        }

                        Rectangle {
                            width: s(20)
                            height: s(20)
                            radius: 0
                            color: root.secondaryColor
                            anchors.verticalCenter: parent.verticalCenter

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.activeColorSlot = 1;
                                    root.showColorPicker = !root.showColorPicker;
                                    root.showSizeConfig = false;
                                    root.showBrushDropdown = false;
                                    if (root.currentTool === "eraser") {
                                        root.currentTool = "pen";
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: 1
                    height: s(16)
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.panelBorderColor
                }

                IconButton {
                    width: root.s(26)
                    height: root.s(26)
                    cornerRadius: 0
                    buttonIcon: "\uF1F8"
                    iconFontSize: root.s(12)
                    accentColor: isHoveredOrHighlighted ? ThemeBackend.surface0 : "transparent"
                    textColor: ThemeBackend.red
                    onClicked: {
                        root.commitAction({ type: "clear" });
                        drawCanvas._clearPending = true;
                        drawCanvas.requestPaint();
                        root.showColorPicker = false;
                        root.showSizeConfig = false;
                        root.showBrushDropdown = false;

                        zoomContainer.scale = 1.0;
                        zoomContainer.x = (cameraRig.width - zoomContainer.width) / 2;
                        zoomContainer.y = (cameraRig.height - zoomContainer.height) / 2;
                    }
                }
            }
        }
    }
}
