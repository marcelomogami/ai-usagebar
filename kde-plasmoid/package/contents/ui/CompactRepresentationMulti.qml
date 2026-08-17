pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../code/plasmoid-logic.mjs" as Logic

MouseArea {
    id: root

    required property var applet

    acceptedButtons: Qt.LeftButton
    hoverEnabled: true

    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    Layout.minimumWidth: root.vertical ? 0 : content.implicitWidth
    Layout.preferredWidth: root.vertical ? 0 : content.implicitWidth
    Layout.minimumHeight: root.vertical ? content.implicitHeight : 0
    Layout.preferredHeight: root.vertical ? content.implicitHeight : 0

    property bool wasExpanded: false
    onPressed: root.wasExpanded = root.applet.expanded
    onClicked: root.applet.expanded = !root.wasExpanded

    function labelsFor(entry) {
        if (!entry)
            return [];
        if (entry.id === "anthropic" || entry.id.indexOf("anthropic@") === 0)
            return ["5h", "7d"];
        if (entry.id === "openai")
            return ["7d"];
        return entry.sections
            .filter(section => section.type === "metric")
            .slice(0, 2)
            .map(section => Logic.shortLabel(section.label));
    }

    function resetText(row, windowLabel) {
        if (!row || !row.resetAt)
            return "—";
        const date = new Date(row.resetAt);
        if (!Number.isFinite(date.getTime()))
            return "—";
        return Qt.formatDateTime(date, windowLabel === "5h" ? "HH:mm" : "dd/MM HH:mm");
    }

    GridLayout {
        id: content
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        flow: root.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
        columnSpacing: Kirigami.Units.largeSpacing
        rowSpacing: Kirigami.Units.smallSpacing

        PlasmaComponents.Label {
            visible: root.applet.displayedEntries.length === 0
            text: root.applet.failure ? "⚠ ai" : "…"
            color: root.applet.failure ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
            textFormat: Text.PlainText
        }

        Repeater {
            model: root.applet.displayedEntries

            delegate: RowLayout {
                id: provider
                required property var modelData
                required property int index

                spacing: Kirigami.Units.smallSpacing
                Layout.leftMargin: !root.vertical && provider.index > 0
                    ? Kirigami.Units.largeSpacing : 0
                Layout.topMargin: root.vertical && provider.index > 0
                    ? Kirigami.Units.smallSpacing : 0
                opacity: provider.modelData.stale ? 0.65 : 1

                HoverHandler {
                    onHoveredChanged: {
                        if (hovered)
                            root.applet.hoveredVendorId = provider.modelData.id;
                    }
                }

                Kirigami.Icon {
                    implicitWidth: Kirigami.Units.iconSizes.small
                    implicitHeight: Kirigami.Units.iconSizes.small
                    source: provider.modelData.id === "openai"
                        ? Qt.resolvedUrl("../icons/openai.svg")
                        : Qt.resolvedUrl("../icons/claude.svg")
                    isMask: true
                    color: provider.modelData.status === "error"
                        ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
                }

                PlasmaComponents.Label {
                    visible: provider.modelData.status === "error"
                    text: "⚠ ERR"
                    color: Kirigami.Theme.negativeTextColor
                    font.family: "monospace"
                    textFormat: Text.PlainText
                }

                Repeater {
                    model: provider.modelData.status === "error"
                        ? [] : root.labelsFor(provider.modelData)

                    delegate: RowLayout {
                        id: metric
                        required property string modelData
                        readonly property var row: Logic.metricForWindow(
                            provider.modelData, metric.modelData)
                        spacing: Math.round(Kirigami.Units.smallSpacing / 2)

                        PlasmaComponents.Label {
                            text: metric.modelData + ":"
                            opacity: 0.7
                            font.family: "monospace"
                            textFormat: Text.PlainText
                        }

                        PlasmaComponents.Label {
                            Layout.minimumWidth: implicitWidthFor100
                            Layout.preferredWidth: implicitWidthFor100
                            readonly property real implicitWidthFor100: metrics.advanceWidth
                            text: metric.row && metric.row.percent !== null
                                ? metric.row.percent + "%" : "—"
                            horizontalAlignment: Text.AlignRight
                            color: metric.row
                                ? (Logic.severityColor(metric.row.severity, root.applet.colors)
                                    ?? Kirigami.Theme.textColor)
                                : Kirigami.Theme.textColor
                            font.family: "monospace"
                            textFormat: Text.PlainText

                            TextMetrics {
                                id: metrics
                                font: parent.font
                                text: "100%"
                            }
                        }

                        PlasmaComponents.Label {
                            Layout.minimumWidth: paceMetrics.advanceWidth
                            Layout.preferredWidth: paceMetrics.advanceWidth
                            text: metric.row && metric.row.elapsedPercent !== null
                                ? "(" + metric.row.elapsedPercent + "%)" : "(—)"
                            horizontalAlignment: Text.AlignRight
                            opacity: 0.8
                            font.family: "monospace"
                            textFormat: Text.PlainText

                            TextMetrics {
                                id: paceMetrics
                                font: parent.font
                                text: "(100%)"
                            }
                        }

                        Kirigami.Icon {
                            source: "view-refresh-symbolic"
                            implicitWidth: Kirigami.Units.iconSizes.small
                            implicitHeight: Kirigami.Units.iconSizes.small
                            opacity: 0.7
                        }

                        PlasmaComponents.Label {
                            Layout.minimumWidth: resetMetrics.advanceWidth
                            Layout.preferredWidth: resetMetrics.advanceWidth
                            text: root.resetText(metric.row, metric.modelData)
                            font.family: "monospace"
                            textFormat: Text.PlainText

                            TextMetrics {
                                id: resetMetrics
                                font: parent.font
                                text: metric.modelData === "5h" ? "00:00" : "00/00 00:00"
                            }
                        }
                    }
                }
            }
        }
    }
}
