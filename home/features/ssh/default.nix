{ config
, pkgs
, ...
}: {
  # ssh-agent is a systemd user service, so it only exists on Linux. macOS uses
  # the launchd-managed agent that ships with the system.
  services.ssh-agent.enable = pkgs.stdenv.hostPlatform.isLinux;

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # Private hosts live in the sops-encrypted `ssh_hosts` secret so they can be
    # committed to a public repo. The Include is emitted above every match block,
    # so entries in there win (ssh keeps the first value it sees) while the
    # `Host *` defaults below still apply. A missing file is ignored by ssh, so
    # this is safe before the secret is first activated.
    includes = [ config.sops.secrets.ssh_hosts.path ];

    settings."*" = {
      AddKeysToAgent = "yes";
      # TERM is the one variable exempt from the server's AcceptEnv allowlist
      # (see ssh_config(5)), so this works everywhere without server changes.
      SetEnv.TERM = "xterm-256color";
    };
  };
}
