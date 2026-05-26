import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

Rectangle {
  id: card

  property var notification
  property bool autoHide: true
  property bool centerMode: false
  property color primary: "#96d8ff"
  property color background: Qt.rgba(21 / 255, 18 / 255, 27 / 255, 0.92)
  property color backgroundStrong: Qt.rgba(10 / 255, 10 / 255, 16 / 255, 0.96)
  property color foreground: "#d9e4ff"
  property color muted: "#6f7285"
  property color warning: "#ffd166"
  property color danger: "#ff5874"
  property string fontFamily: "JetBrains Mono"

  signal dismissed(var notification)

  function actionText(action) {
    if (!action || !action.text) {
      return "";
    }

    return String(action.text).trim();
  }

  function hasVisibleActions(actions) {
    if (!actions) {
      return false;
    }

    for (let index = 0; index < actions.length; index += 1) {
      if (card.actionText(actions[index]) !== "") {
        return true;
      }
    }

    return false;
  }

  function defaultAction() {
    const actions = card.notification ? card.notification.actions : null;

    if (!actions) {
      return null;
    }

    for (let index = 0; index < actions.length; index += 1) {
      if (actions[index].identifier === "default") {
        return actions[index];
      }
    }

    for (let index = 0; index < actions.length; index += 1) {
      if (card.actionText(actions[index]) === "") {
        return actions[index];
      }
    }

    return null;
  }

  function invokeDefaultAction() {
    const action = card.defaultAction();

    if (!action) {
      return;
    }

    action.invoke();
    card.dismissed(card.notification);
  }

  implicitWidth: 420
  implicitHeight: content.implicitHeight + 16
  color: notification && notification.urgency === NotificationUrgency.Critical ? Qt.rgba(255 / 255, 88 / 255, 116 / 255, 0.13) : background
  border.color: notification && notification.urgency === NotificationUrgency.Critical ? danger : Qt.rgba(150 / 255, 216 / 255, 255 / 255, 0.78)
  border.width: 1
  radius: 8

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton
    cursorShape: card.defaultAction() ? Qt.PointingHandCursor : Qt.ArrowCursor
    hoverEnabled: true
    onClicked: card.invokeDefaultAction()
  }

  ColumnLayout {
    id: content

    anchors.fill: parent
    anchors.margins: 8
    spacing: 5

    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      Text {
        Layout.fillWidth: true
        text: card.notification ? (card.notification.appName || "Notification") : "Notification"
        color: card.muted
        elide: Text.ElideRight
        font.family: card.fontFamily
        font.pixelSize: 11
        font.bold: true
        opacity: 0.86
        textFormat: Text.PlainText
      }

      Text {
        text: card.notification && card.notification.urgency === NotificationUrgency.Critical ? "critical" : ""
        visible: text !== ""
        color: card.danger
        font.family: card.fontFamily
        font.pixelSize: 11
        font.bold: true
        textFormat: Text.PlainText
      }

      Text {
        text: "x"
        color: closeArea.containsMouse ? card.foreground : card.muted
        font.family: card.fontFamily
        font.pixelSize: 13
        font.bold: true

        MouseArea {
          id: closeArea

          anchors.fill: parent
          anchors.margins: -6
          hoverEnabled: true
          onClicked: card.dismissed(card.notification)
        }
      }
    }

    Text {
      Layout.fillWidth: true
      text: card.notification ? card.notification.summary : ""
      color: card.foreground
      elide: Text.ElideRight
      font.family: card.fontFamily
      font.pixelSize: 13
      font.bold: true
      maximumLineCount: 2
      textFormat: Text.PlainText
      wrapMode: Text.Wrap
    }

    Text {
      Layout.fillWidth: true
      visible: text !== ""
      text: card.notification ? card.notification.body : ""
      color: card.foreground
      elide: Text.ElideRight
      font.family: card.fontFamily
      font.pixelSize: 12
      maximumLineCount: card.centerMode ? 6 : 3
      opacity: 0.84
      textFormat: Text.PlainText
      wrapMode: Text.Wrap
    }

    Row {
      Layout.fillWidth: true
      Layout.preferredHeight: visible ? implicitHeight : 0
      visible: card.notification && card.hasVisibleActions(card.notification.actions)
      spacing: 6

      Repeater {
        model: card.notification ? card.notification.actions : []

        Rectangle {
          readonly property string label: card.actionText(modelData)

          visible: label !== ""
          implicitWidth: visible ? actionLabel.implicitWidth + 16 : 0
          implicitHeight: visible ? 22 : 0
          color: actionArea.containsMouse ? Qt.rgba(150 / 255, 216 / 255, 255 / 255, 0.20) : card.backgroundStrong
          border.color: card.primary
          border.width: 1
          radius: 7

          Text {
            id: actionLabel

            anchors.centerIn: parent
            text: parent.label
            color: card.primary
            elide: Text.ElideRight
            font.family: card.fontFamily
            font.pixelSize: 11
            font.bold: true
            textFormat: Text.PlainText
          }

          MouseArea {
            id: actionArea

            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
              if (parent.label !== "") {
                modelData.invoke();
                card.dismissed(card.notification);
              }
            }
          }
        }
      }
    }
  }
}
