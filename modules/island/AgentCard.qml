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

    required property QtObject agent
    property bool isBlocked: false
    property bool isExpanded: false
    property bool showLiveView: false

    radius: 8
    color: isBlocked ? Tokens.colours.m3errorContainer : Tokens.colours.m3surfaceContainerLow
    border.color: isBlocked ? Tokens.colours.m3error : Tokens.colours.m3outlineVariant
    border.width: 1
    implicitHeight: column.implicitHeight + 16
    clip: true

    Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
        spacing: 6

        Row {
            width: parent.width
            spacing: 8

            Rectangle {
                id: statusDot
                width: 8
                height: 8
                radius: 4
                anchors.verticalCenter: parent.verticalCenter
                color: {
                    switch (root.agent.status) {
                    case "working": return Tokens.colours.m3primary;
                    case "blocked": return Tokens.colours.m3error;
                    case "idle": return Tokens.colours.m3success;
                    default: return Tokens.colours.m3outline;
                    }
                }

                SequentialAnimationGroup {
                    running: root.agent.status === "working"
                    loops: Animation.Infinite

                    NumberAnimation {
                        target: statusDot
                        property: "opacity"
                        from: 1; to: 0.4
                        duration: 1000
                    }
                    NumberAnimation {
                        target: statusDot
                        property: "opacity"
                        from: 0.4; to: 1
                        duration: 1000
                    }
                }
            }

            Column {
                spacing: 2
                Layout.fillWidth: true

                Text {
                    text: root.agent.name
                    color: Tokens.colours.m3onSurface
                    font.pixelSize: 12
                    font.weight: Font.SemiBold
                    elide: Text.ElideRight
                    width: parent.width
                }

                Text {
                    text: {
                        const ticker = Root.Services.AgentEvents.getTicker(root.agent.paneId);
                        return ticker || root.agent.status;
                    }
                    color: Tokens.colours.m3onSurfaceVariant
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    width: parent.width
                }
            }

            Item { Layout.fillWidth: true }

            Button {
                text: "Jump"
                onClicked: Root.Services.Agents.focus(root.agent.paneId)
            }
        }

        Row {
            width: parent.width
            spacing: 6
            visible: root.isBlocked

            Button {
                text: "Allow"
                onClicked: Root.Services.Agents.approve(root.agent.paneId, "Allow")
            }

            Button {
                text: "Deny"
                onClicked: Root.Services.Agents.approve(root.agent.paneId, "Deny")
            }

            Button {
                text: "Always"
                onClicked: Root.Services.Agents.approve(root.agent.paneId, "Always")
            }
        }

        LiveView {
            width: parent.width
            visible: root.showLiveView
            paneId: root.agent.paneId
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            root.showLiveView = !root.showLiveView;
        }
    }
}
