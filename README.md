# dotfiles

Personal config files for Linux (Hyprland/Wayland) and Windows.

## Structure

```
.bashrc                         # Git Bash / Linux shell
.claude/
  CLAUDE.md                     # Claude Code global instructions
  settings.json                 # Claude Code global settings
.config/
  alacritty/alacritty.toml      # Terminal emulator
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
| `.config/starship.toml` | `~/.config/starship.toml` |
| `.bashrc` | `~/.bashrc` |
| `windows/powershell/Microsoft.PowerShell_profile.ps1` | `~/Documents/WindowsPowerShell/` and `~/Documents/PowerShell/` |
| `windows/clink/starship.lua` | `%LOCALAPPDATA%/clink/starship.lua` |
| `.claude/settings.json` | `~/.claude/settings.json` |
| `.claude/CLAUDE.md` | `~/.claude/CLAUDE.md` |

## Dependencies

### Shared (both platforms)
- [Starship](https://starship.rs/) — cross-shell prompt (`winget install starship`)
- [Iosevka Nerd Font Mono](https://www.nerdfonts.com/) — terminal font
- [Neovim](https://neovim.io/) + [LazyVim](https://www.lazyvim.org/)
- [yazi](https://yazi-rs.github.io/) — terminal file manager

### Windows-only
- [Alacritty](https://alacritty.org/) — GPU terminal (`winget install alacritty`)
- [Clink](https://chrisant996.github.io/clink/) — CMD enhancements for Starship (`winget install chrisant996.Clink`)
- [Git for Windows](https://gitforwindows.org/) — provides Git Bash

### Linux-only
- Hyprland, waybar, rofi, kitty, wezterm

## Neovim

The nvim config is a git submodule pointing to [translibrius/kickstart.nvim](https://github.com/translibrius/kickstart.nvim).

```bash
# Clone with submodules
git clone --recurse-submodules <repo-url>

# Or init after cloning
git submodule update --init
```
