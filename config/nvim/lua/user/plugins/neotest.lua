---@diagnostic disable: missing-fields
return {
	"nvim-neotest/neotest",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-neotest/nvim-nio",
		"nvim-treesitter/nvim-treesitter",
		"marilari88/neotest-vitest",
	},
	config = function()
		require("neotest").setup({
			adapters = {
				require("neotest-vitest"),
			},
			quickfix = {
				open = false,
			},
		})

		local neotest = require("neotest")

		Keymapper("tt", function()
			neotest.run.run()
		end, "Run closest test")
		Keymapper("tf", function()
			neotest.run.run(vim.fn.expand("%"))
		end, "Run all tests in file")
		Keymapper("ta", function()
			neotest.run.attach()
		end, "Attach to test")
		Keymapper("ts", function()
			neotest.summary.toggle()
		end, "Attach to test")
		Keymapper("to", function()
			neotest.output.open({ enter = true })
		end, "Attach to test")

		local function run_in_tmux_pane()
			local current_file = vim.fn.expand("%:t")
			local tmux_command = string.format(
				'tmux new-window -n sandbox "cd ~/programs/testing-instant/src && echo \\"Running: %s\\" && cd ../ && PORT=7777 bun run src/%s; read"',
				current_file,
				current_file
			)
			vim.fn.system(tmux_command)
		end

		vim.keymap.set("n", "<leader>tr", run_in_tmux_pane, { desc = "Run current file in tmux pane" })
	end,
}
