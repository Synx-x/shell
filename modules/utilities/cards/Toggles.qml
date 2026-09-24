pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Bluetooth
import Caelestia.Components
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus
import qs.modules.bar.popouts as BarPopouts

StyledRect {
    id: root

    required property ScreenState screenState
    required property BarPopouts.Wrapper popouts

    readonly property var quickToggles: {
        const seenIds = new Set();

        return Config.utilities.quickToggles.values.filter(item => {
            if (!item.enabled)
                return false;

            if (seenIds.has(item.id)) {
                return false;
            }

            if (item.id === "vpn") {
                return GlobalConfig.utilities.vpn.selectedProvider.length > 0;
            }

            seenIds.add(item.id);
            return true;
        });
    }
    readonly property int splitIndex: Math.ceil(quickToggles.length / 2)
    readonly property bool needExtraRow: quickToggles.length > 6

    implicitHeight: layout.implicitHeight + Tokens.padding.extraLargeIncreased

    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        StyledText {
            text: Tr.tr("Quick toggles")
            font: Tokens.font.body.medium
        }

        QuickToggleRow {
            model: root.needExtraRow ? root.quickToggles.slice(0, root.splitIndex) : root.quickToggles
        }

        QuickToggleRow {
            visible: root.needExtraRow
            model: root.needExtraRow ? root.quickToggles.slice(root.splitIndex) : []
        }
    }

    component QuickToggleRow: ButtonRow {
        property alias model: repeater.model

        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        Repeater {
            id: repeater

            delegate: DelegateChooser {
                role: "id"

                DelegateChoice {
                    roleValue: "wifi"
                    delegate: Toggle {
                        icon: "wifi"
                        checked: Nmcli.wifiEnabled
                        tooltip: checked ? qsTr("Wi-Fi: On") : qsTr("Wi-Fi: Off")
                        onClicked: Nmcli.toggleWifi()
                    }
                }
                DelegateChoice {
                    roleValue: "bluetooth"
                    delegate: Toggle {
                        icon: "bluetooth"
                        checked: Bluetooth.defaultAdapter?.enabled ?? false // qmllint disable unresolved-type
                        tooltip: checked ? qsTr("Bluetooth: On") : qsTr("Bluetooth: Off")
                        onClicked: {
                            const adapter = Bluetooth.defaultAdapter; // qmllint disable unresolved-type
                            if (adapter)
                                adapter.enabled = !adapter.enabled;
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "mic"
                    delegate: Toggle {
                        icon: "mic"
                        checked: !Audio.sourceMuted
                        tooltip: checked ? qsTr("Microphone: Unmuted") : qsTr("Microphone: Muted")
                        onClicked: {
                            const audio = Audio.source?.audio;
                            if (audio)
                                audio.muted = !audio.muted;
                        }

                        WheelHandler {
                            orientation: Qt.Vertical
                            onWheel: event => {
                                if (event.angleDelta.y > 0)
                                    Audio.incrementSourceVolume();
                                else if (event.angleDelta.y < 0)
                                    Audio.decrementSourceVolume();
                            }
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "settings"
                    delegate: Toggle {
                        icon: "settings"
                        inactiveOnColour: Colours.palette.m3onSurfaceVariant
                        isToggle: false
                        tooltip: qsTr("Open settings")
                        onClicked: {
                            root.screenState.utilities = false;
                            WindowFactory.create();
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "gameMode"
                    delegate: Toggle {
                        icon: "gamepad"
                        checked: GameMode.enabled
                        tooltip: checked ? qsTr("Game Mode: On") : qsTr("Game Mode: Off")
                        onClicked: GameMode.enabled = !GameMode.enabled
                    }
                }
                DelegateChoice {
                    roleValue: "dnd"
                    delegate: Toggle {
                        icon: "notifications_off"
                        checked: Notifs.dnd
                        tooltip: checked ? qsTr("Do Not Disturb: On") : qsTr("Do Not Disturb: Off")
                        onClicked: Notifs.dnd = !Notifs.dnd
                    }
                }
                DelegateChoice {
                    roleValue: "vpn"
                    delegate: Toggle {
                        icon: "vpn_key"
                        checked: VPN.connected && VPN.status.state !== "needs-auth" && VPN.status.state !== "error"
                        enabled: !VPN.connecting && !VPN.disconnecting
                        isToggle: VPN.status.state !== "needs-auth" && VPN.status.state !== "error"
                        inactiveOnColour: Colours.palette.m3onSurfaceVariant
                        tooltip: VPN.connecting ? qsTr("VPN: Connecting…") : VPN.disconnecting ? qsTr("VPN: Disconnecting…") : checked ? qsTr("VPN: Connected") : qsTr("VPN: Disconnected")
                        onClicked: VPN.toggle()
                    }
                }
                DelegateChoice {
                    roleValue: "speaker"
                    delegate: Toggle {
                        icon: "volume_up"
                        checked: !Audio.muted
                        tooltip: Audio.muted ? qsTr("Speaker: Muted\nScroll to adjust volume") : qsTr("Speaker: %1%\nScroll to adjust volume").arg(Math.round(Audio.volume * 100))
                        onClicked: {
                            const audio = Audio.sink?.audio;
                            if (audio)
                                audio.muted = !audio.muted;
                        }

                        WheelHandler {
                            orientation: Qt.Vertical
                            onWheel: event => {
                                if (event.angleDelta.y > 0)
                                    Audio.incrementVolume();
                                else if (event.angleDelta.y < 0)
                                    Audio.decrementVolume();
                            }
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "audioOutput"
                    delegate: Toggle {
                        icon: "speaker"
                        inactiveOnColour: Colours.palette.m3onSurfaceVariant
                        isToggle: false
                        enabled: Audio.sinks.length > 1
                        tooltip: {
                            if (Audio.sinks.length <= 1)
                                return qsTr("Output: %1").arg(Audio.sink?.description ?? qsTr("—"));
                            const idx = Audio.sinks.findIndex(s => s === Audio.sink);
                            const next = Audio.sinks[(idx + 1) % Audio.sinks.length];
                            return qsTr("Output: %1\nScroll or click to switch → %2").arg(Audio.sink?.description ?? qsTr("—")).arg(next?.description ?? qsTr("—"));
                        }
                        onClicked: Audio.cycleNextAudioOutput()

                        WheelHandler {
                            orientation: Qt.Vertical
                            onWheel: event => {
                                if (event.angleDelta.y > 0)
                                    Audio.cycleNextAudioOutput();
                                else if (event.angleDelta.y < 0)
                                    Audio.cyclePreviousAudioOutput();
                            }
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "audioDevices"
                    delegate: Toggle {
                        icon: "tune"
                        inactiveOnColour: Colours.palette.m3onSurfaceVariant
                        isToggle: false
                        tooltip: qsTr("Audio settings")
                        onClicked: {
                            root.screenState.utilities = false;
                            WindowFactory.create(null, {
                                initialPageIdx: 3 // Audio page, see PageRegistry.qml
                            });
                        }
                    }
                }
            }
        }
    }

    component Toggle: IconButton {
        id: toggle

        property string tooltip: ""

        inactiveColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
        fillWidth: true
        isToggle: true
        isRound: true
        shapeMorph: true

        ToolTip.visible: toggle.tooltip.length > 0 && hovered
        ToolTip.text: toggle.tooltip
        ToolTip.delay: 500
    }
}
