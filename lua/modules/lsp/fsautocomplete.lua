-- fsautocomplete sometimes gives semantic tokens the wrong span: in
-- `(xs |> f).run` the method token for `run` also covers the parens and
-- spaces, and member tokens start at the `.` before the name. semantic tokens
-- draw over treesitter, so those spots get the wrong color. this trims each
-- name token to the identifier at its end and drops tokens that have none

local name_types = {}
for _, t in ipairs({
  'namespace', 'module', 'type', 'class', 'enum', 'interface', 'struct',
  'typeParameter', 'parameter', 'variable', 'property', 'enumMember', 'event',
  'function', 'method', 'member', 'macro', 'cexpr',
}) do
  name_types[t] = true
end

-- f# identifiers: letters, digits, _ and ', plus any non-ascii letter
local trailing_ident = "[%w_'\128-\255]+$"

---@param data integer[] relative encoded tokens (5 numbers each)
---@param types string[] legend token types
---@param bufnr integer
---@param encoding string client offset encoding
---@return integer[]
local function clean(data, types, bufnr, encoding)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local kept = {}
  local line, start = 0, 0 -- position of the token being decoded

  for i = 1, #data, 5 do
    local d_line, d_start, len, typ, mods =
        data[i], data[i + 1], data[i + 2], data[i + 3], data[i + 4]
    line = line + d_line
    start = d_line == 0 and start + d_start or d_start

    local keep, tok_start, tok_len = true, start, len
    if name_types[types[typ + 1]] then
      local text = lines[line + 1] or ''
      local b0 = vim.str_byteindex(text, encoding, start, false)
      local b1 = vim.str_byteindex(text, encoding, start + len, false)
      local tok = text:sub(b0 + 1, b1)
      -- ``double backtick names`` contain spaces and dots, leave them alone
      if not tok:match('^``.*``$') then
        local s = tok:find(trailing_ident)
        if not s then
          keep = false
        elseif s > 1 then
          tok_start = vim.str_utfindex(text, encoding, b0 + s - 1, false)
          tok_len = len - (tok_start - start)
        end
      end
    end

    if keep then
      kept[#kept + 1] = { line, tok_start, tok_len, typ, mods, #kept }
    end
  end

  -- trimming can move a token past the next one, and the encoding is relative
  table.sort(kept, function(a, b)
    if a[1] ~= b[1] then return a[1] < b[1] end
    if a[2] ~= b[2] then return a[2] < b[2] end
    return a[6] < b[6]
  end)

  local out = {}
  local prev_line, prev_start = 0, 0
  for _, t in ipairs(kept) do
    local rel_line = t[1] - prev_line
    out[#out + 1] = rel_line
    out[#out + 1] = rel_line == 0 and t[2] - prev_start or t[2]
    out[#out + 1] = t[3]
    out[#out + 1] = t[4]
    out[#out + 1] = t[5]
    prev_line, prev_start = t[1], t[2]
  end
  return out
end

local token_methods = {
  ['textDocument/semanticTokens/full'] = true,
  ['textDocument/semanticTokens/range'] = true,
}

vim.lsp.config('fsautocomplete', {
  on_init = function(client)
    local provider = client.server_capabilities.semanticTokensProvider
    if not provider then return end
    local types = provider.legend.tokenTypes

    local request = client.request
    client.request = function(self, method, params, handler, bufnr)
      if handler and token_methods[method] then
        local inner = handler
        handler = function(err, result, ctx, ...)
          if result and type(result.data) == 'table' and ctx.bufnr
              and vim.api.nvim_buf_is_loaded(ctx.bufnr) then
            result.data = clean(result.data, types, ctx.bufnr, client.offset_encoding)
          end
          return inner(err, result, ctx, ...)
        end
      end
      return request(self, method, params, handler, bufnr)
    end
  end,
})
