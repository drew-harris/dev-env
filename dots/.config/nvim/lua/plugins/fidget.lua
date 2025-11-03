return {
	"j-hui/fidget.nvim",
	event = "LspAttach",
	enabled = false,
	opts = {
		progress = {
			-- Suppress new messages while in insert mode
			ignore_done_already = true,
		},
		-- Notification display options
		notification = {
			window = {
				-- Background color opacity in the notification window (0 = fully opaque)
				winblend = 1,
			},
		},
	},
}

