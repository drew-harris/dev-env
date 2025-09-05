return {
	"nvim-lualine/lualine.nvim",
	config = function()
		local custom_theme = require('lualine.themes.base16')

		require("lualine").setup({
			options = {
				-- theme = custom_theme,
				icons_enabled = true,
				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
				disabled_filetypes = {
					statusline = {},
					winbar = {
						"neo-tree",
					},
				},
				globalstatus = true,
				always_divide_middle = true,
				refresh = {
					statusline = 100,
					tabline = 100,
					winbar = 100,
				},
			},
			sections = {
				lualine_a = {},
				lualine_b = { "tabs", "diff" },
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
					{
						"filename",
						path = 1,
						shorting_target = 40,
						symbols = {
							modified = '[+]',
							readonly = '[-]',
							unnamed = '[No Name]',
						}
					},
				},
			},
			inactive_winbar = {
				lualine_c = {
					{
						"filename",
						path = 1,
						shorting_target = 40,
						symbols = {
							modified = '[+]',
							readonly = '[-]',
							unnamed = '[No Name]',
						}
					},
				},
			},
			extensions = {
			},
		})
	end,
}
