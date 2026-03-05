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

    HistoryStore {
        id: history
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
        refreshSessions()
    }

    SettingsDialog {
        id: settingsDialog
        client: client
        anchors.centerIn: parent
    }

    Shortcut { sequence: "Ctrl+,"; onActivated: settingsDialog.open() }
    Shortcut { sequence: "Ctrl+N"; onActivated: newSession() }

    // Current session tracking
    property string currentSessionId: ""

    function newSession() {
        currentSessionId = ""
        client.newSession()
        messages.clear()
        refreshSessions()
    }

    function refreshSessions() {
        sessionList.model = history.listSessions()
    }

    function loadSession(sessionId) {
        const msgs = history.loadSession(sessionId)
        messages.clear()
        client.newSession()

        for (let i = 0; i < msgs.length; i++) {
            const m = msgs[i]
            messages.appendMessage(m.role, m.content)
            client.restoreMessage(m.role, m.content)
        }

        currentSessionId = sessionId
        sessionList.activeSessionId = sessionId
    }

    function ensureSession() {
        if (currentSessionId === "") {
            currentSessionId = history.createSession()
        }
        return currentSessionId
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Sidebar — palette.base
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
                        onClicked: newSession()
                        ToolTip.text: "New session (Ctrl+N)"
                        ToolTip.visible: hovered
                    }
                }

                // Connection status
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: Theme.spacingMd
                    Layout.rightMargin: Theme.spacingMd
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

                // Sessions list — palette.alternateBase
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: palette.alternateBase

                    SessionList {
                        id: sessionList
                        anchors.fill: parent
                        historyStore: history

                        onSessionSelected: (sessionId) => loadSession(sessionId)
                        onSessionDeleted: (sessionId) => {
                            history.deleteSession(sessionId)
                            if (currentSessionId === sessionId) {
                                newSession()
                            }
                            refreshSessions()
                        }
                    }
                }
            }
        }

        // Main chat area — palette.window
        ChatView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            messageModel: messages
            client: client
            historyStore: history

            onMessageSent: (text) => {
                const sid = ensureSession()
                history.saveMessage(sid, "user", text)
                refreshSessions()
                sessionList.activeSessionId = sid
            }

            onResponseComplete: (text) => {
                const sid = ensureSession()
                history.saveMessage(sid, "assistant", text)
                refreshSessions()
            }
        }
    }
}
