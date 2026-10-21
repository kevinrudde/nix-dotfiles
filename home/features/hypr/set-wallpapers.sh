root="$HOME/Pictures/Wallpapers"
config="${XDG_RUNTIME_DIR:-/tmp}/hyprpaper.conf"

command -v hyprpaper >/dev/null || exit 0

pick() {
  find -L "$root/$1" -maxdepth 1 -type f \
    \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
    2>/dev/null | shuf -n 1
}

{
  echo "splash = false"
  hyprctl monitors all -j | jq -r '.[] | "\(.name) \(.width)x\(.height)"' |
    while read -r output resolution; do
      image=$(pick "$resolution")
      [ -n "$image" ] || continue
      printf 'wallpaper {\n    monitor = %s\n    path = %s\n    fit_mode = cover\n}\n' "$output" "$image"
    done
} >"$config"

pkill -x hyprpaper || true
exec hyprpaper --config "$config"
