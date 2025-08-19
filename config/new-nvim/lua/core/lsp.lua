vim.lsp.enable({
    "gopls",
    "lua_ls",
    "typescript_ls",
    "yamlls",
    "jsonls",
    "rust_analyzer",
    "tailwindcss",
})

vim.diagnostic.config({
    --virtual_lines = false,
    virtual_text = true,
    underline = true,
    update_in_insert = true,
    severity_sort = true,
    float = {
        --border = "rounded",
        source = true,
    },
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "󰅚 ",
            [vim.diagnostic.severity.WARN] = "󰀪 ",
            [vim.diagnostic.severity.INFO] = "󰋽 ",
            [vim.diagnostic.severity.HINT] = "󰌶 ",
        },
        numhl = {
            [vim.diagnostic.severity.ERROR] = "ErrorMsg",
            [vim.diagnostic.severity.WARN] = "WarningMsg",
        },
    },
})

local opts = { noremap = true, silent = true }
local keymap = vim.keymap.set

keymap("n", "gD", vim.lsp.buf.declaration, opts)
keymap("n", "gd", vim.lsp.buf.definition, opts)
keymap("n", "gT", vim.lsp.buf.type_definition, opts)
keymap("n", "gI", vim.lsp.buf.implementation, opts)
keymap("n", "gr", vim.lsp.buf.references, opts)
keymap("n", "gR", function()
    require("trouble").toggle("lsp_references")
end, vim.tbl_extend("force", opts, { desc = "Trouble References" }))
keymap("n", "<leader>lD", "<cmd>DocsViewToggle<CR>", opts)
keymap("n", "<leader>lf", function()
    require("conform").format()
end, opts)
keymap("n", "<leader>ls", "<cmd>Telescope lsp_document_symbols<cr>", opts)
keymap("n", "<leader>lr", vim.lsp.buf.rename, opts)
keymap("n", "<leader>I", function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, { desc = "Toggle Inlay Hints" })
keymap("n", "<leader>ls", vim.lsp.buf.signature_help, opts)
keymap("n", "<leader>lq", vim.diagnostic.setloclist, opts)
keymap("n", "<leader>lw", function()
    vim.diagnostic.setqflist()
end, { desc = "Workspace Diagnostics" })

keymap("n", "<leader>lp", function()
    vim.diagnostic.open_float({ focusable = true, max_width = 400, zindex = 1000 })
end)
