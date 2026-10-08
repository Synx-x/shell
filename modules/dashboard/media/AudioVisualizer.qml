pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.services

Item {
    id: root

    readonly property int barCount: GlobalConfig.services.visualiserBars
    readonly property real barSpacing: Tokens.spacing.extraSmall
    readonly property real minBarHeight: Tokens.sizes.controls.small
    readonly property real maxBarHeight: Tokens.sizes.dashboard.mediaVisualizerHeight ?? Tokens.sizes.controls.large * 2

    implicitHeight: maxBarHeight

    // Only active when tab is visible
    required property bool isTabActive

    ServiceRef {
        service: Audio.cava
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.small
        anchors.rightMargin: Tokens.padding.small
        spacing: barSpacing

        Repeater {
            model: barCount

            Rectangle {
                id: bar

                required property int index

                readonly property real normalizedValue: Math.max(0.02, Math.min(1, Audio.cava.values[index] ?? 0))
                readonly property real targetHeight: minBarHeight + normalizedValue * (maxBarHeight - minBarHeight)

                width: (root.width - (barCount - 1) * barSpacing) / barCount
                height: currentHeight
                radius: Tokens.rounding.scale * 2
                color: Colours.palette.m3primary

                Behavior on height {
                    Anim {
                        type: Anim.DefaultEffects
                        duration: 50
                    }
                }

                Behavior on color {
                    CAnim {}
                }

                property real currentHeight: minBarHeight

                Component.onCompleted: {
                    currentHeight = minBarHeight;
                }

                Connections {
                    function onValuesChanged(): void {
                        if (root.isTabActive) {
                            bar.currentHeight = bar.targetHeight;
                        }
                    }

                    target: Audio.cava
                }
            }
        }
    }
}
