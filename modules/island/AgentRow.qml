import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

// One agent in the overview: avatar, name, status, ticker, line counts, elapsed time.
StyledRect {
    id: root

    required property var agent
    property real now

    readonly property bool waiting: agent.status === "blocked" || agent.status === "question"
    readonly property string statusText: agent.status === "blocked" ? qsTr("needs you") : agent.status === "question" ? qsTr("asks you") : agent.status

    signal open

    implicitHeight: layout.implicitHeight + Tokens.padding.medium * 2
    radius: Tokens.rounding.medium
    color: area.containsMouse ? Colours.palette.m3surfaceContainerHighest : Colours.palette.m3surfaceContainerHigh
    border.width: waiting ? 2 : 0
    border.color: Colours.palette.m3error

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        spacing: Tokens.spacing.medium

        Avatar {
            agent: root.agent
            size: 32
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                StyledText {
                    Layout.fillWidth: true
                    text: root.agent.name
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }

                StyledText {
                    text: root.statusText
                    color: root.waiting ? Colours.palette.m3error : root.agent.status === "working" ? Colours.palette.m3primary : Colours.palette.m3outline
                    font: Tokens.font.label.small
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: text.length > 0
                text: root.agent.status === "blocked" ? root.agent.permission ?? "" : root.agent.ticker ?? ""
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }
        }

        ColumnLayout {
            spacing: 2

            StyledText {
                Layout.alignment: Qt.AlignRight
                visible: (root.agent.added ?? 0) + (root.agent.removed ?? 0) > 0
                text: `<font color="${Colours.palette.m3success}">+${root.agent.added ?? 0}</font> <font color="${Colours.palette.m3error}">−${root.agent.removed ?? 0}</font>`
                textFormat: Text.StyledText
                font: Tokens.font.label.small
            }

            StyledText {
                Layout.alignment: Qt.AlignRight
                visible: (root.agent.turnStart ?? 0) > 0
                text: Agents.duration((root.agent.doneAt || root.now) - root.agent.turnStart)
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.small
            }
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.open()
    }
}
