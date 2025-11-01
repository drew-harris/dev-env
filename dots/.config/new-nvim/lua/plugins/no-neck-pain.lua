return {
	"shortcuts/no-neck-pain.nvim",
	version = "*",
	opts = {
		buffers = {
			colors = {
				background = "#171717"
				-- background = "#1E1E2E" -- cattppucin
			}
		},
		width = 120,
		integrations = {
			NvimTree = {
				position = "left"
			}
		}
	},
	keys = {
		{ "<leader>m", "<cmd>NoNeckPain<cr>", desc = "No Neck Pain" },
	},
}
