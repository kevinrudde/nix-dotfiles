{ pkgs
, ...
}: {

  programs.tmux = {
    enable = true;
    
    # Use more modern prefix key (Ctrl+A instead of Ctrl+B)
    prefix = "C-a";
    
    # Enable mouse support for modern workflows
    mouse = true;
    
    # Use vi-style key bindings
    keyMode = "vi";
    
    # Start window and pane numbering at 1 (easier to reach)
    baseIndex = 1;
    
    # Enable 256 color support
    terminal = "tmux-256color";
    
    # Increase scrollback buffer
    historyLimit = 10000;
    
    # Custom key bindings
    extraConfig = ''
      # Reload config with r
      bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"
      
      # Split panes using | and -
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      unbind '"'
      unbind %
      
      # Switch panes using Alt-arrow without prefix
      bind -n M-Left select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up select-pane -U
      bind -n M-Down select-pane -D
      
      # Switch windows using Shift-arrow without prefix
      bind -n S-Left previous-window
      bind -n S-Right next-window
      
      # Don't rename windows automatically
      set-option -g allow-rename off
      
      # Enable activity alerts
      setw -g monitor-activity on
      set -g visual-activity on
      
      # No delay for escape key press
      set -sg escape-time 0
      
      # Status bar styling
      set -g status-bg colour235
      set -g status-fg colour255
      set -g status-left-length 20
      set -g status-right-length 55
      set -g status-left '#[fg=colour16,bg=colour254,bold] #S #[fg=colour254,bg=colour235,nobold]'
      set -g status-right '#[fg=colour255,bg=colour235] %d %b #[fg=colour255,bg=colour235]%R '
      
      # Window status styling
      setw -g window-status-format '#[fg=colour235,bg=colour235]#[default] #I #W #[fg=colour235,bg=colour235]'
      setw -g window-status-current-format '#[fg=colour235,bg=colour39]#[fg=colour16,bg=colour39,bold] #I #W #[fg=colour39,bg=colour235,nobold]'
      
      # Pane border styling
      set -g pane-border-style fg=colour238
      set -g pane-active-border-style fg=colour39
      
      # Copy mode improvements
      bind-key -T copy-mode-vi 'v' send -X begin-selection
      bind-key -T copy-mode-vi 'y' send -X copy-selection-and-cancel
      
      # Create new window in current path
      bind c new-window -c "#{pane_current_path}"
    '';
  };

}
