{ pkgs, ... }:

{
  home.packages = [
    (pkgs.writeShellScriptBin "container-engine" (builtins.readFile ./container-engine.sh))
  ];

  # Published ports bind to loopback unless -p names a host IP explicitly.
  xdg.configFile."containers/containers.conf".text = ''
    [network]
    default_host_ips = ["127.0.0.1", "::1"]
  '';

  # kind and other tools pick their provider from the environment. Mirror the
  # engine chosen by `container-engine` into every fish session, and refresh it
  # right after a switch so no new shell is needed. Resolving kind through
  # mise shims makes a PATH wrapper unreliable, hence the exported variable.
  programs.fish.functions = {
    __container_engine_env = ''
      if test (cat ~/.local/state/container-engine 2>/dev/null) = podman
        set -gx KIND_EXPERIMENTAL_PROVIDER podman
        set -gx CONTAINER_RUNTIME podman
      else
        set -e KIND_EXPERIMENTAL_PROVIDER
        set -e CONTAINER_RUNTIME
      end
    '';

    container-engine = ''
      command container-engine $argv
      and __container_engine_env
    '';
  };

  programs.fish.shellInit = "__container_engine_env";
}
