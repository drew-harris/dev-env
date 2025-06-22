local notify = vim.notify
vim.notify = function(msg, ...)
	if msg:match("nvim%-cmp is not available") then
		return
	end
	notify(msg, ...)
end

vim.cmd([[
  augroup diffcolors
    autocmd!
    autocmd Colorscheme * call s:SetDiffHighlights()
  augroup END
  function! s:SetDiffHighlights()
    highlight DiffAdd gui=bold guifg=none guibg=#2e4b2e
    highlight DiffDelete gui=bold guifg=none guibg=#4c1e15
    highlight DiffChange gui=bold guifg=none guibg=#45565c
    highlight DiffText gui=bold guifg=none guibg=#996d74
  endfunction
]])

require("user.utils.logging")
require("user.keymapper")
require("user.options")
require("user.keymaps")
require("user.plugins")
require("user.colorscheme")
require("avante_lib").load()
require("user.lsp")
require("user.autopairs")
require("user.whichkey")
require("user.autocommands")
require("user.nushell").setup()
require("user.helix")

vim.cmd("highlight! HarpoonInactive guibg=NONE guifg=#63698c")
vim.cmd("highlight! link HarpoonActive IncSearch")
vim.cmd("highlight! link HarpoonNumberActive IncSearch")
vim.cmd("highlight! HarpoonNumberInactive guibg=NONE guifg=#7aa2f7")

vim.cmd("autocmd TermOpen * setlocal nonumber norelativenumber")

vim.cmd("highlight! link YankyPut Visual")
vim.cmd("highlight! link YankyYanked Visual")
