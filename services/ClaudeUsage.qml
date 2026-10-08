pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Claude plan usage from the statusline cache (/tmp/claude-usage-cache.json).
Singleton {
    id: root

    property real fiveHour: -1
    property real weekly: -1
    readonly property bool available: fiveHour >= 0

    FileView {
        id: cache

        path: "/tmp/claude-usage-cache.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const json = JSON.parse(text());
                root.fiveHour = json.five_hour?.utilization ?? -1;
                root.weekly = json.seven_day?.utilization ?? -1;
            } catch (e) {}
        }
    }
}
