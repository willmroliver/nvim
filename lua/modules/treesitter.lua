vim.pack.add({
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter' },
})

require('nvim-treesitter').install({
  'asm',
  'bash',
  'c',
  'cpp',
  'go',
  'nasm',
  'python',
  'regex',
  'rust',
  'zig',

  'css',
  'html',
  'javascript',
  'lua',
  'php',
  'typescript',

  'json',
  'markdown',
  'xml',
  'yaml',

  'make',
  'cmake',
  'dockerfile',
  'terraform',
  'toml',
}):wait(300000)

vim.treesitter.language.register('php', 'html')

vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    if vim.tbl_contains({
          'NvimTree',
          'NvimTreeFilter',
          'TelescopePrompt',
          'TelescopeResults',
          'help',
          'mason_backdrop',
          'mason',
        }, vim.bo[args.buf].filetype) then
      return
    end

    vim.treesitter.start()
  end
})
