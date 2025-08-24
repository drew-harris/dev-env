return {
	"nvim-telescope/telescope.nvim",
	tag = "0.1.8",
	dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "ThePrimeagen/harpoon" },
	config = function()
		local telescope = require("telescope")
		local builtin = require('telescope.builtin')
		local actions = require("telescope.actions")
		local finders = require('telescope.finders')
		local pickers = require('telescope.pickers')
		local conf = require('telescope.config').values
		local action_state = require('telescope.actions.state')

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

		-- JJ diff files function
		local function jj_diff_files()
			-- Execute jj diff command and get the output
			local handle = io.popen('jj diff --name-only --from main')
			if not handle then
				vim.notify("Failed to execute jj diff command", vim.log.levels.ERROR)
				return
			end

			local result = handle:read("*a")
			handle:close()

			-- Parse the output into a table of files
			local files = {}
			for file in result:gmatch("[^\r\n]+") do
				table.insert(files, file)
			end

			if #files == 0 then
				vim.notify("No changed files found", vim.log.levels.INFO)
				return
			end

			-- Create a Telescope picker with the changed files
			pickers.new({}, {
				prompt_title = "JJ Changed Files (from main)",
				finder = finders.new_table {
					results = files,
					entry_maker = function(entry)
						return {
							value = entry,
							display = entry,
							ordinal = entry,
							path = entry,
						}
					end,
				},
				sorter = conf.file_sorter({}),
				previewer = conf.file_previewer({}),
				attach_mappings = function(prompt_bufnr, map)
					actions.select_default:replace(function()
						actions.close(prompt_bufnr)
						local selection = action_state.get_selected_entry()
						if selection then
							vim.cmd('edit ' .. vim.fn.fnameescape(selection.path))
						end
					end)
					return true
				end,
			}):find()
		end

		-- Keymaps
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
		vim.keymap.set("n", "<leader>sg", jj_diff_files, { desc = "Search git (jj) changed files" })
	end,
}
