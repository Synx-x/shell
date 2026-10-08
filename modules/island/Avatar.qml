import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// Agent initials on a colour picked from the pane id. Breathes while the agent works.
StyledRect {
    id: root

    property var agent
    property real size: 32

    readonly property int hue: agent?.hue ?? 0
    readonly property var fills: [Colours.palette.m3primary, Colours.palette.m3secondary, Colours.palette.m3tertiary, Colours.palette.m3primaryContainer]
    readonly property var inks: [Colours.palette.m3onPrimary, Colours.palette.m3onSecondary, Colours.palette.m3onTertiary, Colours.palette.m3onPrimaryContainer]

    implicitWidth: size
    implicitHeight: size
    radius: size / 2
    color: fills[hue]

    StyledText {
        anchors.centerIn: parent
        text: root.agent?.initials ?? "?"
        color: root.inks[root.hue]
        font: root.size < 28 ? Tokens.font.label.small : Tokens.font.label.medium
    }

    SequentialAnimation on scale {
        running: root.agent?.status === "working"
        loops: Animation.Infinite
        alwaysRunToEnd: true

        Anim {
            to: 1.08
            type: Anim.SlowEffects
        }
        Anim {
            to: 1
            type: Anim.SlowEffects
        }
    }
}
