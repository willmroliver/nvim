vim.pack.add({
  'https://github.com/saghen/blink.lib',
  'https://github.com/saghen/blink.cmp',
})

local cmp = require('blink.cmp')
cmp.build():pwait()
cmp.setup({
  -- required to preserve insert-mode recording
  enabled = function()
    return vim.fn.reg_recording() == ''
        and vim.fn.reg_executing() == ''
        and vim.bo.buftype ~= 'prompt'
        and vim.b.completion ~= false
  end,
  keymap = {
    ['<CR>'] = { 'accept', 'fallback' },
  },
})
