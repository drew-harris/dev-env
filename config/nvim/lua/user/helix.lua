-- utils ----------------------------------------------------------------------

local function is_file_buffer(info)
  -- Listed, not special, has a filename
  return info.name ~= ""
    and (info.buftype == nil or info.buftype == "")
    and (info.buflisted == 1 or info.buflisted == nil)
end

local function buffer_arg(info, opts)
  local filepath = vim.fn.fnamemodify(info.name, ":p")
  if filepath == "" then
    return nil
  end

  local win_id = vim.fn.bufwinid(info.bufnr)
  local line, col = 1, 0
  if win_id ~= -1 then
    local cursor = vim.api.nvim_win_get_cursor(win_id)
    line, col = cursor[1], cursor[2]
  end

  local escaped = vim.fn.shellescape(filepath)
  local prefix = opts.file_prefix or ""
  return string.format("%s%s:%d:%d", prefix, escaped, line, col)
end

local function make_open_all_fn(opts)
  return function()
    local listed = vim.fn.getbufinfo({ buflisted = 1 })
    local current_buf = vim.api.nvim_get_current_buf()

    local files, current_file = {}, nil

    for _, info in ipairs(listed) do
      if is_file_buffer(info) then
        local arg = buffer_arg(info, opts)
        if arg then
          if info.bufnr == current_buf then
            current_file = arg
          else
            table.insert(files, arg)
          end
        end
      end
    end

    if current_file then
      table.insert(files, 1, current_file)
    end
    if #files > 0 then
      vim.fn.system(opts.build_cmd(files))
    end
  end
end

local function make_open_current_fn(opts)
  return function()
    local path = vim.fn.expand("%:p")
    if path == "" then
      return
    end
    local cursor = vim.api.nvim_win_get_cursor(0)
    local arg = string.format(
      "%s%s:%d:%d",
      opts.file_prefix or "",
      vim.fn.shellescape(path),
      cursor[1],
      cursor[2]
    )
    vim.fn.system(opts.build_cmd({ arg }))
  end
end

-- editor-specific configs -----------------------------------------------------

local cursor_opts = {
  file_prefix = "-g ",
  build_cmd = function(files)
    return "cursor " .. table.concat(files, " ") .. " -a ."
  end,
}

local helix_opts = {
  build_cmd = function(files)
    return "tmux new-window hx " .. table.concat(files, " ")
  end,
}

local zed_opts = {
  -- no prefix; Zed accepts path:line:col directly
  build_cmd = function(files)
    -- open in a new window (`-n`) so we don’t reuse the last Zed instance
    return "zed -n " .. table.concat(files, " ")
  end,
}

-- commands --------------------------------------------------------------------

-- Cursor
vim.api.nvim_create_user_command(
  "OpenBuffersInCursor",
  make_open_all_fn(cursor_opts),
  { desc = "Open all listed buffers in Cursor", nargs = 0 }
)
vim.api.nvim_create_user_command(
  "OpenCurrentInCursor",
  make_open_current_fn(cursor_opts),
  { desc = "Open current buffer in Cursor", nargs = 0 }
)

-- Helix
vim.api.nvim_create_user_command(
  "OpenBuffersInHelix",
  make_open_all_fn(helix_opts),
  { desc = "Open all listed buffers in Helix", nargs = 0 }
)
vim.api.nvim_create_user_command(
  "OpenCurrentInHelix",
  make_open_current_fn(helix_opts),
  { desc = "Open current buffer in Helix", nargs = 0 }
)

-- Zed
vim.api.nvim_create_user_command(
  "OpenBuffersInZed",
  make_open_all_fn(zed_opts),
  { desc = "Open all listed buffers in Zed", nargs = 0 }
)
vim.api.nvim_create_user_command(
  "OpenCurrentInZed",
  make_open_current_fn(zed_opts),
  { desc = "Open current buffer in Zed", nargs = 0 }
)

-- keymaps ---------------------------------------------------------------------
-- Add your own preferred mappings; examples:
Keymapper("ao", "<cmd>OpenBuffersInCursor<cr>", "Open all buffers in Cursor")
Keymapper("ap", "<cmd>OpenBuffersInHelix<cr>", "Open all buffers in Helix")
Keymapper("az", "<cmd>OpenBuffersInZed<cr>", "Open all buffers in Zed")
