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
link_dir "$root_dir/dotfiles/ghostty"     "$HOME/.config/ghostty"
link_dir "$root_dir/dotfiles/zathura"     "$HOME/.config/zathura"
link_dir "$root_dir/dotfiles/tmux"        "$HOME/.config/tmux"

# zsh is a single file
backup "$HOME/.zshrc"
ln -sfn "$root_dir/dotfiles/zsh/.zshrc" "$HOME/.zshrc"
echo "linked: $HOME/.zshrc -> $root_dir/dotfiles/zsh/.zshrc"

mkdir -p "$HOME/.wallpapers" "$HOME/screenshots"
echo "Ensure a wallpaper at: $HOME/.wallpapers/wall.jpg"

echo "Installing system scripts to /usr/local/bin"
for script in "$root_dir/scripts/rofi-system-menu" "$root_dir/scripts/rofi-wallpaper"; do
  if [ -f "$script" ]; then
    sudo cp "$script" /usr/local/bin/
    sudo chmod +x "/usr/local/bin/$(basename "$script")"
    echo "installed: $(basename "$script") -> /usr/local/bin/"
  fi
done

echo "All set. Start Hyprland (tty: 'Hyprland', or via uwsm)."
