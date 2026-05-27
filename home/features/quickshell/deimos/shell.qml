import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
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
  property bool batteryPopupOpen: false
  property bool networkPopupOpen: false
  property string networkPasswordSsid: ""
  property var popupScreen: null
  property bool rightExpanded: false
  property bool notificationCenterOpen: false
  property bool notificationsDnd: false
  property string submap: ""
  property bool volumeOsdOpen: false
  property var expandedNotificationGroups: ({})
  property var toastDeadlines: ({})
  property var toastNotifications: []
  readonly property int notificationCount: notificationServer.trackedNotifications ? notificationServer.trackedNotifications.values.length : 0
  readonly property string notificationIcon: notificationsDnd ? (notificationCount > 0 ? "󰂛" : "󰪑") : (notificationCount > 0 ? "󰂚" : "󰂜")
  readonly property string notificationText: notificationCount > 0 ? notificationCount + " " + notificationIcon : notificationIcon
  property var status: ({
    backlight: 0,
    network: {
      text: "",
      connected: false
    },
    clock: ""
  })
  property var networkState: ({
    wifiEnabled: false,
    activeWifi: "",
    wired: [],
    wifi: []
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

  function wiredConnections() {
    return root.networkState && root.networkState.wired ? root.networkState.wired : [];
  }

  function wifiNetworks() {
    return root.networkState && root.networkState.wifi ? root.networkState.wifi : [];
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
    const node = Pipewire.defaultAudioSink;
    return root.audioIcon(root.audioMuted(node), root.audioPercent(node));
  }

  function compactBluetoothText() {
    return root.bluetoothPowered() ? "" : "󰂲";
  }

  function batteryDevice() {
    const devices = UPower.devices && UPower.devices.values ? UPower.devices.values : [];
    for (let index = 0; index < devices.length; index += 1) {
      const device = devices[index];
      if (device && device.isLaptopBattery && device.isPresent) {
        return device;
      }
    }

    return UPower.displayDevice;
  }

  function batteryReady() {
    const device = root.batteryDevice();
    return !!(device && device.ready && device.isPresent);
  }

  function batteryPercent() {
    const device = root.batteryDevice();
    const rawPercent = Number(device && device.ready ? device.percentage : 0) || 0;
    return root.clampPercent(rawPercent > 0 && rawPercent <= 1 ? rawPercent * 100 : rawPercent);
  }

  function batteryIcon() {
    const device = root.batteryDevice();
    const percent = root.batteryPercent();

    if (!root.batteryReady()) {
      return "";
    }

    if (device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.PendingCharge) {
      return "";
    }

    if (percent >= 80) {
      return "";
    }

    if (percent >= 60) {
      return "";
    }

    if (percent >= 40) {
      return "";
    }

    if (percent >= 20) {
      return "";
    }

    return "";
  }

  function batteryText() {
    if (!root.batteryReady()) {
      return "--% " + root.batteryIcon();
    }

    return root.batteryPercent() + "% " + root.batteryIcon();
  }

  function batteryForeground() {
    if (!root.batteryReady()) {
      return root.muted;
    }

    const percent = root.batteryPercent();
    if (percent <= 15) {
      return root.danger;
    }

    if (percent <= 30) {
      return root.warning;
    }

    return root.success;
  }

  function batteryStateText() {
    const device = root.batteryDevice();
    if (!root.batteryReady()) {
      return "Unavailable";
    }

    switch (device.state) {
    case UPowerDeviceState.Charging:
      return "Charging";
    case UPowerDeviceState.Discharging:
      return "Discharging";
    case UPowerDeviceState.FullyCharged:
      return "Full";
    case UPowerDeviceState.PendingCharge:
      return "Waiting to charge";
    case UPowerDeviceState.PendingDischarge:
      return "Waiting to discharge";
    case UPowerDeviceState.Empty:
      return "Empty";
    default:
      return UPower.onBattery ? "On battery" : "On AC";
    }
  }

  function formatBatteryDuration(seconds) {
    const value = Math.round(Number(seconds) || 0);
    if (value <= 0) {
      return "";
    }

    const minutes = Math.max(1, Math.round(value / 60));
    const hours = Math.floor(minutes / 60);
    const remainder = minutes % 60;

    if (hours <= 0) {
      return minutes + "m";
    }

    return hours + "h " + (remainder < 10 ? "0" : "") + remainder + "m";
  }

  function batteryTimeText() {
    const device = root.batteryDevice();
    if (!root.batteryReady()) {
      return "Unknown";
    }

    if (device.state === UPowerDeviceState.FullyCharged) {
      return "Full";
    }

    if (device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.PendingCharge) {
      const timeToFull = root.formatBatteryDuration(device.timeToFull);
      return timeToFull === "" ? "Charging" : timeToFull + " to full";
    }

    if (device.state === UPowerDeviceState.Discharging || device.state === UPowerDeviceState.PendingDischarge || UPower.onBattery) {
      const timeToEmpty = root.formatBatteryDuration(device.timeToEmpty);
      return timeToEmpty === "" ? "Calculating" : timeToEmpty + " left";
    }

    return UPower.onBattery ? "Calculating" : "On AC";
  }

  function batteryRateText() {
    const device = root.batteryDevice();
    if (!root.batteryReady()) {
      return "-- W";
    }

    const rate = Math.abs(Number(device.changeRate) || 0);
    let suffix = "idle";

    if (device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.PendingCharge) {
      suffix = "charge";
    } else if (device.state === UPowerDeviceState.Discharging || device.state === UPowerDeviceState.PendingDischarge || UPower.onBattery) {
      suffix = "draw";
    }

    return rate.toFixed(1) + " W " + suffix;
  }

  function batteryEnergyText() {
    const device = root.batteryDevice();
    if (!root.batteryReady() || !device.energyCapacity) {
      return "Unknown";
    }

    return (Number(device.energy) || 0).toFixed(1) + " / " + (Number(device.energyCapacity) || 0).toFixed(1) + " Wh";
  }

  function batteryHealthText() {
    const device = root.batteryDevice();
    if (!root.batteryReady() || !device.healthSupported) {
      return "";
    }

    return root.clampPercent(device.healthPercentage) + "% health";
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

  function bluetoothAdapter() {
    return Bluetooth.defaultAdapter;
  }

  function bluetoothPowered() {
    const adapter = root.bluetoothAdapter();
    return !!(adapter && adapter.enabled);
  }

  function bluetoothDiscovering() {
    const adapter = root.bluetoothAdapter();
    return !!(adapter && adapter.discovering);
  }

  function bluetoothDevices() {
    const adapter = root.bluetoothAdapter();
    const devices = adapter && adapter.devices && adapter.devices.values ? adapter.devices.values : [];

    return devices.slice().sort((left, right) => {
      const leftConnected = left && left.connected ? 0 : 1;
      const rightConnected = right && right.connected ? 0 : 1;
      if (leftConnected !== rightConnected) {
        return leftConnected - rightConnected;
      }

      const leftPaired = left && (left.paired || left.bonded) ? 0 : 1;
      const rightPaired = right && (right.paired || right.bonded) ? 0 : 1;
      if (leftPaired !== rightPaired) {
        return leftPaired - rightPaired;
      }

      return root.bluetoothDeviceName(left).localeCompare(root.bluetoothDeviceName(right));
    });
  }

  function bluetoothConnectedDevices() {
    return root.bluetoothDevices().filter(device => device && device.connected);
  }

  function bluetoothDeviceName(device) {
    return device ? (device.name || device.deviceName || device.address || "Unknown") : "Unknown";
  }

  function bluetoothText() {
    if (!root.bluetoothPowered()) {
      return "󰂲";
    }

    const count = root.bluetoothConnectedDevices().length;
    return count > 0 ? count + " " : "";
  }

  function bluetoothForeground() {
    if (!root.bluetoothPowered()) {
      return root.muted;
    }

    return root.bluetoothConnectedDevices().length > 0 ? root.success : root.primary;
  }

  function setBluetoothScanning(discovering) {
    const adapter = root.bluetoothAdapter();
    if (!adapter || !adapter.enabled) {
      return;
    }

    adapter.discovering = discovering;

    if (discovering) {
      bluetoothScanTimer.restart();
    } else {
      bluetoothScanTimer.stop();
    }
  }

  function toggleBluetoothPower() {
    const adapter = root.bluetoothAdapter();
    if (!adapter) {
      return;
    }

    if (adapter.enabled) {
      bluetoothScanTimer.stop();
    }

    adapter.enabled = !adapter.enabled;
  }

  function bluetoothDetail(device) {
    if (!device) {
      return "";
    }

    const parts = [];

    if (device.connected) {
      parts.push("connected");
    } else if (root.bluetoothDeviceBusy(device)) {
      parts.push("busy");
    } else if (device.paired || device.bonded) {
      parts.push("paired");
    } else {
      parts.push("new");
    }

    if (device.trusted) {
      parts.push("trusted");
    }

    return parts.join(" · ");
  }

  function bluetoothDeviceBusy(device) {
    return !!(device && (device.pairing || device.state === BluetoothDeviceState.Connecting || device.state === BluetoothDeviceState.Disconnecting));
  }

  function bluetoothActionText(device) {
    if (!root.bluetoothPowered()) {
      return "";
    }

    if (root.bluetoothDeviceBusy(device)) {
      return "busy";
    }

    if (device.connected) {
      return "disconnect";
    }

    return device.paired || device.bonded ? "connect" : "pair";
  }

  function activateBluetoothDevice(device) {
    if (!device || !root.bluetoothPowered() || device.blocked || root.bluetoothDeviceBusy(device)) {
      return;
    }

    if (device.connected) {
      device.disconnect();
    } else if (device.paired || device.bonded) {
      device.trusted = true;
      device.connect();
    } else {
      device.trusted = true;
      device.pair();
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

  function closeNotificationCenter() {
    root.notificationCenterOpen = false;
    root.expandedNotificationGroups = ({});
  }

  function dismissNotificationGroup(group) {
    const notifications = group && group.notifications ? group.notifications.slice() : [];

    for (let index = 0; index < notifications.length; index += 1) {
      root.dismissNotification(notifications[index]);
    }

    if (group && group.key) {
      root.setNotificationGroupExpanded(group.key, false);
    }
  }

  function clearNotifications() {
    const notifications = Array.from(notificationServer.trackedNotifications.values);

    for (let index = 0; index < notifications.length; index += 1) {
      notifications[index].dismiss();
    }

    root.toastNotifications = [];
    root.closeNotificationCenter();
  }

  function notificationAppName(notification) {
    const appName = notification ? String(notification.appName || "").trim() : "";
    const desktopEntry = notification ? String(notification.desktopEntry || "").trim() : "";

    if (appName !== "") {
      return appName;
    }

    if (desktopEntry !== "") {
      return desktopEntry;
    }

    return "Notifications";
  }

  function notificationGroupKey(notification) {
    const desktopEntry = notification ? String(notification.desktopEntry || "").trim().toLowerCase() : "";
    if (desktopEntry !== "") {
      return desktopEntry;
    }

    return root.notificationAppName(notification).toLowerCase();
  }

  function notificationGroupExpanded(key) {
    return !!(key && root.expandedNotificationGroups[key]);
  }

  function setNotificationGroupExpanded(key, expanded) {
    if (!key) {
      return;
    }

    const next = Object.assign({}, root.expandedNotificationGroups);

    if (expanded) {
      next[key] = true;
    } else {
      delete next[key];
    }

    root.expandedNotificationGroups = next;
  }

  function toggleNotificationGroup(group) {
    if (!group || !group.notifications || group.notifications.length < 2) {
      return;
    }

    root.setNotificationGroupExpanded(group.key, !root.notificationGroupExpanded(group.key));
  }

  function notificationGroups() {
    const notifications = notificationServer.trackedNotifications ? notificationServer.trackedNotifications.values : [];
    const groupsByKey = {};
    const groups = [];

    for (let index = 0; index < notifications.length; index += 1) {
      const notification = notifications[index];
      const key = root.notificationGroupKey(notification);
      let group = groupsByKey[key];

      if (!group) {
        group = {
          key: key,
          appName: root.notificationAppName(notification),
          critical: false,
          latestId: 0,
          notifications: []
        };
        groupsByKey[key] = group;
        groups.push(group);
      }

      group.notifications.push(notification);
      group.latestId = Math.max(group.latestId, notification ? notification.id : 0);
      group.critical = group.critical || !!(notification && notification.urgency === NotificationUrgency.Critical);
    }

    groups.sort((left, right) => {
      if (left.critical !== right.critical) {
        return left.critical ? -1 : 1;
      }

      return right.latestId - left.latestId;
    });

    for (let groupIndex = 0; groupIndex < groups.length; groupIndex += 1) {
      groups[groupIndex].notifications = groups[groupIndex].notifications.slice().sort((left, right) => (right ? right.id : 0) - (left ? left.id : 0));
    }

    return groups;
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

  function clampPercent(value) {
    return Math.max(0, Math.min(100, Math.round(Number(value) || 0)));
  }

  function audioIcon(muted, percent) {
    if (muted) {
      return "";
    }

    if (percent < 30) {
      return "";
    }

    if (percent < 70) {
      return "";
    }

    return "";
  }

  function audioNode(mode) {
    return mode === "output" ? Pipewire.defaultAudioSink : Pipewire.defaultAudioSource;
  }

  function currentAudioNode() {
    return root.audioNode(root.audioPopupMode);
  }

  function audioPercent(node) {
    return root.clampPercent(node && node.audio ? node.audio.volume * 100 : 0);
  }

  function audioMuted(node) {
    return !!(node && node.audio && node.audio.muted);
  }

  function audioText(node) {
    const muted = root.audioMuted(node);
    const percent = root.audioPercent(node);
    const icon = root.audioIcon(muted, percent);
    return muted ? "muted " + icon : percent + "% " + icon;
  }

  function currentAudioPercent() {
    return root.audioPercent(root.currentAudioNode());
  }

  function currentAudioMuted() {
    return root.audioMuted(root.currentAudioNode());
  }

  function setAudioVolume(node, percent) {
    if (!node || !node.audio) {
      return;
    }

    node.audio.volume = root.clampPercent(percent) / 100;
  }

  function setCurrentAudioVolume(percent) {
    root.setAudioVolume(root.currentAudioNode(), percent);
  }

  function toggleAudioMute(node) {
    if (!node || !node.audio) {
      return;
    }

    node.audio.muted = !node.audio.muted;
  }

  function showVolumeOsd() {
    if (!Pipewire.defaultAudioSink || !Pipewire.defaultAudioSink.audio) {
      return;
    }

    root.volumeOsdOpen = true;
    volumeOsdHideTimer.restart();
  }

  function setCurrentAudioVolumeFromPosition(position, width) {
    if (width <= 0) {
      return;
    }

    root.setCurrentAudioVolume(position * 100 / width);
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
    id: networkActionProc

    onExited: {
      root.refreshNetwork(false);
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
    id: bluetoothScanTimer

    interval: 6000
    repeat: false
    onTriggered: {
      const adapter = root.bluetoothAdapter();
      if (adapter) {
        adapter.discovering = false;
      }
    }
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

  PwObjectTracker {
    objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
  }

  Connections {
    target: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio ? Pipewire.defaultAudioSink.audio : null

    function onVolumesChanged() {
      root.showVolumeOsd();
    }

    function onMutedChanged() {
      root.showVolumeOsd();
    }
  }

  Connections {
    target: Hyprland

    function onRawEvent(event) {
      if (event.name === "submap") {
        root.submap = event.data === "default" ? "" : event.data;
      }
    }
  }

  Timer {
    id: volumeOsdHideTimer

    interval: 1100
    repeat: false
    onTriggered: root.volumeOsdOpen = false
  }

  LazyLoader {
    active: root.volumeOsdOpen

    PanelWindow {
      implicitWidth: 360
      implicitHeight: 58
      color: "transparent"
      exclusiveZone: 0
      aboveWindows: true

      anchors.top: true
      margins.top: 56

      surfaceFormat {
        opaque: false
      }

      mask: Region {}

      Rectangle {
        anchors.fill: parent
        color: root.backgroundStrong
        border.color: root.primary
        border.width: 1
        radius: 8

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 12
          anchors.rightMargin: 14
          spacing: 10

          Text {
            text: root.audioIcon(root.audioMuted(Pipewire.defaultAudioSink), root.audioPercent(Pipewire.defaultAudioSink))
            color: root.audioMuted(Pipewire.defaultAudioSink) ? root.muted : root.primary
            font.family: root.fontFamily
            font.pixelSize: 22
            font.bold: true
            textFormat: Text.PlainText
          }

          Rectangle {
            Layout.fillWidth: true
            height: 8
            color: root.background
            radius: 4

            Rectangle {
              anchors.left: parent.left
              anchors.top: parent.top
              anchors.bottom: parent.bottom
              width: parent.width * root.audioPercent(Pipewire.defaultAudioSink) / 100
              color: root.audioMuted(Pipewire.defaultAudioSink) ? root.muted : root.primary
              radius: 4
            }
          }

          Text {
            width: 56
            text: root.audioMuted(Pipewire.defaultAudioSink) ? "muted" : root.audioPercent(Pipewire.defaultAudioSink) + "%"
            color: root.audioMuted(Pipewire.defaultAudioSink) ? root.muted : root.foreground
            elide: Text.ElideRight
            font.family: root.fontFamily
            font.pixelSize: 13
            font.bold: true
            horizontalAlignment: Text.AlignRight
            textFormat: Text.PlainText
          }
        }
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

        Item {
          id: notificationPopupAnchor

          width: 1
          height: 1
          anchors.top: parent.top
          anchors.right: parent.right
        }

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

            text: root.rightExpanded ? root.audioText(Pipewire.defaultAudioSink) : root.compactAudioText()
            foreground: root.audioMuted(Pipewire.defaultAudioSink) ? root.muted : root.primary
            background: root.background
            horizontalPadding: root.rightExpanded ? 10 : 8
            maxTextWidth: root.rightExpanded ? 120 : 20
            onClicked: mouse => {
              if (mouse.button === Qt.RightButton) {
                root.audioPopupMode = "input";
                root.popupScreen = modelData;
                root.audioPopupOpen = true;
                root.bluetoothPopupOpen = false;
                root.batteryPopupOpen = false;
                root.networkPopupOpen = false;
                root.notificationCenterOpen = false;
              } else if (mouse.button === Qt.MiddleButton) {
                root.toggleAudioMute(Pipewire.defaultAudioSink);
              } else {
                root.audioPopupMode = "output";
                root.audioPopupOpen = !(root.audioPopupOpen && root.popupScreen === modelData);
                root.popupScreen = modelData;
                root.bluetoothPopupOpen = false;
                root.batteryPopupOpen = false;
                root.networkPopupOpen = false;
                root.notificationCenterOpen = false;
              }
            }
            onWheel: wheel => {
              const delta = wheel.angleDelta.y > 0 ? 5 : -5;
              root.setAudioVolume(Pipewire.defaultAudioSink, root.audioPercent(Pipewire.defaultAudioSink) + delta);
            }
          }

          Pill {
            id: bluetoothPill

            text: root.rightExpanded ? root.bluetoothText() : root.compactBluetoothText()
            foreground: root.bluetoothForeground()
            background: root.background
            horizontalPadding: root.rightExpanded ? 10 : 8
            maxTextWidth: root.rightExpanded ? 70 : 20
            onClicked: mouse => {
              if (mouse.button === Qt.RightButton) {
                root.popupScreen = modelData;
                root.bluetoothPopupOpen = true;
                root.audioPopupOpen = false;
                root.batteryPopupOpen = false;
                root.networkPopupOpen = false;
                root.notificationCenterOpen = false;
                root.setBluetoothScanning(true);
              } else {
                root.bluetoothPopupOpen = !(root.bluetoothPopupOpen && root.popupScreen === modelData);
                root.popupScreen = modelData;
                root.audioPopupOpen = false;
                root.batteryPopupOpen = false;
                root.networkPopupOpen = false;
                root.notificationCenterOpen = false;
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
            id: notificationPill

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
                root.batteryPopupOpen = false;
                root.networkPopupOpen = false;
              }
            }
          }

          Pill {
            id: batteryPill

            text: root.rightExpanded ? root.batteryText() : root.batteryIcon()
            foreground: root.batteryForeground()
            background: root.background
            horizontalPadding: root.rightExpanded ? 10 : 8
            maxTextWidth: root.rightExpanded ? 100 : 20
            onClicked: {
              root.batteryPopupOpen = !(root.batteryPopupOpen && root.popupScreen === modelData);
              root.popupScreen = modelData;
              root.audioPopupOpen = false;
              root.bluetoothPopupOpen = false;
              root.networkPopupOpen = false;
              root.notificationCenterOpen = false;
            }
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
                root.batteryPopupOpen = false;
                root.notificationCenterOpen = false;
                root.refreshNetwork(true);
              } else {
                root.networkPopupOpen = !(root.networkPopupOpen && root.popupScreen === modelData);
                root.popupScreen = modelData;
                root.audioPopupOpen = false;
                root.bluetoothPopupOpen = false;
                root.batteryPopupOpen = false;
                root.notificationCenterOpen = false;

                if (root.networkPopupOpen) {
                  root.refreshNetwork(false);
                }
              }
            }
          }

          Pill {
            text: root.status.clock
            foreground: root.primary
            background: root.background
            horizontalPadding: 10
            maxTextWidth: 110
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

            Rectangle {
              width: parent.width
              height: 56
              color: root.background
              border.color: root.activeBackground
              border.width: 1
              radius: 7

              RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                anchors.topMargin: 8
                height: 18
                spacing: 8

                Text {
                  Layout.fillWidth: true
                  text: root.audioPopupMode === "output" ? " Volume" : " Volume"
                  color: root.foreground
                  elide: Text.ElideRight
                  font.family: root.fontFamily
                  font.pixelSize: 12
                  font.bold: true
                  textFormat: Text.PlainText
                }

                Text {
                  text: root.currentAudioMuted() ? "muted" : root.currentAudioPercent() + "%"
                  color: root.currentAudioMuted() ? root.muted : root.primary
                  font.family: root.fontFamily
                  font.pixelSize: 12
                  font.bold: true
                  textFormat: Text.PlainText
                }
              }

              Rectangle {
                id: volumeSlider

                readonly property int percent: root.currentAudioPercent()

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                anchors.bottomMargin: 8
                height: 20
                color: "transparent"

                Rectangle {
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  height: 4
                  color: root.backgroundStrong
                  radius: 2
                }

                Rectangle {
                  anchors.left: parent.left
                  anchors.verticalCenter: parent.verticalCenter
                  width: parent.width * volumeSlider.percent / 100
                  height: 4
                  color: root.currentAudioMuted() ? root.muted : root.primary
                  radius: 2
                }

                Rectangle {
                  width: 14
                  height: 14
                  x: Math.max(0, Math.min(parent.width - width, parent.width * volumeSlider.percent / 100 - width / 2))
                  y: Math.round((parent.height - height) / 2)
                  color: volumeSliderArea.containsMouse ? root.foreground : root.primary
                  border.color: root.backgroundStrong
                  border.width: 1
                  radius: 7
                }

                MouseArea {
                  id: volumeSliderArea

                  anchors.fill: parent
                  anchors.margins: -6
                  hoverEnabled: true
                  onPressed: mouse => root.setCurrentAudioVolumeFromPosition(mouse.x, volumeSlider.width)
                  onPositionChanged: mouse => {
                    if (volumeSliderArea.pressed) {
                      root.setCurrentAudioVolumeFromPosition(mouse.x, volumeSlider.width);
                    }
                  }
                  onWheel: wheel => {
                    const delta = wheel.angleDelta.y > 0 ? 5 : -5;
                    root.setCurrentAudioVolume(root.currentAudioPercent() + delta);
                  }
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
                text: root.bluetoothPowered() ? "on" : "off"
                color: powerArea.containsMouse ? root.foreground : (root.bluetoothPowered() ? root.primary : root.muted)
                font.family: root.fontFamily
                font.pixelSize: 12
                font.bold: true
                textFormat: Text.PlainText

                MouseArea {
                  id: powerArea

                  anchors.fill: parent
                  anchors.margins: -6
                  hoverEnabled: true
                  onClicked: root.toggleBluetoothPower()
                }
              }

              Text {
                visible: root.bluetoothPowered()
                text: root.bluetoothDiscovering() ? "busy" : "scan"
                color: scanBluetoothArea.containsMouse ? root.foreground : root.primary
                font.family: root.fontFamily
                font.pixelSize: 12
                font.bold: true
                textFormat: Text.PlainText

                MouseArea {
                  id: scanBluetoothArea

                  anchors.fill: parent
                  anchors.margins: -6
                  enabled: !root.bluetoothDiscovering()
                  hoverEnabled: true
                  onClicked: root.setBluetoothScanning(true)
                }
              }
            }

            Text {
              width: parent.width
              visible: !root.bluetoothPowered() || root.bluetoothDevices().length === 0
              text: root.bluetoothPowered() ? "No Bluetooth devices" : "Bluetooth disabled"
              color: root.muted
              font.family: root.fontFamily
              font.pixelSize: 12
              font.bold: true
              horizontalAlignment: Text.AlignHCenter
              textFormat: Text.PlainText
            }

            Repeater {
              model: root.bluetoothPowered() ? root.bluetoothDevices().slice(0, 10) : []

              Rectangle {
                readonly property string actionText: root.bluetoothActionText(modelData)
                readonly property bool active: modelData.connected
                readonly property bool usable: root.bluetoothPowered() && !root.bluetoothDeviceBusy(modelData) && !modelData.blocked

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
                    text: root.bluetoothDeviceName(modelData)
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
        id: batteryPopup

        visible: root.batteryPopupOpen && root.popupScreen === modelData
        implicitWidth: 340
        implicitHeight: batteryPopupShell.implicitHeight
        color: "transparent"
        grabFocus: true

        onVisibleChanged: {
          if (!visible && root.popupScreen === modelData) {
            root.batteryPopupOpen = false;
          }
        }

        anchor {
          item: batteryPill
          edges: Edges.Bottom | Edges.Right
          gravity: Edges.Bottom | Edges.Left
          adjustment: PopupAdjustment.Slide | PopupAdjustment.FlipY
          margins.top: 18
        }

        surfaceFormat {
          opaque: false
        }

        Rectangle {
          id: batteryPopupShell

          implicitWidth: 340
          implicitHeight: batteryPopupContent.implicitHeight + 16
          color: root.backgroundStrong
          border.color: root.primary
          border.width: 1
          radius: 8

          Column {
            id: batteryPopupContent

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
                text: "Battery"
                color: root.foreground
                elide: Text.ElideRight
                font.family: root.fontFamily
                font.pixelSize: 13
                font.bold: true
                textFormat: Text.PlainText
              }

              Text {
                text: root.batteryStateText()
                color: root.batteryForeground()
                font.family: root.fontFamily
                font.pixelSize: 12
                font.bold: true
                textFormat: Text.PlainText
              }
            }

            Rectangle {
              width: parent.width
              height: 72
              color: root.background
              border.color: root.activeBackground
              border.width: 1
              radius: 7

              Text {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.leftMargin: 12
                anchors.topMargin: 10
                text: root.batteryPercent() + "%"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: 22
                font.bold: true
                textFormat: Text.PlainText
              }

              Text {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: 12
                anchors.topMargin: 13
                text: root.batteryIcon()
                color: root.batteryForeground()
                font.family: root.fontFamily
                font.pixelSize: 20
                font.bold: true
                textFormat: Text.PlainText
              }

              Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                anchors.bottomMargin: 12
                height: 8
                color: root.backgroundStrong
                radius: 4

                Rectangle {
                  anchors.left: parent.left
                  anchors.top: parent.top
                  anchors.bottom: parent.bottom
                  width: parent.width * root.batteryPercent() / 100
                  color: root.batteryForeground()
                  radius: 4
                }
              }
            }

            RowLayout {
              width: parent.width
              height: 20
              spacing: 8

              Text {
                Layout.fillWidth: true
                text: "Power"
                color: root.muted
                font.family: root.fontFamily
                font.pixelSize: 12
                textFormat: Text.PlainText
              }

              Text {
                text: root.batteryRateText()
                color: root.primary
                font.family: root.fontFamily
                font.pixelSize: 12
                font.bold: true
                textFormat: Text.PlainText
              }
            }

            RowLayout {
              width: parent.width
              height: 20
              spacing: 8

              Text {
                Layout.fillWidth: true
                text: "Time"
                color: root.muted
                font.family: root.fontFamily
                font.pixelSize: 12
                textFormat: Text.PlainText
              }

              Text {
                text: root.batteryTimeText()
                color: root.primary
                font.family: root.fontFamily
                font.pixelSize: 12
                font.bold: true
                textFormat: Text.PlainText
              }
            }

            RowLayout {
              width: parent.width
              height: 20
              spacing: 8

              Text {
                Layout.fillWidth: true
                text: "Energy"
                color: root.muted
                font.family: root.fontFamily
                font.pixelSize: 12
                textFormat: Text.PlainText
              }

              Text {
                text: root.batteryEnergyText()
                color: root.primary
                font.family: root.fontFamily
                font.pixelSize: 12
                font.bold: true
                textFormat: Text.PlainText
              }
            }

            RowLayout {
              visible: root.batteryHealthText() !== ""
              width: parent.width
              height: 20
              spacing: 8

              Text {
                Layout.fillWidth: true
                text: "Health"
                color: root.muted
                font.family: root.fontFamily
                font.pixelSize: 12
                textFormat: Text.PlainText
              }

              Text {
                text: root.batteryHealthText()
                color: root.primary
                font.family: root.fontFamily
                font.pixelSize: 12
                font.bold: true
                textFormat: Text.PlainText
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

      PopupWindow {
        id: notificationCenterPopup

        visible: root.notificationCenterOpen && root.popupScreen === modelData
        implicitWidth: 420
        implicitHeight: Math.min(notificationCenterStack.implicitHeight, Math.max(0, modelData.height - 72))
        color: "transparent"
        grabFocus: true

        onVisibleChanged: {
          if (!visible && root.popupScreen === modelData) {
            root.closeNotificationCenter();
          }
        }

        anchor {
          item: notificationPopupAnchor
          edges: Edges.Top | Edges.Right
          gravity: Edges.Top | Edges.Right
          adjustment: PopupAdjustment.Slide | PopupAdjustment.FlipY
          margins.top: 50
          margins.right: 0
        }

        surfaceFormat {
          opaque: false
        }

        Flickable {
          anchors.fill: parent
          contentHeight: notificationCenterStack.implicitHeight
          clip: true
          interactive: notificationCenterStack.implicitHeight > height

          Column {
            id: notificationCenterStack

            width: parent.width
            spacing: 6

            Rectangle {
              width: parent.width
              height: 28
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
                  color: centerDndArea.containsMouse ? root.foreground : (root.notificationsDnd ? root.muted : root.primary)
                  font.family: root.fontFamily
                  font.pixelSize: 12
                  font.bold: true
                  textFormat: Text.PlainText

                  MouseArea {
                    id: centerDndArea

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
                  color: centerClearArea.containsMouse ? root.foreground : root.primary
                  font.family: root.fontFamily
                  font.pixelSize: 12
                  font.bold: true
                  textFormat: Text.PlainText

                  MouseArea {
                    id: centerClearArea

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
              visible: root.notificationCount === 0
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
              model: root.notificationGroups()

              Column {
                id: notificationGroup

                readonly property var group: modelData
                readonly property var latestNotification: group.notifications.length > 0 ? group.notifications[0] : null
                readonly property bool expandable: group.notifications.length > 1
                readonly property bool expanded: root.notificationGroupExpanded(group.key)

                width: notificationCenterStack.width
                spacing: 5

                Rectangle {
                  width: parent.width
                  height: 28
                  visible: notificationGroup.expanded
                  color: root.activeBackground
                  border.color: modelData.critical ? root.danger : root.primary
                  border.width: 1
                  radius: 8

                  MouseArea {
                    id: groupToggleArea

                    anchors.fill: parent
                    enabled: notificationGroup.expandable
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.toggleNotificationGroup(notificationGroup.group)
                  }

                  RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 8
                    spacing: 8

                    Text {
                      Layout.fillWidth: true
                      text: modelData.appName
                      color: root.foreground
                      elide: Text.ElideRight
                      font.family: root.fontFamily
                      font.pixelSize: 12
                      font.bold: true
                      textFormat: Text.PlainText
                    }

                    Text {
                      text: modelData.notifications.length === 1 ? "1 item" : modelData.notifications.length + " items"
                      color: modelData.critical ? root.danger : root.muted
                      font.family: root.fontFamily
                      font.pixelSize: 11
                      font.bold: true
                      textFormat: Text.PlainText
                    }

                    Text {
                      text: notificationGroup.expanded ? "collapse" : "expand"
                      color: groupToggleArea.containsMouse ? root.foreground : root.primary
                      font.family: root.fontFamily
                      font.pixelSize: 11
                      font.bold: true
                      textFormat: Text.PlainText
                    }

                    Text {
                      text: "clear"
                      color: groupClearArea.containsMouse ? root.foreground : root.primary
                      font.family: root.fontFamily
                      font.pixelSize: 11
                      font.bold: true
                      textFormat: Text.PlainText

                      MouseArea {
                        id: groupClearArea

                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        onClicked: root.dismissNotificationGroup(modelData)
                      }
                    }
                  }
                }

                Rectangle {
                  id: collapsedGroupCard

                  visible: notificationGroup.expandable && !notificationGroup.expanded
                  width: parent.width
                  height: visible ? Math.max(74, collapsedGroupContent.implicitHeight + 18) : 0
                  color: root.background
                  border.color: modelData.critical ? root.danger : root.primary
                  border.width: 1
                  radius: 8

                  MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                      if (mouse.button === Qt.RightButton) {
                        root.dismissNotificationGroup(notificationGroup.group);
                      } else {
                        root.toggleNotificationGroup(notificationGroup.group);
                      }
                    }
                  }

                  ColumnLayout {
                    id: collapsedGroupContent

                    anchors.fill: parent
                    anchors.margins: 9
                    spacing: 4

                    RowLayout {
                      Layout.fillWidth: true
                      spacing: 8

                      Text {
                        Layout.fillWidth: true
                        text: modelData.appName
                        color: root.muted
                        elide: Text.ElideRight
                        font.family: root.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        textFormat: Text.PlainText
                      }

                      Text {
                        text: modelData.notifications.length + " grouped"
                        color: modelData.critical ? root.danger : root.primary
                        font.family: root.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        textFormat: Text.PlainText
                      }

                      Text {
                        text: "clear"
                        color: collapsedGroupClearArea.containsMouse ? root.foreground : root.primary
                        font.family: root.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        textFormat: Text.PlainText

                        MouseArea {
                          id: collapsedGroupClearArea

                          anchors.fill: parent
                          anchors.margins: -6
                          hoverEnabled: true
                          onClicked: root.dismissNotificationGroup(modelData)
                        }
                      }
                    }

                    Text {
                      Layout.fillWidth: true
                      text: notificationGroup.latestNotification ? notificationGroup.latestNotification.summary : ""
                      color: root.foreground
                      elide: Text.ElideRight
                      font.family: root.fontFamily
                      font.pixelSize: 14
                      font.bold: true
                      maximumLineCount: 1
                      textFormat: Text.PlainText
                    }

                    Text {
                      Layout.fillWidth: true
                      visible: text !== ""
                      text: notificationGroup.latestNotification ? notificationGroup.latestNotification.body : ""
                      color: root.foreground
                      elide: Text.ElideRight
                      font.family: root.fontFamily
                      font.pixelSize: 13
                      maximumLineCount: 2
                      opacity: 0.84
                      textFormat: Text.PlainText
                      wrapMode: Text.Wrap
                    }
                  }
                }

                Repeater {
                  model: notificationGroup.expanded || !notificationGroup.expandable ? notificationGroup.group.notifications : []

                  NotificationCard {
                    width: notificationGroup.width
                    height: implicitHeight
                    notification: modelData
                    autoHide: false
                    centerMode: true
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
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: toastWindow

      required property var modelData

      screen: modelData
      visible: !root.notificationCenterOpen && root.toastNotifications.length > 0
      implicitWidth: 420
      implicitHeight: Math.min(toastStack.implicitHeight, screen.height - 72)
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
        contentHeight: toastStack.implicitHeight
        clip: true
        interactive: toastStack.implicitHeight > height

        Column {
          id: toastStack

          width: parent.width
          spacing: 6

          Repeater {
            model: toastModel

            NotificationCard {
              notification: modelData
              autoHide: true
              centerMode: false
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
