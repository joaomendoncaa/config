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

# Globals
force_delete=false

# Check args
while [[ $# -gt 0 ]]; do
	case "$1" in
	--force)
		force_delete=true
		;;
	*)
		echo "Unknown option: $1"
		exit 1
		;;
	esac
	shift
done

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
	echo -e "${Green}$@ ${Color_Off} \n"
}

# Simplify creating a symlink with this repository /dotfiles/*
create_symlink() {
	local config_path="$1"
	local source_path="$2"

	if [[ "$force_delete" == true || ! -e "$config_path" ]]; then
		rm -rf "$config_path"
		ln -s "$source_path" "$config_path"

		success "Symlink created successfully: $source_path -> $config_path"
	else
		error_silent "There's already a config in $config_path"
		info "You can:"
		info "1. Delete it with rm -rf $config_path [D/d]"
		info "2. Backup it and proceed with symlinking [B/b] (default)"
		info "3. Abort symlinking [N/n]"

		read -p "Enter your choice [B/b/D/d/N/n]: " response
		response=${response:-b}                                   # set default value to b if no input
		response=$(echo "$response" | tr '[:upper:]' '[:lower:]') # convert to lowercase

		case $response in
		d)
			info "Deleting existing config at $config_path..."
			rm -rf "$config_path"
			ln -s "$source_path" "$config_path"
			success "Symlink created successfully: $source_path -> $config_path"
			;;
		b)
			info "Creating backup of existing config at $config_path.bak..."
			mv "$config_path" "$config_path.bak"
			ln -s "$source_path" "$config_path"
			success "Symlink created successfully: $source_path -> $config_path. Previous config backed up as $config_path.bak"
			;;
		n)
			info "Symlinking aborted."
			;;
		*)
			info "Invalid choice. Symlinking aborted."
			;;
		esac
	fi
}

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

create_symlink "/home/joao/.config/nvim" "$DIR/dotfiles/nvim"
create_symlink "/home/joao/.config/starship.toml" "$DIR/dotfiles/starship/starship.toml"
create_symlink "/home/joao/.config/yazi/yazi.toml" "$DIR/dotfiles/yazi/yazi.toml"
create_symlink "/home/joao/.config/tmux" "$DIR/dotfiles/tmux"
create_symlink "/home/joao/.config/lazygit" "$DIR/dotfiles/lazygit"
create_symlink "/home/joao/.config/atuin" "$DIR/dotfiles/atuin"
