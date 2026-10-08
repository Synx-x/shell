import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// Status dot that pulses while the agent works.
StyledRect {
    id: root

    property string status

    implicitWidth: 10
    implicitHeight: 10
    radius: 5
    color: status === "blocked" ? Colours.palette.m3error : status === "working" ? Colours.palette.m3primary : Colours.palette.m3outline

    SequentialAnimation on opacity {
        running: root.status === "working"
        loops: Animation.Infinite
        alwaysRunToEnd: true

        Anim {
            to: 0.35
            type: Anim.SlowEffects
        }
        Anim {
            to: 1
            type: Anim.SlowEffects
        }
    }
}
