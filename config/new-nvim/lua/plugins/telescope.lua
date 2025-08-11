return {
	"nvim-telescope/telescope.nvim",
	tag = "0.1.8",
	dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "ThePrimeagen/harpoon" },
	config = function()
		local telescope = require("telescope")
		local builtin = require('telescope.builtin')
		local actions = require("telescope.actions")
		telescope.setup({
			defaults = {
				mappings = {
					i = {
						["<C-j>"] = actions.move_selection_next,
						["<C-k>"] = actions.move_selection_previous,
					}
				},
				border = false
			}
		})
		telescope.load_extension("harpoon")
		-- vim.keymap.set('n', '<leader>f', builtin.find_files, { desc = 'Telescope find files' })
		vim.keymap.set("n", "<leader>F", "<cmd>Telescope live_grep theme=ivy<cr>", { desc = "Search in files" })

		-- Instant
		vim.keymap.set("n", "<leader>ks", function()
			require("telescope.builtin").find_files({
				border = false,
				cwd = "~/programs/testing-instant/",
			})
		end, { desc = "Sandbox" })

		local dropdown = require("telescope.themes").get_dropdown({ border = false })
		vim.keymap.set("n", "<leader>b", function()
			require("telescope.builtin").buffers(dropdown)
		end, { desc = "Search buffers" })

		vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "Search help" })
		vim.keymap.set("n", "<leader>sr", builtin.oldfiles, { desc = "Search recent files" })
		vim.keymap.set("n", "<leader>ss", builtin.lsp_document_symbols, { desc = "Search document symbols" })
		vim.keymap.set("n", "<leader>sS", builtin.lsp_dynamic_workspace_symbols, { desc = "Search workspace symbols" })
	end,
}
