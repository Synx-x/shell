import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

Item {
    id: root

    property int uvIndex: 0
    property int usAqi: -1

    implicitWidth: pillLayout.implicitWidth
    implicitHeight: pillLayout.implicitHeight

    RowLayout {
        id: pillLayout

        anchors.fill: parent
        spacing: Tokens.spacing.medium

        EnvironmentPill {
            id: uvPill

            Layout.fillWidth: true
            icon: "wb_sunny"
            label: Tr.tr("UV Index")
            value: root.uvIndex
            levelText: getUvLevel(root.uvIndex)
            colour: getUvColour(root.uvIndex)
        }

        EnvironmentPill {
            id: aqiPill

            Layout.fillWidth: true
            icon: "air"
            label: Tr.tr("Air Quality")
            value: root.usAqi >= 0 ? root.usAqi : -1
            levelText: getAqiLevel(root.usAqi)
            colour: getAqiColour(root.usAqi)
        }
    }

    function getUvLevel(index: int): string {
        if (index < 3) return Tr.tr("Low");
        if (index < 6) return Tr.tr("Moderate");
        if (index < 8) return Tr.tr("High");
        if (index < 11) return Tr.tr("Very High");
        return Tr.tr("Extreme");
    }

    function getUvColour(index: int): color {
        if (index < 3) return Colours.palette.m3tertiary;
        if (index < 6) return Colours.palette.m3primary;
        if (index < 8) return Colours.palette.m3error;
        if (index < 11) return Colours.palette.m3error;
        return Colours.palette.m3error;
    }

    function getAqiLevel(aqi: int): string {
        if (aqi < 0) return Tr.tr("Unknown");
        if (aqi < 51) return Tr.tr("Good");
        if (aqi < 101) return Tr.tr("Fair");
        if (aqi < 151) return Tr.tr("Moderate");
        if (aqi < 201) return Tr.tr("Poor");
        if (aqi < 301) return Tr.tr("Very Poor");
        return Tr.tr("Hazardous");
    }

    function getAqiColour(aqi: int): color {
        if (aqi < 0) return Colours.palette.m3onSurfaceVariant;
        if (aqi < 51) return Colours.palette.m3tertiary;
        if (aqi < 101) return Colours.palette.m3primary;
        if (aqi < 151) return Colours.palette.m3tertiary;
        if (aqi < 201) return Colours.palette.m3error;
        if (aqi < 301) return Colours.palette.m3error;
        return Colours.palette.m3error;
    }

    component EnvironmentPill: StyledRect {
        id: pillRoot

        property string icon
        property string label
        property int value
        property string levelText
        property color colour

        implicitHeight: 70
        radius: Tokens.rounding.large
        color: Colours.tPalette.m3surfaceContainer

        RowLayout {
            anchors.fill: parent
            anchors.margins: Tokens.padding.small
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: pillRoot.icon
                fontStyle: Tokens.font.icon.large
                color: pillRoot.colour
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: -Tokens.spacing.extraSmall

                StyledText {
                    text: pillRoot.label
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }

                RowLayout {
                    spacing: Tokens.spacing.small

                    StyledText {
                        text: pillRoot.value >= 0 ? pillRoot.value.toString() : "--"
                        font: Tokens.font.body.builders.medium.weight(Font.DemiBold).build()
                        color: pillRoot.colour
                    }

                    StyledText {
                        text: pillRoot.levelText
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurface
                    }
                }
            }
        }
    }
}
