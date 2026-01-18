-- lua/custom/config/keymaps.lua

-- Clipboard integration
vim.g.clipboard = {
  name = 'system+tmux+file',
  copy = {
    ['+'] = { 'nvim-yank-plus' },
  },
  paste = {
    ['+'] = { 'tmux', 'save-buffer', '-' },
  },
  cache_enabled = false,
}

-- Yank to system clipboard
vim.keymap.set('n', 'Y', '"+yy', { desc = 'Copy line to + register', noremap = true, silent = true })
vim.keymap.set('v', 'Y', '"+y', { desc = 'Copy selection to + register', noremap = true, silent = true })

-- File browser
vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })
vim.keymap.set('n', '<leader>e', function()
  MiniFiles.open()
end, { desc = 'Open mini.files' })

-- Lazy.nvim
vim.keymap.set('n', '<leader>L', ':Lazy<CR>', { noremap = true, desc = 'Open lazy.nvim' })

-- Session restore
vim.keymap.set('n', '<leader>qs', function()
  require('persistence').load()
end, { desc = 'Restore session' })

-- Save
vim.keymap.set('n', '<C-s>', ':w<CR>', { noremap = true, desc = 'Write file' })
vim.keymap.set('i', '<C-s>', '<Esc>:w<CR>', { noremap = true, desc = 'Write file' })

-- Comments (Neovim 0.10+ comment mappings)
vim.keymap.set('n', '<C-/>', 'gcc', { remap = true, desc = 'Toggle comment (line)' })
vim.keymap.set('n', '<C-_>', 'gcc', { remap = true, desc = 'Toggle comment (line)' })
vim.keymap.set('x', '<C-/>', 'gc', { remap = true, desc = 'Toggle comment (visual)' })

--------------------------------------------------------------------------------
-- Treesitter scope jumps ([c and ]c)
--------------------------------------------------------------------------------

local function jump_scope_start()
  local ts_utils = require 'nvim-treesitter.ts_utils'
  local node = ts_utils.get_node_at_cursor()
  if not node then
    vim.notify('No Treesitter node under cursor', vim.log.levels.WARN)
    return
  end

  while node do
    local type = node:type()
    if
      type == 'function_definition'
      or type == 'function_declaration'
      or type == 'method_definition'
      or type == 'if_statement'
      or type == 'for_statement'
      or type == 'while_statement'
      or type == 'class_definition'
      or type == 'do_statement'
    then
      local start_row = node:start()
      vim.api.nvim_win_set_cursor(0, { start_row + 1, 0 })
      return
    end
    node = node:parent()
  end

  vim.notify('No enclosing scope found', vim.log.levels.INFO)
end

local function jump_scope_end()
  local ts_utils = require 'nvim-treesitter.ts_utils'
  local node = ts_utils.get_node_at_cursor()
  if not node then
    vim.notify('No Treesitter node under cursor', vim.log.levels.WARN)
    return
  end

  while node do
    local type = node:type()
    if
      type == 'function_definition'
      or type == 'function_declaration'
      or type == 'method_definition'
      or type == 'if_statement'
      or type == 'for_statement'
      or type == 'while_statement'
      or type == 'class_definition'
      or type == 'do_statement'
    then
      local end_row = node:end_()
      vim.api.nvim_win_set_cursor(0, { end_row + 1, 0 })
      return
    end
    node = node:parent()
  end

  vim.notify('No enclosing scope found', vim.log.levels.INFO)
end

-- Normal mode mappings
vim.keymap.set('n', '[c', jump_scope_start, { desc = 'Jump to start of current scope', silent = true })
vim.keymap.set('n', ']c', jump_scope_end, { desc = 'Jump to end of current scope', silent = true })

-- Visual-mode helper: extend selection to new cursor position after a jump.
local function visual_extend_after_jump(jump_fn)
  return function()
    -- Anchor where Visual mode started (mark "v")
    local anchor = vim.fn.getpos 'v'

    -- Perform the jump (moves the cursor)
    jump_fn()

    -- Current cursor becomes the other end
    local new_end = vim.fn.getpos '.'

    local function before(a, b)
      if a[2] ~= b[2] then
        return a[2] < b[2]
      end
      return a[3] < b[3]
    end

    local lo, hi = anchor, new_end
    if before(new_end, anchor) then
      lo, hi = new_end, anchor
    end

    -- Update visual selection bounds then reselect
    vim.fn.setpos("'<", lo)
    vim.fn.setpos("'>", hi)
    vim.cmd 'normal! gv'
  end
