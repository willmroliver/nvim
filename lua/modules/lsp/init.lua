vim.pack.add({
  { src = 'https://github.com/neovim/nvim-lspconfig' },
  { src = 'https://github.com/mason-org/mason.nvim' },
  { src = 'https://github.com/mason-org/mason-lspconfig.nvim' },
})
require('mason').setup()

local servers = {
  -- editor / config
  'lua_ls',
  'vimls', -- vimscript

  -- sys
  'clangd',
  'asm_lsp',
  'rust_analyzer',
  'gopls', -- go
  'zls',   -- zig

  -- dotnet
  -- f#. mason's registry stopped at 0.83.0, whose decompiler can't read
  -- .NET 10 assemblies (go to definition on BCL types fails). fixed in 0.85.3
  'fsautocomplete@0.86.1',

  -- script
  'bashls',
  'pyright', -- python types
  'ruff',    -- python lint / format

  -- data
  'jsonls',
  'yamlls',
  'lemminx',  -- xml
  'taplo',    -- toml
  'marksman', -- markdown
  'sqlls',    -- sql

  -- web
  'html',
  'cssls',
  'somesass_ls',           -- scss / sass
  'emmet_language_server', -- emmet expansion (html/css/jsx)
  'ts_ls',                 -- javascript / typescript
  'eslint',                -- js/ts linting (LSP)
  'intelephense',          -- php
  'svelte',                -- svelte
  'vue_ls',                -- vue

  -- infra
  'dockerls',
  'docker_compose_language_service',
  'terraformls',
  'gh_actions_ls', -- github actions workflows
}

-- mason can only build ocamllsp with opam, so skip it on machines without it
if vim.fn.executable('opam') == 1 then
  table.insert(servers, 'ocamllsp')
end

require('mason-lspconfig').setup({
  ensure_installed = servers,
})

require('modules.lsp.nvim')
require('modules.lsp.fsautocomplete')
