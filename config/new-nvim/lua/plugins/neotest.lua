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

		vim.keymap.set("n", "<leader>tt", function()
			neotest.run.run()
		end, { desc = "Run closest test" })
		
		vim.keymap.set("n", "<leader>tf", function()
			neotest.run.run(vim.fn.expand("%"))
		end, { desc = "Run all tests in file" })
		
		vim.keymap.set("n", "<leader>ta", function()
			neotest.run.attach()
		end, { desc = "Attach to test" })
		
		vim.keymap.set("n", "<leader>ts", function()
			neotest.summary.toggle()
		end, { desc = "Toggle test summary" })
		
		vim.keymap.set("n", "<leader>to", function()
			neotest.output.open({ enter = true })
		end, { desc = "Open test output" })
	end,
}
