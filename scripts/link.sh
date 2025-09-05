#!/usr/bin/env bash
set -euo pipefail

root_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

backup() {
  local target="$1"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    mv -v "$target" "${target}.bak"
  fi
}

link_dir() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  backup "$dst"
  ln -sfn "$src" "$dst"
  echo "linked: $dst -> $src"
}

echo "Linking configs from $root_dir/dotfiles"

link_dir "$root_dir/dotfiles/hypr"        "$HOME/.config/hypr"
link_dir "$root_dir/dotfiles/waybar"      "$HOME/.config/waybar"
link_dir "$root_dir/dotfiles/mako"        "$HOME/.config/mako"
link_dir "$root_dir/dotfiles/rofi"        "$HOME/.config/rofi"
link_dir "$root_dir/dotfiles/yazi"        "$HOME/.config/yazi"
link_dir "$root_dir/dotfiles/alacritty"   "$HOME/.config/alacritty"

# zsh is a single file
backup "$HOME/.zshrc"
ln -sfn "$root_dir/dotfiles/zsh/.zshrc" "$HOME/.zshrc"
echo "linked: $HOME/.zshrc -> $root_dir/dotfiles/zsh/.zshrc"

mkdir -p "$HOME/.wallpapers" "$HOME/Screenshots"
echo "Ensure a wallpaper at: $HOME/.wallpapers/wall.jpg"

echo "All set. Start Hyprland (tty: 'Hyprland', or via uwsm)."
