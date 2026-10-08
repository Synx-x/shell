import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// 5-hour usage ring with the 5-hour and weekly percentages beside it.
StyledRect {
    id: root

    visible: ClaudeUsage.available
    implicitWidth: row.implicitWidth + Tokens.padding.medium * 2
    implicitHeight: row.implicitHeight + Tokens.padding.small * 2
    radius: implicitHeight / 2
    color: Colours.palette.m3surfaceContainerHigh

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: Tokens.spacing.small

        CircularProgress {
            implicitWidth: 22
            implicitHeight: 22
            value: Math.max(0, ClaudeUsage.fiveHour) / 100
        }

        StyledText {
            text: ClaudeUsage.weekly >= 0 ? qsTr("5h %1% · wk %2%").arg(Math.round(ClaudeUsage.fiveHour)).arg(Math.round(ClaudeUsage.weekly)) : qsTr("5h %1%").arg(Math.round(ClaudeUsage.fiveHour))
            font: Tokens.font.label.small
        }
    }
}
