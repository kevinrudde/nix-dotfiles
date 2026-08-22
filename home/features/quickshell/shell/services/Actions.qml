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

    // hyperion runs vicinae (home/features/vicinae), where this is a one-shot IPC
    // call into the daemon and so wants no uwsm app scope of its own; every other
    // host is still on fuzzel. Mirrors the launcher bind in
    // systems/shared/hypr/conf/bindings.lua, which the host picks via HL_LAUNCHER.
    function launcher(): void {
        root.run(Quickshell.env("DOTFILES_HOST") === "hyperion" ? "vicinae toggle" : "uwsm app -- fuzzel");
    }

    function powerMenu(): void {
        root.run(Quickshell.shellDir + "/scripts/power-menu.sh");
    }

    function brightnessStep(up: bool): void {
        root.run(up ? "brightnessctl set 5%+" : "brightnessctl set 5%-");
    }

    // Array form rather than a shell string: a URL is untrusted enough (it
    // comes back from an API response) that it should never be interpolated
    // into something a shell parses.
    function openUrl(url: string): void {
        Quickshell.execDetached(["xdg-open", url]);
    }

    Process {
        id: actionProc
    }
}
