import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
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

                    Button {
                        text: "+"
                        flat: true
                        onClicked: messages.clear()

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
        }
    }
}
