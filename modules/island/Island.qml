pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// The agent island. Springs between a pill and one of five cards:
//   live      one agent's stream (row click, or Reply on a done card)
//   done      an agent's finished summary (hover or click the 6 s green done flash)
//   overview  every agent (hover, or pinned by click)
//   permission / question   the first agent waiting on you (opens by itself)
// A waiting card wins over the hover overview so its buttons stay under the cursor.
StyledRect {
    id: root

    property bool pinned
    property string livePane
    property bool liveFocusInput
    property string donePane
    property string flashPane
    property bool compact
    property real now: Date.now()

    readonly property var waitingAgent: Agents.waiting[0] ?? null
    readonly property var liveAgent: Agents.agents.find(a => a.paneId === livePane) ?? null
    readonly property var doneAgent: Agents.agents.find(a => a.paneId === donePane) ?? null
    readonly property var flashAgent: Agents.agents.find(a => a.paneId === flashPane) ?? null

    readonly property string view: {
        if (liveAgent)
            return "live";
        if (doneAgent)
            return "done";
        if (pinned)
            return "overview";
        if (waitingAgent)
            return waitingAgent.status === "question" ? "question" : "permission";
        if (hover.hovered)
            return "overview";
        return "pill";
    }
    readonly property bool expanded: view !== "pill"
    readonly property real cardWidth: view === "live" ? 560 : view === "overview" ? 520 : 480
    readonly property real pad: expanded ? Tokens.padding.large : Tokens.padding.small

    // Anything that changes what the pill would say wakes it from the compact dot
    readonly property int activity: Agents.working.length + Agents.waiting.length * 100

    implicitWidth: expanded ? cardWidth : Math.max(34, content.implicitWidth + Tokens.padding.large * 2)
    implicitHeight: Math.max(34, content.implicitHeight + pad * 2)
    radius: expanded ? Tokens.rounding.extraLarge : implicitHeight / 2
    clip: true
    color: {
        if (view === "pill" && waitingAgent)
            return Colours.palette.m3errorContainer;
        if (view === "pill" && flashAgent)
            return Colours.palette.m3successContainer;
        return Colours.palette.m3surfaceContainer;
    }
    border.width: waitingAgent && (view === "pill" || view === "permission" || view === "question") ? 2 : 0
    border.color: waitingAgent?.status === "question" ? Colours.palette.m3primary : Colours.palette.m3error

    function closeAll(): void {
        pinned = false;
        livePane = "";
        donePane = "";
    }

    onViewChanged: fadeIn.restart()
    onActivityChanged: {
        compact = false;
        idleTimer.restart();
    }

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

    Behavior on color {
        CAnim {}
    }

    // Hovering a done flash opens that agent's summary, not the overview
    HoverHandler {
        id: hover

        onHoveredChanged: if (hovered && root.flashPane)
            root.donePane = root.flashPane
    }

    Connections {
        target: Agents

        function onAgentFinished(paneId: string): void {
            root.flashPane = paneId;
            flashTimer.restart();
        }
    }

    Timer {
        id: flashTimer

        interval: 6000
        onTriggered: root.flashPane = ""
    }

    Timer {
        id: idleTimer

        interval: 30000
        running: true
        onTriggered: root.compact = Agents.working.length === 0 && Agents.waiting.length === 0
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.expanded
        triggeredOnStart: true
        onTriggered: root.now = Date.now()
    }

    Anim {
        id: fadeIn

        target: content
        property: "opacity"
        from: 0
        to: 1
        type: Anim.DefaultEffects
    }

    Loader {
        id: content

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: root.pad

        sourceComponent: {
            switch (root.view) {
            case "live":
                return liveComp;
            case "done":
                return doneComp;
            case "overview":
                return overviewComp;
            case "permission":
                return permissionComp;
            case "question":
                return questionComp;
            default:
                return pillComp;
            }
        }
    }

    Component {
        id: pillComp

        Item {
            implicitWidth: pill.implicitWidth
            implicitHeight: Math.max(22, pill.implicitHeight)

            Pill {
                id: pill

                anchors.centerIn: parent
                flashAgent: root.flashAgent
                compact: root.compact
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.flashAgent)
                        root.donePane = root.flashPane;
                    else
                        root.pinned = true;
                }
            }
        }
    }

    Component {
        id: permissionComp

        PermissionCard {
            width: root.cardWidth - root.pad * 2
            agent: root.waitingAgent
            now: root.now
            othersWaiting: Agents.waiting.length - 1
        }
    }

    Component {
        id: questionComp

        QuestionCard {
            width: root.cardWidth - root.pad * 2
            agent: root.waitingAgent
            othersWaiting: Agents.waiting.length - 1
        }
    }

    Component {
        id: overviewComp

        OverviewCard {
            width: root.cardWidth - root.pad * 2
            now: root.now
            pinned: root.pinned
            onTogglePin: {
                if (root.pinned)
                    root.closeAll();
                else
                    root.pinned = true;
            }
            onOpenAgent: paneId => {
                root.pinned = true;
                root.liveFocusInput = false;
                root.livePane = paneId;
            }
        }
    }

    Component {
        id: liveComp

        LiveCard {
            width: root.cardWidth - root.pad * 2
            agent: root.liveAgent
            now: root.now
            focusInput: root.liveFocusInput
            onBack: root.livePane = ""
        }
    }

    Component {
        id: doneComp

        DoneCard {
            width: root.cardWidth - root.pad * 2
            agent: root.doneAgent
            onReply: {
                root.pinned = true;
                root.liveFocusInput = true;
                root.livePane = root.donePane;
                root.donePane = "";
            }
            onDismiss: root.donePane = ""
        }
    }
}
