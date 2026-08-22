{ sops
, config
, pkgs
, ...
}: {
  sops = {
    age.keyFile = "${
    if pkgs.stdenv.hostPlatform.isDarwin
    then "/Users/kevin/Library/Application Support/sops/age/keys.txt"
    else "/home/kevin/.config/sops/age/keys.txt"
    }";

    defaultSopsFile = ./secrets.yaml;

    secrets.ssh_key = {
      path = "${config.home.homeDirectory}/.ssh/id_rsa";
      format = "yaml";
      mode = "0600";
    };

    # Private `Host` entries, pulled into ~/.ssh/config via an Include in
    # home/features/ssh. Left at the default symlink path so the ssh module can
    # reference `config.sops.secrets.ssh_hosts.path` instead of hardcoding it.
    secrets.ssh_hosts = {
      format = "yaml";
      mode = "0600";
    };
  };

}
