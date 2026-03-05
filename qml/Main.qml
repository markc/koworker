import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.settings
import Koworker

ApplicationWindow {
    id: window

    width: 900
    height: 650
    minimumWidth: 500
    minimumHeight: 400
    visible: true
    title: "koworker"
    color: Theme.bg

    MessageModel {
        id: messages
    }

    AnthropicClient {
        id: client
    }

    // Load saved settings into client on startup
    Settings {
        id: appSettings
        property string apiKey
        property string model: "claude-sonnet-4-20250514"
        property string systemPrompt
    }

    Component.onCompleted: {
        client.apiKey = appSettings.apiKey
        client.model = appSettings.model
        client.systemPrompt = appSettings.systemPrompt
    }

    // Settings dialog
    SettingsDialog {
        id: settingsDialog
        client: client
        anchors.centerIn: parent
    }

    // Ctrl+, for settings
    Shortcut {
        sequence: "Ctrl+,"
        onActivated: settingsDialog.open()
    }

    // Ctrl+N for new session
    Shortcut {
        sequence: "Ctrl+N"
        onActivated: {
            client.newSession()
            messages.clear()
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Sidebar
        Rectangle {
            Layout.preferredWidth: Theme.sidebarWidth
            Layout.fillHeight: true
            color: Theme.bgSurface

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: Theme.spacingMd

                    Label {
                        text: "koworker"
                        font.pixelSize: Theme.fontXl
                        font.bold: true
                        color: Theme.textPrimary
                        Layout.fillWidth: true
                    }

                    // Settings button
                    Button {
                        flat: true
                        onClicked: settingsDialog.open()

                        contentItem: Text {
                            text: "\u2699"
                            color: Theme.textMuted
                            font.pixelSize: Theme.fontLg
                            horizontalAlignment: Text.AlignHCenter
                        }

                        background: Rectangle {
                            implicitWidth: 32
                            implicitHeight: 32
                            radius: Theme.radiusSm
                            color: parent.hovered ? Theme.bgCard : "transparent"
                        }
                    }

                    // New session button
                    Button {
                        flat: true
                        onClicked: {
                            client.newSession()
                            messages.clear()
                        }

                        contentItem: Text {
                            text: "+"
                            color: Theme.textPrimary
                            font.pixelSize: Theme.fontXl
                            horizontalAlignment: Text.AlignHCenter
                        }

                        background: Rectangle {
                            implicitWidth: 32
                            implicitHeight: 32
                            radius: Theme.radiusSm
                            color: parent.hovered ? Theme.bgCard : "transparent"
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.border
                }

                // Connection status
                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: Theme.spacingMd
                    spacing: Theme.spacingSm

                    Rectangle {
                        width: 8; height: 8
                        radius: 4
                        color: client.apiKey.length > 0 ? "#55cc55" : "#cc5555"
                    }

                    Label {
                        text: client.apiKey.length > 0 ? client.model : "No API key"
                        color: Theme.textMuted
                        font.pixelSize: Theme.fontSm
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.border
                }

                // Sessions placeholder
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Label {
                        anchors.centerIn: parent
                        text: "No sessions yet"
                        color: Theme.textMuted
                        font.pixelSize: Theme.fontSm
                    }
                }
            }
        }

        // Sidebar / chat separator
        Rectangle {
            Layout.fillHeight: true
            width: 1
            color: Theme.border
        }

        // Main chat area
        ChatView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            messageModel: messages
            client: client
        }
    }
}
