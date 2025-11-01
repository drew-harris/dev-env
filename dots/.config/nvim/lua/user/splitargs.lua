-- Add this to your Neovim config (init.lua or a plugin file)

vim.api.nvim_create_user_command("SplitArgs", function(opts)
	-- Get the visual selection
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")

	-- Extract the selected text
	local lines = vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, end_pos[2], false)

	if #lines == 0 then
		print("No text selected")
		return
	end

	-- Handle single line selection
	local text
	if #lines == 1 then
		-- For visual selection, end_pos[3] is inclusive, so we need to adjust
		text = string.sub(lines[1], start_pos[3], end_pos[3])
	else
		-- Handle multi-line selection
		lines[1] = string.sub(lines[1], start_pos[3])
		lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
		text = table.concat(lines, " ")
	end

	-- Split the text into arguments (handles quoted strings properly)
	local args = {}
	local current_arg = ""
	local in_quotes = false
	local quote_char = nil
	local i = 1

	while i <= #text do
		local char = text:sub(i, i)

		if not in_quotes then
			if char == '"' or char == "'" then
				in_quotes = true
				quote_char = char
			elseif char:match("%s") then
				if current_arg ~= "" then
					table.insert(args, current_arg)
					current_arg = ""
				end
			else
				current_arg = current_arg .. char
			end
		else
			if char == quote_char then
				in_quotes = false
				quote_char = nil
			else
				current_arg = current_arg .. char
			end
		end

		i = i + 1
	end

	-- Add the last argument if it exists
	if current_arg ~= "" then
		table.insert(args, current_arg)
	end

	-- Convert to quoted format
	local quoted_args = {}
	for _, arg in ipairs(args) do
		table.insert(quoted_args, '"' .. arg .. '"')
	end

	local result = table.concat(quoted_args, ", ")

	-- Replace the selected text with the quoted arguments
	-- Convert 1-based positions to 0-based for nvim_buf_set_text
	local start_row = start_pos[2] - 1
	local start_col = start_pos[3] - 1
	local end_row = end_pos[2] - 1
	local end_col = end_pos[3] -- end_pos[3] is already correct for nvim_buf_set_text

	vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, { result })

	print("Converted to: " .. result)
end, {
	desc = "Split highlighted text into quoted arguments",
	range = true, -- This allows the command to work with visual selections
})

-- Optional: Create a visual mode mapping for easier access
vim.keymap.set("v", "<leader>sa", ":SplitArgs<CR>", {
	desc = "Split selection into quoted args",
	silent = true,
})
