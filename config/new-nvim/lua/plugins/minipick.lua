return {
	{
		'echasnovski/mini.pick',
		version = false,
		config = function()
			local minipick = require("mini.pick")
			minipick.setup({})
			vim.keymap.set("n", "<leader>f", function()
				minipick.builtin.files({ tool = 'git' })
			end)
		end
	},
}
