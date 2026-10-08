pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import qs.components
import qs.services
import "../.." as Root

Rectangle {
    id: root

    required property string paneId

    radius: 4
    color: Tokens.colours.m3surfaceContainerLowest
    border.color: Tokens.colours.m3outlineVariant
    border.width: 1
    implicitHeight: 120
    clip: true

    Column {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4

        Text {
            text: "Live Output"
            color: Tokens.colours.m3onSurfaceVariant
            font.pixelSize: 9
            font.weight: Font.Bold
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            width: parent.width
            height: parent.height - 20
            contentHeight: liveText.implicitHeight
            clip: true

            Text {
                id: liveText
                width: parent.width
                text: root.lastOutput
                color: Tokens.colours.m3onSurface
                font.family: "monospace"
                font.pixelSize: 9
                wrapMode: Text.Wrap
                textFormat: Text.PlainText
            }
        }
    }

    property string lastOutput: ""

    Timer {
        id: updateTimer
        interval: 1000
        repeat: true
        running: root.visible

        onTriggered: {
            const proc = Quickshell.exec(["herdr", "pane", "read", root.paneId, "--source", "recent", "--lines", "10"], result => {
                if (result.stdout) {
                    root.lastOutput = result.stdout;
                }
            });
        }
    }

    Component.onCompleted: {
        updateTimer.start();
    }

    Component.onDestruction: {
        updateTimer.stop();
    }
}
