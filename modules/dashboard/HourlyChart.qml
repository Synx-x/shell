import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

StyledRect {
    id: root

    property list<var> hourlyData: []

    implicitWidth: 600
    implicitHeight: 180
    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.small
        spacing: Tokens.spacing.small

        StyledText {
            text: Tr.tr("Next 12 Hours")
            font: Tokens.font.body.builders.medium.weight(Font.DemiBold).build()
            color: Colours.palette.m3onSurface
        }

        Canvas {
            id: canvas

            Layout.fillWidth: true
            Layout.fillHeight: true

            onPaint: {
                const ctx = getContext("2d");
                const w = width;
                const h = height;
                const data = root.hourlyData.slice(0, 12);

                if (data.length === 0)
                    return;

                ctx.clearRect(0, 0, w, h);

                // Find min/max temps
                let minTemp = data[0].tempC;
                let maxTemp = data[0].tempC;
                for (let i = 0; i < data.length; i++) {
                    minTemp = Math.min(minTemp, data[i].tempC);
                    maxTemp = Math.max(maxTemp, data[i].tempC);
                }

                const tempRange = Math.max(maxTemp - minTemp, 5);
                const padding = 40;
                const chartW = w - padding * 2;
                const chartH = h - padding * 2;
                const stepX = data.length > 1 ? chartW / (data.length - 1) : chartW / 2;

                // Draw precipitation bars
                ctx.globalAlpha = 0.3;
                for (let i = 0; i < data.length; i++) {
                    const chance = data[i].precipChance ?? 0;
                    const barH = (chance / 100) * chartH * 0.4;
                    const x = padding + i * stepX;
                    ctx.fillRect(x - 6, padding + chartH * 0.6 - barH, 12, barH);
                }
                ctx.globalAlpha = 1.0;

                // Draw temperature line
                ctx.strokeStyle = Colours.palette.m3primary;
                ctx.lineWidth = 2;
                ctx.beginPath();

                for (let i = 0; i < data.length; i++) {
                    const temp = data[i].tempC;
                    const normalized = (temp - minTemp) / tempRange;
                    const x = padding + i * stepX;
                    const y = padding + (1 - normalized) * chartH * 0.5;

                    if (i === 0)
                        ctx.moveTo(x, y);
                    else
                        ctx.lineTo(x, y);
                }
                ctx.stroke();

                // Draw temperature dots and labels
                ctx.textAlign = "center";
                ctx.textBaseline = "top";
                ctx.font = "10px sans-serif";
                ctx.fillStyle = Colours.palette.m3onSurfaceVariant;

                for (let i = 0; i < data.length; i++) {
                    const x = padding + i * stepX;
                    const temp = data[i].tempC;
                    const normalized = (temp - minTemp) / tempRange;
                    const y = padding + (1 - normalized) * chartH * 0.5;

                    // Draw dot
                    ctx.fillStyle = Colours.palette.m3primary;
                    ctx.beginPath();
                    ctx.arc(x, y, 3, 0, Math.PI * 2);
                    ctx.fill();

                    // Draw time label
                    ctx.fillStyle = Colours.palette.m3onSurfaceVariant;
                    ctx.fillText(data[i].hour + ":00", x, padding + chartH * 0.55);
                }
            }

            Component.onCompleted: canvas.requestPaint()

            Connections {
                target: root

                function onHourlyDataChanged() {
                    canvas.requestPaint();
                }
            }
        }
    }
}
