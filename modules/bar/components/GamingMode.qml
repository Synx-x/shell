import QtQuick
import Quickshell.Io
import Caelestia
import Caelestia.Config
import qs.components
import qs.services

// Local: runs ~/.claude/scripts/gaming-mode.sh, which stops and records
// services, docker and waydroid, pins the CPU governor and sweeps old
// sessions (sparing ~/.config/gaming-mode/keep.txt). A second click undoes
// it. The engine's state file tells the button whether game mode is on.
Item {
    id: root

    readonly property string engine: "/home/pc/.claude/scripts/gaming-mode.sh"
    readonly property string stateFile: "/home/pc/.claude/state/gaming-mode.state.json"

    property bool active: false
    readonly property bool busy: run.running

    function refresh(): void {
        check.running = true;
    }

    implicitWidth: icon.implicitHeight + Tokens.padding.small
    implicitHeight: icon.implicitHeight

    StateLayer {
        // Same oversized hit area as the power button beside it
        anchors.fill: undefined
        anchors.centerIn: parent
        implicitWidth: implicitHeight
        implicitHeight: icon.implicitHeight + Tokens.padding.small
        radius: Tokens.rounding.full
        disabled: root.busy
        onClicked: {
            run.command = [root.engine, root.active ? "undo" : "on"];
            run.running = true;
        }
    }

    StyledRect {
        anchors.centerIn: parent
        implicitWidth: icon.implicitHeight + Tokens.padding.small
        implicitHeight: implicitWidth
        radius: Tokens.rounding.full
        color: Colours.palette.m3primaryContainer
        opacity: root.active ? 1 : 0

        Behavior on opacity {
            Anim {}
        }
    }

    MaterialIcon {
        id: icon

        anchors.centerIn: parent

        text: root.busy ? "hourglass_top" : "sports_esports"
        fill: root.active ? 1 : 0
        color: root.active ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
        fontStyle: Tokens.font.icon.builders.small.weight(Font.Bold).build()
    }

    Process {
        id: check

        command: ["test", "-f", root.stateFile]
        onExited: code => root.active = code === 0 // qmllint disable signal-handler-parameters
    }

    Process {
        id: run

        stdout: StdioCollector {}
        onExited: code => { // qmllint disable signal-handler-parameters
            const turningOn = run.command[1] === "on";
            root.refresh();
            if (code === 0)
                Toaster.toast(turningOn ? "Game mode on" : "Game mode off", turningOn ? "Stopped background services and swept old sessions" : "Restored the services game mode stopped", "sports_esports");
            else
                Toaster.toast("Game mode failed", "gaming-mode.sh exited with code " + code, "error");
        }
    }

    // The engine can also run from a terminal, so poll the state file.
    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
