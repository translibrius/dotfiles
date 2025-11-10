local wezterm = require 'wezterm'
local constants = require 'constants'
local config = wezterm.config_builder()

-- Tab bar
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true

-- Font
config.font = wezterm.font('Iosevka Nerd Font Mono')
config.font_size = 18
config.line_height = 1.2 --120%

-- Colors
config.colors = {
    cursor_bg = "white",
    cursor_border = "white",
}

-- Appearance
--config.window_decorations = "RESIZE"
config.window_background_image = constants.bg_image
config.window_background_opacity = 1.00
config.window_padding = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0,
}

-- Misc
config.max_fps = 179
config.prefer_egl = true


----------------------------------------------------------------
-- Opacity toggle setup
local opacity_enabled = true

wezterm.on("toggle-opacity", function(window, _)
  local overrides = window:get_config_overrides() or {}
  if opacity_enabled then
    -- Turn OFF opacity (make it solid)
    overrides.window_background_opacity = 1.0
  else
    -- Turn ON opacity (restore it)
    overrides.window_background_opacity = 0.85
  end
  opacity_enabled = not opacity_enabled
  window:set_config_overrides(overrides)
end)

-- Add a key binding to trigger the toggle
config.keys = {
  {
    key = "O",
    mods = "CTRL|SHIFT",
    action = wezterm.action.EmitEvent("toggle-opacity"),
  },
}

----------------------------------------------------------------

return config
