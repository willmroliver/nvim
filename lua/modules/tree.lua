vim.pack.add({
  { src = 'https://github.com/nvim-tree/nvim-tree.lua' },
})

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

local tree = require('nvim-tree')

--@type nvim_tree.config
local config = {
  view = {
    width = 30,
  },
  hijack_netrw = true,
  sync_root_with_cwd = true,
  update_focused_file = {
    enable = true,
    update_root = true,
    -- files here don't move the root (and cwd). fsautocomplete decompiles
    -- std lib types into the temp dir; rooting the tree there froze nvim
    -- watching thousands of temp folders (go builds etc.)
    ignore_list = { vim.uv.os_tmpdir() },
  },
  renderer = {
    highlight_git = false,
    highlight_opened_files = 'none',
    highlight_modified = 'none',
    highlight_bookmarks = 'none',
    highlight_diagnostics = 'none',
    highlight_clipboard = 'none',
  },
}

tree.setup(config)

local api = require('nvim-tree.api')

vim.keymap.set('n', '<C-n>', api.tree.toggle, {
  desc = 'Toggle NvimTree',
})

vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    api.tree.open()
  end,
})
vim.api.nvim_create_autocmd('ColorScheme', {
  callback = function()
    api.tree.reload()
  end,
})
