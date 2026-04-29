# Codex Dotfiles

This directory owns the user-managed Codex setup, same pattern as `~/dotfiles/.claude`.

Live symlinks:

- `~/.codex/config.toml -> ~/dotfiles/.codex/config.toml`
- `~/.codex/hooks.json -> ~/dotfiles/.codex/hooks.json`
- `~/.codex/rules/default.rules -> ~/dotfiles/.codex/rules/default.rules`
- `~/.codex/skills/caveman -> ~/dotfiles/.codex/skills/caveman`
- `~/.codex/skills/compress -> ~/dotfiles/.codex/skills/compress`

What lives here:

- `config.toml`: base Codex config
- `hooks.json`: global SessionStart behavior
- `rules/default.rules`: approval allowlist learned over time
- `skills/`: user-installed global skills

Current extras:

- `caveman`: terse communication mode
- `compress`: companion skill for compressing natural-language memory files

Notes:

- Codex does not mirror Claude config 1:1.
- Claude plugin settings and marketplaces do not port directly.
- The practical equivalent is global hooks + global skills + symlinked config.

If Codex ignores changes:

1. Restart Codex.
2. Start a fresh session.

If you want more global behavior later, add it to `hooks.json` first, not repo-local files.
