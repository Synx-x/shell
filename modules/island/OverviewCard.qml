pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// Every agent, grouped by project, with a filter and the plan usage ring.
ColumnLayout {
    id: root

    property real now
    property bool pinned
    property string filter: "all"

    readonly property var shown: Agents.agents.filter(a => filter === "all" || (filter === "working" ? a.status === "working" : a.status === "blocked" || a.status === "question"))
    readonly property var groups: {
        const map = {};
        for (const a of shown)
            (map[a.group] ?? (map[a.group] = [])).push(a);
        return Object.keys(map).sort().map(k => ({
                    name: k,
                    agents: map[k]
                }));
    }

    signal openAgent(string paneId)
    signal togglePin

    spacing: Tokens.spacing.medium

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        StyledText {
            Layout.fillWidth: true
            text: qsTr("Agents")
            font: Tokens.font.title.small
        }

        UsageRing {}

        IconButton {
            icon: root.pinned ? "close" : "push_pin"
            type: IconButton.Text
            onClicked: root.togglePin()
        }
    }

    RowLayout {
        spacing: Tokens.spacing.small

        Repeater {
            model: [
                {
                    id: "all",
                    label: qsTr("All %1").arg(Agents.count)
                },
                {
                    id: "working",
                    label: qsTr("Working %1").arg(Agents.working.length)
                },
                {
                    id: "waiting",
                    label: qsTr("Needs you %1").arg(Agents.waiting.length)
                }
            ]

            TextButton {
                required property var modelData

                text: modelData.label
                type: root.filter === modelData.id ? TextButton.Filled : TextButton.Tonal
                onClicked: root.filter = modelData.id
            }
        }
    }

    Repeater {
        model: ScriptModel {
            values: root.groups
            objectProp: "name"
        }

        ColumnLayout {
            id: group

            required property var modelData

            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledText {
                text: group.modelData.name.toUpperCase()
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.small
            }

            Repeater {
                model: ScriptModel {
                    values: group.modelData.agents
                    objectProp: "paneId"
                }

                AgentRow {
                    required property var modelData

                    Layout.fillWidth: true
                    agent: modelData
                    now: root.now
                    onOpen: root.openAgent(modelData.paneId)
                }
            }
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: root.shown.length === 0
        text: qsTr("Nothing here")
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
        horizontalAlignment: Text.AlignHCenter
    }

    StyledText {
        Layout.fillWidth: true
        text: qsTr("Click a row for its live view")
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.label.small
    }
}
