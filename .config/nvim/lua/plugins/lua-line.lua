return {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
        require("lualine").setup({
            options = {
                theme = "cyberdream",
                icons_enabled = true,
                component_separators = { "|" },
                section_separators = { left = '', right = ''},
            }
        })
    end,
};
