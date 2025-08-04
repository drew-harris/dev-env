return {
	"WilliamHsieh/overlook.nvim",
	opts = {
		ui = {
			border = "single"
		}
	},

	-- Optional: set up common keybindings
	keys = {
		{ "<leader>lc", function() require("overlook.api").peek_definition() end, desc = "Overlook: Peek definition" },
		{ "<leader>lC", function() require("overlook.api").close_all() end,       desc = "Overlook: Close all popup" },
		-- { "<leader>pu", function() require("overlook.api").restore_popup() end,   desc = "Overlook: Restore popup" },
	},
}
