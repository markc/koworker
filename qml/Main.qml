import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import Koworker

ApplicationWindow {
    id: window

    width: 900
    height: 650
    minimumWidth: 500
    minimumHeight: 400
    visible: true
    title: "koworker"

    MessageModel {
        id: messages
    }

    AnthropicClient {
        id: client
    }

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

    SettingsDialog {
        id: settingsDialog
        client: client
        anchors.centerIn: parent
    }

    Shortcut { sequence: "Ctrl+,"; onActivated: settingsDialog.open() }
    Shortcut {
        sequence: "Ctrl+N"
        onActivated: { client.newSession(); messages.clear() }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Sidebar — palette.base (darkest)
        Rectangle {
            Layout.preferredWidth: Theme.sidebarWidth
            Layout.fillHeight: true
            color: palette.base

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: Theme.spacingSm
                    Layout.leftMargin: Theme.spacingMd

                    Label {
                        text: "koworker"
                        font.pixelSize: Theme.fontLg
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    ToolButton {
                        icon.name: "configure"
                        onClicked: settingsDialog.open()
                        ToolTip.text: "Settings (Ctrl+,)"
                        ToolTip.visible: hovered
                    }

                    ToolButton {
                        icon.name: "list-add"
                        onClicked: { client.newSession(); messages.clear() }
                        ToolTip.text: "New session (Ctrl+N)"
                        ToolTip.visible: hovered
                    }
                }

                // Connection status
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: Theme.spacingMd
                    Layout.rightMargin: Theme.spacingMd
                    Layout.topMargin: Theme.spacingXs
                    Layout.bottomMargin: Theme.spacingSm
                    spacing: Theme.spacingSm

                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: client.apiKey.length > 0
                            ? Qt.rgba(0.3, 0.8, 0.3, 1.0)
                            : Qt.rgba(0.8, 0.3, 0.3, 1.0)
                    }

                    Label {
                        text: client.apiKey.length > 0 ? client.model : "No API key"
                        opacity: 0.5
                        font.pixelSize: Theme.fontSm
                        elide: Text.ElideMiddle
                        Layout.fillWidth: true
                    }
                }

                // Sessions list area — palette.alternateBase (mid tone)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: palette.alternateBase

                    Label {
                        anchors.centerIn: parent
                        text: "No sessions yet"
                        opacity: 0.3
                        font.pixelSize: Theme.fontSm
                    }
                }
            }
        }

        // Main chat area — palette.window (standard)
        ChatView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            messageModel: messages
            client: client
        }
    }
}
