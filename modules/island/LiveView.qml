pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.services

// The agent's last 16 transcript lines, refreshed every second while visible: its text,
// tool calls (⏺, primary colour) and tool results (⎿, dimmed, green when they pass).
// Reads the Claude session transcript, since the pane's bottom rows are only the status line.
StyledRect {
    id: root

    required property string sessionId
    property var lines: []
    // Two sizes below the mono token, to fit more of the stream
    readonly property font lineFont: Qt.font({
        family: Tokens.font.mono.small.family,
        pointSize: Math.max(7, Tokens.font.mono.small.pointSize - 2)
    })

    implicitHeight: col.implicitHeight + Tokens.padding.medium * 2
    radius: Tokens.rounding.medium
    color: Colours.palette.m3surfaceContainerLowest

    function colourFor(line: string): color {
        const t = line.trim();
        if (/^[⏺●]/.test(t))
            return Colours.palette.m3primary;
        if (/✓|passed|\bpass\b/.test(t))
            return Colours.palette.m3success;
        if (/^⎿/.test(t))
            return Colours.palette.m3outline;
        return Colours.palette.m3onSurface;
    }

    // First line of a tool call's most telling argument
    function toolArg(input: var): string {
        const v = input?.command ?? input?.file_path ?? input?.pattern ?? input?.url ?? input?.description ?? input?.prompt ?? "";
        return String(v).split("\n")[0];
    }

    function resultText(content: var): string {
        if (Array.isArray(content))
            content = content.map(c => c.text ?? "").join(" ");
        return String(content ?? "").trim().split("\n")[0];
    }

    function parse(text: string): void {
        const out = [];
        for (const line of text.split("\n")) {
            let e;
            try {
                e = JSON.parse(line);
            } catch (err) {
                continue;
            }
            const content = e.message?.content;
            if (!Array.isArray(content))
                continue;
            for (const b of content) {
                if (b.type === "text" && e.type === "assistant" && b.text.trim())
                    out.push(b.text.trim().split("\n")[0]);
                else if (b.type === "tool_use")
                    out.push(`⏺ ${b.name}(${toolArg(b.input)})`);
                else if (b.type === "tool_result")
                    out.push(`⎿  ${resultText(b.content) || "done"}`);
            }
        }
        lines = out.slice(-16);
    }

    Process {
        id: readProc

        command: ["sh", "-c", `f=$(ls "$HOME"/.claude/projects/*/"$1".jsonl 2>/dev/null | head -n 1) && tail -n 120 "$f"`, "sh", root.sessionId]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Timer {
        interval: 1000
        repeat: true
        triggeredOnStart: true
        running: root.visible && root.sessionId.length > 0
        onTriggered: readProc.running = true
    }

    ColumnLayout {
        id: col

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        spacing: 0

        Repeater {
            model: root.lines

            StyledText {
                required property string modelData

                Layout.fillWidth: true
                text: modelData
                elide: Text.ElideRight
                font: root.lineFont
                color: root.colourFor(modelData)
            }
        }
    }
}
