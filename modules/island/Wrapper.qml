pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// Top-center agent island. Hidden while the dashboard is open, since both use the top edge.
Item {
    id: root

    required property ScreenState screenState

    readonly property bool shown: Agents.enabled && Agents.count > 0 && !screenState.dashboard

    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.topMargin: Tokens.padding.small

    implicitWidth: shown ? island.implicitWidth : 0
    implicitHeight: shown ? island.implicitHeight : 0
    opacity: shown ? 1 : 0
    visible: opacity > 0

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    Island {
        id: island

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
    }
}
