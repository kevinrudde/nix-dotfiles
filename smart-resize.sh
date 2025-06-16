#!/bin/bash

# Smart resize script for AeroSpace
# Detects terminal and applies appropriate sizing

# Add some delay to ensure AeroSpace state is stable
sleep 0.1

# Get current workspace
WORKSPACE=$(aerospace list-workspaces --focused)
WINDOW_COUNT=$(aerospace list-windows --workspace "$WORKSPACE" --count)

# Debug logging
echo "$(date): Smart resize triggered" >> /tmp/smart-resize.log
echo "$(date): Workspace: '$WORKSPACE', Windows: '$WINDOW_COUNT'" >> /tmp/smart-resize.log

# Only apply auto-sizing if there are 2+ windows
if [ "$WINDOW_COUNT" -ge 2 ]; then
    # Check if WezTerm is present in this workspace
    WEZTERM_COUNT=$(aerospace list-windows --workspace "$WORKSPACE" --app-bundle-id "com.github.wez.wezterm" --count)
    
    echo "$(date): WezTerm count: $WEZTERM_COUNT" >> /tmp/smart-resize.log
    
    if [ "$WEZTERM_COUNT" -gt 0 ]; then
        # Terminal present: Give it smaller portion (1/3)
        echo "$(date): Applying terminal resize (2/3-1/3 split)" >> /tmp/smart-resize.log
        aerospace balance-sizes --workspace "$WORKSPACE"
        sleep 0.1
        
        # Find and resize terminal window to be smaller
        WEZTERM_ID=$(aerospace list-windows --workspace "$WORKSPACE" --app-bundle-id "com.github.wez.wezterm" --format "%{window-id}" | head -1)
        if [ -n "$WEZTERM_ID" ]; then
            aerospace resize --window-id "$WEZTERM_ID" width -400
            echo "$(date): Resized WezTerm $WEZTERM_ID" >> /tmp/smart-resize.log
        fi
    else
        # No terminal: Just balance everything equally
        echo "$(date): No terminal found, balancing equally" >> /tmp/smart-resize.log
        aerospace balance-sizes --workspace "$WORKSPACE"
    fi
else
    echo "$(date): Less than 2 windows ($WINDOW_COUNT), no resize needed" >> /tmp/smart-resize.log
fi

echo "$(date): Smart resize completed" >> /tmp/smart-resize.log 