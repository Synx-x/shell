import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.services
import qs.utils

StyledRect {
    id: root

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.extraLarge

    implicitWidth: Tokens.sizes.dashboard.perfNetworkCardWidth
    implicitHeight: Tokens.sizes.dashboard.perfNetworkCardHeight

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        RowLayout {
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: "bolt"
                color: Colours.palette.m3primary
                fontStyle: Tokens.font.icon.medium
            }

            StyledText {
                text: Tr.tr("Power")
                font: Tokens.font.title.medium
            }
        }

        // Battery status when available
        ColumnLayout {
            visible: UPower.displayDevice && UPower.displayDevice.isLaptopBattery
            spacing: Tokens.spacing.small

            RowLayout {
                Layout.leftMargin: -Tokens.padding.extraSmall
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: "battery_full"
                    color: Colours.palette.m3secondary
                    fontStyle: Tokens.font.icon.medium
                }

                StyledText {
                    text: Tr.tr("Battery")
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    text: Strings.percentOne(UPower.displayDevice.percentage ?? 0)
                    font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
                    color: Colours.palette.m3secondary
                }
            }

            StyledProgressBar {
                value: (UPower.displayDevice.percentage ?? 0) / 100
                implicitHeight: Tokens.padding.small
                fgColour: Colours.palette.m3secondary
            }

            // Battery time remaining
            RowLayout {
                visible: UPower.displayDevice.state !== UPowerDeviceState.FullyCharged && UPower.displayDevice.state !== UPowerDeviceState.Charging
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: "schedule"
                    color: Colours.palette.m3outline
                    fontStyle: Tokens.font.icon.small
                }

                StyledText {
                    text: root.formatBatteryTime(UPower.displayDevice.timeToEmpty ?? 0)
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            // Charging status
            RowLayout {
                visible: [UPowerDeviceState.Charging, UPowerDeviceState.PendingCharge].includes(UPower.displayDevice.state ?? -1)
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: "charging_station"
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.small
                }

                StyledText {
                    text: Tr.tr("Charging")
                    font: Tokens.font.body.small
                    color: Colours.palette.m3primary
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }

        // AC status
        RowLayout {
            Layout.leftMargin: -Tokens.padding.extraSmall
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: UPower.displayDevice && UPower.displayDevice.nativePath.includes("AC") ? "power_on" : "power_off"
                color: Colours.palette.m3tertiary
                fontStyle: Tokens.font.icon.medium
                fill: 1
            }

            StyledText {
                text: Tr.tr("AC")
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                text: UPower.displayDevice && UPower.displayDevice.nativePath.includes("AC") ? Tr.tr("Connected") : Tr.tr("Disconnected")
                font: Tokens.font.body.builders.small.weight(Font.Medium).build()
                color: Colours.palette.m3tertiary
            }
        }
    }

    function formatBatteryTime(seconds: real): string {
        if (seconds <= 0) return "...";
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        if (hours > 0) {
            return Tr.trCtx("%1h %2m", "battery time remaining").arg(hours).arg(minutes);
        }
        return Tr.trCtx("%1m", "battery time remaining").arg(minutes);
    }
}
