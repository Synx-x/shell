pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

// Pill that springs open into a card: on hover, on click (pinned), or when an agent blocks.
StyledRect {
    id: root

    property bool pinned
    // paneId -> true for cards with the live view open; survives model refreshes
    property var livePanes: ({})
    property string doneText

    readonly property bool alert: Agents.blocked.length > 0
    readonly property bool expanded: pinned || hover.containsMouse || alert
    readonly property var shownAgents: expanded && !pinned && !hover.containsMouse ? Agents.blocked : Agents.agents

    implicitWidth: expanded ? 420 : pill.implicitWidth + Tokens.padding.large * 2
    implicitHeight: (expanded ? card.implicitHeight : pill.implicitHeight) + Tokens.padding.medium * 2
    radius: expanded ? Tokens.rounding.large : implicitHeight / 2
    color: Colours.palette.m3surfaceContainer
    clip: true

    Behavior on implicitWidth {
        Anim {
            type: Anim.DefaultSpatial
        }
    }

    Behavior on implicitHeight {
        Anim {
            type: Anim.DefaultSpatial
        }
    }

    Behavior on radius {
        Anim {
            type: Anim.DefaultSpatial
        }
    }

    Connections {
        target: Agents

        function onAgentFinished(paneId: string): void {
            const a = Agents.agents.find(x => x.paneId === paneId);
            root.doneText = `${a?.name ?? "Agent"} done`;
            doneTimer.restart();
        }
    }

    Timer {
        id: doneTimer

        interval: 3000
        onTriggered: root.doneText = ""
    }

    MouseArea {
        id: hover

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onClicked: root.pinned = !root.pinned
    }

    RowLayout {
        id: pill

        anchors.centerIn: parent
        spacing: Tokens.spacing.small
        opacity: root.expanded ? 0 : 1
        visible: opacity > 0

        Behavior on opacity {
            Anim {
                type: Anim.FastEffects
            }
        }

        StatusDot {
            status: Agents.workingCount > 0 ? "working" : "idle"
        }

        StyledText {
            text: root.doneText || (Agents.workingCount > 0 ? qsTr("%1 working").arg(Agents.workingCount) : qsTr("%1 idle").arg(Agents.count))
            font: Tokens.font.label.medium
        }

        UsagePill {
            compact: true
        }
    }

    ColumnLayout {
        id: card

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Tokens.padding.medium
        spacing: Tokens.spacing.small
        opacity: root.expanded ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                Layout.fillWidth: true
                text: root.alert && root.shownAgents === Agents.blocked ? qsTr("Needs you") : qsTr("Agents")
                font: Tokens.font.title.small
            }

            UsagePill {}
        }

        Repeater {
            model: ScriptModel {
                values: root.shownAgents
                objectProp: "paneId"
            }

            AgentCard {
                required property var modelData

                Layout.fillWidth: true
                agent: modelData
                live: root.livePanes[modelData.paneId] ?? false
                onToggleLive: {
                    const next = Object.assign({}, root.livePanes);
                    next[modelData.paneId] = !live;
                    root.livePanes = next;
                }
            }
        }
    }
}
