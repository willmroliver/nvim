vim.pack.add({
  { src = 'https://github.com/oxfist/night-owl.nvim' },
  { src = 'https://github.com/shatur/neovim-ayu' },
})

-- weird issue with night-owl color scheme not setting colors_name
vim.api.nvim_create_autocmd('ColorScheme', {
  pattern = 'night-owl',
  once = false,
  callback = function()
    vim.g.colors_name = 'night-owl'
  end,
})
