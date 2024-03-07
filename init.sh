#!/usr/bin/env bash
set -euo pipefail

if [[ ${OS:-} = Windows_NT ]]; then
    echo 'error: This config is destined to a UNIX based system.'
    exit 1
fi

if [[ -t 1 ]]; then
    # Reset
    Color_Off='\033[0m' # Text Reset

    # Regular Colors
    Red='\033[0;31m'   # Red
    Green='\033[0;32m' # Green
    Dim='\033[0;2m'    # White

    # Bold
    Bold_Green='\033[1;32m' # Bold Green
    Bold_White='\033[1m'    # Bold White
fi

error() {
    echo -e "${Red}error${Color_Off}:" "$@" >&2
    exit 1
}

error_silent() {
    echo -e "${Red}error${Color_Off}:" "$@" >&2
}

info() {
    echo -e "${Dim}$@ ${Color_Off}"
}

info_bold() {
    echo -e "${Bold_White}$@ ${Color_Off}"
}

success() {
    echo -e "${Green}$@ ${Color_Off}"
}

# Simplify creating a symlink with this repository /dotfiles/*
# TODO: interactive mode to configure paths on the fly
create_symlink() {
  local config_path="$1"
  local source_path="$2"

  if [ -e "$config_path" ]; then
    error_silent "There's already a config in $config_path"
    info "You can delete it with rm -rf $config_path"
  else
    ln -s "$source_path" "$config_path"
    success "Symlink created successfully: $source_path -> $config_path"
  fi
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

create_symlink "/home/joao/.config/nvim" "$DIR/dotfiles/nvim"
create_symlink "/home/joao/.config/starship.toml" "$DIR/dotfiles/starship/starship.toml"
create_symlink "/home/joao/.config/zellij" "$DIR/dotfiles/zellij"
