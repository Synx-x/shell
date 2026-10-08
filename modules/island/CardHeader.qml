import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

// Avatar, name, subtitle and a status chip. Shared by every agent card.
RowLayout {
    id: root

    property var agent
    property string subtitle
    property string chip
    property color chipColour: Colours.palette.m3secondaryContainer
    property color chipInk: Colours.palette.m3onSecondaryContainer

    spacing: Tokens.spacing.medium

    Avatar {
        agent: root.agent
        size: 36
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        StyledText {
            Layout.fillWidth: true
            text: root.agent?.name ?? ""
            font: Tokens.font.body.medium
            elide: Text.ElideRight
        }

        StyledText {
            Layout.fillWidth: true
            text: root.subtitle
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.small
            elide: Text.ElideRight
        }
    }

    StyledRect {
        visible: root.chip.length > 0
        implicitWidth: chipText.implicitWidth + Tokens.padding.medium * 2
        implicitHeight: chipText.implicitHeight + Tokens.padding.small
        radius: implicitHeight / 2
        color: root.chipColour

        StyledText {
            id: chipText

            anchors.centerIn: parent
            text: root.chip
            color: root.chipInk
            font: Tokens.font.label.small
        }
    }
}
