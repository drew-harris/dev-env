local function open_all_buffers_in_helix()
	local listed_bufinfos = vim.fn.getbufinfo({ buflisted = 1 })
	local files_to_open = {}
	local current_buf = vim.api.nvim_get_current_buf()
	local current_file = nil

	for _, info in ipairs(listed_bufinfos) do
		local is_suitable = true
		local skip_reason = ""

		if not (info.name and info.name ~= "") then
			is_suitable = false
		end

		if info.buftype and info.buftype ~= "" then
			is_suitable = false
		end

		if info.buflisted ~= 1 and info.buflisted ~= nil then
			is_suitable = false
		end

		if is_suitable then
			local filepath = vim.fn.fnamemodify(info.name, ":p")

			if filepath and filepath ~= "" then
				local win_id = vim.fn.bufwinid(info.bufnr)
				local file_with_line

				if win_id ~= -1 then
					local cursor = vim.api.nvim_win_get_cursor(win_id)
					local line_number = cursor[1]
					local char_number = cursor[2]
					file_with_line = string.format("%s:%d:%d", vim.fn.shellescape(filepath), line_number, char_number)
				else
					file_with_line = vim.fn.shellescape(filepath)
				end

				if info.bufnr == current_buf then
					current_file = file_with_line
				else
					table.insert(files_to_open, file_with_line)
				end
			end
		end
	end

	if #files_to_open > 0 or current_file then
		if current_file then
			table.insert(files_to_open, 1, current_file)
		end
		local cmd = "tmux new-window hx " .. table.concat(files_to_open, " ")
		vim.fn.system(cmd)
	end
end

vim.api.nvim_create_user_command("OpenBuffersInHelix", open_all_buffers_in_helix, {
	desc = "Open all listed, file-associated buffers in Helix (project context)",
	nargs = 0,
})

Keymapper("aO", "<cmd>OpenBuffersInHelix<cr>", "Open all buffers in Helix")

local function open_current_buffer_in_helix()
	local current_buf_path = vim.fn.expand("%:p")
	if current_buf_path and current_buf_path ~= "" then
		local cursor = vim.api.nvim_win_get_cursor(0)
		local line_number = cursor[1]
		local char_number = cursor[2]
		local cmd = string.format("tmux new-window hx %s:%d:%d", vim.fn.shellescape(current_buf_path), line_number, char_number)
		vim.fn.system(cmd)
	end
end

vim.api.nvim_create_user_command("OpenCurrentInHelix", open_current_buffer_in_helix, {
	desc = "Open the current buffer in Helix (project context)",
	nargs = 0,
}) 