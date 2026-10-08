import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

Item {
    id: root

    property string sunrise: "--:--"
    property string sunset: "--:--"
    property var goldenHourStart: null
    property var goldenHourEnd: null

    implicitWidth: 300
    implicitHeight: 200

    ColumnLayout {
        anchors.fill: parent
        spacing: Tokens.spacing.small

        StyledText {
            Layout.leftMargin: Tokens.padding.small
            text: Tr.tr("Sun Position")
            font: Tokens.font.body.builders.medium.weight(Font.DemiBold).build()
            color: Colours.palette.m3onSurface
        }

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true

            radius: Tokens.rounding.large
            color: Colours.tPalette.m3surfaceContainer

            Canvas {
                id: sunCanvas

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium

                onPaint: {
                    const ctx = getContext("2d");
                    const w = width;
                    const h = height;
                    const centerX = w / 2;
                    const centerY = h * 0.8;
                    const radius = Math.min(w, h) / 2.5;

                    ctx.clearRect(0, 0, w, h);

                    // Draw arc
                    ctx.strokeStyle = Colours.palette.m3tertiary;
                    ctx.lineWidth = 2;
                    ctx.beginPath();
                    ctx.arc(centerX, centerY, radius, Math.PI, 0, false);
                    ctx.stroke();

                    // Calculate current sun position
                    const now = new Date();
                    const sunriseDate = parseSunTime(root.sunrise);
                    const sunsetDate = parseSunTime(root.sunset);
                    const dayStart = sunriseDate.getTime();
                    const dayEnd = sunsetDate.getTime();
                    const dayDuration = dayEnd - dayStart;
                    const timeInDay = Math.max(0, Math.min(dayDuration, now.getTime() - dayStart));
                    const progress = timeInDay / dayDuration;
                    const sunAngle = Math.PI + progress * Math.PI;

                    // Draw golden hour zones
                    if (root.goldenHourStart && root.goldenHourEnd) {
                        const ghStart = root.goldenHourStart.getTime();
                        const ghEnd = root.goldenHourEnd.getTime();
                        const startProgress = (ghStart - dayStart) / dayDuration;
                        const endProgress = (ghEnd - dayStart) / dayDuration;
                        const startAngle = Math.PI + startProgress * Math.PI;
                        const endAngle = Math.PI + endProgress * Math.PI;

                        ctx.fillStyle = Colours.palette.m3tertiary;
                        ctx.globalAlpha = 0.15;
                        ctx.beginPath();
                        ctx.moveTo(centerX, centerY);
                        ctx.arc(centerX, centerY, radius, startAngle, endAngle, false);
                        ctx.lineTo(centerX, centerY);
                        ctx.fill();
                        ctx.globalAlpha = 1.0;
                    }

                    // Draw sunrise marker
                    const sunriseAngle = Math.PI;
                    ctx.fillStyle = Colours.palette.m3tertiary;
                    ctx.beginPath();
                    ctx.arc(centerX + Math.cos(sunriseAngle) * radius, centerY + Math.sin(sunriseAngle) * radius, 4, 0, Math.PI * 2);
                    ctx.fill();

                    // Draw sunset marker
                    const sunsetAngle = 0;
                    ctx.fillStyle = Colours.palette.m3secondary;
                    ctx.beginPath();
                    ctx.arc(centerX + Math.cos(sunsetAngle) * radius, centerY + Math.sin(sunsetAngle) * radius, 4, 0, Math.PI * 2);
                    ctx.fill();

                    // Draw sun position
                    if (timeInDay >= 0 && timeInDay <= dayDuration) {
                        ctx.fillStyle = Colours.palette.m3primary;
                        ctx.beginPath();
                        ctx.arc(centerX + Math.cos(sunAngle) * radius, centerY + Math.sin(sunAngle) * radius, 5, 0, Math.PI * 2);
                        ctx.fill();
                    }
                }

                function parseSunTime(timeStr: string): Date {
                    const today = new Date();
                    const parts = timeStr.split(":");
                    const hours = parseInt(parts[0]) || 0;
                    const minutes = parseInt(parts[1]) || 0;
                    today.setHours(hours, minutes, 0);
                    return today;
                }

                Timer {
                    interval: 60000
                    running: true
                    repeat: true
                    onTriggered: sunCanvas.requestPaint()
                }

                Component.onCompleted: requestPaint()
            }

            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Tokens.padding.medium
                spacing: Tokens.spacing.medium

                Column {
                    Layout.fillWidth: true

                    StyledText {
                        text: Tr.tr("Sunrise")
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurfaceVariant
                    }
                    StyledText {
                        text: root.sunrise
                        font: Tokens.font.body.builders.small.weight(Font.DemiBold).build()
                        color: Colours.palette.m3tertiary
                    }
                }

                Column {
                    Layout.fillWidth: true

                    StyledText {
                        text: Tr.tr("Golden Hour")
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurfaceVariant
                    }
                    StyledText {
                        text: root.goldenHourStart ? Qt.formatDateTime(root.goldenHourStart, Units.twelveHourClock ? "h:mm A" : "h:mm") + " - " + Qt.formatDateTime(root.goldenHourEnd, Units.twelveHourClock ? "h:mm A" : "h:mm") : "--:-- - --:--"
                        font: Tokens.font.body.builders.small.weight(Font.DemiBold).build()
                        color: Colours.palette.m3secondary
                    }
                }

                Column {
                    Layout.fillWidth: true

                    StyledText {
                        text: Tr.tr("Sunset")
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurfaceVariant
                    }
                    StyledText {
                        text: root.sunset
                        font: Tokens.font.body.builders.small.weight(Font.DemiBold).build()
                        color: Colours.palette.m3secondary
                    }
                }
            }
        }
    }
}
