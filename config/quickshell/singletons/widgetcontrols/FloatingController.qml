pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../"

Item {
    id: controller

    signal setIndexRequested(var screen, string index)
    signal showTabRequested(var screen, string tab)
    signal toggleTabRequested(var screen, string tab)
    signal nextTabRequested(var screen)
    signal prevTabRequested(var screen)
    signal showSystemUsageRequested(var screen)
    signal showNotesRequested(var screen)
    signal showSpotifyRequested(var screen)
    signal openRequested(var screen)
    signal closeRequested(var screen)

    property bool closedAny: false

    function targetScreen(screen) {
        if (screen) return screen;
        if (Quickshell.cursorScreen) return Quickshell.cursorScreen;
        return Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    function setIndex(index, screen) {
        let target = targetScreen(screen);
        if (target) controller.setIndexRequested(target, index);
    }

    function showTab(tab, screen) {
        let target = targetScreen(screen);
        if (target) controller.showTabRequested(target, tab);
    }

    function toggleTab(tab, screen) {
        let target = targetScreen(screen);
        if (target) controller.toggleTabRequested(target, tab);
    }

    function nextTab(screen) {
        let target = targetScreen(screen);
        if (target) controller.nextTabRequested(target);
    }

    function prevTab(screen) {
        let target = targetScreen(screen);
        if (target) controller.prevTabRequested(target);
    }

    function showSystemUsage(screen) {
        let target = targetScreen(screen);
        if (target) controller.showSystemUsageRequested(target);
    }

    function showNotes(screen) {
        let target = targetScreen(screen);
        if (target) controller.showNotesRequested(target);
    }

    function showSpotify(screen) {
        let target = targetScreen(screen);
        if (target) controller.showSpotifyRequested(target);
    }

    function open(screen) {
        let target = targetScreen(screen);
        if (target) controller.openRequested(target);
    }

    function close(screen) {
        controller.closedAny = false;
        controller.closeRequested(screen || null);
        return controller.closedAny;
    }

    function toggle(screen) {
        if (!controller.close(null)) controller.open(screen);
    }

    IpcHandler {
        target: "floating"

        function setIndex(index: string) {
            controller.setIndex(index, null);
        }

        function showTab(tab: string) {
            controller.showTab(tab, null);
        }

        function toggleTab(tab: string) {
            controller.toggleTab(tab, null);
        }

        function nextTab() {
            controller.nextTab(null);
        }

        function prevTab() {
            controller.prevTab(null);
        }

        function toggleCalc() {
            controller.toggleTab("calc", null);
        }

        function toggleDraw() {
            controller.toggleTab("draw", null);
        }

        function toggleTimer() {
            controller.toggleTab("timer", null);
        }

        function toggleNotes() {
            controller.toggleTab("notes", null);
        }

        function toggleSysinfo() {
            controller.toggleTab("sysinfo", null);
        }

        function toggleSpotify() {
            controller.toggleTab("spotify", null);
        }

        function showSystemUsage() {
            controller.showSystemUsage(null);
        }

        function showNotes() {
            controller.showNotes(null);
        }

        function showSpotify() {
            controller.showSpotify(null);
        }

        function open() {
            controller.open(null);
        }

        function close() {
            controller.close(null);
        }

        function toggle() {
            controller.toggle(null);
        }

        function forceReload() {
            Quickshell.reload(true)
        }
    }
}
