vim.pack.add({
  { src = 'https://github.com/nvim-tree/nvim-web-devicons' },
  { src = 'https://github.com/nvim-lualine/lualine.nvim' },
})

local M = {
  lualine = {},
  devicons = {},
}

local lualine = require('lualine')
M.lualine.init = function()
  lualine.setup({
    options = {
      theme = 'auto',
    },
  })
end

local devicons = require('nvim-web-devicons')

M.devicons.init = function()
  devicons.setup()
  devicons.set_up_highlights()
end

require('autocmd.vimenter').add(function()
  devicons.set_up_highlights()
end)

require('autocmd.colorscheme').add(function()
  devicons.set_up_highlights()
end)

return M
