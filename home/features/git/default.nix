{ pkgs, ... }: {

  home.packages = with pkgs; [
    delta
  ];

  programs.git = {
    enable = true;
    package = pkgs.git;
    lfs = {
      enable = true;
    };

    signing.key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCoDDDhao2sZNI8bkouzh0J21uSWRNUvKfHhsliR8U1oPKs8r7xSovTgY2Ex7cSmoDfOj5xBvocgE/QWGwPso9QibNv7+DgaFALtofcjiUr53CVxym7vFwAOseiydjQHhrvYZuRBLe+bcUKByA3oN9yBNSJYP5a2owJNLzdnOSQBWcVQdHuUtgyZqYL2In1e0xuhETsZWznOaZyrFrRIKoknPRbZvnhLgN0L/U+t0mjRczkj1SxBKKQW6DqGdeSrPo+KFFxGcrciQTkLotthnGtv/J3z+NQvWNsJBYDU7rrooL6xA0//m1+P9e1K4u5coAwSb6DTDfEhos5G/PC+03J";
    signing.signByDefault = true;

    settings = {
      user = {
        email = "k.rudde@shopware.com";
        name = "Kevin Rudde";
      };
      push.autoSetupRemote = true;
      init.defaultBranch = "main";
      pull.rebase = true;
      rebase.autoStash = true;
      push.default = "simple";
      fetch.prune = true;

      gpg.format = "ssh";
      url."git@github.com:".insteadOf = "https://github.com";
    };
  };

  programs.lazygit = {
    enable = true;
    settings = {
      promptToReturnFromSubprocess = false;
      git = {
        overrideGpg = true;
        pagers = [
          {
            colorArg = "always";
            pager = "delta --dark --paging=never";
          }
        ];
      };
    };
  };

  home.file = {
    ".ssh/allowed_signers".text = "k.rudde@shopware.com namespaces=\"git\" ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCoDDDhao2sZNI8bkouzh0J21uSWRNUvKfHhsliR8U1oPKs8r7xSovTgY2Ex7cSmoDfOj5xBvocgE/QWGwPso9QibNv7+DgaFALtofcjiUr53CVxym7vFwAOseiydjQHhrvYZuRBLe+bcUKByA3oN9yBNSJYP5a2owJNLzdnOSQBWcVQdHuUtgyZqYL2In1e0xuhETsZWznOaZyrFrRIKoknPRbZvnhLgN0L/U+t0mjRczkj1SxBKKQW6DqGdeSrPo+KFFxGcrciQTkLotthnGtv/J3z+NQvWNsJBYDU7rrooL6xA0//m1+P9e1K4u5coAwSb6DTDfEhos5G/PC+03J";
  };
}
