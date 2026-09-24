pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"
import qs.components
import qs.services
import Caelestia.Config
import Caelestia.I18n

Item {
    id: root

    required property var modelData
    required property ScreenState screenState

    StyledRect {
        id: rect

        anchors.fill: parent
        radius: Tokens.rounding.large
        color: {
            if (mouse.containsMouse)
                return Qt.alpha(Colours.palette.m3onSurface, 0.08);
            if (GridView.isCurrentItem)
                return Qt.alpha(Colours.palette.m3onSurface, 0.08);
            return "transparent";
        }

        MouseArea {
            id: mouse

            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                Emojis.copyEmoji(root.modelData); // qmllint disable missing-property
                root.screenState.launcher = false;
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Tokens.padding.small / 2
            spacing: Tokens.spacing.medium

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                text: root.modelData.emoji
                font: Tokens.font.headline.builders.small.size(Math.round(Tokens.font.headline.small.pointSize * 1.2)).build()
                horizontalAlignment: Text.AlignHCenter
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.maximumWidth: rect.width - Tokens.padding.extraSmall * 2
                text: root.modelData.name
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.NoWrap
            }
        }
    }
}
