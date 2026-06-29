local builtin = require('telescope.builtin')

vim.keymap.set('n', '<leader>th', function()
  builtin.colorscheme({
    enable_preview = true,
    attach_mappings = function(_, map)
      local actions = require('telescope.actions')
      local state = require('telescope.actions.state')

      map('i', '<CR>', function(bufnr)
        local theme = state.get_selected_entry().value
        actions.close(bufnr)

        vim.schedule(function()
          vim.cmd.colorscheme(theme)
        end)
      end)

      return true
    end,
  })
end, { desc = 'Telescope theme picker' })
