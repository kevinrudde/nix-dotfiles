#!/bin/bash

sudo dnf install ninja-build cmake meson gcc-c++ libxcb-devel libX11-devel pixman-devel wayland-protocols-devel cairo-devel pango-devel
mkdir -p /tmp/hyprland
git clone --recursive https://github.com/hyprwm/Hyprland /tmp/hyprland
cd /tmp/hyprland
make all
sudo make install

