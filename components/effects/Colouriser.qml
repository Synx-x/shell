import QtQuick
import QtQuick.Effects
import qs.components

MultiEffect {
    property color sourceColor: "black"
    property bool colorize: true

    colorization: colorize ? 1 : 0
    brightness: 1 - sourceColor.hslLightness

    Behavior on colorizationColor {
        CAnim {}
    }
}
