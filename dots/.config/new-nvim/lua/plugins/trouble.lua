return {
	"folke/trouble.nvim",
	config = function()
		local trouble = require("trouble")
		trouble.setup({})
		vim.keymap.set("n", "<leader>lt", "<cmd>Trouble diagnostics filter.severity=vim.diagnostic.severity.ERROR<cr>",
			{ desc = "Toggle Trouble" })
	end
}
