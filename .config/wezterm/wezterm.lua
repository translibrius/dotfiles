-- Port of .config/alacritty/alacritty.toml (+ windows/ overrides). Keep the two in sync-ish.
local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

local is_windows = wezterm.target_triple:find('windows') ~= nil

if is_windows then
  config.default_prog = { 'powershell.exe', '-NoLogo' }
end

-- Window: plain 120x35, no padding, no tabs unless you open a second one
config.initial_cols = 120
config.initial_rows = 35
config.window_background_opacity = 1.0
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.window_close_confirmation = 'NeverPrompt'
config.audible_bell = 'Disabled'
config.scrollback_lines = 10000

-- Font: Iosevka NF Mono 13. Alacritty doesn't do ligatures, so kill them here too
config.font = wezterm.font('Iosevka Nerd Font Mono')
config.font_size = 13
config.harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' }

-- Cursor: yellow steady block, text under it drawn in the bg color (alacritty "CellBackground")
config.default_cursor_style = 'SteadyBlock'

-- Alacritty's built-in default palette, pitch black bg
config.colors = {
  foreground = '#d8d8d8',
  background = '#000000',
  cursor_bg = '#ffff00',
  cursor_border = '#ffff00',
  cursor_fg = '#000000',
  selection_bg = '#d8d8d8',
  selection_fg = '#000000',
  ansi = { '#181818', '#ac4242', '#90a959', '#f4bf75', '#6a9fb5', '#aa759f', '#75b5aa', '#d8d8d8' },
  brights = { '#6b6b6b', '#c55555', '#aac474', '#feca88', '#82b8c8', '#c28cb8', '#93d3c3', '#f8f8f8' },
}

-- Needed for the twitch emote mod (inline images). Default on, but be explicit
config.enable_kitty_graphics = true

config.keys = {
  -- Shift+Enter -> ESC CR, so Claude Code / TUIs get a newline instead of submit
  { key = 'Enter', mods = 'SHIFT', action = act.SendString('\x1b\r') },
  { key = 'C', mods = 'CTRL|SHIFT', action = act.CopyTo('Clipboard') },
  { key = 'V', mods = 'CTRL|SHIFT', action = act.PasteFrom('Clipboard') },
}

return config
