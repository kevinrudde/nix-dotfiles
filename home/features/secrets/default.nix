{ sops
, config
, pkgs
, ...
}: {
  sops = {
    age.keyFile = "${
    if pkgs.stdenv.hostPlatform.isDarwin
    then "/Users/C.Hessel/Library/Application Support/sops/age/keys.txt"
    else "/home/C.Hessel/.config/sops/age/keys.txt"
    }";

    defaultSopsFile = ./secrets.yaml;

    secrets.ssh_key = {
      path = "${config.home.homeDirectory}/.ssh/id_ed225519";
      format = "yaml";
      mode = "0600";
    };
  };

}
