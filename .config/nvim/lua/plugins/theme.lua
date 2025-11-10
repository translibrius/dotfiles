return {
    "scottmckendry/cyberdream.nvim",
    lazy = false,
    priority = 1000,
    config = function()
        require("cyberdream").setup({
            transparent = true,
            variant = "dark",
            terminal_colors = true,
        })
        vim.cmd.colorscheme('cyberdream')
        --vim.api.nvim_set_hl(0, 'CursorLine', { underline = true })
    end,
}
