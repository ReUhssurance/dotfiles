-- Obsidian and WIKI plugins

local opts = {
  noremap = true,
  silent = true
}

-- Obsidian
vim.keymap.set("n", "<leader>os", ":ObsidianSearch<CR>", opts)
vim.keymap.set("n", "<leader>osb", ":ObsidianBacklinks<CR>", opts)
vim.keymap.set("n", "<leader>ost", ":ObsidianToday<CR>", opts)
vim.keymap.set("n", "<leader>osy", ":ObsidianYesterday<CR>", opts)
vim.keymap.set("n", "<leader>osn", ":ObsidianNew<CR>", opts)
vim.keymap.set("n", "<leader>ok", ":!mv '%:p' ~/main-vault/permanent<cr>:bd<cr>")
vim.keymap.set("n", "<leader>odd", ":!rm '%:p'<cr>:bd<cr>")

return {
  {
    'ixru/nvim-markdown',
  },
  {
    'iamcco/markdown-preview.nvim',
    ft = 'markdown',
    build = 'cd app && npm install',
  },
  {
    'epwalsh/obsidian.nvim',
    requires = {
      'nvim-lua/plenary.nvim',
    },
    config = function()
      require('obsidian').setup({
        -- workspaces = {
        --   {
        --     name = 'personal',
        --     path = '~/vaults/personal',
        --   },
        -- },
        dir = '~/main-vault',
        completion = {
          nvim_cmp = true,
          min_chars = 3,
        },
        daily_notes = {
          folder = 'daily',
          date_format = '%Y-%m-%d',
          template = 'daily.md',
        },
        notes_subdir = 'inbox',
        new_notes_location = 'notes_subdir',
        templates = {
          folder = 'templates',
          date_format = '%Y-%m-%d',
          time_format = '%H:%M',
        },
        ui = {
          enabled = false,
        },
        note_id_func = function(title)
          local suffix = ''
          if title ~= nil then
            suffix = title:gsub(' ', '-'):lower()
          else
            for _ = 1, 4 do
              suffix = suffix .. string.char(math.random(65, 90))
            end
          end
          return tostring(os.date('%Y-%m-%d')) .. '-' .. suffix
        end,
        note_frontmatter_func = function(note)
          if note.title then
            note:add_alias(note.title)
          end

          local today = os.date('%Y-%m-%d')
          note:add_tag(today)

          local out = { id = note.id, aliases = note.aliases, tags = note.tags }

          if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
            for k, v in pairs(note.metadata) do
              out[k] = v
            end
          end

          return out
        end,
        follow_url_func = function(url)
          vim.fn.jobstart({ 'open', url })
        end,
      })
    end,
  },
}
