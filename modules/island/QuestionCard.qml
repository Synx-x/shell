pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// An agent asking an AskUserQuestion question: numbered choices, answered by key press.
ColumnLayout {
    id: root

    required property var agent
    property int othersWaiting
    // Questions answered from here; the agent moves to the next one after each answer
    property int index

    readonly property var questions: agent.questions ?? []
    readonly property var current: questions[index] ?? null

    spacing: Tokens.spacing.medium

    onAgentChanged: if (!agent.questions)
        index = 0

    CardHeader {
        Layout.fillWidth: true
        agent: root.agent
        subtitle: root.questions.length > 1 ? qsTr("Question %1 of %2").arg(Math.min(root.index + 1, root.questions.length)).arg(root.questions.length) : root.agent.group
        chip: qsTr("asks you")
        chipColour: Colours.palette.m3primaryContainer
        chipInk: Colours.palette.m3onPrimaryContainer
    }

    StyledText {
        Layout.fillWidth: true
        text: root.current?.question ?? qsTr("Waiting for the agent")
        font: Tokens.font.body.medium
        wrapMode: Text.Wrap
    }

    Repeater {
        model: root.current?.options ?? []

        StyledRect {
            id: option

            required property var modelData
            required property int index

            Layout.fillWidth: true
            implicitHeight: optionLayout.implicitHeight + Tokens.padding.medium * 2
            radius: Tokens.rounding.medium
            color: optionArea.containsMouse ? Colours.palette.m3surfaceContainerHighest : Colours.palette.m3surfaceContainerHigh

            RowLayout {
                id: optionLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                spacing: Tokens.spacing.medium

                StyledRect {
                    Layout.alignment: Qt.AlignTop
                    implicitWidth: 24
                    implicitHeight: 24
                    radius: 12
                    color: Colours.palette.m3secondaryContainer

                    StyledText {
                        anchors.centerIn: parent
                        text: option.index + 1
                        color: Colours.palette.m3onSecondaryContainer
                        font: Tokens.font.label.small
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        Layout.fillWidth: true
                        text: option.modelData.label ?? ""
                        font: Tokens.font.body.small
                        wrapMode: Text.Wrap
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: text.length > 0
                        text: option.modelData.description ?? ""
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.small
                        wrapMode: Text.Wrap
                    }
                }
            }

            MouseArea {
                id: optionArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Agents.answer(root.agent.paneId, option.index);
                    root.index++;
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true

        TextButton {
            text: qsTr("Reply in terminal")
            type: TextButton.Text
            onClicked: Agents.focus(root.agent.paneId)
        }

        Item {
            Layout.fillWidth: true
        }

        StyledText {
            text: root.othersWaiting > 0 ? qsTr("%1 more waiting").arg(root.othersWaiting) : qsTr("Press a choice to answer")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.small
        }
    }
}
