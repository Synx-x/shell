pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import Caelestia.Images

IconImage {
    id: root

    required property color colour
    property bool analysed: false

    asynchronous: true
    mipmap: true
    backer.smooth: false

    layer.enabled: true
    layer.effect: Colouriser {
        sourceColor: analyser.dominantColour
        colorizationColor: root.colour
        colorize: root.analysed
    }

    layer.onEnabledChanged: {
        if (layer.enabled && status === Image.Ready)
            analyser.requestUpdate();
    }

    onStatusChanged: {
        if (layer.enabled && status === Image.Ready)
            analyser.requestUpdate();
    }

    ImageAnalyser {
        id: analyser

        sourceItem: root

        onDominantColourChanged: root.analysed = true
    }
}
