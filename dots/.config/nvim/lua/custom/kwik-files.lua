local M = {}

function M.setup()
	local keymap = vim.api.nvim_set_keymap
	local opts = { noremap = true, silent = true }

	-- Kwik files keymaps
	keymap("n", "<leader>ke", "<cmd>e .env<cr>", opts)
	keymap("n", "<leader>ka", "<cmd>e .air.toml<cr>", opts)
	keymap("n", "<leader>ki", "<cmd>e .gitignore<cr>", opts)
	keymap("n", "<leader>kp", "<cmd>e package.json<cr>", opts)
	keymap("n", "<leader>kt", "<cmd>e cargo.toml<cr>", opts)
	keymap("n", "<leader>kl", "<cmd>e .eslintrc.cjs<cr>", opts)
	keymap("n", "<leader>kr", "<cmd>e README.md<cr>", opts)
	keymap("n", "<leader>kd", "<cmd>e .dockerignore<cr>", opts)
	keymap("n", "<leader>kj", "<cmd>e .justfile<cr>", opts)
	keymap("n", "<leader>kn", "<cmd>e pad.nu<cr>", opts)
	keymap("n", "<leader>kw", "<cmd>e worker/.env<cr>", opts)
	keymap("n", "<leader>km", "<cmd>e mprocs.yaml<cr>", opts)
end

return M