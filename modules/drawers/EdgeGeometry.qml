pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.modules.bar as Bar

QtObject {
    id: root

    required property Bar.BarWrapper bar
    required property var win
    required property int configPosition
    required property int dashboardPosition

    readonly property int position: normalize(configPosition)
    readonly property bool horizontal: position === BarPosition.Top || position === BarPosition.Bottom
    readonly property bool barOnLeft: position === BarPosition.Left
    readonly property bool barOnTop: position === BarPosition.Top
    readonly property bool barOnBottom: position === BarPosition.Bottom
    readonly property int effectiveDashboardPosition: {
        if (barOnTop)
            return DashboardPosition.Left;
        if (barOnBottom)
            return dashboardPosition;
        return DashboardPosition.Top;
    }

    // Local: with the bar on top, the dashboard opens from the bottom centre.
    // The launcher then opens from its keybind only, since it shares that edge.
    readonly property bool dashboardOnBottom: barOnTop

    // Local: with the bar on the bottom it floats as a pill, lifted off
    // the thin screen frame by floatGap and inset floatInset from each side.
    readonly property bool barFloating: barOnBottom
    readonly property real floatGap: 10
    readonly property real floatInset: 180
    readonly property bool dashboardOnLeft: !dashboardOnBottom && effectiveDashboardPosition === DashboardPosition.Left
    readonly property bool dashboardOnTop: !dashboardOnBottom && effectiveDashboardPosition === DashboardPosition.Top

    readonly property real barExtent: bar.extent
    readonly property real barClamped: bar.clampedExtent

    function normalize(pos: int): int {
        if (pos === BarPosition.Top || pos === BarPosition.Bottom)
            return pos;
        if (pos === BarPosition.Right)
            console.warn("Right bar position is not supported, falling back to left");
        return BarPosition.Left;
    }

    function insetLeft(border: real, clamped = false): real {
        return barOnLeft ? (clamped ? barClamped : barExtent) : border;
    }

    function insetTop(border: real, clamped = false): real {
        return barOnTop ? (clamped ? barClamped : barExtent) : border;
    }

    function insetBottom(border: real, clamped = false): real {
        if (barFloating)
            return (clamped ? barClamped : barExtent) + floatGap + border;
        return barOnBottom ? (clamped ? barClamped : barExtent) : border;
    }

    function barContains(x: real, y: real, clamped = false): bool {
        const extent = clamped ? barClamped : barExtent;
        if (barOnTop)
            return y < extent;
        if (barOnBottom)
            return y > win.height - extent;
        return x < extent;
    }

    function inwardDrag(dragX: real, dragY: real): real {
        if (barOnTop)
            return dragY;
        if (barOnBottom)
            return -dragY;
        return dragX;
    }

    function axisPos(x: real, y: real): real {
        return horizontal ? x : y;
    }
}
