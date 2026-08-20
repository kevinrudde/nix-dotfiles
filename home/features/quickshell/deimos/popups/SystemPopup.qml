import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs
import qs.services
import qs.widgets

// Everything the old separate audio, brightness and battery popups covered,
// plus the power profile and a resource readout — one popup instead of four,
// the way SystemWidget is one pill instead of three. Network and Bluetooth
// stay in their own popups: both carry a real interaction (a Wi-Fi password
// prompt, pairing) that a glance-and-close panel has no room for.
BarPopup {
    id: root

    popupName: "system"
    body: surface

    readonly property bool showProfiles: PowerProfiles.hasPerformanceProfile || PowerProfiles.profile !== PowerProfile.Balanced

    PopupSurface {
        id: surface

        surfaceWidth: 380

        // ── Volume ───────────────────────────────────────────────────────
        Caption {
            width: parent.width
            label: "Volume"
        }

        Row {
            width: parent.width
            height: Theme.rowHeight
            spacing: 6

            TabButton {
                width: (parent.width - parent.spacing) / 2
                text: "Output"
                active: Audio.mode === "output"
                onClicked: Audio.mode = "output"
            }

            TabButton {
                width: (parent.width - parent.spacing) / 2
                text: "Input"
                active: Audio.mode === "input"
                onClicked: Audio.mode = "input"
            }
        }

        RowLayout {
            width: parent.width
            height: 28
            spacing: 10

            IconButton {
                icon: Audio.mode === "output" ? Audio.sinkIcon : Theme.iconMicrophone
                iconColor: Audio.currentMuted ? Theme.muted : Theme.primary
                onClicked: Audio.toggleMute(Audio.current)
            }

            Slider {
                Layout.fillWidth: true
                percent: Audio.currentPercent
                fillColor: Audio.currentMuted ? Theme.muted : Theme.primary
                onMoved: percent => Audio.setCurrentVolume(percent)
                onStepped: direction => Audio.setCurrentVolume(Audio.currentPercent + direction * 5)
            }

            StyledText {
                Layout.preferredWidth: 40
                horizontalAlignment: Text.AlignRight
                text: Audio.currentMuted ? "muted" : Audio.currentPercent + "%"
                color: Audio.currentMuted ? Theme.muted : Theme.primary
            }
        }

        EmptyHint {
            width: parent.width
            visible: Audio.devices.length === 0
            text: Audio.mode === "output" ? "No output devices" : "No input devices"
        }

        Repeater {
            model: Audio.devices

            ListRow {
                required property var modelData

                readonly property bool current: Audio.isCurrent(modelData)

                width: parent.width
                minHeight: 34
                icon: current ? Theme.iconCheck : ""
                iconColor: Theme.success
                title: Audio.displayName(modelData)
                titleColor: current ? Theme.foreground : Theme.primary
                detail: Audio.detail(modelData)
                active: current
                onActivated: Audio.select(modelData)
            }
        }

        Divider {}

        // ── Brightness ───────────────────────────────────────────────────
        Column {
            width: parent.width
            visible: Brightness.available
            spacing: Theme.popupSpacing

            Caption {
                width: parent.width
                label: "Display"
            }

            RowLayout {
                width: parent.width
                height: 28
                spacing: 10

                IconButton {
                    icon: Brightness.icon
                    onClicked: Brightness.toggle()
                }

                Slider {
                    Layout.fillWidth: true
                    percent: Brightness.percent
                    fillColor: Theme.primary
                    onMoved: percent => Brightness.setPercent(percent)
                    onStepped: direction => Brightness.setPercent(Brightness.percent + direction * 5)
                }

                StyledText {
                    Layout.preferredWidth: 40
                    horizontalAlignment: Text.AlignRight
                    text: Brightness.percent + "%"
                }
            }
        }

        Divider {
            visible: Brightness.available
        }

        // ── Power profile ────────────────────────────────────────────────
        Column {
            width: parent.width
            visible: root.showProfiles
            spacing: Theme.popupSpacing

            Caption {
                width: parent.width
                label: "Power profile"
            }

            Row {
                width: parent.width
                spacing: 6

                Chip {
                    width: (parent.width - parent.spacing * 2) / 3
                    text: "Saver"
                    selected: PowerProfiles.profile === PowerProfile.PowerSaver
                    onClicked: PowerProfiles.profile = PowerProfile.PowerSaver
                }

                Chip {
                    width: (parent.width - parent.spacing * 2) / 3
                    text: "Balanced"
                    selected: PowerProfiles.profile === PowerProfile.Balanced
                    onClicked: PowerProfiles.profile = PowerProfile.Balanced
                }

                Chip {
                    width: (parent.width - parent.spacing * 2) / 3
                    text: "Performance"
                    enabled: PowerProfiles.hasPerformanceProfile
                    selected: PowerProfiles.profile === PowerProfile.Performance
                    onClicked: PowerProfiles.profile = PowerProfile.Performance
                }
            }
        }

        Divider {
            visible: root.showProfiles
        }

        // ── Resources ────────────────────────────────────────────────────
        Column {
            width: parent.width
            spacing: 10

            Caption {
                width: parent.width
                label: "Resources"
            }

            StatBar {
                width: parent.width
                icon: Theme.iconCpu
                label: "CPU"
                detail: Theme.clampPercent(SysStats.cpu * 100) + "%"
                percent: Theme.clampPercent(SysStats.cpu * 100)
                barColor: SysStats.cpu > 0.85 ? Theme.danger : (SysStats.cpu > 0.6 ? Theme.warning : Theme.primary)
            }

            StatBar {
                width: parent.width
                icon: Theme.iconRam
                label: "Memory"
                detail: SysStats.memUsedGiB.toFixed(1) + " / " + SysStats.memTotalGiB.toFixed(1) + " GiB"
                percent: Theme.clampPercent(SysStats.mem * 100)
                barColor: SysStats.mem > 0.9 ? Theme.danger : Theme.success
            }
        }

        Divider {
            visible: BatteryInfo.ready
        }

        // ── Battery ──────────────────────────────────────────────────────
        Expander {
            id: batteryExpander

            width: parent.width
            visible: BatteryInfo.ready

            header: [
                StyledText {
                    text: BatteryInfo.icon
                    color: BatteryInfo.foreground
                    font.pixelSize: Theme.fontSizeLarge
                },
                StyledText {
                    Layout.fillWidth: true
                    text: BatteryInfo.percent + "% · " + BatteryInfo.stateText.toLowerCase()
                    color: BatteryInfo.foreground
                    elide: Text.ElideRight
                },
                StyledText {
                    text: batteryExpander.expanded ? "less" : "more"
                    color: Theme.muted
                    font.bold: false
                    font.pixelSize: Theme.fontSizeTiny
                }
            ]

            InfoRow {
                width: parent.width
                label: "Time"
                value: BatteryInfo.timeText
            }

            InfoRow {
                width: parent.width
                label: "Power"
                value: BatteryInfo.rateText
            }

            InfoRow {
                width: parent.width
                label: "Energy"
                value: BatteryInfo.energyText
            }

            InfoRow {
                width: parent.width
                visible: BatteryInfo.healthText !== ""
                label: "Health"
                value: BatteryInfo.healthText
            }
        }
    }
}
