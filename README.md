# dotfiles

Personal config files for Linux (Hyprland/Wayland) and Windows.

## Structure

```
.bashrc                         # Git Bash / Linux shell
.claude/
  CLAUDE.md                     # Claude Code global instructions
  settings.json                 # Claude Code global settings
.codex/
  config.toml                   # Codex global settings (+ Z.AI provider)
  glm.config.toml               # `codex --profile glm` -> Z.AI GLM
  zai-models.json               # Codex model catalog for GLM
.local/bin/glm                  # `claude` pointed at Z.AI GLM (Git Bash / Linux)
.config/
  alacritty/alacritty.toml      # Terminal emulator
  zed/settings.json             # Zed editor settings
  opencode/opencode.jsonc       # OpenCode v2 (DeepInfra, GLM-5.3 default)
  starship.toml                 # Cross-shell prompt
  nvim/                         # Neovim (LazyVim) — git submodule
  hypr/hyprland.conf            # Hyprland window manager (Linux)
  kitty/kitty.conf              # Kitty terminal (Linux)
  waybar/                       # Status bar (Linux)
  rofi/                         # App launcher (Linux)
  fastfetch/config.jsonc        # System info fetch
  wezterm/                      # WezTerm terminal (Linux)
  yazi/                         # File manager
windows/
  powershell/                   # PowerShell profile (Starship init)
  clink/                        # CMD prompt via Clink (Starship init)
link.ps1                        # Windows symlink script (like GNU Stow)
```

## Setup

### Linux

Uses [GNU Stow](https://www.gnu.org/software/stow/) — run from the repo directory:

```bash
cd ~/dotfiles
stow .
```

### Windows

Uses `link.ps1` which creates symlinks from the repo to their Windows-specific locations:

```powershell
# Preview what will be linked
.\link.ps1 -DryRun

# Link everything (overwrites existing, backs up to .bak)
.\link.ps1 -Force

# Remove all symlinks
.\link.ps1 -Unlink
```

Requires **Developer Mode** (Settings > System > For developers) or **Run as Administrator**.

#### Windows path mapping

| Repo path | Links to |
|---|---|
| `.config/alacritty/alacritty.toml` | `%APPDATA%/alacritty/alacritty.toml` |
| `.config/zed/settings.json` | `%APPDATA%/Zed/settings.json` |
| `.config/starship.toml` | `~/.config/starship.toml` |
| `.bashrc` | `~/.bashrc` |
| `windows/powershell/Microsoft.PowerShell_profile.ps1` | `~/Documents/WindowsPowerShell/` and `~/Documents/PowerShell/` |
| `windows/clink/starship.lua` | `%LOCALAPPDATA%/clink/starship.lua` |
| `.claude/settings.json` | `~/.claude/settings.json` |
| `.claude/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| `.codex/config.toml` | `~/.codex/config.toml` |
| `.codex/glm.config.toml`, `.codex/zai-models.json` | `~/.codex/` |
| `.local/bin/glm` | `~/.local/bin/glm` |
| `.config/opencode/opencode.jsonc` | `~/.config/opencode/opencode.jsonc` |

## Dependencies

### Shared (both platforms)
- [Starship](https://starship.rs/) — cross-shell prompt (`winget install starship`)
- [Iosevka Nerd Font Mono](https://www.nerdfonts.com/) — terminal font
- [Neovim](https://neovim.io/) + [LazyVim](https://www.lazyvim.org/)
- [yazi](https://yazi-rs.github.io/) — terminal file manager

### Claude Code
- `scoop install jq uv`: jq feeds `.claude/statusline.sh` (without it the status line is just `| repo:branch`), uv runs the emote mod's font builder
- Twitch emotes mod ([translibrius/claude-twitch-mod](https://github.com/translibrius/claude-twitch-mod)), enabled in `.claude/settings.json`:
  `/plugin install twitch-emotes --marketplace translibrius/claude-twitch-mod`
  - WezTerm: nothing else, `wezterm.lua` already loads the mod's font shim
  - Zed: start `claude` once in Zed's terminal, wait for "built the Zed emote font", restart Zed. The fallback is already in `.config/zed/settings.json`. The font is built for Zed's terminal font size + display scale and rebuilt by the mod when those change

### Windows-only
- [Alacritty](https://alacritty.org/) — GPU terminal (`winget install alacritty`)
- [Clink](https://chrisant996.github.io/clink/) — CMD enhancements for Starship (`winget install chrisant996.Clink`)
- [Git for Windows](https://gitforwindows.org/) — provides Git Bash

### Linux-only
- Hyprland, waybar, rofi, kitty, wezterm

## AI agent CLIs on other providers

Secrets live in `~/.secrets` (bash syntax, never in git). `.bashrc`, `.zshrc` and the PowerShell profile all load it:

```bash
export ZAI_API_KEY=...         # z.ai > Personal Coding Plan > Plan Overview
export DEEPINFRA_API_KEY=...   # deepinfra.com > Dashboard > API Keys
```

| Command | What it is |
|---|---|
| `claude` | Claude Code on Anthropic, untouched |
| `glm` | Same Claude Code binary, routed to Z.AI's GLM Coding Plan (`glm-5.3`, haiku slot = `glm-5.3-flash`). `GLM_MODEL=glm-5.3-flash[1m] glm` for the cheap one |
| `codex --profile glm` | Codex on Z.AI (Responses API). Plain `codex` stays on OpenAI |
| `opencode` | OpenCode v2 (`scoop install versions/opencode2`), defaults to `deepinfra/zai-org/GLM-5.3` (per token). Any DeepInfra model works as `deepinfra/<id>`; Z.AI plan still in `/models` |

OpenCode v2 runs a background service and resolves `{env:DEEPINFRA_API_KEY}` / `{env:ZAI_API_KEY}` inside it. If the service was started from a shell without the key, `opencode service restart` from one that has it.

`glm` exists twice on purpose: `.local/bin/glm` for bash and a `glm` function in the PowerShell profile. Same env table, keep them in sync.

Z.AI only allows the Coding Plan key through their listed tools; raw SDK use may get the plan throttled.

## Neovim

The nvim config is a git submodule pointing to [translibrius/kickstart.nvim](https://github.com/translibrius/kickstart.nvim).

```bash
# Clone with submodules
git clone --recurse-submodules <repo-url>

# Or init after cloning
git submodule update --init
```
