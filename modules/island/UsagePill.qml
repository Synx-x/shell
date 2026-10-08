pragma ComponentBehavior: Bound

import QtQuick
import Caelestia
import Caelestia.Config
import qs.components
import qs.services
import "../.." as Root

Rectangle {
    id: root

    radius: 6
    color: Tokens.colours.m3surfaceContainerLow
    border.color: Tokens.colours.m3outlineVariant
    border.width: 1

    implicitWidth: usageRow.implicitWidth + 12
    implicitHeight: usageRow.implicitHeight + 8

    Row {
        id: usageRow
        anchors.centerIn: parent
        spacing: 8

        Text {
            text: `5h: ${Root.Services.ClaudeUsage.fiveHourPercentage.toFixed(1)}%`
            color: Tokens.colours.m3onSurface
            font.pixelSize: 10
            font.weight: Font.Medium
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            width: 1
            height: 12
            color: Tokens.colours.m3outlineVariant
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: `Weekly: ${Root.Services.ClaudeUsage.weeklyPercentage.toFixed(1)}%`
            color: Tokens.colours.m3onSurface
            font.pixelSize: 10
            font.weight: Font.Medium
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
