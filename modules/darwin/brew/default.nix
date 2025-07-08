{ pkgs
, ...
}: {
  # Homebrew configuration for packages not available or problematic in Nix on Darwin
  # Priority: Always try Nix first, use Homebrew as fallback
  # 
  # Use Homebrew when:
  # - Package not available in nixpkgs for Darwin
  # - Package exists but doesn't work properly (GUI apps, system integrations)
  # - Package requires system-level permissions or integrations
  # - Package is proprietary and not redistributable through Nix

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };

    taps = [
      "aws/tap"
    ];

    # CLI tools not available or problematic in Nix
    brews = [
      "docker-credential-helper"
      "argocd"
      "mysql-client"
      "television"
    ];

    # GUI applications and system integrations
    casks = [
      "orbstack"            # Container management (better than Nix version)
      "hammerspoon"         # macOS automation (requires system access)
      "gitify"              # GitHub notifications (GUI app)
      "sourcetree"          # Git GUI client (not available in nixpkgs)
      "tailscale-app"       # Tailscale GUI+CLI (official macOS app, prevents conflicts with Nix version)
    ];
  };
}
