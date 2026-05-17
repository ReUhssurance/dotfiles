-- Buffer operations
vim.keymap.set('n', '<leader>w', ':w<CR>', { desc = '[W]rite [B]uffer' })
vim.keymap.set('n', '<leader>q', ':q<CR>', { desc = '[Q]uit [B]uffer' })
vim.keymap.set('n', '<leader>wq', ':wq<CR>', { desc = '[W]rite [Q]uit buffer' })
vim.keymap.set('n', '<leader>bd', ':bd<CR>', { desc = '[D]elete [B]uffer' })

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>dq', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})
