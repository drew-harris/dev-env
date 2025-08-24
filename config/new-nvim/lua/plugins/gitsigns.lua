return {
	"lewis6991/gitsigns.nvim",
	config = function()
		local gitsigns = require("gitsigns")
		gitsigns.setup({})

		-- Git hunk mappings
		vim.keymap.set("n", "<leader>gr", gitsigns.reset_hunk, { desc = "Reset git hunk" })
		vim.keymap.set("n", "<leader>gR", gitsigns.reset_buffer, { desc = "Reset git buffer" })
		vim.keymap.set("n", "<leader>gj", gitsigns.next_hunk, { desc = "Next git hunk" })
		vim.keymap.set("n", "<leader>gk", gitsigns.prev_hunk, { desc = "Previous git hunk" })
		vim.keymap.set("n", "<leader>gl", gitsigns.blame_line, { desc = "Git line blame" })
		vim.keymap.set("n", "<leader>gb", function()
			gitsigns.change_base("main")
		end, { desc = "Change file base to main" })
	end,
}
