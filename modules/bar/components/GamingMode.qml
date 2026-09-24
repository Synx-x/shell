import QtQuick
import Quickshell.Io
import Caelestia
import Caelestia.Config
import qs.components
import qs.services

// Local: drives ~/.claude/scripts/gaming-mode.sh, which stops and records
// services, docker and waydroid, pins the CPU governor and sweeps old
// sessions (sparing ~/.config/gaming-mode/keep.txt).
// Left click turns game mode on, or undoes it when it is on.
// Right click runs the full pass again even when it is on.
// The engine runs in its own transient unit. Its memory reclaim restarts
// this shell, which would otherwise kill it halfway.
Item {
    id: root

    readonly property string engine: "/home/pc/.claude/scripts/gaming-mode.sh"
    readonly property string stateFile: "/home/pc/.claude/state/gaming-mode.state.json"
    readonly property string unit: "gaming-mode-btn"

    property bool active: false
    property bool busy: false

    function refresh(): void {
        check.running = true;
    }

    function start(action: string): void {
        if (busy)
            return;
        const scripts = {
            on: `"${engine}" on && msg="Stopped background services and swept old sessions" || msg="gaming-mode.sh on failed"; notify-send -a "Game mode" -i input-gaming "Game mode on" "$msg"`,
            full: `"${engine}" on; notify-send -a "Game mode" -i input-gaming "Full cleanup done" "Stopped services, swept old sessions and reclaimed memory"`,
            undo: `"${engine}" undo; notify-send -a "Game mode" -i input-gaming "Game mode off" "Restored the services game mode stopped"`
        };
        busy = true;
        run.command = ["systemd-run", "--user", "--collect", "--quiet", "--unit=" + unit, "sh", "-c", scripts[action]];
        run.running = true;
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
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        disabled: root.busy
        onClicked: event => { // qmllint disable signal-handler-parameters
            if (event.button === Qt.RightButton)
                root.start("full");
            else
                root.start(root.active ? "undo" : "on");
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
        id: run

        onExited: code => { // qmllint disable signal-handler-parameters
            // systemd-run refuses a second unit with the same name, so a
            // failure here usually means a run is already going.
            if (code !== 0)
                Toaster.toast("Game mode is busy", "A game mode run is still going", "hourglass_top");
            root.refresh();
        }
    }

    // Prints "<state file missing?> <unit not running?>", 0 meaning yes.
    Process {
        id: check

        command: ["sh", "-c", `test -f "${root.stateFile}"; a=$?; systemctl --user --quiet is-active ${root.unit}.service; echo "$a $?"`]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(" ");
                root.active = parts[0] === "0";
                root.busy = parts[1] === "0";
            }
        }
    }

    // The engine can also run from a terminal, so poll.
    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
