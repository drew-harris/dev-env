return {
	{
		"saghen/blink.compat",
		-- use the latest release, via version = '*', if you also use the latest release for blink.cmp
		version = "*",
		-- lazy.nvim will automatically load the plugin when it's required by blink.cmp
		lazy = true,
		-- make sure to set opts so that lazy.nvim calls blink.compat's setup
		opts = {},
	},
	{
		"saghen/blink.cmp",
		dependencies = { "folke/lazydev.nvim" },

		version = "1.*",

		---@module 'blink.cmp'
		opts = {
			keymap = {
				preset = "default",
				-- ["<cr>"] = {
				-- 	function(cmp)
				-- 		if vim.api.nvim_get_mode().mode == "i" and vim.bo.buftype == "" then
				-- 			if cmp.snippet_active() then
				-- 				return cmp.accept()
				-- 			else
				-- 				return cmp.select_and_accept()
				-- 			end
				-- 		else
				-- 		end
				-- 	end,
				-- 	-- "snippet_forward",
				-- 	"fallback",
				-- },
			},

			appearance = {
				-- use_nvim_cmp_as_default = true,
				nerd_font_variant = "mono",
			},

			completion = {
				accept = {
					auto_brackets = {
						enabled = true,
						kind_resolution = {
							enabled = true,
							blocked_filetypes = {},
						},
						semantic_token_resolution = {
							enabled = true,
							blocked_filetypes = {},
							-- How long to wait for semantic tokens to return before assuming no brackets should be added
							timeout_ms = 400,
						},
					},
				},
				-- menu = {
				-- 	auto_show = false,
				-- },
			},

			signature = { enabled = true },

			cmdline = {
				enabled = true,
				completion = {
					menu = { auto_show = false },
				},
				-- Dont show autocomplete for :w
				sources = function()
					local type = vim.fn.getcmdtype()
					local cmd = vim.fn.getcmdline()
					if type == ":" and cmd ~= "w" then
						return { "cmdline" }
					end
					return {}
				end,
			},

			-- default list of enabled providers defined so that you can extend it
			-- elsewhere in your config, without redefining it, via `opts_extend`
			sources = {
				default = {
					"avante_commands",
					"avante_mentions",
					"avante_files",
					"lsp",
					"path",
					"snippets",
					"buffer",
					"lazydev",
				},
				providers = {
					snippets = {
						opts = {
							search_paths = { "/Users/drew/.config/nvim/snippets" },
						},
					},
					avante_commands = {
						name = "avante_commands",
						module = "blink.compat.source",
						score_offset = 90, -- show at a higher priority than lsp
						opts = {},
					},
					avante_files = {
						name = "avante_files",
						module = "blink.compat.source",
						score_offset = 100, -- show at a higher priority than lsp
						opts = {},
					},
					avante_mentions = {
						name = "avante_mentions",
						module = "blink.compat.source",
						score_offset = 1000, -- show at a higher priority than lsp
						opts = {},
					},

					-- dont show LuaLS require statements when lazydev has items
					lazydev = { name = "LazyDev", module = "lazydev.integrations.blink", fallbacks = { "lsp" } },
				},
				-- optionally disable cmdline completions
				-- cmdline = {},
			},

			-- experimental signature help support
			-- signature = { enabled = true },
		},
		-- allows extending the providers array elsewhere in your config
		-- without having to redefine it
		opts_extend = { "sources.default" },
	},
}
