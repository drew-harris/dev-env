return {
	"nvim-lualine/lualine.nvim",
	config = function()
		require("lualine").setup({
			options = {
				icons_enabled = true,
			},
			sections = {
				lualine_a = { "tabs" },
				lualine_b = { "diff" },
				lualine_x = { { "diagnostics", sources = { "nvim_lsp" } } },
				lualine_y = { "progress" },
				lualine_z = { "location" },
			},
			inactive_sections = {
				lualine_a = {},
				lualine_b = {},
				-- lualine_c = { "filename" },
				lualine_x = { "location" },
				lualine_y = {},
				lualine_z = {},
			},
			tabline = {},
			winbar = {
				lualine_c = {
					{ "filename", path = 1 },
				},
			},
			inactive_winbar = {
				lualine_c = {
					{ "filename", path = 1 },
				},
			},
			extensions = {
			},
		})
	end,
}
