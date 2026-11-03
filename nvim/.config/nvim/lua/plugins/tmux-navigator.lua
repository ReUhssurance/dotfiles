local opts = {
  noremap = true,
  silent = true,
}

vim.keymap.set('n', '<leader>va', ':VtrAttachToPane<CR>', opts)
vim.keymap.set('n', '<leader>vl', ':VtrSendLinesToRunner<CR>', opts)
vim.keymap.set('v', '<leader>vl', ':VtrSendLinesToRunner<CR>', opts)

-- Inside herdr, vim-tmux-navigator has no tmux to talk to, so <C-hjkl> would
-- stop at the outermost window. Move within nvim first and hand off to herdr
-- only when the window did not change, which is the half of the handoff that
-- herdr's own bin/herdr-nav cannot do.
local in_herdr = vim.env.HERDR_PANE_ID ~= nil and vim.env.TMUX == nil

if in_herdr then
  vim.g.tmux_navigator_no_mappings = 1

  for key, direction in pairs { h = 'left', j = 'down', k = 'up', l = 'right' } do
    vim.keymap.set('n', '<C-' .. key .. '>', function()
      local from = vim.api.nvim_get_current_win()
      vim.cmd.wincmd(key)
      if vim.api.nvim_get_current_win() == from then
        vim.fn.jobstart { 'herdr', 'pane', 'focus', '--direction', direction, '--current' }
      end
    end, vim.tbl_extend('force', opts, { desc = 'Focus window or herdr pane ' .. direction }))
  end
end

return {
  'christoomey/vim-tmux-navigator',
  'christoomey/vim-tmux-runner',
}
