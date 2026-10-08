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

    readonly property list<PwNode> sinks: Audio.sinks
    readonly property PwNode currentSink: Audio.sink

    implicitHeight: visible ? layout.implicitHeight : 0
    visible: sinks.length > 1

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Tokens.spacing.small

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: "volume_up"
                fontStyle: Tokens.font.icon.small
                color: Colours.palette.m3onSurfaceVariant
            }

            StyledText {
                text: Tr.tr("Output")
                font: Tokens.font.label.medium
                color: Colours.palette.m3onSurfaceVariant
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            Repeater {
                model: sinks

                TextButton {
                    id: sink

                    required property int index
                    required property PwNode modelData

                    readonly property bool isActive: modelData === root.currentSink

                    text: modelData.description || modelData.name || Tr.trCtx("Unknown", "unknown audio device")
                    type: isActive ? TextButton.Filled : TextButton.Tonal

                    onClicked: {
                        if (!isActive) {
                            Audio.setAudioSink(modelData);
                        }
                    }

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }
            }
        }
    }
}
