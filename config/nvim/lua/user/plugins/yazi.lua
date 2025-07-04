---@type LazySpec
return {
	"mikavilpas/yazi.nvim",
	event = "VeryLazy",
	dependencies = {
		-- check the installation instructions at
		-- https://github.com/folke/snacks.nvim
		"folke/snacks.nvim",
	},
	keys = {
		-- 👇 in this section, choose your own keymappings!
		{
			"<leader>e",
			mode = { "n", "v" },
			"<cmd>Yazi<cr>",
			desc = "Open yazi at the current file",
		},
		-- {
		-- 	"-",
		-- 	mode = { "n", "v" },
		-- 	"<cmd>Yazi<cr>",
		-- 	desc = "Open yazi at the current file",
		-- },
		-- {
		-- 	"_",
		-- 	mode = { "n", "v" },
		-- 	"<cmd>Yazi cwd<cr>",
		-- 	desc = "Open yazi at the current file",
		-- },
		-- {
		-- 	"-",
		-- 	mode = { "n", "v" },
		-- 	"<cmd>Yazi<cr>",
		-- 	desc = "Open yazi at the current file",
		-- },
		-- {
		-- 	"_",
		-- 	mode = { "n", "v" },
		-- 	"<cmd>Yazi cwd<cr>",
		-- 	desc = "Open yazi at the current file",
		-- },
		{
			-- Open in the current working directory
			"<leader>E",
			"<cmd>Yazi cwd<cr>",
			desc = "Open the file manager in nvim's working directory",
		},
		{
			"<leader>me",
			"<cmd>Yazi toggle<cr>",
			desc = "Resume the last yazi session",
		},
	},
	---@type YaziConfig | {}
	opts = {
		-- if you want to open yazi instead of netrw, see below for more info
		open_for_directories = true,
		keymaps = {
			show_help = "<f1>",
		},
		yazi_floating_window_border = "none",
	},
	-- 👇 if you use `open_for_directories=true`, this is recommended
	init = function()
		-- More details: https://github.com/mikavilpas/yazi.nvim/issues/802
		-- vim.g.loaded_netrw = 1
		vim.g.loaded_netrwPlugin = 1
	end,
}
