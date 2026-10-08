import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// Claude plan usage: 5-hour, plus weekly when not compact.
StyledRect {
    id: root

    property bool compact

    visible: ClaudeUsage.available
    implicitWidth: label.implicitWidth + Tokens.padding.medium * 2
    implicitHeight: label.implicitHeight + Tokens.padding.small
    radius: implicitHeight / 2
    color: Colours.palette.m3secondaryContainer

    StyledText {
        id: label

        anchors.centerIn: parent
        color: Colours.palette.m3onSecondaryContainer
        font: Tokens.font.label.small
        text: root.compact || ClaudeUsage.weekly < 0 ? qsTr("5h %1%").arg(Math.round(ClaudeUsage.fiveHour)) : qsTr("5h %1% · wk %2%").arg(Math.round(ClaudeUsage.fiveHour)).arg(Math.round(ClaudeUsage.weekly))
    }
}
