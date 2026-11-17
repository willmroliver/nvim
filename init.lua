vim.cmd('set number')
vim.cmd('set relativenumber')
vim.cmd('set expandtab!')
vim.cmd('set shiftwidth=2')
vim.cmd('set tabstop=4')
vim.cmd('set clipboard=unnamedplus')

vim.g.mapleader = ' '

vim.opt.fillchars = { eob = ' ' }
vim.opt.termguicolors = true

require('modules')

-- errors
vim.keymap.set('n', '<leader>q', vim.diagnostic.setqflist, {
  desc = 'Diagnostics to quickfix',
})

-- pane switching
vim.keymap.set('n', '<C-h>', '<C-w>h')
vim.keymap.set('n', '<C-j>', '<C-w>j')
vim.keymap.set('n', '<C-k>', '<C-w>k')
vim.keymap.set('n', '<C-l>', '<C-w>l')

-- clear highlighted
vim.keymap.set('n', '<Esc>', ':noh<CR><Esc>')
