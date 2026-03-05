pragma Singleton

import QtQuick

QtObject {
    // Spacing scale
    readonly property real spacingXs: 4
    readonly property real spacingSm: 8
    readonly property real spacingMd: 16
    readonly property real spacingLg: 24
    readonly property real spacingXl: 32

    // Font sizes
    readonly property real fontSm: 12
    readonly property real fontMd: 14
    readonly property real fontLg: 18
    readonly property real fontXl: 24

    // Border radius
    readonly property real radiusSm: 4
    readonly property real radiusMd: 8
    readonly property real radiusLg: 12

    // Sidebar
    readonly property real sidebarWidth: 260

    // Colour palette — Crimson (default)
    readonly property color bg:          "#1a1a1e"
    readonly property color bgSurface:   "#242428"
    readonly property color bgCard:      "#2a2a30"
    readonly property color bgInput:     "#32323a"
    readonly property color textPrimary: "#e8e8ec"
    readonly property color textMuted:   "#8888a0"
    readonly property color accent:      "#e05555"
    readonly property color accentMuted: "#a03838"
    readonly property color userBubble:  "#3a3a48"
    readonly property color border:      "#3a3a42"
}
