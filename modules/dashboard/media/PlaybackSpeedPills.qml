pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    // Only show if player supports rate changes
    readonly property bool rateSupported: Players.active?.rateSupported ?? false
    readonly property real currentRate: Players.active?.rate ?? 1.0

    implicitHeight: visible ? layout.implicitHeight : 0
    visible: rateSupported

    RowLayout {
        id: layout

        anchors.fill: parent
        spacing: Tokens.spacing.small

        StyledText {
            text: Tr.tr("Speed")
            font: Tokens.font.label.medium
            color: Colours.palette.m3onSurfaceVariant
        }

        Repeater {
            model: [1.0, 1.25, 1.5]

            TextButton {
                id: speedBtn

                required property int modelData

                text: modelData === 1.0 ? "1x" : modelData.toString() + "x"
                type: Math.abs(root.currentRate - modelData) < 0.01 ? TextButton.Filled : TextButton.Tonal

                onClicked: {
                    if (Players.active?.rateSupported) {
                        Players.active.rate = modelData;
                    }
                }
            }
        }
    }
}
