pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    readonly property list<PwNode> streams: Audio.streams.filter(s => s.audio && s.isStream && (s.properties["application.name"] ?? s.name) !== "caelestia-shell" && (s.properties["application.process.binary"] ?? "") !== "qs")
    readonly property int maxStreamsToShow: 4

    implicitHeight: visible ? layout.implicitHeight : 0
    visible: visibleStreams.length > 0

    readonly property list<PwNode> visibleStreams: streams.slice(0, maxStreamsToShow)

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Tokens.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: "apps"
                fontStyle: Tokens.font.icon.small
                color: Colours.palette.m3onSurfaceVariant
            }

            StyledText {
                text: Tr.tr("App Volume")
                font: Tokens.font.label.medium
                color: Colours.palette.m3onSurfaceVariant
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                visible: streams.length > maxStreamsToShow
                text: Tr.tr("+%1 more").arg(streams.length - maxStreamsToShow)
                font: Tokens.font.label.small
                color: Colours.palette.m3onSurfaceVariant
            }
        }

        Repeater {
            model: visibleStreams

            ColumnLayout {
                id: streamControl

                required property int index
                required property PwNode modelData

                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                StyledText {
                    Layout.fillWidth: true
                    text: Audio.getStreamName(modelData)
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    StyledSlider {
                        Layout.fillWidth: true
                        value: Audio.getStreamVolume(modelData) / GlobalConfig.services.maxVolume
                        wavy: false

                        onInteraction: value => {
                            Audio.setStreamVolume(modelData, value * GlobalConfig.services.maxVolume);
                        }
                    }

                    StyledText {
                        Layout.preferredWidth: 40
                        text: Math.round(Audio.getStreamVolume(modelData) * 100) + "%"
                        font: Tokens.font.label.small
                        color: Colours.palette.m3onSurfaceVariant
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }
}
