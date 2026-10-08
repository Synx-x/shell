pragma ComponentBehavior: Bound

import QtQuick
import qs.components

Item {
    id: root

    required property ScreenState screenState
    required property Item dashboardPanel

    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.margins: 8

    Island {
        anchors.fill: parent
        screenState: root.screenState
        dashboardPanel: root.dashboardPanel
    }
}
