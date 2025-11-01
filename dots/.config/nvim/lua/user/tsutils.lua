local M = {}

function M.wrap_with_unwrap()
	local ts = vim.treesitter
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row, col = cursor[1] - 1, cursor[2]

	-- Get the node under cursor
	local node = ts.get_node({ bufnr = bufnr, pos = { row, col } })

	if not node then
		vim.notify("No node found under cursor", vim.log.levels.WARN)
		return
	end

	-- Start with the current node as target
	local target_node = node

	-- If we're on an identifier, check if it's part of a call_expression
	if node:type() == "identifier" and node:parent() then
		local parent = node:parent()
		if parent:type() == "call_expression" then
			target_node = parent
		end
		-- If not part of a call_expression, keep the original identifier
	end

	-- Get the text and position of the target node
	local text = ts.get_node_text(target_node, bufnr)
	local start_row, start_col, end_row, end_col = target_node:range()

	-- Wrap with unwrap()
	local new_text = "unwrap(" .. text .. ")"

	-- Replace the text
	vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col, { new_text })

	vim.notify("Wrapped: " .. text)
end

return M
