# Lines configured by zsh-newuser-install
HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=1000

setopt autocd extendedglob nomatch
unsetopt beep
bindkey -e
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/joaom/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

# Alias
alias v='nvim'
alias sv='sudo nvim'
alias c='clear'
alias lab='cd ~/lab'
alias config='cd ~/.config'
alias l='exa'
alias clip='xclip -selection c'
alias thorium='thorium-browser --enable-gpu-rasterization --ignore-gpu-blacklist'

# Env Global Variables
EDITOR=/usr/bin/code
VISUAL=/usr/bin/code
GIT_EDITOR=/usr/bin/helix

# bun
[ -s "/home/joaom/.bun/_bun" ] && source "/home/joaom/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Initialize starship
eval "$(starship init zsh)"

# pnpm
export PNPM_HOME="/home/joaom/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
