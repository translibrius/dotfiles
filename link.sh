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
    stow -v -D --ignore='^\.codex' -t "$HOME" $DRY -d "$DOTFILES" .
else
    echo "  Linking dotfiles..."
    stow -v --adopt --ignore='^\.codex' -t "$HOME" $DRY -d "$DOTFILES" .
fi

# ~/.codex also contains Codex-managed runtime state, so link only the
# user-managed entries instead of asking Stow to own the whole directory.
CODEX_LINKS=(
    "config.toml"
    "hooks.json"
    "rules/default.rules"
    "skills/caveman"
    "skills/compress"
)

for RELATIVE_PATH in "${CODEX_LINKS[@]}"; do
    SOURCE_PATH="$DOTFILES/.codex/$RELATIVE_PATH"
    TARGET_PATH="$HOME/.codex/$RELATIVE_PATH"

    if [ "$ACTION" = "unstow" ]; then
        if [ -L "$TARGET_PATH" ] && [ "$(readlink "$TARGET_PATH")" = "$SOURCE_PATH" ]; then
            if [ -n "$DRY" ]; then
                echo "  WOULD UNLINK  ~/.codex/$RELATIVE_PATH"
            else
                rm "$TARGET_PATH"
                echo "  UNLINKED  ~/.codex/$RELATIVE_PATH"
            fi
        fi
        continue
    fi

    if [ -n "$DRY" ]; then
        echo "  WOULD LINK  ~/.codex/$RELATIVE_PATH"
        continue
    fi

    mkdir -p "$(dirname "$TARGET_PATH")"
    ln -sfn "$SOURCE_PATH" "$TARGET_PATH"
    echo "  LINKED  ~/.codex/$RELATIVE_PATH"
done

# Remove the stale nested link created by older versions of this script.
if [ "$ACTION" != "unstow" ] && [ -L "$HOME/.codex/.codex" ] && \
   [ "$(readlink "$HOME/.codex/.codex")" = "$DOTFILES/.codex" ]; then
    if [ -n "$DRY" ]; then
        echo "  WOULD REMOVE  ~/.codex/.codex (stale nested link)"
    else
        rm "$HOME/.codex/.codex"
        echo "  REMOVED  ~/.codex/.codex (stale nested link)"
    fi
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
