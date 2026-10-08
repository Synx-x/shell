pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

// Collapsed island content: idle, working, done flash, or needs-you.
RowLayout {
    id: root

    property var flashAgent
    property bool compact

    readonly property var waitingAgent: Agents.waiting[0] ?? null
    readonly property string mode: waitingAgent ? "waiting" : flashAgent ? "done" : Agents.working.length > 0 ? "working" : compact ? "dot" : "idle"

    spacing: Tokens.spacing.small

    // Needs you
    Avatar {
        visible: root.mode === "waiting"
        agent: root.waitingAgent
        size: 22
    }

    StyledText {
        visible: root.mode === "waiting"
        text: qsTr("%1 needs you").arg(root.waitingAgent?.name ?? "")
        color: Colours.palette.m3onErrorContainer
        font: Tokens.font.label.medium
        elide: Text.ElideRight
        Layout.maximumWidth: 220
    }

    // Done flash
    StyledRect {
        visible: root.mode === "done"
        implicitWidth: 22
        implicitHeight: 22
        radius: 11
        color: Colours.palette.m3success

        MaterialIcon {
            anchors.centerIn: parent
            text: "check"
            color: Colours.palette.m3onSuccess
        }
    }

    StyledText {
        visible: root.mode === "done"
        text: root.flashAgent?.name ?? ""
        color: Colours.palette.m3onSuccessContainer
        font: Tokens.font.label.medium
        elide: Text.ElideRight
        Layout.maximumWidth: 200
    }

    StyledText {
        visible: root.mode === "done"
        text: qsTr("done")
        color: Colours.palette.m3success
        font: Tokens.font.label.medium
    }

    // Working: stacked avatars, count, latest action, usage
    Row {
        visible: root.mode === "working"
        spacing: -8

        Repeater {
            model: Agents.working.slice(0, 3)

            Avatar {
                required property var modelData

                agent: modelData
                size: 22
                border.width: 2
                border.color: Colours.palette.m3surfaceContainer
            }
        }
    }

    StyledText {
        visible: root.mode === "working"
        text: qsTr("%1 working").arg(Agents.working.length)
        font: Tokens.font.label.medium
    }

    StyledText {
        visible: root.mode === "working" && text.length > 0
        text: Agents.working[0]?.ticker ?? ""
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.label.small
        elide: Text.ElideRight
        Layout.maximumWidth: 160
    }

    UsagePill {
        visible: root.mode === "working" && ClaudeUsage.available
        compact: true
    }

    // Idle and dot
    StyledRect {
        visible: root.mode === "idle" || root.mode === "dot"
        implicitWidth: 8
        implicitHeight: 8
        radius: 4
        color: Colours.palette.m3outline
    }

    StyledText {
        visible: root.mode === "idle"
        text: qsTr("%1 idle").arg(Agents.count)
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.label.medium
    }
}
