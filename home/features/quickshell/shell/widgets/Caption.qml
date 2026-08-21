import qs

// Small uppercase heading above one section of a popup. Quieter than
// SectionHeader on purpose — a combined popup has several short sections and a
// full header row per section would outweigh the content under it.
StyledText {
    id: root

    property string label: ""

    text: root.label.toUpperCase()
    color: Theme.muted
    font.bold: true
    font.pixelSize: Theme.fontSizeTiny
    font.letterSpacing: 1
}
