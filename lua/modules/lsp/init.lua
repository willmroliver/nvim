vim.pack.add({
  { src = 'https://github.com/neovim/nvim-lspconfig' },
  { src = 'https://github.com/mason-org/mason.nvim' },
  { src = 'https://github.com/mason-org/mason-lspconfig.nvim' },
})
require('mason').setup()
require('mason-lspconfig').setup({
  ensure_installed = {
    -- editor / config
    'lua_ls',
    'vimls', -- vimscript

    -- sys
    'clangd',
    'asm_lsp',
    'rust_analyzer',
    'gopls', -- go
    'zls',   -- zig
    'ocamllsp',

    -- dotnet
    'fsautocomplete', -- f#

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
  },
})

require('modules.lsp.nvim')
