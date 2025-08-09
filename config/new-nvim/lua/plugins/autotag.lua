return {
	"windwp/nvim-ts-autotag",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		require("nvim-ts-autotag").setup({
			opts = {
				enable_close = true, -- Auto close tags
				enable_rename = true, -- Auto rename pairs of tags
				enable_close_on_slash = false, -- Auto close on trailing </
			},
			-- Per filetype config
			per_filetype = {
				["html"] = {
					enable_close = true,
					enable_rename = true,
					enable_close_on_slash = true,
				},
				["xml"] = {
					enable_close = true,
					enable_rename = true,
					enable_close_on_slash = true,
				},
			},
		})
	end,
}