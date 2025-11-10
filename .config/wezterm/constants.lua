local M = {}

-- Get home directory depending on OS
local home = os.getenv("HOME") or os.getenv("USERPROFILE")

-- Add a path separator if missing
local sep = package.config:sub(1, 1) -- "\" on Windows, "/" on Unix
if not home:match(sep .. "$") then
  home = home .. sep
end

-- Build paths safely
M.bg_blurred_darker = home .. ".config" .. sep .. "wezterm" .. sep .. "assets" .. sep .. "bg-blurred-darker.png"
M.bg_blurred = home .. ".config" .. sep .. "wezterm" .. sep .. "assets" .. sep .. "bg-blurred.png"
M.bg_image = M.bg_blurred_darker

return M