#!/usr/bin/env bash
# macOS/Linux dotfile linker — wraps GNU Stow
# Usage: ./link.sh [-u] [-n]
#   -u  Unlink (unstow)
#   -n  Dry run

set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
ACTION="stow"
DRY=""

while getopts "un" opt; do
    case $opt in
        u) ACTION="unstow" ;;
        n) DRY="--simulate" ;;
        *) echo "Usage: $0 [-u] [-n]"; exit 1 ;;
    esac
done

if ! command -v stow &>/dev/null; then
    echo "GNU Stow not found. Install it:"
    echo "  macOS:  brew install stow"
    echo "  Linux:  sudo apt install stow / sudo pacman -S stow"
    exit 1
fi

echo ""
if [ "$ACTION" = "unstow" ]; then
    echo "  Unlinking dotfiles..."
    stow -v -D -t "$HOME" $DRY -d "$DOTFILES" .
else
    echo "  Linking dotfiles..."
    stow -v --adopt -t "$HOME" $DRY -d "$DOTFILES" .
fi

# Link zsh profile if on macOS
if [[ "$OSTYPE" == darwin* ]] && [ "$ACTION" != "unstow" ]; then
    ZSHRC="$HOME/.zshrc"
    ZSHRC_SRC="$DOTFILES/.zshrc"
    if [ -f "$ZSHRC_SRC" ]; then
        if [ -L "$ZSHRC" ] || [ ! -f "$ZSHRC" ]; then
            ln -sf "$ZSHRC_SRC" "$ZSHRC"
            echo "  LINKED  ~/.zshrc"
        else
            echo "  EXISTS  ~/.zshrc (back it up and re-run, or use -u first)"
        fi
    fi
fi

echo ""
echo "  Done."
echo ""
