pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// An agent that just finished: its last message and what the turn changed.
ColumnLayout {
    id: root

    required property var agent

    signal reply
    signal dismiss

    spacing: Tokens.spacing.medium

    CardHeader {
        Layout.fillWidth: true
        agent: root.agent
        subtitle: root.agent.turnStart && root.agent.doneAt ? qsTr("%1 · %2").arg(root.agent.group).arg(Agents.duration(root.agent.doneAt - root.agent.turnStart)) : root.agent.group
        chip: qsTr("finished")
        chipColour: Colours.palette.m3successContainer
        chipInk: Colours.palette.m3onSuccessContainer
    }

    StyledText {
        Layout.fillWidth: true
        visible: text.length > 0
        text: root.agent.summary ?? ""
        font: Tokens.font.body.small
        wrapMode: Text.Wrap
        maximumLineCount: 5
        elide: Text.ElideRight
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        Repeater {
            model: [
                {
                    value: String((root.agent.files ?? []).length),
                    label: qsTr("files")
                },
                {
                    value: `<font color="${Colours.palette.m3success}">+${root.agent.added ?? 0}</font> <font color="${Colours.palette.m3error}">−${root.agent.removed ?? 0}</font>`,
                    label: qsTr("lines")
                },
                {
                    value: root.agent.turnStart && root.agent.doneAt ? Agents.duration(root.agent.doneAt - root.agent.turnStart) : "–",
                    label: qsTr("time")
                }
            ]

            StyledRect {
                id: tile

                required property var modelData

                Layout.fillWidth: true
                implicitHeight: tileCol.implicitHeight + Tokens.padding.medium * 2
                radius: Tokens.rounding.medium
                color: Colours.palette.m3surfaceContainerHigh

                ColumnLayout {
                    id: tileCol

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    spacing: 0

                    StyledText {
                        text: tile.modelData.value
                        textFormat: Text.StyledText
                        font: Tokens.font.title.small
                    }

                    StyledText {
                        text: tile.modelData.label
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.small
                    }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        TextButton {
            Layout.fillWidth: true
            text: qsTr("Reply")
            type: TextButton.Filled
            onClicked: root.reply()
        }

        TextButton {
            Layout.fillWidth: true
            text: qsTr("Jump to pane")
            type: TextButton.Tonal
            onClicked: Agents.focus(root.agent.paneId)
        }

        TextButton {
            Layout.fillWidth: true
            text: qsTr("Dismiss")
            type: TextButton.Tonal
            onClicked: root.dismiss()
        }
    }
}
