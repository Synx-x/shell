pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components.containers
import qs.modules.bar as Bar

Scope {
    id: root

    required property ShellScreen screen
    required property Bar.BarWrapper bar
    required property EdgeGeometry geometry

    ExclusionZone {
        anchors.left: true
        hasBar: root.geometry.barOnLeft
    }

    ExclusionZone {
        anchors.top: true
        hasBar: root.geometry.barOnTop
    }

    ExclusionZone {
        anchors.right: true
    }

    ExclusionZone {
        anchors.bottom: true
        hasBar: root.geometry.barOnBottom
        // Local: a floating bar also reserves its gap and the frame below it.
        extraZone: root.geometry.barFloating ? root.geometry.floatGap + contentItem.Config.border.thickness : 0
    }

    component ExclusionZone: StyledWindow {
        property bool hasBar
        property real extraZone

        screen: root.screen
        name: "border-exclusion"
        exclusiveZone: hasBar ? root.bar.exclusiveZone + extraZone : contentItem.Config.border.thickness
        mask: Region {}
        implicitWidth: 1
        implicitHeight: 1
    }
}
