{ pkgs, ... }: {
  programs.ssh = {
    enable = true;
    
    # Add the SSH configuration with the user's requested settings
    extraConfig = ''
      Host *
        IdentityFile ~/.ssh/id_ed25519
        AddKeysToAgent yes
        SetEnv TERM=xterm-256color
        TCPKeepAlive yes
        ServerAliveInterval 60
        ServerAliveCountMax 1200
    '';
    
    # Optional: Add common SSH settings for better security and usability
    forwardAgent = false;
    compression = true;
    
    # You can also add specific host configurations here if needed
    # matchBlocks = {
    #   "example.com" = {
    #     hostname = "example.com";
    #     user = "username";
    #     port = 22;
    #   };
    # };
  };
} 