# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)
source $ZSH/oh-my-zsh.sh

# Editor
export EDITOR=nvim

# Aliases
alias ls='ls --color=auto'
alias grep='grep --color=auto'

# Quick navigation
dots() { cd ~/dotfiles }
proj() { cd ~/projects }

# Yazi — cd to last dir on exit
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd <"$tmp"
    [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}

# Wix
alias npmpublic="npm config set registry https://registry.npmjs.org/ && npm config get registry && yarn config set npmRegistryServer https://registry.npmjs.org/ --home || yarn config set registry https://registry.npmjs.org/"
alias npmprivate="npm config set registry https://npm.dev.wixpress.com && npm config get registry && yarn config set npmRegistryServer https://npm.dev.wixpress.com --home || yarn config set registry https://npm.dev.wixpress.com"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# vcpkg
export VCPKG_ROOT="$HOME/vcpkg"
export PATH="$VCPKG_ROOT:$PATH"

# Local bins
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.opencode/bin:$PATH"

# Bazel
[ -f "$HOME/.bazelenv" ] && source "$HOME/.bazelenv"

# Secrets (Wix MCP-S, etc.) — keep out of git
[ -f "$HOME/.secrets" ] && source "$HOME/.secrets"

# Initialize zoxide
eval "$(zoxide init zsh)"

# Initialize Starship prompt (overrides oh-my-zsh theme)
eval "$(starship init zsh)"
