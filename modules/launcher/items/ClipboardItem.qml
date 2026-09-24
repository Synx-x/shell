pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"
import qs.components
import qs.components.controls
import qs.services
import Caelestia.Config
import Caelestia.I18n

Item {
    id: root

    required property var modelData
    required property int index
    required property ScreenState screenState

    property bool isItemHovered: itemHoverHandler.hovered
    readonly property bool isHovered: root.isItemHovered
    readonly property bool isCurrent: ListView.isCurrentItem && root.ListView.view?.lastInteraction === "keyboard" // qmllint disable missing-property

    implicitHeight: Tokens.sizes.launcher.itemHeight
    anchors.left: parent?.left
    anchors.right: parent?.right

    onIsItemHoveredChanged: {
        if (isItemHovered) {
            root.ListView.view.hoveredItem = root;
            root.ListView.view.lastInteraction = "hover";
        }
    }

    HoverHandler {
        id: itemHoverHandler
    }

    StyledRect {
        id: rect

        anchors.fill: parent
        implicitHeight: content.implicitHeight + Tokens.padding.medium * 2
        radius: Tokens.rounding.large
        color: {
            if (root.isHovered || root.isCurrent)
                return Qt.alpha(Colours.palette.m3onSurface, 0.08);
            return "transparent";
        }

        MouseArea {
            id: mouse

            anchors.fill: parent
            onClicked: {
                root.ListView.view.currentIndex = root.index;
                Clipboard.copyToClipboard(root.modelData); // qmllint disable missing-property
                root.screenState.launcher = false;
            }
        }

        RowLayout {
            id: content

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Tokens.padding.medium
            anchors.rightMargin: Tokens.padding.medium
            spacing: Tokens.spacing.medium

            MaterialIcon {
                text: {
                    if (root.modelData.isPinned)
                        return "push_pin";
                    if (root.modelData.isImage)
                        return "image";
                    return "description";
                }
                color: root.modelData.isPinned ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                StyledText {
                    Layout.fillWidth: true
                    text: root.modelData.content
                    color: root.isCurrent ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.medium
                    elide: Text.ElideRight
                }

                StyledText {
                    text: {
                        const content = root.modelData.content;
                        const words = content.split(/\s+/).length;
                        const chars = content.length;
                        return Tr.tr("%1 characters, %2 words").arg(chars).arg(words);
                    }
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                }
            }

            Row {
                id: buttonsRow

                spacing: Tokens.spacing.small

                IconButton {
                    id: pinButton

                    icon: root.modelData.isPinned ? "push_pin" : "keep"
                    type: root.modelData.isPinned ? IconButton.Filled : IconButton.Text
                    radius: Tokens.rounding.medium
                    padding: Tokens.padding.extraSmall
                    onClicked: {
                        Clipboard.togglePin(root.modelData); // qmllint disable missing-property
                    }
                }

                IconButton {
                    id: deleteButton

                    icon: "delete"
                    type: IconButton.Text
                    radius: Tokens.rounding.medium
                    padding: Tokens.padding.extraSmall
                    onClicked: {
                        root.ListView.view.deletedItemIndex = root.index;
                        Clipboard.deleteItem(root.modelData); // qmllint disable missing-property
                    }
                }
            }
        }
    }
}
