vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })

vim.keymap.set('n', '<leader>e', ':Ex<CR>', { noremap = true, desc = 'Open file explorer' })

vim.keymap.set('n', '<leader>L', ':Lazy<CR>', { noremap = true, desc = 'Open lazy.nvim' })

vim.keymap.set('n', '<leader>qs', function()
  require('persistence').load()
end, { desc = 'Restore session' })

vim.keymap.set('n', '<C-s>', ':w<CR>', { noremap = true, desc = 'Write file' })
vim.keymap.set('i', '<C-s>', '<Esc>:w<CR>', { noremap = true, desc = 'Write file' })
