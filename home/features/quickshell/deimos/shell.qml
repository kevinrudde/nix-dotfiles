import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Scope {
  id: root

  readonly property string primary: "#96d8ff"
  readonly property string foreground: "#d9e4ff"
  readonly property string muted: "#6f7285"
  readonly property string success: "#a8ff96"
  readonly property string warning: "#ffd166"
  readonly property string danger: "#ff5874"
  readonly property color background: Qt.rgba(21 / 255, 18 / 255, 27 / 255, 0.82)
  readonly property color backgroundStrong: Qt.rgba(10 / 255, 10 / 255, 16 / 255, 0.92)
  readonly property color activeBackground: Qt.rgba(150 / 255, 216 / 255, 255 / 255, 0.14)
  readonly property string fontFamily: "JetBrains Mono"

  property bool idleInhibited: false
  property bool audioPopupOpen: false
  property string audioPopupMode: "output"
  property bool bluetoothPopupOpen: false
  property bool networkPopupOpen: false
  property string networkPasswordSsid: ""
  property var popupScreen: null
  property bool rightExpanded: false
  property bool notificationCenterOpen: false
  property bool notificationsDnd: false
  property string submap: ""
  property var toastDeadlines: ({})
  property var toastNotifications: []
  readonly property int notificationCount: notificationServer.trackedNotifications ? notificationServer.trackedNotifications.values.length : 0
  readonly property string notificationIcon: notificationsDnd ? (notificationCount > 0 ? "󰂛" : "󰪑") : (notificationCount > 0 ? "󰂚" : "󰂜")
  readonly property string notificationText: notificationCount > 0 ? notificationCount + " " + notificationIcon : notificationIcon
  property var status: ({
    backlight: 0,
    audio: {
      text: "--% ",
      sourceMuted: false
    },
    bluetooth: {
      text: "",
      powered: false,
      connected: false,
      count: 0
    },
    network: {
      text: "",
      connected: false
    },
    battery: {
      text: "--% ",
      class: "missing"
    },
    clock: ""
  })
  property var networkState: ({
    wifiEnabled: false,
    activeWifi: "",
    wired: [],
    wifi: []
  })
  property var bluetoothState: ({
    powered: false,
    discovering: false,
    devices: []
  })

  function run(command) {
    actionProc.command = ["sh", "-c", command];
    actionProc.startDetached();
    refreshDelay.restart();
  }

  function refresh() {
    if (!statusProc.running) {
      statusProc.running = true;
    }
  }

  function setStatus(text) {
    try {
      root.status = JSON.parse(text);
    } catch (error) {
      console.log("quickshell status parse failed: " + error);
    }
  }

  function setNetworkState(text) {
    try {
      root.networkState = JSON.parse(text);
    } catch (error) {
      console.log("quickshell network parse failed: " + error);
    }
  }

  function setBluetoothState(text) {
    try {
      root.bluetoothState = JSON.parse(text);
    } catch (error) {
      console.log("quickshell bluetooth parse failed: " + error);
    }
  }

  function wiredConnections() {
    return root.networkState && root.networkState.wired ? root.networkState.wired : [];
  }

  function wifiNetworks() {
    return root.networkState && root.networkState.wifi ? root.networkState.wifi : [];
  }

  function bluetoothDevices() {
    return root.bluetoothState && root.bluetoothState.devices ? root.bluetoothState.devices : [];
  }

  function lastStatusToken(text, fallback) {
    const value = String(text || "").trim();
    if (value === "") {
      return fallback;
    }

    const parts = value.split(/\s+/);
    return parts.length > 0 ? parts[parts.length - 1] : fallback;
  }

  function compactAudioText() {
    if (String(root.status.audio.text).indexOf("muted") === 0) {
      return "";
    }

    return root.lastStatusToken(root.status.audio.text, "");
  }

  function compactBluetoothText() {
    return root.status.bluetooth && root.status.bluetooth.powered ? "" : "󰂲";
  }

  function refreshBluetooth(scan) {
    if (bluetoothProc.running) {
      return;
    }

    bluetoothProc.command = scan ? [Quickshell.shellDir + "/scripts/bluetooth-status.sh", "--scan"] : [Quickshell.shellDir + "/scripts/bluetooth-status.sh"];
    bluetoothProc.running = true;
  }

  function refreshNetwork(rescan) {
    if (networkProc.running) {
      return;
    }

    networkProc.command = rescan ? [Quickshell.shellDir + "/scripts/network-status.sh", "--rescan"] : [Quickshell.shellDir + "/scripts/network-status.sh"];
    networkProc.running = true;
  }

  function wifiSignalIcon(signal) {
    if (signal >= 80) {
      return "󰤨";
    }

    if (signal >= 60) {
      return "󰤥";
    }

    if (signal >= 40) {
      return "󰤢";
    }

    if (signal >= 20) {
      return "󰤟";
    }

    return "󰤯";
  }

  function wifiDetail(network) {
    if (!network) {
      return "";
    }

    const parts = [];

    if (network.security) {
      parts.push(network.security);
    } else {
      parts.push("open");
    }

    if (network.known) {
      parts.push("saved");
    } else if (network.security) {
      parts.push("password");
    }

    parts.push(network.signal + "%");
    return parts.join(" · ");
  }

  function canConnectWifi(network) {
    return network && !network.active;
  }

  function needsWifiPassword(network) {
    return network && !network.active && network.security && !network.known;
  }

  function connectWifi(network, password) {
    if (!root.canConnectWifi(network)) {
      return;
    }

    if (root.needsWifiPassword(network) && !password) {
      root.networkPasswordSsid = network.ssid || "";
      return;
    }

    networkActionProc.command = [
      Quickshell.shellDir + "/scripts/network-action.sh",
      "connect",
      network.ssid || "",
      network.knownConnection || "",
      network.security || "",
      password || ""
    ];
    networkActionProc.running = true;
    networkPasswordSsid = "";
    networkPopupOpen = false;
  }

  function bluetoothDeviceIcon(device) {
    const icon = String(device && device.icon ? device.icon : "");

    if (icon.indexOf("head") >= 0 || icon.indexOf("audio") >= 0) {
      return "";
    }

    if (icon.indexOf("keyboard") >= 0) {
      return "󰌌";
    }

    if (icon.indexOf("mouse") >= 0) {
      return "󰍽";
    }

    return "";
  }

  function bluetoothDetail(device) {
    if (!device) {
      return "";
    }

    const parts = [];

    if (device.connected) {
      parts.push("connected");
    } else if (device.paired) {
      parts.push("paired");
    } else {
      parts.push("new");
    }

    if (device.trusted) {
      parts.push("trusted");
    }

    return parts.join(" · ");
  }

  function bluetoothActionText(device) {
    if (!root.bluetoothState.powered) {
      return "";
    }

    if (device.connected) {
      return "disconnect";
    }

    return device.paired ? "connect" : "pair";
  }

  function runBluetoothAction(action, address) {
    bluetoothActionProc.command = address ? [Quickshell.shellDir + "/scripts/bluetooth-action.sh", action, address] : [Quickshell.shellDir + "/scripts/bluetooth-action.sh", action];
    bluetoothActionProc.running = true;
  }

  function activateBluetoothDevice(device) {
    if (!device || bluetoothActionProc.running || !root.bluetoothState.powered) {
      return;
    }

    if (device.connected) {
      root.runBluetoothAction("disconnect", device.address);
    } else if (device.paired) {
      root.runBluetoothAction("connect", device.address);
    } else {
      root.runBluetoothAction("pair", device.address);
    }
  }

  function addToast(notification) {
    const deadlines = Object.assign({}, root.toastDeadlines);
    deadlines[notification.id] = Date.now() + root.notificationTimeout(notification);
    root.toastDeadlines = deadlines;

    const next = root.toastNotifications.filter(item => item !== notification);
    next.unshift(notification);
    root.toastNotifications = next.slice(0, 4);
  }

  function removeToast(notification) {
    root.toastNotifications = root.toastNotifications.filter(item => item !== notification);
  }

  function notificationTimeout(notification) {
    if (!notification) {
      return 6000;
    }

    if (notification.expireTimeout > 0) {
      return Math.max(1000, notification.expireTimeout);
    }

    if (notification.urgency === NotificationUrgency.Critical) {
      return 10000;
    }

    if (notification.urgency === NotificationUrgency.Low) {
      return 4000;
    }

    return 6000;
  }

  function dismissNotification(notification) {
    if (!notification) {
      return;
    }

    root.removeToast(notification);
    notification.dismiss();
  }

  function clearNotifications() {
    const notifications = Array.from(notificationServer.trackedNotifications.values);

    for (let index = 0; index < notifications.length; index += 1) {
      notifications[index].dismiss();
    }

    root.toastNotifications = [];
    root.notificationCenterOpen = false;
  }

  function nodeDisplayName(node) {
    if (!node) {
      return "Unknown";
    }

    return node.description || node.nickname || node.name || "Unknown";
  }

  function nodeDetail(node) {
    if (!node) {
      return "";
    }

    const name = node.name || "";
    const nickname = node.nickname || "";

    if (nickname !== "" && nickname !== nodeDisplayName(node)) {
      return nickname;
    }

    return name;
  }

  function nodeTypeText(node) {
    return node ? PwNodeType.toString(node.type) : "";
  }

  function isMonitorNode(node) {
    const name = String(node ? node.name : "").toLowerCase();
    const description = String(node ? node.description : "").toLowerCase();
    return name.indexOf("monitor") >= 0 || description.indexOf("monitor") >= 0;
  }

  function isOutputNode(node) {
    return node && node.audio && node.isSink && !node.isStream && !isMonitorNode(node);
  }

  function isInputNode(node) {
    return node && node.audio && !node.isSink && !node.isStream && !isMonitorNode(node);
  }

  function sortedAudioNodes(nodes) {
    return nodes.slice().sort((left, right) => nodeDisplayName(left).localeCompare(nodeDisplayName(right)));
  }

  function outputNodes() {
    return sortedAudioNodes(Pipewire.nodes.values.filter(node => isOutputNode(node)));
  }

  function inputNodes() {
    return sortedAudioNodes(Pipewire.nodes.values.filter(node => isInputNode(node)));
  }

  function currentAudioNodes() {
    return audioPopupMode === "output" ? outputNodes() : inputNodes();
  }

  function isCurrentAudioNode(node) {
    const current = audioPopupMode === "output" ? Pipewire.defaultAudioSink : Pipewire.defaultAudioSource;
    return current && node && current.id === node.id;
  }

  function selectAudioNode(node) {
    if (!node) {
      return;
    }

    if (audioPopupMode === "output") {
      Pipewire.preferredDefaultAudioSink = node;
    } else {
      Pipewire.preferredDefaultAudioSource = node;
    }

    refreshDelay.restart();
  }

  Process {
    id: statusProc

    command: [Quickshell.shellDir + "/scripts/status.sh"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: root.setStatus(this.text)
    }
  }

  Process {
    id: actionProc
  }

  Process {
    id: networkProc

    command: [Quickshell.shellDir + "/scripts/network-status.sh"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: root.setNetworkState(this.text)
    }
  }

  Process {
    id: bluetoothProc

    command: [Quickshell.shellDir + "/scripts/bluetooth-status.sh"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: root.setBluetoothState(this.text)
    }
  }

  Process {
    id: networkActionProc

    onExited: {
      root.refreshNetwork(false);
      refreshDelay.restart();
    }
  }

  Process {
    id: bluetoothActionProc

    onExited: {
      root.refreshBluetooth(false);
      refreshDelay.restart();
    }
  }

  Timer {
    interval: 2000
    repeat: true
    running: true
    onTriggered: root.refresh()
  }

  Timer {
    id: refreshDelay

    interval: 250
    repeat: false
    onTriggered: root.refresh()
  }

  Timer {
    interval: 500
    repeat: true
    running: true
    onTriggered: {
      const now = Date.now();
      root.toastNotifications = root.toastNotifications.filter(notification => (root.toastDeadlines[notification.id] || 0) > now);
    }
  }

  ScriptModel {
    id: toastModel

    values: root.toastNotifications
  }

  NotificationServer {
    id: notificationServer

    actionsSupported: true
    actionIconsSupported: true
    bodyImagesSupported: true
    bodyMarkupSupported: false
    bodySupported: true
    imageSupported: true
    inlineReplySupported: false
    keepOnReload: true
    persistenceSupported: true

    onNotification: notification => {
      notification.tracked = true;
      notification.closed.connect(function() {
        root.removeToast(notification);
      });

      if (!root.notificationsDnd) {
        root.addToast(notification);
      }
    }
  }

  PwObjectTracker {
    objects: Pipewire.nodes.values
  }

  Connections {
    target: Hyprland

    function onRawEvent(event) {
      if (event.name === "submap") {
        root.submap = event.data === "default" ? "" : event.data;
      }
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: bar

      required property var modelData

      screen: modelData
      implicitHeight: 36
      color: "transparent"

      surfaceFormat {
        opaque: false
      }

      anchors {
        top: true
        left: true
        right: true
      }

      margins {
        top: 6
        left: 10
        right: 10
      }

      IdleInhibitor {
        window: bar
        enabled: root.idleInhibited
      }

      Item {
        anchors.fill: parent

        Row {
          id: leftModules

          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          spacing: 8

          Pill {
            text: ""
            fontSize: 17
            horizontalPadding: 9
            foreground: root.primary
            background: root.background
            onClicked: root.run("uwsm app -- fuzzel")
          }

          Rectangle {
            id: workspaceGroup

            implicitWidth: workspacesRow.implicitWidth + 8
            implicitHeight: 28
            color: root.background
            border.color: root.primary
            border.width: 1
            radius: 8

            Row {
              id: workspacesRow

              anchors.centerIn: parent
              spacing: 0

              Repeater {
                model: Hyprland.workspaces

                Rectangle {
                  property bool workspaceActive: modelData.active || modelData.focused

                  width: Math.max(28, workspaceLabel.implicitWidth + 14)
                  height: 24
                  color: workspaceActive ? root.activeBackground : "transparent"
                  radius: 7

                  Text {
                    id: workspaceLabel

                    anchors.centerIn: parent
                    text: modelData.name
                    color: workspaceActive ? root.primary : root.muted
                    font.bold: true
                    font.family: root.fontFamily
                    font.pixelSize: 14
                  }

                  MouseArea {
                    anchors.fill: parent
                    onClicked: modelData.activate()
                  }
                }
              }
            }
          }

          Pill {
            visible: root.submap !== ""
            text: root.submap
            foreground: root.success
            background: root.backgroundStrong
            maxTextWidth: 150
          }
        }

        Pill {
          id: windowTitle

          anchors.horizontalCenter: parent.horizontalCenter
          anchors.verticalCenter: parent.verticalCenter
          text: Hyprland.activeToplevel && Hyprland.activeToplevel.title ? Hyprland.activeToplevel.title : "Desktop"
          foreground: root.foreground
          background: root.background
          horizontalPadding: 14
          minPillWidth: 0
          maxTextWidth: Math.max(0, Math.min(520, parent.width - 2 * Math.max(leftModules.width, rightModules.width) - 60))
        }

        Row {
          id: rightModules

          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: root.rightExpanded ? 8 : 5

          Pill {
            text: root.rightExpanded ? ">" : "<"
            foreground: root.primary
            background: root.background
            horizontalPadding: 8
            maxTextWidth: 14
            onClicked: root.rightExpanded = !root.rightExpanded
          }

          Rectangle {
            visible: SystemTray.items.values.length > 0
            implicitWidth: Math.max(28, trayRow.implicitWidth + 16)
            implicitHeight: 28
            color: root.background
            border.color: root.primary
            border.width: 1
            radius: 8

            Row {
              id: trayRow

              anchors.centerIn: parent
              spacing: 6

              Repeater {
                model: SystemTray.items

                Item {
                  width: 18
                  height: 18

                  IconImage {
                    anchors.centerIn: parent
                    implicitSize: 18
                    source: modelData.icon
                  }

                  MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: mouse => {
                      if (mouse.button === Qt.RightButton && modelData.hasMenu) {
                        modelData.display(bar, rightModules.x, bar.implicitHeight);
                      } else if (mouse.button === Qt.MiddleButton) {
                        modelData.secondaryActivate();
                      } else {
                        modelData.activate();
                      }
                    }
                    onWheel: wheel => modelData.scroll(wheel.angleDelta.y, false)
                  }
                }
              }
            }
          }

          Pill {
            visible: root.rightExpanded
            text: root.idleInhibited ? "" : ""
            foreground: root.primary
            background: root.background
            horizontalPadding: 9
            onClicked: root.idleInhibited = !root.idleInhibited
          }

          Pill {
            id: audioPill

            text: root.rightExpanded ? root.status.audio.text : root.compactAudioText()
            foreground: root.status.audio.text.indexOf("muted") === 0 ? root.muted : root.primary
            background: root.background
            horizontalPadding: root.rightExpanded ? 10 : 8
            maxTextWidth: root.rightExpanded ? 120 : 20
            onClicked: mouse => {
              if (mouse.button === Qt.RightButton) {
                root.audioPopupMode = "input";
                root.popupScreen = modelData;
                root.audioPopupOpen = true;
                root.bluetoothPopupOpen = false;
                root.networkPopupOpen = false;
                root.notificationCenterOpen = false;
              } else if (mouse.button === Qt.MiddleButton) {
                root.run("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle");
              } else {
                root.audioPopupMode = "output";
                root.audioPopupOpen = !(root.audioPopupOpen && root.popupScreen === modelData);
                root.popupScreen = modelData;
                root.bluetoothPopupOpen = false;
                root.networkPopupOpen = false;
                root.notificationCenterOpen = false;
              }
            }
            onWheel: wheel => {
              if (wheel.angleDelta.y > 0) {
                root.run("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+");
              } else {
                root.run("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-");
              }
            }
          }

          Pill {
            id: bluetoothPill

            text: root.rightExpanded ? root.status.bluetooth.text : root.compactBluetoothText()
            foreground: root.status.bluetooth.connected ? root.success : root.status.bluetooth.powered ? root.primary : root.muted
            background: root.background
            horizontalPadding: root.rightExpanded ? 10 : 8
            maxTextWidth: root.rightExpanded ? 70 : 20
            onClicked: mouse => {
              if (mouse.button === Qt.RightButton) {
                root.popupScreen = modelData;
                root.bluetoothPopupOpen = true;
                root.audioPopupOpen = false;
                root.networkPopupOpen = false;
                root.notificationCenterOpen = false;
                root.runBluetoothAction("scan");
              } else {
                root.bluetoothPopupOpen = !(root.bluetoothPopupOpen && root.popupScreen === modelData);
                root.popupScreen = modelData;
                root.audioPopupOpen = false;
                root.networkPopupOpen = false;
                root.notificationCenterOpen = false;

                if (root.bluetoothPopupOpen) {
                  root.refreshBluetooth(false);
                }
              }
            }
          }

          Pill {
            visible: root.rightExpanded
            text: "󰃠 " + root.status.backlight + "%"
            foreground: root.primary
            background: root.background
            onWheel: wheel => {
              if (wheel.angleDelta.y > 0) {
                root.run("brightnessctl set 5%+");
              } else {
                root.run("brightnessctl set 5%-");
              }
            }
          }

          Pill {
            text: root.notificationText
            fontSize: 17
            foreground: root.notificationsDnd ? root.muted : root.primary
            background: root.background
            horizontalPadding: root.rightExpanded ? 9 : 8
            maxTextWidth: root.rightExpanded ? 80 : 52
            onClicked: mouse => {
              if (mouse.button === Qt.RightButton) {
                root.notificationsDnd = !root.notificationsDnd;
                root.toastNotifications = [];
              } else {
                root.notificationCenterOpen = !(root.notificationCenterOpen && root.popupScreen === modelData);
                root.popupScreen = modelData;
                root.audioPopupOpen = false;
                root.bluetoothPopupOpen = false;
                root.networkPopupOpen = false;
              }
            }
          }

          Pill {
            text: root.rightExpanded ? root.status.battery.text : root.lastStatusToken(root.status.battery.text, "")
            foreground: root.status.battery.class === "critical" ? root.danger : root.status.battery.class === "warning" ? root.warning : root.success
            background: root.background
            horizontalPadding: root.rightExpanded ? 10 : 8
            maxTextWidth: root.rightExpanded ? 100 : 20
          }

          Pill {
            id: networkPill

            text: root.rightExpanded ? root.status.network.text : root.lastStatusToken(root.status.network.text, "")
            foreground: root.status.network.connected ? root.primary : root.muted
            background: root.background
            horizontalPadding: root.rightExpanded ? 10 : 8
            maxTextWidth: root.rightExpanded ? 110 : 20
            onClicked: mouse => {
              if (mouse.button === Qt.RightButton) {
                root.popupScreen = modelData;
                root.networkPopupOpen = true;
                root.audioPopupOpen = false;
                root.bluetoothPopupOpen = false;
                root.notificationCenterOpen = false;
                root.refreshNetwork(true);
              } else {
                root.networkPopupOpen = !(root.networkPopupOpen && root.popupScreen === modelData);
                root.popupScreen = modelData;
                root.audioPopupOpen = false;
                root.bluetoothPopupOpen = false;
                root.notificationCenterOpen = false;

                if (root.networkPopupOpen) {
                  root.refreshNetwork(false);
                }
              }
            }
          }

          Pill {
            visible: root.rightExpanded
            text: root.status.clock
            foreground: root.primary
            background: root.background
            horizontalPadding: 12
            maxTextWidth: 180
          }

          Pill {
            visible: root.rightExpanded
            text: ""
            foreground: root.danger
            background: root.background
            horizontalPadding: 9
            onClicked: root.run(Quickshell.shellDir + "/scripts/power-menu.sh")
          }
        }
      }

      PopupWindow {
        id: audioPopup

        visible: root.audioPopupOpen && root.popupScreen === modelData
        implicitWidth: 360
        implicitHeight: audioPopupShell.implicitHeight
        color: "transparent"
        grabFocus: true

        onVisibleChanged: {
          if (!visible && root.popupScreen === modelData) {
            root.audioPopupOpen = false;
          }
        }

        anchor {
          item: audioPill
          edges: Edges.Bottom | Edges.Right
          gravity: Edges.Bottom | Edges.Left
          adjustment: PopupAdjustment.Slide | PopupAdjustment.FlipY
          margins.top: 18
        }

        surfaceFormat {
          opaque: false
        }

        Rectangle {
          id: audioPopupShell

          implicitWidth: 360
          implicitHeight: audioPopupContent.implicitHeight + 16
          color: root.backgroundStrong
          border.color: root.primary
          border.width: 1
          radius: 8

          Column {
            id: audioPopupContent

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8
            spacing: 8

            Row {
              width: parent.width
              height: 28
              spacing: 6

              Rectangle {
                width: (parent.width - 6) / 2
                height: 28
                color: root.audioPopupMode === "output" ? root.activeBackground : root.background
                border.color: root.primary
                border.width: 1
                radius: 7

                Text {
                  anchors.centerIn: parent
                  text: " Output"
                  color: root.audioPopupMode === "output" ? root.foreground : root.primary
                  font.family: root.fontFamily
                  font.pixelSize: 12
                  font.bold: true
                  textFormat: Text.PlainText
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  onClicked: root.audioPopupMode = "output"
                }
              }

              Rectangle {
                width: (parent.width - 6) / 2
                height: 28
                color: root.audioPopupMode === "input" ? root.activeBackground : root.background
                border.color: root.primary
                border.width: 1
                radius: 7

                Text {
                  anchors.centerIn: parent
                  text: " Input"
                  color: root.audioPopupMode === "input" ? root.foreground : root.primary
                  font.family: root.fontFamily
                  font.pixelSize: 12
                  font.bold: true
                  textFormat: Text.PlainText
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  onClicked: root.audioPopupMode = "input"
                }
              }
            }

            Text {
              width: parent.width
              visible: root.currentAudioNodes().length === 0
              text: root.audioPopupMode === "output" ? "No output devices" : "No input devices"
              color: root.muted
              font.family: root.fontFamily
              font.pixelSize: 12
              font.bold: true
              horizontalAlignment: Text.AlignHCenter
              textFormat: Text.PlainText
            }

            Repeater {
              model: root.currentAudioNodes()

              Rectangle {
                readonly property bool current: root.isCurrentAudioNode(modelData)

                width: audioPopupContent.width
                height: Math.max(34, deviceText.implicitHeight + deviceDetail.implicitHeight + 12)
                color: deviceArea.containsMouse || current ? root.activeBackground : "transparent"
                border.color: current ? root.primary : "transparent"
                border.width: 1
                radius: 7

                Text {
                  id: checkMark

                  anchors.left: parent.left
                  anchors.leftMargin: 8
                  anchors.verticalCenter: parent.verticalCenter
                  text: current ? "" : ""
                  color: root.success
                  font.family: root.fontFamily
                  font.pixelSize: 12
                  font.bold: true
                  textFormat: Text.PlainText
                }

                Column {
                  anchors.left: parent.left
                  anchors.leftMargin: 28
                  anchors.right: parent.right
                  anchors.rightMargin: 8
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: 1

                  Text {
                    id: deviceText

                    width: parent.width
                    text: root.nodeDisplayName(modelData)
                    color: current ? root.foreground : root.primary
                    elide: Text.ElideRight
                    font.family: root.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                    textFormat: Text.PlainText
                  }

                  Text {
                    id: deviceDetail

                    width: parent.width
                    visible: text !== ""
                    text: root.nodeDetail(modelData)
                    color: root.muted
                    elide: Text.ElideRight
                    font.family: root.fontFamily
                    font.pixelSize: 11
                    textFormat: Text.PlainText
                  }
                }

                MouseArea {
                  id: deviceArea

                  anchors.fill: parent
                  hoverEnabled: true
                  onClicked: root.selectAudioNode(modelData)
                }
              }
            }
          }
        }
      }

      PopupWindow {
        id: bluetoothPopup

        visible: root.bluetoothPopupOpen && root.popupScreen === modelData
        implicitWidth: 380
        implicitHeight: bluetoothPopupShell.implicitHeight
        color: "transparent"
        grabFocus: true

        onVisibleChanged: {
          if (!visible && root.popupScreen === modelData) {
            root.bluetoothPopupOpen = false;
          }
        }

        anchor {
          item: bluetoothPill
          edges: Edges.Bottom | Edges.Right
          gravity: Edges.Bottom | Edges.Left
          adjustment: PopupAdjustment.Slide | PopupAdjustment.FlipY
          margins.top: 18
        }

        surfaceFormat {
          opaque: false
        }

        Rectangle {
          id: bluetoothPopupShell

          implicitWidth: 380
          implicitHeight: bluetoothPopupContent.implicitHeight + 16
          color: root.backgroundStrong
          border.color: root.primary
          border.width: 1
          radius: 8

          Column {
            id: bluetoothPopupContent

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8
            spacing: 8

            RowLayout {
              width: parent.width
              height: 26
              spacing: 8

              Text {
                Layout.fillWidth: true
                text: "Bluetooth"
                color: root.foreground
                elide: Text.ElideRight
                font.family: root.fontFamily
                font.pixelSize: 13
                font.bold: true
                textFormat: Text.PlainText
              }

              Text {
                text: root.bluetoothState.powered ? "on" : "off"
                color: powerArea.containsMouse ? root.foreground : (root.bluetoothState.powered ? root.primary : root.muted)
                font.family: root.fontFamily
                font.pixelSize: 12
                font.bold: true
                textFormat: Text.PlainText

                MouseArea {
                  id: powerArea

                  anchors.fill: parent
                  anchors.margins: -6
                  hoverEnabled: true
                  onClicked: root.runBluetoothAction("power")
                }
              }

              Text {
                visible: root.bluetoothState.powered
                text: bluetoothActionProc.running || bluetoothProc.running ? "busy" : "scan"
                color: scanBluetoothArea.containsMouse ? root.foreground : root.primary
                font.family: root.fontFamily
                font.pixelSize: 12
                font.bold: true
                textFormat: Text.PlainText

                MouseArea {
                  id: scanBluetoothArea

                  anchors.fill: parent
                  anchors.margins: -6
                  enabled: !bluetoothActionProc.running
                  hoverEnabled: true
                  onClicked: root.runBluetoothAction("scan")
                }
              }
            }

            Text {
              width: parent.width
              visible: !root.bluetoothState.powered || root.bluetoothDevices().length === 0
              text: root.bluetoothState.powered ? "No Bluetooth devices" : "Bluetooth disabled"
              color: root.muted
              font.family: root.fontFamily
              font.pixelSize: 12
              font.bold: true
              horizontalAlignment: Text.AlignHCenter
              textFormat: Text.PlainText
            }

            Repeater {
              model: root.bluetoothState.powered ? root.bluetoothDevices().slice(0, 10) : []

              Rectangle {
                readonly property string actionText: root.bluetoothActionText(modelData)
                readonly property bool active: modelData.connected
                readonly property bool usable: root.bluetoothState.powered && !bluetoothActionProc.running && !modelData.blocked

                width: bluetoothPopupContent.width
                height: Math.max(38, bluetoothName.implicitHeight + bluetoothDetail.implicitHeight + 12)
                color: bluetoothArea.containsMouse || active ? root.activeBackground : "transparent"
                border.color: active ? root.primary : "transparent"
                border.width: 1
                radius: 7

                Text {
                  anchors.left: parent.left
                  anchors.leftMargin: 8
                  anchors.verticalCenter: parent.verticalCenter
                  text: active ? "" : root.bluetoothDeviceIcon(modelData)
                  color: active ? root.success : usable ? root.primary : root.muted
                  font.family: root.fontFamily
                  font.pixelSize: 13
                  font.bold: true
                  textFormat: Text.PlainText
                }

                Column {
                  anchors.left: parent.left
                  anchors.leftMargin: 30
                  anchors.right: bluetoothActionLabel.left
                  anchors.rightMargin: 8
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: 1

                  Text {
                    id: bluetoothName

                    width: parent.width
                    text: modelData.name || modelData.address
                    color: active ? root.foreground : usable ? root.primary : root.muted
                    elide: Text.ElideRight
                    font.family: root.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                    textFormat: Text.PlainText
                  }

                  Text {
                    id: bluetoothDetail

                    width: parent.width
                    text: root.bluetoothDetail(modelData)
                    color: root.muted
                    elide: Text.ElideRight
                    font.family: root.fontFamily
                    font.pixelSize: 11
                    textFormat: Text.PlainText
                  }
                }

                Text {
                  id: bluetoothActionLabel

                  anchors.right: parent.right
                  anchors.rightMargin: 8
                  anchors.verticalCenter: parent.verticalCenter
                  width: 74
                  text: actionText
                  color: usable ? root.primary : root.muted
                  elide: Text.ElideRight
                  font.family: root.fontFamily
                  font.pixelSize: 11
                  font.bold: true
                  horizontalAlignment: Text.AlignRight
                  textFormat: Text.PlainText
                }

                MouseArea {
                  id: bluetoothArea

                  anchors.fill: parent
                  enabled: usable
                  hoverEnabled: true
                  onClicked: root.activateBluetoothDevice(modelData)
                }
              }
            }
          }
        }
      }

      PopupWindow {
        id: networkPopup

        visible: root.networkPopupOpen && root.popupScreen === modelData
        implicitWidth: 380
        implicitHeight: networkPopupShell.implicitHeight
        color: "transparent"
        grabFocus: true

        onVisibleChanged: {
          if (!visible && root.popupScreen === modelData) {
            root.networkPopupOpen = false;
            root.networkPasswordSsid = "";
          }
        }

        anchor {
          item: networkPill
          edges: Edges.Bottom | Edges.Right
          gravity: Edges.Bottom | Edges.Left
          adjustment: PopupAdjustment.Slide | PopupAdjustment.FlipY
          margins.top: 18
        }

        surfaceFormat {
          opaque: false
        }

        Rectangle {
          id: networkPopupShell

          implicitWidth: 380
          implicitHeight: networkPopupContent.implicitHeight + 16
          color: root.backgroundStrong
          border.color: root.primary
          border.width: 1
          radius: 8

          Column {
            id: networkPopupContent

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8
            spacing: 8

            RowLayout {
              width: parent.width
              height: 26
              spacing: 8

              Text {
                Layout.fillWidth: true
                text: "Network"
                color: root.foreground
                elide: Text.ElideRight
                font.family: root.fontFamily
                font.pixelSize: 13
                font.bold: true
                textFormat: Text.PlainText
              }

              Text {
                text: root.networkState.wifiEnabled ? "Wi-Fi on" : "Wi-Fi off"
                color: root.networkState.wifiEnabled ? root.primary : root.muted
                font.family: root.fontFamily
                font.pixelSize: 12
                font.bold: true
                textFormat: Text.PlainText
              }

              Text {
                text: "scan"
                color: scanArea.containsMouse ? root.foreground : root.primary
                font.family: root.fontFamily
                font.pixelSize: 12
                font.bold: true
                textFormat: Text.PlainText

                MouseArea {
                  id: scanArea

                  anchors.fill: parent
                  anchors.margins: -6
                  hoverEnabled: true
                  onClicked: root.refreshNetwork(true)
                }
              }
            }

            Rectangle {
              width: parent.width
              height: Math.max(34, wiredColumn.implicitHeight + 12)
              visible: root.wiredConnections().length > 0
              color: root.background
              border.color: root.primary
              border.width: 1
              radius: 7

              Column {
                id: wiredColumn

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 3

                Repeater {
                  model: root.wiredConnections()

                  RowLayout {
                    width: wiredColumn.width
                    spacing: 8

                    Text {
                      text: "󰈀"
                      color: modelData.connected ? root.success : root.muted
                      font.family: root.fontFamily
                      font.pixelSize: 13
                      font.bold: true
                      textFormat: Text.PlainText
                    }

                    Text {
                      Layout.fillWidth: true
                      text: modelData.connection || modelData.device
                      color: root.foreground
                      elide: Text.ElideRight
                      font.family: root.fontFamily
                      font.pixelSize: 12
                      font.bold: true
                      textFormat: Text.PlainText
                    }

                    Text {
                      text: modelData.connected ? "connected" : modelData.state
                      color: modelData.connected ? root.success : root.muted
                      font.family: root.fontFamily
                      font.pixelSize: 11
                      textFormat: Text.PlainText
                    }
                  }
                }
              }
            }

            Text {
              width: parent.width
              visible: root.wifiNetworks().length === 0
              text: root.networkState.wifiEnabled ? "No Wi-Fi networks" : "Wi-Fi disabled"
              color: root.muted
              font.family: root.fontFamily
              font.pixelSize: 12
              font.bold: true
              horizontalAlignment: Text.AlignHCenter
              textFormat: Text.PlainText
            }

            Repeater {
              model: root.wifiNetworks().slice(0, 10)

              Rectangle {
                readonly property bool connectable: root.canConnectWifi(modelData)
                readonly property bool passwordOpen: root.networkPasswordSsid === modelData.ssid && root.needsWifiPassword(modelData)

                width: networkPopupContent.width
                height: passwordOpen ? 78 : Math.max(36, networkName.implicitHeight + networkDetail.implicitHeight + 12)
                color: networkArea.containsMouse || modelData.active ? root.activeBackground : "transparent"
                border.color: modelData.active ? root.primary : "transparent"
                border.width: 1
                radius: 7

                onPasswordOpenChanged: {
                  if (passwordOpen) {
                    passwordInput.text = "";
                    passwordInput.forceActiveFocus();
                  }
                }

                Text {
                  anchors.left: parent.left
                  anchors.leftMargin: 8
                  y: passwordOpen ? 13 : (parent.height - implicitHeight) / 2
                  text: modelData.active ? "" : root.wifiSignalIcon(modelData.signal)
                  color: modelData.active ? root.success : (connectable ? root.primary : root.muted)
                  font.family: root.fontFamily
                  font.pixelSize: 13
                  font.bold: true
                  textFormat: Text.PlainText
                }

                Column {
                  anchors.left: parent.left
                  anchors.leftMargin: 30
                  anchors.right: parent.right
                  anchors.rightMargin: 8
                  y: passwordOpen ? 8 : (parent.height - implicitHeight) / 2
                  spacing: 1

                  Text {
                    id: networkName

                    width: parent.width
                    text: modelData.ssid
                    color: modelData.active ? root.foreground : (connectable ? root.primary : root.muted)
                    elide: Text.ElideRight
                    font.family: root.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                    textFormat: Text.PlainText
                  }

                  Text {
                    id: networkDetail

                    width: parent.width
                    text: root.wifiDetail(modelData)
                    color: root.muted
                    elide: Text.ElideRight
                    font.family: root.fontFamily
                    font.pixelSize: 11
                    textFormat: Text.PlainText
                  }
                }

                Rectangle {
                  id: passwordField

                  visible: passwordOpen
                  anchors.left: parent.left
                  anchors.leftMargin: 30
                  anchors.right: connectButton.left
                  anchors.rightMargin: 6
                  anchors.bottom: parent.bottom
                  anchors.bottomMargin: 8
                  height: 26
                  color: root.background
                  border.color: passwordInput.activeFocus ? root.primary : root.muted
                  border.width: 1
                  radius: 6

                  TextInput {
                    id: passwordInput

                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    clip: true
                    color: root.foreground
                    selectionColor: root.activeBackground
                    selectedTextColor: root.foreground
                    echoMode: TextInput.Password
                    font.family: root.fontFamily
                    font.pixelSize: 12

                    onAccepted: root.connectWifi(modelData, text)
                    Keys.onEscapePressed: root.networkPasswordSsid = ""
                  }
                }

                Rectangle {
                  id: connectButton

                  visible: passwordOpen
                  anchors.right: parent.right
                  anchors.rightMargin: 8
                  anchors.bottom: parent.bottom
                  anchors.bottomMargin: 8
                  width: 60
                  height: 26
                  color: connectArea.containsMouse ? root.activeBackground : root.background
                  border.color: root.primary
                  border.width: 1
                  radius: 6

                  Text {
                    anchors.centerIn: parent
                    text: "join"
                    color: root.primary
                    font.family: root.fontFamily
                    font.pixelSize: 11
                    font.bold: true
                    textFormat: Text.PlainText
                  }

                  MouseArea {
                    id: connectArea

                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.connectWifi(modelData, passwordInput.text)
                  }
                }

                MouseArea {
                  id: networkArea

                  anchors.fill: parent
                  enabled: !passwordOpen
                  hoverEnabled: true
                  onClicked: root.connectWifi(modelData)
                }
              }
            }
          }
        }
      }
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: notificationWindow

      required property var modelData

      readonly property bool centerOpen: root.notificationCenterOpen && root.popupScreen === modelData
      readonly property int itemCount: centerOpen ? root.notificationCount : root.toastNotifications.length

      screen: modelData
      visible: centerOpen || root.toastNotifications.length > 0
      implicitWidth: 420
      implicitHeight: Math.min(notificationStack.implicitHeight, screen.height - 72)
      color: "transparent"
      exclusiveZone: 0
      aboveWindows: true

      surfaceFormat {
        opaque: false
      }

      anchors {
        top: true
        right: true
      }

      margins {
        top: 8
        right: 10
      }

      Flickable {
        anchors.fill: parent
        contentHeight: notificationStack.implicitHeight
        clip: true
        interactive: notificationStack.implicitHeight > height

        Column {
          id: notificationStack

          width: parent.width
          spacing: 6

          Rectangle {
            width: parent.width
            height: 28
            visible: notificationWindow.centerOpen
            color: root.backgroundStrong
            border.color: root.primary
            border.width: 1
            radius: 8

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 8
              spacing: 7

              Text {
                Layout.fillWidth: true
                text: root.notificationCount === 1 ? "1 notification" : root.notificationCount + " notifications"
                color: root.foreground
                elide: Text.ElideRight
                font.family: root.fontFamily
                font.pixelSize: 12
                font.bold: true
                textFormat: Text.PlainText
              }

              Text {
                text: root.notificationsDnd ? "DND on" : "DND off"
                color: dndArea.containsMouse ? root.foreground : (root.notificationsDnd ? root.muted : root.primary)
                font.family: root.fontFamily
                font.pixelSize: 12
                font.bold: true
                textFormat: Text.PlainText

                MouseArea {
                  id: dndArea

                  anchors.fill: parent
                  anchors.margins: -6
                  hoverEnabled: true
                  onClicked: {
                    root.notificationsDnd = !root.notificationsDnd;
                    root.toastNotifications = [];
                  }
                }
              }

              Text {
                text: "clear"
                visible: root.notificationCount > 0
                color: clearArea.containsMouse ? root.foreground : root.primary
                font.family: root.fontFamily
                font.pixelSize: 12
                font.bold: true
                textFormat: Text.PlainText

                MouseArea {
                  id: clearArea

                  anchors.fill: parent
                  anchors.margins: -6
                  hoverEnabled: true
                  onClicked: root.clearNotifications()
                }
              }
            }
          }

          Rectangle {
            width: parent.width
            height: 52
            visible: notificationWindow.centerOpen && root.notificationCount === 0
            color: root.background
            border.color: root.primary
            border.width: 1
            radius: 8

            Text {
              anchors.centerIn: parent
              text: "No notifications"
              color: root.muted
              font.family: root.fontFamily
              font.pixelSize: 13
              font.bold: true
              textFormat: Text.PlainText
            }
          }

          Repeater {
            model: notificationWindow.centerOpen ? notificationServer.trackedNotifications : toastModel

            NotificationCard {
              notification: modelData
              autoHide: !notificationWindow.centerOpen
              centerMode: notificationWindow.centerOpen
              primary: root.primary
              background: root.background
              backgroundStrong: root.backgroundStrong
              foreground: root.foreground
              muted: root.muted
              warning: root.warning
              danger: root.danger
              fontFamily: root.fontFamily
              onDismissed: notification => root.dismissNotification(notification)
            }
          }
        }
      }
    }
  }
}
