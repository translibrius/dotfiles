-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Color column
vim.opt.colorcolumn = "120"
vim.cmd([[highlight ColorColumn guibg=#2a2a2a]])

-- Tab / Ident
vim.opt.tabstop = 4 -- Tab width
vim.opt.shiftwidth = 4 -- Ident width
vim.opt.softtabstop = 4 -- Soft tab stop
vim.opt.expandtab = true -- Uses spaces instead of tabs