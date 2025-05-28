local do_autoformat = true

-- Function to check if biome.json exists in root directory
local function has_biome_config()
	local root_dir = vim.fn.getcwd()
	local biome_json = vim.fn.filereadable(root_dir .. "/biome.json")
	return biome_json == 1
end

-- Create autoformat toggle
vim.api.nvim_create_user_command("AutoformatToggle", function()
	do_autoformat = not do_autoformat
	if do_autoformat then
		print("Autoformat enabled")
	else
		print("Autoformat disabled")
	end
end, { nargs = 0 })

require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		-- Conform will run multiple formatters sequentially
		-- python = { "isort", "black" },
		go = { "goimports", "gofmt" },
		-- Use a sub-list to run only the first available formatter
		javascript = function(bufnr)
			if has_biome_config() then
				return { "biome" }
			else
				return { "prettierd" }
			end
		end,
		javascriptreact = function(bufnr)
			if has_biome_config() then
				return { "biome" }
			else
				return { "prettierd" }
			end
		end,
		typescript = function(bufnr)
			if has_biome_config() then
				return { "biome" }
			else
				return { "prettierd" }
			end
		end,
		typescriptreact = function(bufnr)
			if has_biome_config() then
				return { "biome" }
			else
				return { "prettierd" }
			end
		end,
		astro = { "prettierd" },
		java = { "google-java-format" },
	},
	format_on_save = function(bufnr)
		if not do_autoformat then
			return
		end
		-- These options will be passed to conform.format()
		local ignore_filetypes = { "java", "css", "xml" }
		if vim.tbl_contains(ignore_filetypes, vim.bo[bufnr].filetype) then
			return
		end
		return {
			timeout_ms = 500,
			lsp_fallback = true,
		}
	end,
})
