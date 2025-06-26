{ pkgs
, remapKeys
, ...
}: {
  system.defaults.dock = {
    autohide = true;
    autohide-delay = 0.0;

    autohide-time-modifier = 0.2;
    expose-animation-duration = 0.2;
    tilesize = 48;
    launchanim = false;
    static-only = false;
    showhidden = true;
    show-recents = false;
    show-process-indicators = true;
    orientation = "bottom";
    mru-spaces = false;
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  system.keyboard = {
    enableKeyMapping = true;
    swapLeftCommandAndLeftAlt = remapKeys;

    # use https://hidutil-generator.netlify.app/ and convert hex to decimal
    userKeyMapping = [
      {
        HIDKeyboardModifierMappingSrc = 30064771300;
        HIDKeyboardModifierMappingDst = 30064771302;
      }
    ];
  };

  system.defaults = {
    NSGlobalDomain.AppleShowAllExtensions = true;
    NSGlobalDomain.NSWindowShouldDragOnGesture = true;
    WindowManager.EnableStandardClickToShowDesktop = false;
    finder.AppleShowAllExtensions = true;
    finder._FXShowPosixPathInTitle = true;
    finder.FXEnableExtensionChangeWarning = false;
    NSGlobalDomain."com.apple.swipescrolldirection" = false;
  };

  system.defaults.CustomUserPreferences = {
    "com.apple.finder" = {
      ShowExternalHardDrivesOnDesktop = true;
      ShowHardDrivesOnDesktop = true;
      ShowMountedServersOnDesktop = true;
      ShowRemovableMediaOnDesktop = true;
      _FXSortFoldersFirst = true;
      # When performing a search, search the current folder by default
      FXDefaultSearchScope = "SCcf";
    };
    "com.apple.desktopservices" = {
      # Avoid creating .DS_Store files on network or USB volumes
      DSDontWriteNetworkStores = true;
      DSDontWriteUSBStores = true;
    };
    "com.apple.spaces" = {
      # Disable displays from spanning across multiple desktops/spaces
      # 
      # This prevents windows from spanning across monitors when using Mission Control
      # or desktop spaces, which is essential for proper AeroSpace window management.
      # AeroSpace assigns specific workspaces to specific monitors (see ../aerospace/default.nix)
      # and spans-displays interferes with this by allowing windows to stretch across displays.
      #
      # Equivalent to: defaults write com.apple.spaces spans-displays -bool false && killall SystemUIServer
      # ⚠️ IMPORTANT: Requires logout to take effect after first installation
      spans-displays = false;
    };
    "com.apple.AdLib" = {
      allowApplePersonalizedAdvertising = false;
    };
    "com.apple.SoftwareUpdate" = {
      AutomaticCheckEnabled = true;
      ScheduleFrequency = 1;
      AutomaticDownload = 1;
      CriticalUpdateInstall = 0;
    };
    "com.apple.ImageCapture".disableHotPlug = true;
    "com.apple.commerce".AutoUpdate = true;
  };
}
