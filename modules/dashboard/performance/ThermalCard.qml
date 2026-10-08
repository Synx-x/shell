import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Services
import qs.components
import qs.services

StyledRect {
    id: root

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.extraLarge

    implicitWidth: Tokens.sizes.dashboard.perfNetworkCardWidth
    implicitHeight: Tokens.sizes.dashboard.perfNetworkCardHeight

    ServiceRef {
        service: SystemUsage
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        RowLayout {
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: "thermometer"
                color: Colours.palette.m3primary
                fontStyle: Tokens.font.icon.medium
            }

            StyledText {
                text: Tr.tr("Thermal")
                font: Tokens.font.title.medium
            }
        }

        // CPU Temperature
        ColumnLayout {
            spacing: Tokens.spacing.extraSmall

            RowLayout {
                Layout.leftMargin: -Tokens.padding.extraSmall
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: SystemUsage.cpuTempC > 90 ? "thermometer_alert" : "thermometer"
                    color: SystemUsage.cpuTempC > 90 ? Colours.palette.m3error : Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.medium
                    fill: 1
                }

                StyledText {
                    text: Tr.tr("CPU")
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    text: isNaN(SystemUsage.cpuTempC) ? "..." : "%1°C".arg(Math.round(SystemUsage.cpuTempC))
                    font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
                    color: SystemUsage.cpuTempC > 90 ? Colours.palette.m3error : Colours.palette.m3primary
                }
            }

            StyledProgressBar {
                value: isNaN(SystemUsage.cpuTempC) ? 0 : Math.min(SystemUsage.cpuTempC / 100, 1)
                implicitHeight: Tokens.padding.small
                fgColour: SystemUsage.cpuTempC > 90 ? Colours.palette.m3error : Colours.palette.m3primary
                indeterminate: isNaN(SystemUsage.cpuTempC)
            }
        }

        Item {
            Layout.fillHeight: true
        }

        // Fan RPM
        ColumnLayout {
            visible: SystemUsage.fanRpmMax > 0
            spacing: Tokens.spacing.extraSmall

            RowLayout {
                Layout.leftMargin: -Tokens.padding.extraSmall
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: "device_thermostat"
                    color: Colours.palette.m3secondary
                    fontStyle: Tokens.font.icon.medium
                    fill: 1
                }

                StyledText {
                    text: Tr.tr("Fan RPM")
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    text: SystemUsage.fanRpmMax > 0 ? "%1".arg(SystemUsage.fanRpmMax) : "..."
                    font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
                    color: Colours.palette.m3secondary
                }
            }
        }
    }
}
