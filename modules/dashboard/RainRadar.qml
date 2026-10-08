import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia
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

            // 3x3 tiles at zoom 6 (RainViewer's max), shifted so the location sits in the centre
            Item {
                id: tiles

                readonly property int zoom: 6
                readonly property real fx: (parseFloat(root.longitude) + 180) / 360 * Math.pow(2, zoom)
                readonly property real fy: (1 - Math.log(Math.tan(Math.PI / 4 + parseFloat(root.latitude) * Math.PI / 360)) / Math.PI) / 2 * Math.pow(2, zoom)
                readonly property int tx: Math.floor(fx)
                readonly property int ty: Math.floor(fy)

                width: 768
                height: 768
                x: radarContainer.width / 2 - (256 + (fx - tx) * 256)
                y: radarContainer.height / 2 - (256 + (fy - ty) * 256)

                Repeater {
                    model: 9

                    Item {
                        id: tile

                        required property int index
                        readonly property int dx: index % 3 - 1
                        readonly property int dy: Math.floor(index / 3) - 1

                        x: (dx + 1) * 256
                        y: (dy + 1) * 256
                        width: 256
                        height: 256

                        Image {
                            anchors.fill: parent
                            asynchronous: true
                            source: `https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/${tiles.zoom}/${tiles.ty + tile.dy}/${tiles.tx + tile.dx}`
                        }

                        Image {
                            anchors.fill: parent
                            asynchronous: true
                            opacity: 0.8
                            source: root.radarData?.radarPath ? `https://tilecache.rainviewer.com${root.radarData.radarPath}/256/${tiles.zoom}/${tiles.tx + tile.dx}/${tiles.ty + tile.dy}/4/1_1.png` : ""
                        }
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

                text: root.radarData && root.radarData.time ? Qt.formatDateTime(new Date(root.radarData.time * 1000), "h:mm") : "--:--"
                font: Tokens.font.body.builders.small.build()
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }

    property var radarData: null

    Component.onCompleted: fetchRadarData()

    function fetchRadarData(): void {
        Requests.get("https://api.rainviewer.com/public/weather-maps.json", text => {
            if (!root)
                return;
            try {
                const json = JSON.parse(text);
                if (json.radar && json.radar.nowcast && json.radar.nowcast.length > 0) {
                    const latest = json.radar.nowcast[json.radar.nowcast.length - 1];
                    root.radarData = {
                        time: latest.time,
                        radarPath: latest.path
                    };
                } else if (json.radar && json.radar.past && json.radar.past.length > 0) {
                    const latest = json.radar.past[json.radar.past.length - 1];
                    root.radarData = {
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
