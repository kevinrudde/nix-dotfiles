import QtQuick

Rectangle {
  id: root

  property string text: ""
  property color foreground: "#96d8ff"
  property color background: Qt.rgba(21 / 255, 18 / 255, 27 / 255, 0.82)
  property color hoverBackground: Qt.rgba(150 / 255, 216 / 255, 255 / 255, 0.20)
  property color borderColor: "#96d8ff"
  property string fontFamily: "JetBrains Mono"
  property int fontSize: 14
  property int horizontalPadding: 10
  property int minPillWidth: 18
  property int maxTextWidth: 260
  readonly property int textWidthLimit: Math.max(0, maxTextWidth)
  readonly property int labelNaturalWidth: Math.ceil(fontMetrics.advanceWidth(text))

  signal clicked(var mouse)
  signal wheel(var wheel)

  implicitWidth: Math.max(minPillWidth, Math.min(labelNaturalWidth, textWidthLimit) + horizontalPadding * 2)
  implicitHeight: 28
  clip: true
  color: buttonArea.containsMouse ? hoverBackground : background
  border.color: borderColor
  border.width: 1
  radius: 8

  Text {
    id: label

    anchors.centerIn: parent
    width: Math.min(root.labelNaturalWidth, root.textWidthLimit)
    clip: true
    text: root.text
    color: root.foreground
    elide: Text.ElideRight
    font.bold: true
    font.family: root.fontFamily
    font.pixelSize: root.fontSize
    horizontalAlignment: Text.AlignHCenter
    textFormat: Text.PlainText
    verticalAlignment: Text.AlignVCenter
  }

  FontMetrics {
    id: fontMetrics

    font.bold: true
    font.family: root.fontFamily
    font.pixelSize: root.fontSize
  }

  MouseArea {
    id: buttonArea

    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    hoverEnabled: true
    onClicked: mouse => root.clicked(mouse)
    onWheel: wheel => root.wheel(wheel)
  }
}
