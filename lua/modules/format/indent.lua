local tabs8      = {
  expandtab = false,
  shiftwidth = 8,
  tabstop = 8,
  softtabstop = 0,
}
local spaces4    = {
  expandtab = true,
  shiftwidth = 4,
  tabstop = 4,
  softtabstop = 4,
}
local spaces2    = {
  expandtab = true,
  shiftwidth = 2,
  tabstop = 2,
  softtabstop = 2,
}

local spaces2    = {
  expandtab = true,
  shiftwidth = 2,
  tabstop = 2,
  softtabstop = 2,
}

local type_rules = {
  asm = tabs8,

  -- ocamlformat default
  ocaml = spaces2,
  ocamlinterface = spaces2,
  dune = spaces2,
}

for _, type in ipairs({
  'html', 'php',
  'css', 'scss',
  'svelte', 'vue',
  'fsharp', -- tabs are a compile error in f#
}) do
  type_rules[type] = spaces4
end

for _, type in ipairs({
  'json', 'jsonc',
  'javascript', 'javascriptreact',
  'typescript', 'typescriptreact',
}) do
  type_rules[type] = spaces2
end

local ext_rules = {
  c = tabs8,
  h = tabs8,
  cc = spaces4,
  cpp = spaces4,
  cxx = spaces4,
  ['c++'] = spaces4,
  hh = spaces4,
  hpp = spaces4,
  hxx = spaces4,
  ['h++'] = spaces4,
}

local clang_cache = {}

-- look for a project-relative .clang-format file
local function clang_format_rule(path)
  if path == '' then return nil end

  local cfg = vim.fs.find({ '.clang-format', '_clang-format' }, {
    upward = true,
    path = vim.fs.dirname(path),
  })[1]
  if not cfg then return nil end

  local cached = clang_cache[cfg]
  if cached ~= nil then return cached or nil end

  if vim.fn.executable('clang-format') == 0 then return nil end

  local out = vim.fn.system({
    'clang-format', '--dump-config', '-style=file',
    '-assume-filename=' .. path,
  })
  if vim.v.shell_error ~= 0 then
    clang_cache[cfg] = false
    return nil
  end

  local indent = tonumber(out:match('\nIndentWidth:%s*(%d+)'))
  if not indent then
    clang_cache[cfg] = false
    return nil
  end
  local tabw = tonumber(out:match('\nTabWidth:%s*(%d+)'))
  local usetab = out:match('\nUseTab:%s*(%w+)')
  local expandtab = usetab == 'Never' or usetab == nil

  local rule = {
    expandtab = expandtab,
    shiftwidth = indent,
    tabstop = tabw or indent,
    softtabstop = expandtab and indent or 0,
  }
  clang_cache[cfg] = rule
  return rule
end

local function apply(buf, rule)
  for k, v in pairs(rule) do
    vim.bo[buf][k] = v
  end
end

vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    local ft = vim.bo[args.buf].filetype

    -- c/cpp rules need to work with clang formatting if present
    if ft == 'c' or ft == 'cpp' then
      local path = vim.api.nvim_buf_get_name(args.buf)

      local rule = clang_format_rule(path)
          or ext_rules[vim.fn.fnamemodify(path, ':e'):lower()]

      if rule then apply(args.buf, rule) end
      return
    end

    local rule = type_rules[ft]
    if rule then apply(args.buf, rule) end
  end,
})
