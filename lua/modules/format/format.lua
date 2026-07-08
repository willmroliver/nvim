vim.pack.add({
  { src = 'https://github.com/stevearc/conform.nvim' },
})

local function local_prettier(bufnr)
  local root = vim.fs.root(bufnr or 0, {
    'node_modules',
    'package.json',
    '.git',
  })

  if not root then return nil end

  local bin = root .. '/node_modules/.bin/prettier'
  if vim.uv.fs_stat(bin) then return bin end

  return nil
end

local function prettier_if_local(bufnr)
  return local_prettier(bufnr) and { 'prettier' } or {}
end

require('conform').setup({
  formatters = {
    prettier = {
      command = function(_, ctx)
        return local_prettier(ctx.buf)
      end,
    },
  },

  formatters_by_ft = {
    javascript      = prettier_if_local,
    javascriptreact = prettier_if_local,
    typescript      = prettier_if_local,
    typescriptreact = prettier_if_local,
    css             = prettier_if_local,
    scss            = prettier_if_local,
    html            = prettier_if_local,
    svelte          = prettier_if_local,
    vue             = prettier_if_local,
    json            = prettier_if_local,
    jsonc           = prettier_if_local,
    yaml            = prettier_if_local,
    markdown        = prettier_if_local,
  },

  format_on_save = function(bufnr)
    if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
      return
    end
    return { timeout_ms = 500, lsp_format = 'fallback' }
  end,
})
