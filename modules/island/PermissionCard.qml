pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// An agent waiting on a tool permission: what it wants to run, and Allow / Always / Deny.
ColumnLayout {
    id: root

    required property var agent
    property real now
    property int othersWaiting

    spacing: Tokens.spacing.medium

    CardHeader {
        Layout.fillWidth: true
        agent: root.agent
        subtitle: root.agent.turnStart ? qsTr("%1 · working %2").arg(root.agent.group).arg(Agents.duration(root.now - root.agent.turnStart)) : root.agent.group
        chip: qsTr("needs you")
        chipColour: Colours.palette.m3errorContainer
        chipInk: Colours.palette.m3onErrorContainer
    }

    StyledText {
        Layout.fillWidth: true
        text: root.agent.permission || qsTr("Wants to use a tool")
        font: Tokens.font.body.medium
        wrapMode: Text.Wrap
    }

    StyledRect {
        Layout.fillWidth: true
        visible: (root.agent.toolDetail ?? "").length > 0
        implicitHeight: detail.implicitHeight + Tokens.padding.medium * 2
        radius: Tokens.rounding.medium
        color: Colours.palette.m3surfaceContainerLowest

        StyledText {
            id: detail

            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            text: root.agent.toolDetail ?? ""
            font: Tokens.font.mono.small
            wrapMode: Text.WrapAnywhere
            maximumLineCount: 6
            elide: Text.ElideRight
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        TextButton {
            Layout.fillWidth: true
            text: qsTr("Allow  1")
            type: TextButton.Filled
            onClicked: Agents.approve(root.agent.paneId, "Allow")
        }

        TextButton {
            Layout.fillWidth: true
            text: qsTr("Always  2")
            type: TextButton.Tonal
            onClicked: Agents.approve(root.agent.paneId, "Always")
        }

        TextButton {
            Layout.fillWidth: true
            text: qsTr("Deny  esc")
            type: TextButton.Tonal
            onClicked: Agents.approve(root.agent.paneId, "Deny")
        }
    }

    RowLayout {
        Layout.fillWidth: true

        TextButton {
            text: qsTr("Jump to pane")
            type: TextButton.Text
            onClicked: Agents.focus(root.agent.paneId)
        }

        Item {
            Layout.fillWidth: true
        }

        StyledText {
            visible: root.othersWaiting > 0
            text: qsTr("%1 more waiting").arg(root.othersWaiting)
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.small
        }
    }
}
