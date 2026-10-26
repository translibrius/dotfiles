#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'

# Yazi hack
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd <"$tmp"
    [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}

# Editor
export EDITOR=nvim

# Local bins: claude (native installer), glm launcher, opencode
export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$PATH"

# API keys etc, never in git. bash syntax: export KEY=value
# (the PowerShell profile parses the same file)
[ -f "$HOME/.secrets" ] && source "$HOME/.secrets"

# Initialize Starship prompt
eval "$(starship init bash)"

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/Users/daumantasb/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)
