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
    }
}
