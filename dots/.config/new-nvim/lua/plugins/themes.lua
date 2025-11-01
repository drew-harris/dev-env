return {
    {
        "sainnhe/sonokai",
        priority = 1000,
        config = function()
            vim.g.sonokai_style = "shusia"
            vim.g.sonokai_transparent_background = 2
        end,
    },
    {
        "catppuccin/nvim",
        config = function()
            require('catppuccin').setup({
                opts = {
                    transparent_background = true, -- disables setting the background color.
                    flavor = "macchiato"
                },
            })
        end
    },
    {
        "folke/tokyonight.nvim",
        lazy = false,
        priority = 1000,
        opts = {
            transparent = true,
            style = "night",
            light_style = "day",       -- The theme is used when the background is set to light,
        },
    }
}
