return {
    {
        "sainnhe/sonokai",
        config = function()
            vim.g.sonokai_style = "andromeda"
            vim.g.sonokai_transparent_background = 2

            vim.cmd.colorscheme("sonokai")
        end,
    }
}
