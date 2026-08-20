import QtQuick
import Quickshell
import qs.widgets

// Date and time. Its own SystemClock rather than a field on the status
// script's JSON: the string changes once a minute, and Quickshell ticks it
// with no process at all where the script cost a bash + nmcli + jq pipeline
// every two seconds to keep it current.
Pill {
    // en_US rather than the system locale, so the month stays the three ASCII
    // letters `maxTextWidth` below is measured against.
    //
    // Uppercased for the reason status.sh used `%^b`: a lowercase month
    // abbreviation is the only part of this string with a descender ("Aug"'s
    // g), which pulls the shared text baseline down and makes the digits
    // either side of it read as sitting above true centre even though the
    // string as a whole measures centred.
    text: clock.date.toLocaleString(Qt.locale("en_US"), "dd MMM HH:mm").toUpperCase()
    maxTextWidth: 110

    SystemClock {
        id: clock

        // The displayed string has no seconds in it, so waking once a minute
        // is not an approximation — it is every change there is.
        precision: SystemClock.Minutes
    }
}
