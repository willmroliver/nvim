vim.pack.add({
  'https://github.com/nvim-lua/plenary.nvim',
  {
    src = 'https://github.com/nvim-telescope/telescope.nvim',
    version = '*',
  },
})

vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    if ev.data and ev.data.name == 'telescope-fzf-native.nvim' then
      vim.system({ 'make' }, { cwd = ev.data.path })
    end
  end
})

vim.pack.add({
  'https://github.com/nvim-telescope/telescope-fzf-native.nvim',
})

local config = {
  defaults = {
    layout_config = {
      horizontal = {
        preview_cutoff = 80,
      },
    },
  },
  mappings = {},
}
require('telescope').setup(config)

local builtin = require('telescope.builtin')

vim.keymap.set('n', '<leader>ff', builtin.find_files, {
  desc = 'Telescope find files',
})

vim.keymap.set('n', '<leader>fg', builtin.live_grep, {
  desc = 'Telescope live grep',
})

vim.keymap.set("n", "<leader>fG", function()
  builtin.live_grep({
    additional_args = function()
      return { "--hidden", "--glob", "!**/.git/*" }
    end,
  })
end)

vim.keymap.set('n', '<leader>fb', builtin.buffers, {
  desc = 'Telescope buffer view',
})

vim.keymap.set('n', '<leader>gd', builtin.lsp_definitions, {
  desc = 'Telescope go to definitions',
})

vim.keymap.set('n', '<leader>gr', builtin.lsp_references, {
  desc = 'Telescope find references',
})

require('modules.telescope.themepicker')
