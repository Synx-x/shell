import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Services
import qs.components
import qs.services
import qs.utils

StyledRect {
    id: root

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.extraLarge

    implicitWidth: Tokens.sizes.dashboard.perfNetworkCardWidth
    implicitHeight: Tokens.sizes.dashboard.perfNetworkCardHeight

    visible: !isNaN(GpuMem.total) && GpuMem.processesByVram.count > 0

    ServiceRef {
        service: GpuMem
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        RowLayout {
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: "memory_alt"
                color: Colours.palette.m3secondary
                fontStyle: Tokens.font.icon.medium
            }

            StyledText {
                text: Tr.tr("VRAM by Process")
                font: Tokens.font.title.medium
            }
        }

        // Stacked bar showing process VRAM usage
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            // Stacked bar
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Tokens.padding.large

                StyledRect {
                    anchors.fill: parent
                    color: Colours.palette.m3outline
                    radius: Tokens.rounding.small
                }

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    Repeater {
                        model: GpuMem.processesByVram

                        Item {
                            Layout.fillHeight: true
                            Layout.preferredWidth: (model.bytes / GpuMem.used) * parent.width

                            StyledRect {
                                anchors.fill: parent
                                color: getProcessColor(index)
                                radius: index === 0 ? Tokens.rounding.small : 0
                                anchors.rightMargin: index === GpuMem.processesByVram.count - 1 ? 0 : -1
                            }

                            ToolTip.text: "%1: %2".arg(model.name).arg(Units.formatBytes(model.bytes))
                            ToolTip.visible: ma.containsMouse && model.bytes > 0
                            ToolTip.delay: 500

                            MouseArea {
                                id: ma
                                anchors.fill: parent
                                hoverEnabled: true
                            }
                        }
                    }
                }
            }

            // Legend
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall

                Repeater {
                    model: Math.min(GpuMem.processesByVram.count, 4)

                    RowLayout {
                        spacing: Tokens.spacing.small

                        Rectangle {
                            Layout.preferredWidth: Tokens.padding.medium
                            Layout.preferredHeight: Tokens.padding.medium
                            color: getProcessColor(index)
                            radius: Tokens.rounding.extraSmall
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: GpuMem.processesByVram.get(index).name
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }

                        StyledText {
                            text: Units.formatBytes(GpuMem.processesByVram.get(index).bytes)
                            font: Tokens.font.body.builders.small.weight(Font.Medium).build()
                            color: Colours.palette.m3onSurfaceVariant
                        }
                    }
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignRight
                text: Tr.trCtx("Total", "VRAM total").arg(Units.formatBytes(GpuMem.used))
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }

    function getProcessColor(index: int): color {
        const colors = [
            Colours.palette.m3primary,
            Colours.palette.m3secondary,
            Colours.palette.m3tertiary,
            Colours.palette.m3error
        ];
        return colors[index % colors.length];
    }
}
