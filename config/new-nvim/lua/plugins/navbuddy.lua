return {
	"neovim/nvim-lspconfig",
	dependencies = {
		{
			"SmiteshP/nvim-navbuddy",
			dependencies = {
				"SmiteshP/nvim-navic",
				"MunifTanjim/nui.nvim"
			},
			config = function()
				local navbuddy = require("nvim-navbuddy")
				navbuddy.setup({
					lsp = { auto_attach = true }
				})
				vim.keymap.set("n", "<leader>n", navbuddy.open, { desc = "Navbuddy" })
			end
		}
	},
	-- your lsp config or other stuff
}
