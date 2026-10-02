vim.pack.add({
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter' },
})

local types = {
  'asm',
  'bash',
  'c',
  'cpp',
  'go',
  'nasm',
  'ocaml',
  'ocaml_interface',
  'python',
  'regex',
  'rust',
  'zig',
  'css',
  'html',
  'javascript',
  'lua',
  'php',
  'svelte',
  'typescript',
  'vue',
  'json',
  'markdown',
  'xml',
  'yaml',
  'make',
  'cmake',
  'dockerfile',
  'terraform',
  'toml',
}

require('nvim-treesitter').install(types):wait(300000)

vim.treesitter.language.register('php', 'html')

vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    -- filetype and parser names can differ (e.g. ocamlinterface -> ocaml_interface)
    local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
    if vim.tbl_contains(types, lang) then
      vim.treesitter.start()
    end
  end
})
