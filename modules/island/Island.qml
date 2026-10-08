pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import qs.components
import qs.services
import "../.." as Root

Item {
    id: root

    required property ScreenState screenState
    required property Item dashboardPanel

    property bool isExpanded: false
    property string blockedPaneId: ""
    property list<QtObject> permissionPrompts: []

    readonly property real pillHeight: 32
    readonly property real pillWidth: Math.min(150, parent.width - 40)
    readonly property real cardWidth: 350
    readonly property real cardMaxHeight: Math.min(500, parent.height - 100)

    visible: Root.Services.Agents.hasAgents && !(root.screenState.dashboard && Root.Config.dashboard.enabled)
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: 12

    implicitWidth: isExpanded ? cardWidth : pillWidth
    implicitHeight: isExpanded ? cardMaxHeight : pillHeight

    onBlockedPaneIdChanged: {
        if (blockedPaneId) {
            isExpanded = true;
        }
    }

    Behavior on implicitWidth {
        Anim { type: Anim.DefaultSpatial }
    }

    Behavior on implicitHeight {
        Anim { type: Anim.DefaultSpatial }
    }

    Rectangle {
        id: background
        anchors.fill: parent
        radius: isExpanded ? 12 : pilldHeight / 2
        color: Tokens.colours.m3surfaceContainer
        border.color: Tokens.colours.m3outline
        border.width: 1

        Behavior on radius {
            Anim { type: Anim.DefaultSpatial }
        }
    }

    MouseArea {
        id: pillClick
        anchors.fill: parent
        enabled: !root.isExpanded
        onClicked: root.isExpanded = true
    }

    Flickable {
        id: cardContent
        anchors.fill: parent
        anchors.margins: 8
        clip: true
        visible: root.isExpanded
        contentHeight: cardColumn.implicitHeight

        Column {
            id: cardColumn
            width: parent.width
            spacing: 8

            Text {
                text: `${Root.Services.Agents.agentCount} agents working`
                color: Tokens.colours.m3onSurface
                font.pixelSize: 13
                font.weight: Font.Bold
                width: parent.width
                elide: Text.ElideRight
            }

            Repeater {
                model: Root.Services.Agents.agents
                delegate: AgentCard {
                    width: cardColumn.width
                    agent: modelData
                    isBlocked: modelData.paneId === root.blockedPaneId
                }
            }
        }
    }

    Text {
        id: pillText
        visible: !root.isExpanded
        anchors.centerIn: parent
        text: `● ${Root.Services.Agents.agentCount} working`
        color: Tokens.colours.m3onSurface
        font.pixelSize: 11
        font.weight: Font.Medium
    }

    Item {
        id: closeArea
        anchors.top: parent.top
        anchors.right: parent.right
        width: 24
        height: 24
        visible: root.isExpanded

        MouseArea {
            anchors.fill: parent
            onClicked: root.isExpanded = false
        }

        Text {
            anchors.centerIn: parent
            text: "✕"
            color: Tokens.colours.m3onSurface
            font.pixelSize: 14
        }
    }

    UsagePill {
        visible: root.isExpanded
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 4
        anchors.rightMargin: 28
    }

    Connections {
        target: Root.Services.Agents
        function onAgentsChanged() {
            if (!Root.Services.Agents.hasAgents) {
                root.isExpanded = false;
            }
        }
    }
}
