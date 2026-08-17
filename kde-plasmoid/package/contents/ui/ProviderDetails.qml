import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../code/plasmoid-logic.mjs" as Logic

ColumnLayout {
    id: details

    required property var applet
    required property var entry

    readonly property var rows: Logic.detailRows(details.entry)
    readonly property string status: details.applet.statusMessage(details.entry)

    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing

    RowLayout {
        Layout.fillWidth: true

        Kirigami.Heading {
            Layout.fillWidth: true
            level: 4
            text: details.entry.label
            textFormat: Text.PlainText
        }

        PlasmaComponents.Label {
            visible: text !== ""
            text: details.entry.plan || ""
            opacity: 0.7
            font: Kirigami.Theme.smallFont
            textFormat: Text.PlainText
        }
    }

    Rectangle {
        Layout.fillWidth: true
        visible: details.status !== ""
        implicitHeight: visible ? statusLabel.implicitHeight + Kirigami.Units.largeSpacing : 0
        radius: Kirigami.Units.cornerRadius
        color: Qt.alpha(details.applet.statusIsUrgent(details.entry)
            ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor, 0.09)
        border.width: 1
        border.color: Qt.alpha(details.applet.statusIsUrgent(details.entry)
            ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor, 0.35)

        PlasmaComponents.Label {
            id: statusLabel
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            text: details.status
            wrapMode: Text.WordWrap
            font: Kirigami.Theme.smallFont
            textFormat: Text.PlainText
        }
    }

    Repeater {
        model: details.rows

        UsageRow {
            required property var modelData
            Layout.fillWidth: true
            row: modelData
            colors: details.applet.colors
            resetText: details.applet.resetText(modelData.resetAt)
            showBar: details.applet.showBars
        }
    }
}
