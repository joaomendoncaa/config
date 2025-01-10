#!/usr/bin/env bash
set -euo pipefail

if [[ ${OS:-} = Windows_NT ]]; then
	echo 'error: This config is destined to a UNIX based system.'
	exit 1
fi

FORCE_DELETE=false
CONFIG_SOURCE="$HOME/.config.jmmm.sh"
COLOR_RESET=''
RED=''
GREEN=''
DIM=''
BOLD_WHITE=''

if [[ -t 1 ]]; then
	COLOR_RESET='\033[0m'
	RED='\033[0;31m'
	GREEN='\033[0;32m'
	DIM='\033[0;2m'
	BOLD_WHITE='\033[1m'
fi

while [[ $# -gt 0 ]]; do
	case "$1" in
	--force)
		FORCE_DELETE=true
		;;
	*)
		echo "Unknown option: $1"
		exit 1
		;;
	esac
	shift
done

error() {
	echo -e "${RED}error${COLOR_RESET}:" "$@" >&2
	exit 1
}

error_silent() {
	echo -e "${RED}error${COLOR_RESET}:" "$@" >&2
}

info() {
	echo -e "${DIM}$@ ${COLOR_RESET}"
}

info_bold() {
	echo -e "${BOLD_WHITE}$@ ${COLOR_RESET}"
}

success() {
	echo -e "${GREEN}$@ ${COLOR_RESET} \n"
}

path() {
	local new_path="$1"

	if [[ ":$PATH:" != *":$new_path:"* ]]; then
		export PATH="$new_path:$PATH"
		success "Added $new_path to PATH"
	else
		info "Path $new_path already exists in PATH"
	fi
}

symlink() {
	local config_path="$1"
	local source_path="$2"

	if [ ! -t 0 ]; then
		if [ -e "$config_path" ]; then
			info "Creating backup of existing config at $config_path.bak..."
			mv "$config_path" "$config_path.bak"
		fi

		ln -s "$source_path" "$config_path"
		success "Symlink created successfully: $source_path -> $config_path"

		return
	fi

	if [[ "$FORCE_DELETE" == true || ! -e "$config_path" ]]; then
		rm -rf "$config_path"
		ln -s "$source_path" "$config_path"
		success "Symlink created successfully: $source_path -> $config_path"

		return
	fi

	error_silent "There's already a config in $config_path"
	info "You can:"
	info "1. Delete it [D]"
	info "2. Backup it and proceed with symlinking [B] (default)"
	info "3. Don't symlink this config [N]"

	read -n1 -p "Enter your choice [D/B/N]: " response
	echo ""

	case $response in
	[dD])
		info "Deleting existing config at $config_path..."
		rm -rf "$config_path"
		ln -s "$source_path" "$config_path"
		success "Symlink created successfully: $source_path -> $config_path"
		;;
	[bB] | "")
		info "Creating backup of existing config at $config_path.bak..."
		mv "$config_path" "$config_path.bak"
		ln -s "$source_path" "$config_path"
		success "Symlink created successfully: $source_path -> $config_path. Previous config backed up as $config_path.bak"
		;;
	[nN])
		info "Symlinking for $source_path cancelled."
		;;
	*)
		info "Invalid choice."
		symlink "$config_path" "$source_path"
		;;
	esac
}

echo "Removing previous nix installation..."

if systemctl is-active --quiet nix-daemon.service; then
	sudo systemctl stop nix-daemon.service || info "Failed to stop nix-daemon.service, it may not be running"
fi

if systemctl is-enabled --quiet nix-daemon.socket 2>/dev/null; then
	sudo systemctl disable nix-daemon.socket || info "Failed to disable nix-daemon.socket"
fi

if systemctl is-enabled --quiet nix-daemon.service 2>/dev/null; then
	sudo systemctl disable nix-daemon.service || info "Failed to disable nix-daemon.service"
fi

sudo systemctl daemon-reload || info "Failed to reload systemd daemon"

sudo rm -rf \
	/nix \
	/etc/nix \
	/var/root/.nix-profile \
	~root/.nix-profile \
	~root/.nix-channels \
	~root/.nix-defexpr \
	/etc/tmpfiles.d/nix-daemon.conf \
	/etc/profile.d/nix.sh \
	/etc/zshrc.backup-before-nix \
	/etc/bashrc.backup-before-nix \
	/etc/bash.bashrc.backup-before-nix \
	/etc/profile.d/nix.sh.backup-before-nix

for i in $(seq 1 32); do
	if id "nixbld$i" &>/dev/null; then
		sudo userdel "nixbld$i" 2>/dev/null || info "Could not remove nixbld$i user"
	fi
done

if getent group nixbld >/dev/null; then
	sudo groupdel nixbld 2>/dev/null || info "Could not remove nixbld group"
fi

echo "Starting Installation..."

sh <(curl -L https://nixos.org/nix/install) --daemon

if [ -e ~/.nix-profile/etc/profile.d/nix.sh ]; then
	. ~/.nix-profile/etc/profile.d/nix.sh
elif [ -e /etc/profile.d/nix.sh ]; then
	. /etc/profile.d/nix.sh
fi

if ! grep -q "experimental-features.*nix-command" ~/.config/nix/nix.conf 2>/dev/null; then
	echo "Enabling flakes..."
	mkdir -p ~/.config/nix
	echo "experimental-features = nix-command flakes" >>~/.config/nix/nix.conf
fi

echo "Installing packages..."

nix profile install .#desktop

echo "Creating symlinks for config files..."

symlink "$HOME/.config/nix" "$CONFIG_SOURCE/dotfiles/nix"
symlink "$HOME/.config/nvim" "$CONFIG_SOURCE/dotfiles/nvim"
symlink "$HOME/.config/starship.toml" "$CONFIG_SOURCE/dotfiles/starship/starship.toml"
symlink "$HOME/.config/yazi" "$CONFIG_SOURCE/dotfiles/yazi"
symlink "$HOME/.config/tmux" "$CONFIG_SOURCE/dotfiles/tmux"
symlink "$HOME/.config/lazygit" "$CONFIG_SOURCE/dotfiles/lazygit"
symlink "$HOME/.config/atuin" "$CONFIG_SOURCE/dotfiles/atuin"
symlink "$HOME/.starship" "$CONFIG_SOURCE/dotfiles/starship/starship.toml"
symlink "$HOME/.gitconfig" "$CONFIG_SOURCE/dotfiles/git/.gitconfig"
symlink "$HOME/.bashrc" "$CONFIG_SOURCE/dotfiles/bash/.bashrc"
symlink "$HOME/biome.json" "$CONFIG_SOURCE/dotfiles/biome/config.json"

echo "Creating symlinks for binaries..."

mkdir -p "$HOME/.local/bin"

symlink "$HOME/.local/bin/git-dir-status" "$CONFIG_SOURCE/bin/git-dir-status"

echo "Adding new binaries PATH..."

path "$HOME/.local/bin"

echo "Setup complete!"
