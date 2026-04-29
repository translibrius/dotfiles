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

# ctalk — Claude Code with global CLAUDE.md + hooks disabled for pure chat
# Backs up ~/.claude/CLAUDE.md and settings.json (both symlinks to dotfiles),
# runs claude in empty dir, restores on exit/crash/ctrl-c.
ctalk() {
    local stamp=$(date +%s)
    local cdir="$HOME/.claude"
    local bakdir="$cdir/.ctalk-backup-$stamp"
    local origpwd="$PWD"
    mkdir -p "$bakdir"

    { [ -e "$cdir/CLAUDE.md" ] || [ -L "$cdir/CLAUDE.md" ]; } && mv "$cdir/CLAUDE.md" "$bakdir/CLAUDE.md"
    { [ -e "$cdir/settings.json" ] || [ -L "$cdir/settings.json" ]; } && mv "$cdir/settings.json" "$bakdir/settings.json"

    {
        mkdir -p /tmp/ctalk && builtin cd /tmp/ctalk
        claude
    } always {
        { [ -e "$bakdir/CLAUDE.md" ] || [ -L "$bakdir/CLAUDE.md" ]; } && mv "$bakdir/CLAUDE.md" "$cdir/CLAUDE.md"
        { [ -e "$bakdir/settings.json" ] || [ -L "$bakdir/settings.json" ]; } && mv "$bakdir/settings.json" "$cdir/settings.json"
        rmdir "$bakdir" 2>/dev/null
        builtin cd -- "$origpwd"
        echo "ctalk: session ended, configs restored"
    }
}

# Auto-restore on shell start if previous ctalk session crashed
for bakdir in "$HOME/.claude/".ctalk-backup-*(N); do
    [ -d "$bakdir" ] || continue
    echo "ctalk: restoring orphaned backup $bakdir"
    { [ -e "$bakdir/CLAUDE.md" ] || [ -L "$bakdir/CLAUDE.md" ]; } && mv "$bakdir/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
    { [ -e "$bakdir/settings.json" ] || [ -L "$bakdir/settings.json" ]; } && mv "$bakdir/settings.json" "$HOME/.claude/settings.json"
    rmdir "$bakdir" 2>/dev/null
done
unset bakdir

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

export PATH="$HOME/bin:$PATH"

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/Users/daumantasb/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)
