vim.keymap.set('n', 'Y', '"+yy', { desc = 'Copy line to system clipboard' })
vim.keymap.set('v', 'Y', '"+y', { desc = 'Copy selected to system clipboard' })

vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })

-- vim.keymap.set('n', '<leader>e', ':Ex<CR>', { noremap = true, desc = 'Open file explorer' })
vim.keymap.set('n', '<leader>e', function()
  MiniFiles.open()
end, { desc = 'Open mini.files' })

vim.keymap.set('n', '<leader>L', ':Lazy<CR>', { noremap = true, desc = 'Open lazy.nvim' })

vim.keymap.set('n', '<leader>qs', function()
  require('persistence').load()
end, { desc = 'Restore session' })

vim.keymap.set('n', '<C-s>', ':w<CR>', { noremap = true, desc = 'Write file' })
vim.keymap.set('i', '<C-s>', '<Esc>:w<CR>', { noremap = true, desc = 'Write file' })

-- Use vim.comment (built-in from Neovim 0.10+)
vim.keymap.set('n', '<C-/>', 'gcc', { remap = true, desc = 'Toggle comment (line)' })
vim.keymap.set('n', '<C-_>', 'gcc', { remap = true, desc = 'Toggle comment (line)' })
vim.keymap.set('x', '<C-/>', 'gc', { remap = true, desc = 'Toggle comment (visual)' })

-- vim.keymap.set('n', '[c', function()
--   require('treesitter-context').go_to_context(vim.v.count1)
-- end, { silent = true, desc = 'Go up scope level' })

-- Jump to top of current scope
vim.keymap.set('n', '[c', function()
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
      local start_row, _, _ = node:start()
      vim.api.nvim_win_set_cursor(0, { start_row + 1, 0 })
      return
    end
    node = node:parent()
  end
  vim.notify('No enclosing scope found', vim.log.levels.INFO)
end, { desc = 'Jump to start of current scope', silent = true })

-- Jump to end of current scope
vim.keymap.set('n', ']c', function()
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
      local end_row, _, _ = node:end_()
      vim.api.nvim_win_set_cursor(0, { end_row + 1, 0 })
      return
    end
    node = node:parent()
  end
  vim.notify('No enclosing scope found', vim.log.levels.INFO)
end, { desc = 'Jump to end of current scope', silent = true })

-- Jump to the start/end of the current "context" (scope defined by Treesitter locals)
function _G.__jump_to_context_edge(to_end)
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
    -- If we're sitting on the declaration line of the current scope, prefer the parent.
    if cursor_row == start_row and idx < #scopes then
      local parent = scope:parent()
      if parent then
        local parent_type = parent:type()
        local scope_type = scope:type()
        local parent_is_classlike = parent_type and (parent_type:find 'class' or parent_type:find 'struct')
        local scope_is_function = scope_type and (scope_type:find 'function' or scope_type:find 'method')

        -- If we're on a method/function header and the parent is class-like, jump to the parent.
        if parent_is_classlike and scope_is_function then
          return pick_scope(idx + 1)
        end
      end
    end

    -- Avoid choosing the absolute root if there's a more meaningful parent.
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
    -- Treesitter end positions are exclusive, so if we land at col 0 of the next
    -- line (common in Python), back up to the previous line.
    if target_col == 0 and target_row > 0 then
      target_row = target_row - 1
      target_col = #vim.api.nvim_buf_get_lines(bufnr, target_row, target_row + 1, false)[1]
    end
  else
    target_row, target_col = scope:start()
  end

  local line = vim.api.nvim_buf_get_lines(bufnr, target_row, target_row + 1, false)[1] or ''
  target_col = math.min(target_col, #line)
  vim.api.nvim_win_set_cursor(0, { target_row + 1, target_col })
end

vim.keymap.set('n', '[[', function()
  _G.__jump_to_context_edge(false)
end, { desc = 'Jump to start of current context', silent = true })

vim.keymap.set('n', ']]', function()
  _G.__jump_to_context_edge(true)
end, { desc = 'Jump to end of current context', silent = true })

-- Override any ftplugin-provided [[/]] mappings (e.g., python.vim) with our context jumps.
vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    vim.keymap.set('n', '[[', function()
      _G.__jump_to_context_edge(false)
    end, { buffer = args.buf, desc = 'Jump to start of current context', silent = true })

    vim.keymap.set('n', ']]', function()
      _G.__jump_to_context_edge(true)
    end, { buffer = args.buf, desc = 'Jump to end of current context', silent = true })
  end,
})
