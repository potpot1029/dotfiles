#!/bin/bash
# Set up these dotfiles on Arch Linux or macOS.
#
#   ./install.sh              symlink configs into $HOME (safe to re-run)
#   ./install.sh --packages   install packages first (packages/), then symlink
#
# The repo mirrors $HOME: .config/<name> -> ~/.config/<name>.
# Anything already in the way is moved to ~/dotfiles_old.

set -euo pipefail

dir=~/dotfiles
olddir=~/dotfiles_old
linux_only="hypr waybar" # not linked on macOS

case "$(uname -s)" in
Darwin) os=mac ;;
Linux) [ -f /etc/arch-release ] && os=arch || os=linux ;;
*) os=unknown ;;
esac

# package list file -> one name per line, comments and blanks dropped
pkg_list() { sed 's/#.*//' "$1" | awk 'NF'; }

install_packages() {
  case "$os" in
  arch)
    echo "== pacman (packages/arch.txt)"
    # shellcheck disable=SC2046
    sudo pacman -S --needed $(pkg_list "$dir/packages/arch.txt")

    local aur_helper
    aur_helper=$(command -v yay || command -v paru || true)
    if [ -n "$aur_helper" ]; then
      echo "== AUR (packages/aur.txt)"
      # shellcheck disable=SC2046
      "$aur_helper" -S --needed $(pkg_list "$dir/packages/aur.txt")
    else
      echo "skip     AUR packages: install yay or paru, then re-run with --packages"
    fi
    ;;
  mac)
    if ! command -v brew >/dev/null; then
      echo "Homebrew is required: https://brew.sh" >&2
      exit 1
    fi
    echo "== Homebrew (packages/Brewfile)"
    brew bundle --file "$dir/packages/Brewfile"
    ;;
  *)
    echo "--packages supports Arch Linux and macOS only (detected: $(uname -s))" >&2
    exit 1
    ;;
  esac
}

# link $dir/$1 -> ~/$1, backing up whatever is there unless it already points into the repo
link() {
  local rel=$1 src="$dir/$1" target=~/"$1"
  if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$src")" ]; then
    echo "ok       ~/$rel"
    return
  fi
  if [ -e "$target" ] || [ -L "$target" ]; then
    echo "backup   ~/$rel -> $olddir/$rel"
    mkdir -p "$olddir/$(dirname "$rel")"
    mv "$target" "$olddir/$rel"
  fi
  mkdir -p "$(dirname "$target")"
  ln -sn "$src" "$target"
  echo "linked   ~/$rel"
}

for arg in "$@"; do
  case "$arg" in
  --packages) install_packages ;;
  -h | --help)
    sed -n '2,8p' "$0"
    exit 0
    ;;
  *)
    echo "unknown option: $arg" >&2
    exit 1
    ;;
  esac
done

cd "$dir"
shopt -s dotglob nullglob
for path in .config/*; do
  name=${path#.config/}
  if [ "$os" = mac ] && [[ " $linux_only " == *" $name "* ]]; then
    echo "skip     ~/$path (Linux only)"
    continue
  fi
  link "$path"
done
shopt -u dotglob nullglob

# oh-my-zsh (sourced by .zshrc)
if [ ! -d ~/.oh-my-zsh ]; then
  echo "installing oh-my-zsh"
  git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh ~/.oh-my-zsh
fi

# tmux plugin manager
if [ ! -d ~/.tmux/plugins/tpm ]; then
  echo "installing tpm"
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# ~/.zshrc: a LOCAL untracked stub that sources the shared config,
# so installers appending to ~/.zshrc don't touch the repo.
if [ -L ~/.zshrc ]; then
  rm ~/.zshrc
elif [ -f ~/.zshrc ] && ! grep -q "dotfiles/.zshrc" ~/.zshrc; then
  mkdir -p "$olddir"
  mv ~/.zshrc "$olddir/.zshrc"
fi
if [ ! -f ~/.zshrc ]; then
  cat >~/.zshrc <<'STUB'
# ~/.zshrc — LOCAL, untracked. Installers that append to ~/.zshrc write here.
# Shared config lives in ~/dotfiles/.zshrc.
source "$HOME/dotfiles/.zshrc"

# ---- machine-specific (installer lines go below) ----
STUB
fi
