import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Item {
    id: full

    required property var applet

    readonly property int contentHeight: column.implicitHeight + Kirigami.Units.largeSpacing * 2
    implicitWidth: Kirigami.Units.gridUnit * 24
    implicitHeight: full.contentHeight
    Layout.minimumHeight: full.contentHeight
    Layout.preferredHeight: full.contentHeight
    Layout.maximumHeight: full.contentHeight

    ColumnLayout {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true

            Kirigami.Heading {
                Layout.fillWidth: true
                level: 3
                text: i18n("AI Usage Bar")
                textFormat: Text.PlainText
            }

            PlasmaComponents.ToolButton {
                icon.name: "view-refresh-symbolic"
                display: PlasmaComponents.AbstractButton.IconOnly
                enabled: full.applet.pendingCommand === ""
                text: i18n("Refresh now")
                PlasmaComponents.ToolTip.text: text
                PlasmaComponents.ToolTip.visible: hovered
                PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
                onClicked: full.applet.refresh()
            }
        }

        Repeater {
            model: full.applet.displayedEntries

            delegate: ColumnLayout {
                id: providerBlock
                required property var modelData
                required property int index
                Layout.fillWidth: true

                Kirigami.Separator {
                    Layout.fillWidth: true
                    visible: providerBlock.index > 0
                }

                ProviderDetails {
                    Layout.fillWidth: true
                    applet: full.applet
                    entry: providerBlock.modelData
                }
            }
        }

        PlasmaComponents.Label {
            Layout.fillWidth: true
            visible: full.applet.displayedEntries.length === 0
            text: full.applet.failure || i18n("No configured provider reported usage.")
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            textFormat: Text.PlainText
        }
    }
}
