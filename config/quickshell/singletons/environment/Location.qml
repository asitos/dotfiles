pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../"

Item {
    id: root

    readonly property string stateLocationPath: (typeof Caching !== "undefined" && Caching.stateDir) ? (Caching.stateDir + "/location.json") : ""
    property var stateLocationData: ({})
    readonly property var configLocationData: (typeof Config !== "undefined" && Config.rawSettings && Config.rawSettings.general && Config.rawSettings.general.location) ? Config.rawSettings.general.location : ({})
    readonly property var locationData: hasCoords(stateLocationData) ? stateLocationData : (hasCoords(configLocationData) ? configLocationData : ({}))
    property bool isDetecting: false

    function hasCoords(obj) {
        return !!(obj && typeof obj === "object" && obj.latitude !== undefined && obj.latitude !== null && obj.longitude !== undefined && obj.longitude !== null);
    }

    readonly property string ip: locationData.ip || ""
    readonly property real latitude: locationData.latitude !== undefined ? Number(locationData.latitude) : 0.0
    readonly property real longitude: locationData.longitude !== undefined ? Number(locationData.longitude) : 0.0
    readonly property string city: locationData.city || "Unknown"
    readonly property string region: locationData.region || "Unknown"
    readonly property string regionCode: locationData.region_code || ""
    readonly property string countryName: locationData.country_name || locationData.country || "Unknown"
    readonly property string countryCode: locationData.country_code || ""
    readonly property string postal: locationData.postal || locationData.zip || ""
    readonly property string timezone: locationData.timezone || "UTC"
    readonly property string utcOffset: locationData.utc_offset || ""
    readonly property string currency: locationData.currency || ""
    readonly property string languages: locationData.languages || ""
    readonly property string asn: locationData.asn || ""
    readonly property string org: locationData.org || ""
    readonly property string source: locationData.source || "unknown"
    readonly property var updatedAt: locationData.updated_at !== undefined ? locationData.updated_at : 0

    readonly property var entries: {
        let arr = [];
        if (root.locationData) {
            for (let key in root.locationData) {
                let val = root.locationData[key];
                if (key === "updated_at" && typeof val === "number") {
                    val = new Date(val * 1000).toLocaleString();
                }
                arr.push({ label: key, value: String(val) });
            }
        }
        return arr;
    }

    signal locationUpdated()

    Connections {
        target: typeof Config !== "undefined" ? Config : null
        function onSettingsLoaded() {
            root.isDetecting = false;
            root.locationUpdated();
        }
    }

    FileView {
        id: locationFileWatcher
        path: root.stateLocationPath
        watchChanges: true
        onPathChanged: if (path) reload()
        onFileChanged: reload()
        onLoaded: {
            try {
                let raw = typeof text === "function" ? text() : text;
                if (typeof raw === "string" && raw.trim().length > 0) {
                    let parsed = JSON.parse(raw.trim());
                    if (root.hasCoords(parsed)) {
                        root.stateLocationData = parsed;
                        return;
                    }
                }
            } catch (e) {
            }
            root.stateLocationData = ({});
        }
    }

    onLocationDataChanged: {
        root.locationUpdated();
    }

    function get(key, fallbackValue) {
        if (root.locationData && root.locationData.hasOwnProperty(key)) {
            return root.locationData[key];
        }
        return fallbackValue !== undefined ? fallbackValue : "";
    }

    function detectAuto() {
        if (!Caching.quickshellDir) return;
        root.isDetecting = true;
        autoProcess.running = false;
        autoProcess.running = true;
    }

    function setManual(lat, lon) {
        if (!Caching.quickshellDir) return;
        root.isDetecting = true;
        manualProcess.lat = lat.toString();
        manualProcess.lon = lon.toString();
        manualProcess.running = false;
        manualProcess.running = true;
    }

    Process {
        id: autoProcess
        command: ["bash", "-c", Caching.quickshellDir + "/scripts/location.sh --refresh"]
        onExited: {
            root.isDetecting = false;
            if (locationFileWatcher.path) locationFileWatcher.reload();
        }
    }

    Process {
        id: manualProcess
        property string lat: ""
        property string lon: ""
        command: ["bash", "-c", Caching.quickshellDir + "/scripts/location_manual.sh '" + lat + "' '" + lon + "'"]
        onExited: {
            root.isDetecting = false;
            if (locationFileWatcher.path) locationFileWatcher.reload();
        }
    }

    Component.onCompleted: {
        if (locationFileWatcher.path) {
            locationFileWatcher.reload();
        }
    }
}
