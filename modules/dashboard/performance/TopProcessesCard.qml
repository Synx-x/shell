import QtQuick
import QtQuick.Layouts
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

    Component.onCompleted: TopProcesses.refCount++
    Component.onDestruction: TopProcesses.refCount--

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        RowLayout {
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: "speed"
                color: Colours.palette.m3primary
                fontStyle: Tokens.font.icon.medium
            }

            StyledText {
                text: Tr.tr("Top Processes")
                font: Tokens.font.title.medium
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Tokens.spacing.small

            Repeater {
                model: TopProcesses.processes

                ProcessRow {
                    required property var modelData

                    Layout.fillWidth: true
                    cpu: modelData.cpu
                    memory: modelData.mem
                    name: modelData.name
                    pid: modelData.pid
                    isProtected: modelData.protected
                }
            }

            Item {
                Layout.fillHeight: true
            }

            StyledText {
                visible: TopProcesses.processes.count === 0
                text: Tr.tr("No processes")
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
                Layout.alignment: Qt.AlignCenter
            }
        }
    }

    component ProcessRow: Item {
        id: procRow

        required property real cpu
        required property real memory
        required property string name
        required property int pid
        property bool isProtected

        property int killConfirmState: 0 // 0=no, 1=pending, 2=killed

        implicitHeight: procLayout.implicitHeight

        RowLayout {
            id: procLayout

            anchors.fill: parent
            spacing: Tokens.spacing.small

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall

                StyledText {
                    text: procRow.name
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }

                RowLayout {
                    spacing: Tokens.spacing.medium

                    RowLayout {
                        spacing: Tokens.spacing.extraSmall

                        MaterialIcon {
                            text: "speed"
                            color: Colours.palette.m3tertiary
                            fontStyle: Tokens.font.icon.small
                        }

                        StyledText {
                            text: "%1%".arg(procRow.cpu.toFixed(1))
                            font: Tokens.font.body.builders.small.weight(Font.Medium).build()
                            color: Colours.palette.m3tertiary
                        }
                    }

                    RowLayout {
                        spacing: Tokens.spacing.extraSmall

                        MaterialIcon {
                            text: "memory_alt"
                            color: Colours.palette.m3secondary
                            fontStyle: Tokens.font.icon.small
                        }

                        StyledText {
                            text: "%1%".arg(procRow.memory.toFixed(1))
                            font: Tokens.font.body.builders.small.weight(Font.Medium).build()
                            color: Colours.palette.m3secondary
                        }
                    }
                }
            }

            IconButton {
                visible: !procRow.isProtected && procRow.killConfirmState < 2
                icon: procRow.killConfirmState === 1 ? "check" : "close"
                type: IconButton.Tonal

                onClicked: {
                    if (procRow.killConfirmState === 0) {
                        procRow.killConfirmState = 1;
                        confirmTimer.restart();
                    } else if (procRow.killConfirmState === 1) {
                        TopProcesses.kill(procRow.pid);
                        procRow.killConfirmState = 2;
                        killTimer.restart();
                    }
                }

                Timer {
                    id: confirmTimer
                    interval: 3000
                    onTriggered: {
                        procRow.killConfirmState = 0;
                    }
                }

                Timer {
                    id: killTimer
                    interval: 2000
                    onTriggered: {
                        procRow.killConfirmState = 0;
                    }
                }
            }

            StyledText {
                visible: procRow.killConfirmState === 2
                text: Tr.tr("✓")
                color: Colours.palette.m3primary
                font: Tokens.font.body.medium
            }
        }
    }
}
