pragma Singleton

// Everything the shell shells out for. Detached on purpose: the shell must not
// keep a child process alive for a launcher or a power menu.
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    function run(command: string): void {
        actionProc.command = ["sh", "-c", command];
        actionProc.startDetached();
        SystemStatus.refreshSoon();
    }

    function launcher(): void {
        root.run("uwsm app -- fuzzel");
    }

    function powerMenu(): void {
        root.run(Quickshell.shellDir + "/scripts/power-menu.sh");
    }

    function brightnessStep(up: bool): void {
        root.run(up ? "brightnessctl set 5%+" : "brightnessctl set 5%-");
    }

    Process {
        id: actionProc
    }
}
