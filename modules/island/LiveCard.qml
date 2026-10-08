pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// One agent up close: streamed output, files touched this turn, and a message box.
ColumnLayout {
    id: root

    required property var agent
    property real now
    property bool focusInput

    signal back

    spacing: Tokens.spacing.medium

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        IconButton {
            icon: "arrow_back"
            type: IconButton.Tonal
            onClicked: root.back()
        }

        CardHeader {
            Layout.fillWidth: true
            agent: root.agent
            subtitle: root.agent.turnStart ? qsTr("%1 · %2 %3").arg(root.agent.group).arg(root.agent.status).arg(Agents.duration((root.agent.doneAt || root.now) - root.agent.turnStart)) : root.agent.group
            chip: qsTr("live")
        }
    }

    LiveView {
        Layout.fillWidth: true
        sessionId: root.agent.sessionId ?? ""
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: (root.agent.files ?? []).length > 0
        spacing: Tokens.spacing.small

        StyledText {
            text: qsTr("Files touched this turn")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.small
        }

        Flow {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            Repeater {
                model: root.agent.files ?? []

                StyledRect {
                    id: chip

                    required property var modelData

                    implicitWidth: chipText.implicitWidth + Tokens.padding.medium * 2
                    implicitHeight: chipText.implicitHeight + Tokens.padding.small * 2
                    radius: Tokens.rounding.small
                    color: Colours.palette.m3surfaceContainerHigh

                    StyledText {
                        id: chipText

                        anchors.centerIn: parent
                        textFormat: Text.StyledText
                        text: `${chip.modelData.name} <font color="${Colours.palette.m3success}">+${chip.modelData.added}</font> <font color="${Colours.palette.m3error}">−${chip.modelData.removed}</font>`
                        font: Tokens.font.label.small
                    }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        StyledTextField {
            id: input

            Layout.fillWidth: true
            type: StyledTextField.Filled
            placeholderText: qsTr("Send the agent a message")
            onAccepted: {
                Agents.message(root.agent.paneId, text);
                text = "";
            }
            Component.onCompleted: if (root.focusInput)
                forceActiveFocus()
        }

        TextButton {
            text: qsTr("Jump")
            type: TextButton.Tonal
            onClicked: Agents.focus(root.agent.paneId)
        }

        TextButton {
            visible: root.agent.status === "working"
            text: qsTr("Stop")
            type: TextButton.Tonal
            onClicked: Agents.interrupt(root.agent.paneId)
        }
    }
}
