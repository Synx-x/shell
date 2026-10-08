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

    implicitWidth: layout.implicitWidth + Tokens.padding.large * 2
    implicitHeight: layout.implicitHeight + Tokens.padding.large * 2

    Component.onCompleted: GpuProfile.refCount++
    Component.onDestruction: GpuProfile.refCount--

    ColumnLayout {
        id: layout

        anchors.centerIn: parent
        spacing: Tokens.spacing.small

        RowLayout {
            Layout.leftMargin: -Tokens.padding.extraSmall
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: GpuProfile.profile === "docked" ? "storage" : "smartphone"
                color: GpuProfile.profile === "docked" ? Colours.palette.m3secondary : Colours.palette.m3tertiary
                fontStyle: Tokens.font.icon.medium
            }

            StyledText {
                text: GpuProfile.profile === "docked" ? Tr.tr("Docked (NVIDIA)") : (GpuProfile.profile === "mobile" ? Tr.tr("Mobile (Intel)") : Tr.tr("GPU?"))
                font: Tokens.font.title.small
                color: GpuProfile.profile === "docked" ? Colours.palette.m3secondary : Colours.palette.m3tertiary
            }
        }

        // Show dGPU stats when active
        ColumnLayout {
            visible: GpuProfile.profile === "docked"
            spacing: Tokens.spacing.extraSmall

            RowLayout {
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: GpuProfile.dgpuState === "active" ? "power" : "power_off"
                    color: GpuProfile.dgpuState === "active" ? Colours.palette.m3primary : Colours.palette.m3outline
                    fontStyle: Tokens.font.icon.small
                }

                StyledText {
                    text: GpuProfile.dgpuState === "active" ? Tr.tr("dGPU Awake") : Tr.tr("dGPU Suspended")
                    font: Tokens.font.body.small
                    color: GpuProfile.dgpuState === "active" ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                }
            }

            // Power and temp when awake
            RowLayout {
                visible: GpuProfile.dgpuState === "active"
                spacing: Tokens.spacing.medium

                RowLayout {
                    spacing: Tokens.spacing.extraSmall

                    MaterialIcon {
                        text: "bolt"
                        color: Colours.palette.m3primary
                        fontStyle: Tokens.font.icon.small
                    }

                    StyledText {
                        text: "%1 W".arg(GpuProfile.dgpuPowerW.toFixed(1))
                        font: Tokens.font.body.small
                    }
                }

                RowLayout {
                    spacing: Tokens.spacing.extraSmall

                    MaterialIcon {
                        text: GpuProfile.dgpuTempC > 80 ? "device_thermostat" : "device_thermostat"
                        color: GpuProfile.dgpuTempC > 80 ? Colours.palette.m3error : Colours.palette.m3primary
                        fontStyle: Tokens.font.icon.small
                    }

                    StyledText {
                        text: "%1°C".arg(Math.round(GpuProfile.dgpuTempC))
                        font: Tokens.font.body.small
                    }
                }
            }
        }
    }
}
