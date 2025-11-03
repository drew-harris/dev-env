return {
	"aznhe21/actions-preview.nvim",
	config = function()
		local actions = require("actions-preview")

		actions.setup({
			backend = { "minipick" }
		})

		vim.keymap.set("n", "<leader>la",
			actions.code_actions
			, { desc = "Code action" })
	end
}
