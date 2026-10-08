pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.services

// Last 10 lines of an agent's pane, refreshed every second while visible.
StyledRect {
    id: root

    required property string paneId
    property var lines: []

    implicitHeight: col.implicitHeight + Tokens.padding.small * 2
    radius: Tokens.rounding.small
    color: Colours.tPalette.m3surfaceContainerLowest

    Process {
        id: readProc

        command: [Quickshell.env("HOME") + "/.local/bin/herdr", "pane", "read", root.paneId, "--source", "recent", "--lines", "40"]
        stdout: StdioCollector {
            onStreamFinished: {
                const clean = text.replace(/\x1b\[[0-9;?]*[A-Za-z]/g, "").replace(/\r/g, "");
                // Drop blank lines, box borders and the empty input prompt
                root.lines = clean.split("\n").filter(l => /[^\s─━│┃╭╮╰╯═┄┈>❯-]/.test(l)).slice(-10);
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        triggeredOnStart: true
        running: root.visible
        onTriggered: readProc.running = true
    }

    ColumnLayout {
        id: col

        anchors.fill: parent
        anchors.margins: Tokens.padding.small
        spacing: 0

        Repeater {
            model: root.lines

            StyledText {
                required property string modelData

                Layout.fillWidth: true
                text: modelData
                elide: Text.ElideRight
                font: Tokens.font.mono.small
                color: /^\s*[⏺●]/.test(modelData) ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            }
        }
    }
}