end

-- Visual/select mode: extend selection to scope edge
vim.keymap.set('x', '[c', visual_extend_after_jump(jump_scope_start), {
  desc = 'Extend selection to start of current scope',
  silent = true,
})
vim.keymap.set('x', ']c', visual_extend_after_jump(jump_scope_end), {
  desc = 'Extend selection to end of current scope',
  silent = true,
})

--------------------------------------------------------------------------------
-- Treesitter "context" jumps ([[ and ]]) using nvim-treesitter.locals
--------------------------------------------------------------------------------

local function jump_to_context_edge(to_end)
  local ts_utils = require 'nvim-treesitter.ts_utils'
  local ts_locals = require 'nvim-treesitter.locals'

  local node = ts_utils.get_node_at_cursor()
  if not node then
    vim.notify('No Treesitter node under cursor', vim.log.levels.WARN)
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local scopes = ts_locals.get_scope_tree(node, bufnr)
  if not scopes or #scopes == 0 then
    vim.notify('No enclosing context found', vim.log.levels.INFO)
    return
  end

  local cursor_row = vim.api.nvim_win_get_cursor(0)[1] - 1

  local function pick_scope(idx)
    local scope = scopes[idx]
    if not scope then
      return nil
    end

    local start_row = scope:start()

    -- If we're on the declaration line of the current scope, sometimes prefer the parent.
    if cursor_row == start_row and idx < #scopes then
      local parent = scope:parent()
      if parent then
        local parent_type = parent:type()
        local scope_type = scope:type()
        local parent_is_classlike = parent_type and (parent_type:find 'class' or parent_type:find 'struct')
        local scope_is_function = scope_type and (scope_type:find 'function' or scope_type:find 'method')

        if parent_is_classlike and scope_is_function then
          return pick_scope(idx + 1)
        end
      end
    end

    -- Avoid absolute root if there's a more meaningful parent.
    if not scope:parent() and idx < #scopes then
      return pick_scope(idx + 1)
    end

    return scope
  end

  local scope = pick_scope(1)
  if not scope then
    vim.notify('No enclosing context found', vim.log.levels.INFO)
    return
  end

  local target_row, target_col
  if to_end then
    target_row, target_col = scope:end_()

    -- TS end positions are exclusive; if we land at col 0 of next line, back up.
    if target_col == 0 and target_row > 0 then
      target_row = target_row - 1
      local line = vim.api.nvim_buf_get_lines(bufnr, target_row, target_row + 1, false)[1] or ''
      target_col = #line
    end
  else
    target_row, target_col = scope:start()
  end

  local line = vim.api.nvim_buf_get_lines(bufnr, target_row, target_row + 1, false)[1] or ''
  target_col = math.min(target_col, #line)
  vim.api.nvim_win_set_cursor(0, { target_row + 1, target_col })
end

-- Override ftplugin-provided [[/]] (e.g., python.vim) with Treesitter context jumps.
vim.api.nvim_create_autocmd('FileType', {
  pattern = '*',
  callback = function(args)
    -- Normal mode
    vim.keymap.set('n', '[[', function()
      jump_to_context_edge(false)
    end, { buffer = args.buf, desc = 'Jump to start of current context', silent = true })

    vim.keymap.set('n', ']]', function()
      jump_to_context_edge(true)
    end, { buffer = args.buf, desc = 'Jump to end of current context', silent = true })

    -- Visual/select mode: extend selection
    vim.keymap.set(
      'x',
      '[[',
      visual_extend_after_jump(function()
        jump_to_context_edge(false)
      end),
      { buffer = args.buf, desc = 'Extend selection to start of current context', silent = true }
    )

    vim.keymap.set(
      'x',
      ']]',
      visual_extend_after_jump(function()
        jump_to_context_edge(true)
      end),
      { buffer = args.buf, desc = 'Extend selection to end of current context', silent = true }
    )
  end,
})
