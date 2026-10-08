pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

Item {
    id: root

    // Get chapters from MPRIS metadata
    readonly property var chapters: {
        if (!Players.active)
            return [];

        const metadata = Players.active.metadata ?? {};
        const chapters = metadata["org.mpris.MediaPlayer2.chapters"] ??
                        metadata["mpris:chapters"] ??
                        [];
        return Array.isArray(chapters) ? chapters : [];
    }

    readonly property int totalDuration: Players.active?.length ?? 0
    readonly property bool hasChapters: chapters.length > 0

    implicitHeight: visible ? 6 : 0
    visible: hasChapters

    Row {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.small
        anchors.rightMargin: Tokens.padding.small
        spacing: 0

        Repeater {
            model: root.chapters

            Rectangle {
                id: tick

                required property int index

                readonly property real position: modelData.startTime ?? (modelData.offset ?? 0)
                readonly property real relativePos: totalDuration > 0 ? position / totalDuration : 0

                width: root.width * relativePos - (index > 0 ? root.children[index - 1].width : 0)
                height: parent.height
                color: "transparent"

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: Tokens.spacing.extraSmall
                    height: parent.height
                    color: Colours.palette.m3secondary
                    radius: Tokens.rounding.scale

                    Behavior on color {
                        CAnim {}
                    }
                }
            }
        }
    }
}
