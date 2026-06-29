require('modules.ui.theme')

local deps = require('modules.ui.deps')

local theme_file = vim.fn.stdpath('config') .. '/theme.txt'

vim.api.nvim_create_autocmd('ColorScheme', {
  callback = function()
    local theme = vim.g.colors_name
    if not theme then return end

    vim.fn.writefile({ theme }, theme_file)

    deps.devicons.init()
    deps.lualine.init()
  end,
})

vim.api.nvim_create_autocmd('UIEnter', {
  once = true,
  callback = function()
    local ok, lines = pcall(vim.fn.readfile, theme_file)
    if ok and lines[1] then
      pcall(vim.cmd.colorscheme, lines[1])
    end

    deps.devicons.init()
    deps.lualine.init(lines[1])
  end,
})
