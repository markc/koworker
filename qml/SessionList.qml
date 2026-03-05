import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ListView {
    id: root

    required property var historyStore
    property string activeSessionId: ""

    signal sessionSelected(string sessionId)
    signal sessionDeleted(string sessionId)

    clip: true
    spacing: 0

    delegate: ItemDelegate {
        id: del

        required property int index
        required property var modelData

        width: root.width
        highlighted: modelData.id === root.activeSessionId

        contentItem: ColumnLayout {
            spacing: 2

            Label {
                text: del.modelData.title || "New session"
                font.pixelSize: Theme.fontMd
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Label {
                text: {
                    const d = new Date(del.modelData.updated_at * 1000)
                    const now = new Date()
                    const diff = now - d
                    if (diff < 60000) return "Just now"
                    if (diff < 3600000) return Math.floor(diff / 60000) + "m ago"
                    if (diff < 86400000) return Math.floor(diff / 3600000) + "h ago"
                    return d.toLocaleDateString()
                }
                font.pixelSize: Theme.fontSm
                opacity: 0.4
                Layout.fillWidth: true
            }
        }

        onClicked: root.sessionSelected(modelData.id)

        // Right-click context menu
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            onClicked: (mouse) => {
                contextMenu.sessionId = del.modelData.id
                contextMenu.popup()
            }
        }
    }

    Menu {
        id: contextMenu
        property string sessionId

        MenuItem {
            text: "Delete"
            icon.name: "edit-delete"
            onTriggered: root.sessionDeleted(contextMenu.sessionId)
        }
    }

    // Empty state
    Label {
        anchors.centerIn: parent
        visible: root.count === 0
        text: "No sessions yet"
        opacity: 0.3
        font.pixelSize: Theme.fontSm
    }
}
