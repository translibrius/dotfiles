-- https://github.com/nvim-treesitter/nvim-treesitter

return {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPost", "BufNewFile" },
    lazy = false,
    build = ":TSUpdate",
    branch = "main",
    config = function()
        require('nvim-treesitter.config').setup({
            -- Ones that MUST be installed
            ensure_installed = {
                "c",
                "cpp",
                "bash",
                "html",
                "css",
                "json",
                "yaml",
                "lua",
                "vim",
                "vimdoc",
                "query",
                "markdown",
                "markdown_inline"
            },
            auto_install = true, -- Install on open unknown type
            sync_install = false,
            highlight = {
                enable = true,
                additional_vim_regex_highlighting = false,
            },
            indent = { enable = true },
            incremental_selection = {
                enable = true,
                init_selection = "<CR>",
                node_incremental = "<CR>",
                scope_incremental = "<TAB>",
                node_decremental = "<S-TAB>",
            }
        })
    end,
};
