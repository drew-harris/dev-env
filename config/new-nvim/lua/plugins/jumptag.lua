return {
	"harrisoncramer/jump-tag",
	ft = "typescriptreact",
	config = function()
		local jumptag = require("jump-tag")

		vim.keymap.set("n", "<leader>tk", jumptag.jumpParent, {
			desc = "Jump to parent tag",
		})
		vim.keymap.set("n", "<leader>tj", jumptag.jumpChild, {
			desc = "Jump to child tag",
		})
		vim.keymap.set("n", "<leader>tl", jumptag.jumpNextSibling, {
			desc = "Jump to next sibling tag",
		})
		vim.keymap.set("n", "<leader>th", jumptag.jumpPrevSibling, {
			desc = "Jump to previous sibling tag",
		})
	end,
}
