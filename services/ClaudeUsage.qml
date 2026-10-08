pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real fiveHourPercentage: 0
    property real weeklyPercentage: 0
    property string resetsAt: ""

    function refresh() {
        try {
            const cacheFile = Quickshell.exec(["cat", "/tmp/claude-usage-cache.json"], result => {
                if (result.stdout) {
                    try {
                        const data = JSON.parse(result.stdout);
                        const fiveHour = data.five_hour || {};
                        root.fiveHourPercentage = parseFloat(fiveHour.utilization || 0);
                        root.resetsAt = fiveHour.resets_at || "";

                        const extra = data.extra_usage || {};
                        if (extra.utilization && extra.utilization > 0) {
                            root.weeklyPercentage = parseFloat(extra.utilization);
                        } else {
                            root.weeklyPercentage = root.fiveHourPercentage;
                        }
                    } catch (e) {
                        console.warn("Failed to parse usage cache:", e);
                        root.fiveHourPercentage = 0;
                        root.weeklyPercentage = 0;
                    }
                }
            });
        } catch (e) {
            console.warn("Error reading usage cache:", e);
        }
    }

    Timer {
        id: refreshTimer
        interval: 5000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: {
        root.refresh();
    }
}
