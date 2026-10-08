import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

StyledRect {
    id: root

    property string latitude: "0"
    property string longitude: "0"

    implicitWidth: 300
    implicitHeight: 240
    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.small
        spacing: Tokens.spacing.small

        StyledText {
            text: Tr.tr("Rain Radar")
            font: Tokens.font.body.builders.medium.weight(Font.DemiBold).build()
            color: Colours.palette.m3onSurface
        }

        Item {
            id: radarContainer

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Image {
                id: baseMap

                anchors.fill: parent
                cache: false
                asynchronous: true

                source: {
                    const lat = root.latitude;
                    const lon = root.longitude;
                    const zoom = 8;
                    const size = 256;
                    return `https://tile.openstreetmap.org/${zoom}/${Math.floor((parseFloat(lon) + 180) / 360 * Math.pow(2, zoom))}/${Math.floor((1 - Math.log(Math.tan(Math.PI / 4 + parseFloat(lat) * Math.PI / 360)) / Math.PI) / 2 * Math.pow(2, zoom))}.png`;
                }

                onStatusChanged: {
                    if (status === Image.Error) {
                        console.warn("Failed to load base map");
                        radarContainer.visible = false;
                    }
                }
            }

            Image {
                id: radarOverlay

                anchors.fill: parent
                cache: false
                asynchronous: true
                opacity: 0.7

                source: {
                    if (!radarData || !radarData.radarPath)
                        return "";
                    const lat = root.latitude;
                    const lon = root.longitude;
                    const zoom = 8;
                    const size = 256;
                    const tileX = Math.floor((parseFloat(lon) + 180) / 360 * Math.pow(2, zoom));
                    const tileY = Math.floor((1 - Math.log(Math.tan(Math.PI / 4 + parseFloat(lat) * Math.PI / 360)) / Math.PI) / 2 * Math.pow(2, zoom));
                    return `https://tilecache.rainviewer.com${radarData.radarPath}/256/${zoom}/${tileX}/${tileY}/4/1_1.png`;
                }

                onStatusChanged: {
                    if (status === Image.Error) {
                        console.warn("Failed to load radar overlay");
                    }
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: 8
                height: 8
                radius: 4
                color: Colours.palette.m3primary
            }

            Rectangle {
                anchors.centerIn: parent
                width: 14
                height: 14
                radius: 7
                color: "transparent"
                border.color: Colours.palette.m3primary
                border.width: 1
            }

            StyledText {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: Tokens.padding.extraSmall

                text: radarData && radarData.time ? new Date(radarData.time * 1000).toLocaleTimeString() : "--:--"
                font: Tokens.font.body.builders.extraSmall.build()
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }

    property var radarData: null

    Component.onCompleted: fetchRadarData()

    function fetchRadarData(): void {
        Requests.get("https://api.rainviewer.com/public/weather-maps.json", text => {
            try {
                const json = JSON.parse(text);
                if (json.radar && json.radar.nowcast && json.radar.nowcast.length > 0) {
                    const latest = json.radar.nowcast[json.radar.nowcast.length - 1];
                    radarData = {
                        time: latest.time,
                        radarPath: latest.path
                    };
                } else if (json.radar && json.radar.past && json.radar.past.length > 0) {
                    const latest = json.radar.past[json.radar.past.length - 1];
                    radarData = {
                        time: latest.time,
                        radarPath: latest.path
                    };
                } else {
                    console.warn("No radar data available");
                }
            } catch (error) {
                console.warn("Failed to parse radar data:", error);
                radarContainer.visible = false;
            }
        }, error => {
            console.warn("Failed to fetch radar data:", error);
            radarContainer.visible = false;
        });
    }

    Timer {
        interval: 600000
        running: true
        repeat: true
        onTriggered: fetchRadarData()
    }
}
