return {
    {
        "sainnhe/sonokai",
        priority = 1000,
        config = function()
            vim.g.sonokai_style = "shusia"
            vim.g.sonokai_transparent_background = 2
            vim.cmd.colorscheme("sonokai")
        end,
    }
}
