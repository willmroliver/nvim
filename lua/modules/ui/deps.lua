vim.pack.add({
  { src = 'https://github.com/nvim-tree/nvim-web-devicons' },
  { src = 'https://github.com/nvim-lualine/lualine.nvim' },
})

local M = {
  lualine = {},
  devicons = {},
}

local lualine = require('lualine')
M.lualine.init = function(th)
  lualine.setup({
    options = {
      theme = th or 'auto',
      globalstatus = true,
    },
    extensions = {
      {
        filetypes = { 'NvimTree' },
        sections = {},
      },
    },
  })
end

local devicons = require('nvim-web-devicons')

M.devicons.init = function()
  devicons.setup()
  devicons.set_up_highlights()
end

vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    devicons.set_up_highlights()
  end,
})

vim.api.nvim_create_autocmd('ColorScheme', {
  callback = function()
    devicons.set_up_highlights()
  end,
})

return M
