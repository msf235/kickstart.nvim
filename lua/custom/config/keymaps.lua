vim.keymap.set('n', 'Y', '"+yy', { desc = 'Copy line to system clipboard' })

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
