import QtQuick
import qs

// Text with the shell's defaults applied. Plain text on purpose: notification
// bodies and window titles are untrusted input and must not render markup.
Text {
    color: Theme.foreground
    font.bold: true
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSizeSmall
    textFormat: Text.PlainText
}
