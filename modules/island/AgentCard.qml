pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// One agent: status, activity ticker, actions, optional live view.
StyledRect {
    id: root

    required property var agent
    property bool live

    signal toggleLive

    readonly property bool blocked: agent.status === "blocked"
    readonly property string permission: AgentEvents.permissionFor(agent.paneId)

    implicitHeight: layout.implicitHeight + Tokens.padding.medium * 2
    radius: Tokens.rounding.medium
    color: Colours.tPalette.m3surfaceContainerHigh

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        spacing: Tokens.spacing.small

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StatusDot {
                status: root.agent.status
            }

            StyledText {
                Layout.fillWidth: true
                text: root.agent.name
                font: Tokens.font.body.medium
                elide: Text.ElideRight
            }

            StyledText {
                text: root.blocked ? qsTr("needs you") : root.agent.status
                color: root.blocked ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.small
            }

            IconButton {
                icon: "terminal"
                type: IconButton.Text
                onClicked: root.toggleLive()
            }

            IconButton {
                icon: "open_in_new"
                type: IconButton.Text
                onClicked: Agents.focus(root.agent.paneId)
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: text.length > 0
            text: root.blocked && root.permission ? root.permission : AgentEvents.tickerFor(root.agent.paneId)
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.small
            wrapMode: root.blocked ? Text.Wrap : Text.NoWrap
            elide: Text.ElideRight
            maximumLineCount: root.blocked ? 4 : 1
        }

        RowLayout {
            visible: root.blocked
            spacing: Tokens.spacing.small

            TextButton {
                text: qsTr("Allow")
                type: TextButton.Filled
                onClicked: Agents.approve(root.agent.paneId, "Allow")
            }

            TextButton {
                text: qsTr("Always")
                type: TextButton.Tonal
                onClicked: Agents.approve(root.agent.paneId, "Always")
            }

            TextButton {
                text: qsTr("Deny")
                type: TextButton.Tonal
                onClicked: Agents.approve(root.agent.paneId, "Deny")
            }
        }

        LiveView {
            Layout.fillWidth: true
            visible: root.live
            paneId: root.agent.paneId
        }
    }
}
