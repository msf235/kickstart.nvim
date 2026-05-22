-- lua/custom/config/keymaps.lua

-- Clipboard integration
local yank_plus = vim.fn.expand '~/.local/bin/nvim-yank-plus'

vim.g.clipboard = {
  name = 'system+tmux+file',
  copy = {
    ['+'] = { yank_plus },
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
