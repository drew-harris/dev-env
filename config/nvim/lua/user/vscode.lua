-- Function to open all listed, named buffers in Cursor (VS Code fork)
-- in the context of the current directory.
local function open_all_buffers_in_cursor()
	-- Get buffers that are part of the buffer list
	local listed_bufinfos = vim.fn.getbufinfo({ buflisted = 1 })
	local files_to_open = {}
	local current_buf = vim.api.nvim_get_current_buf()
	local current_file = nil

	for _, info in ipairs(listed_bufinfos) do
		local is_suitable = true
		local skip_reason = ""

		-- Condition 1: Buffer must have a name (be associated with a file)
		if not (info.name and info.name ~= "") then
			is_suitable = false
		end

		-- Condition 2: Buffer must not be a special type (terminal, help, etc.)
		if info.buftype and info.buftype ~= "" then
			is_suitable = false
		end

		-- Condition 3: Ensure it's actually marked as listed in its info structure.
		if info.buflisted ~= 1 and info.buflisted ~= nil then
			is_suitable = false
		end

		if is_suitable then
			-- Attempt to get the full, absolute path
			local filepath = vim.fn.fnamemodify(info.name, ":p")

			-- Condition 4: The resolved filepath must be valid
			if filepath and filepath ~= "" then
				if info.bufnr == current_buf then
					current_file = vim.fn.shellescape(filepath)
				else
					table.insert(files_to_open, vim.fn.shellescape(filepath))
				end
			end
		end
	end

	if #files_to_open > 0 then
		-- Add current file first if it exists
		if current_file then
			table.insert(files_to_open, 1, current_file)
		end
		local cmd = "cursor " .. table.concat(files_to_open, " ") .. " -a ."
		vim.fn.system(cmd)
	end
end

-- Create the user command (if not already present or if you're replacing the whole block)
vim.api.nvim_create_user_command("OpenBuffersInCursor", open_all_buffers_in_cursor, {
	desc = "Open all listed, file-associated buffers in Cursor (project context)",
	nargs = 0,
})

Keymapper("ao", "<cmd>OpenBuffersInCursor<cr>", "Open all buffers in Cursor")

-- The OpenCurrentInCursor function and its command definition remain the same
local function open_current_buffer_in_cursor()
	local current_buf_path = vim.fn.expand("%:p")
	if current_buf_path and current_buf_path ~= "" then
		local cmd = "cursor " .. vim.fn.shellescape(current_buf_path) .. " -a ."
		vim.fn.system(cmd)
	end
end

vim.api.nvim_create_user_command("OpenCurrentInCursor", open_current_buffer_in_cursor, {
	desc = "Open the current buffer in Cursor (project context)",
	nargs = 0,
})
