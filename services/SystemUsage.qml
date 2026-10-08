pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config

// CPU temperature, fan RPM, and other system thermal metrics
Singleton {
    id: root

    property real cpuTempC: NaN
    property int fanRpmMin: 0
    property int fanRpmMax: 0

    Process {
        id: sensorsProc

        command: ["sensors", "-j"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                parseSensorsOutput(text);
            }
        }
    }

    Timer {
        interval: GlobalConfig.dashboard.resourceUpdateInterval
        running: true
        repeat: true

        onTriggered: {
            sensorsProc.running = true;
        }
    }

    function parseSensorsOutput(json: string): void {
        try {
            const data = JSON.parse(json);
            let maxTemp = NaN;

            // Look for CPU temp sensors
            for (const sensor in data) {
                if (sensor.includes("coretemp") || sensor.includes("acpitz") || sensor.includes("iwlwifi")) {
                    const sensorData = data[sensor];
                    if (sensorData && sensorData[0]) {
                        for (const key in sensorData[0]) {
                            if (key.includes("_input")) {
                                const temp = sensorData[0][key] / 1000;
                                if (!isNaN(temp) && (isNaN(maxTemp) || temp > maxTemp)) {
                                    maxTemp = temp;
                                }
                            }
                        }
                    }
                }
            }

            if (!isNaN(maxTemp)) {
                root.cpuTempC = maxTemp;
            }

            // Look for fan RPM from "it8792-*" or "asus_*" type sensors
            for (const sensor in data) {
                if (sensor.includes("fan") || sensor.includes("it8792") || sensor.includes("asus")) {
                    const sensorData = data[sensor];
                    if (sensorData && sensorData[0]) {
                        for (const key in sensorData[0]) {
                            if (key.includes("_input") && key.includes("fan")) {
                                const rpm = sensorData[0][key];
                                if (!isNaN(rpm) && rpm > 0) {
                                    if (root.fanRpmMin === 0 || rpm < root.fanRpmMin) {
                                        root.fanRpmMin = Math.round(rpm);
                                    }
                                    if (rpm > root.fanRpmMax) {
                                        root.fanRpmMax = Math.round(rpm);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } catch (e) {
            console.error("Failed to parse sensors JSON:", e.message);
        }
    }

    Component.onCompleted: {
        sensorsProc.running = true;
    }
}
