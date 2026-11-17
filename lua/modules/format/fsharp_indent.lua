-- indentexpr for f#. neither neovim nor nvim-treesitter ship f# indent rules,
-- so without this a new line only copies the line above. these are heuristics
-- for the common cases; fantomas fixes the rest on save
local M = {}

local fn = vim.fn

-- line with string contents blanked and any // comment cut, so brackets and
-- keywords inside them don't count. columns stay where they were
local function code(lnum)
  local line = fn.getline(lnum)
  local out, i, in_str = {}, 1, false
  while i <= #line do
    local c = line:sub(i, i)
    if in_str then
      if c == '\\' then
        out[#out + 1] = '__'
        i = i + 1
      elseif c == '"' then
        in_str = false
        out[#out + 1] = c
      else
        out[#out + 1] = '_'
      end
    elseif c == '"' then
      in_str = true
      out[#out + 1] = c
    elseif c == "'" and line:sub(i + 2, i + 2) == "'" then -- 'x'
      out[#out + 1] = "'_'"
      i = i + 2
    elseif c == "'" and line:sub(i + 1, i + 1) == '\\' and line:sub(i + 3, i + 3) == "'" then -- '\n'
      out[#out + 1] = "'__'"
      i = i + 3
    elseif c == '/' and line:sub(i + 1, i + 1) == '/' then
      break
    else
      out[#out + 1] = c
    end
    i = i + 1
  end
  return (table.concat(out):gsub('%s+$', ''))
end

local function first_word(s) return s:match('^[%w_!]+') end
local function last_word(s) return s:match('[%w_!]+$') end

local function is_case(s) -- `| Pattern`, not `|>` or `||`
  return s:match('^|') ~= nil and not s:match('^|[>|%]}]')
end

local open_words = {}
for _, w in ipairs({
  'then', 'else', 'do', 'do!', 'try', 'finally', 'function', 'begin', 'lazy',
  'yield', 'yield!', 'return', 'return!', 'with', 'struct', 'class', 'interface',
}) do
  open_words[w] = true
end

-- does the line end with something whose body goes on the next lines
local function opens(s)
  return s:match('[=%(%[{]$') or s:match('%->$') or s:match('<%-$')
      or s:match('[%[{]|$') or open_words[last_word(s) or '']
end

-- `let f` / `member x.F` with no `=` yet: parameters continue below
local decl_words = {}
for _, w in ipairs({ 'let', 'let!', 'use', 'use!', 'and', 'member', 'override', 'default', 'static', 'new' }) do
  decl_words[w] = true
end

-- column of the first item after the bracket at col (`[ a` -> a, `[| a` -> a)
local function item_col(s, col)
  local after = s:find('%S', col + 1)
  if after and s:sub(after, after) == '|' then after = s:find('%S', after + 1) end
  return after
end

-- skip brackets inside strings and comments when matching pairs
local function in_string_or_comment()
  local ok, node = pcall(vim.treesitter.get_node, { pos = { fn.line('.') - 1, fn.col('.') - 1 } })
  if not ok or not node then return false end
  local t = node:type()
  return t:find('string') ~= nil or t:find('comment') ~= nil or t == 'char'
end

local bracket_pat = { [')'] = { '(', ')' }, [']'] = { '\\[', '\\]' }, ['}'] = { '{', '}' } }

-- line holding the bracket that the closer at (lnum, col) closes
local function opener_line(lnum, col, closer)
  local p = bracket_pat[closer]
  fn.cursor(lnum, col)
  local pos = fn.searchpairpos(p[1], '', p[2], 'bnW', in_string_or_comment, math.max(1, lnum - 500))
  return pos[1] > 0 and pos[1] or nil
end

-- column of the last bracket left open, and of the last closer with no opener
local function brackets(s)
  local open, unmatched = {}, nil
  for i = 1, #s do
    local c = s:sub(i, i)
    if c == '(' or c == '[' or c == '{' then
      open[#open + 1] = i
    elseif c == ')' or c == ']' or c == '}' then
      if #open > 0 then open[#open] = nil else unmatched = i end
    end
  end
  return open[#open], unmatched
end

-- nearest code line above, skipping blanks, comments and #if lines
local function prev_code(lnum)
  for l = lnum - 1, 1, -1 do
    local s = code(l)
    if s:match('%S') and not s:match('^%s*#') then return l, s end
  end
end

-- first line from `from` upward indented at most `limit` that matches
local function find_up(from, limit, match)
  for l = from, math.max(1, from - 300), -1 do
    local s = vim.trim(code(l))
    if s ~= '' and fn.indent(l) <= limit and match(s) then return l end
  end
end

---@param lnum? integer
---@return integer
function M.get(lnum)
  lnum = lnum or vim.v.lnum
  local pl, praw = prev_code(lnum)
  if not pl then return 0 end

  local sw = fn.shiftwidth()
  local raw = code(lnum)
  local cur = vim.trim(raw)
  local p = vim.trim(praw)
  local pind = fn.indent(pl)

  -- `)`, `]`, `}`, `|]` starting the line: line up with the line that opened it
  local bar, closer = cur:match('^(|?)([%)%]}])')
  if closer then
    local l = opener_line(lnum, #raw:match('^%s*') + #bar + 1, closer)
    if l then return fn.indent(l) end
  end

  local w = first_word(cur)

  -- else / elif: back to the if
  if w == 'else' or w == 'elif' then
    local l = find_up(pl, pind, function(s)
      local fw = first_word(s)
      return fw == 'if' or fw == 'elif'
    end)
    if l then return fn.indent(l) end
  end

  -- with / finally of a try
  if w == 'with' or w == 'finally' then
    local l = find_up(pl, pind, function(s) return first_word(s) == 'try' end)
    if l then return fn.indent(l) end
  end

  -- `| Case` after a case body: walk out of the body to the case it belongs to
  if is_case(cur) then
    if is_case(p) then return pind end
    if not opens(p) then
      local limit = pind
      for l = pl - 1, math.max(1, pl - 300), -1 do
        if limit == 0 then break end
        local s = vim.trim(code(l))
        local ind = fn.indent(l)
        if s ~= '' and not s:match('^#') and ind < limit then
          if is_case(s) or last_word(s) == 'with' then return ind end
          limit = ind
        end
      end
    end
  end

  -- a line that closes brackets opened above belongs to the line that opened them
  local base = pind
  local open_col, unmatched = brackets(praw)
  if unmatched then
    local l = opener_line(pl, unmatched, praw:sub(unmatched, unmatched))
    if l then base = fn.indent(l) end
  end

  -- `.Method()` chained below a value
  if cur == '.' or cur:match('^%.[^.]') then
    if p:match('^%.') then return pind end
    if not opens(p) then return base + sw end
  end

  if opens(p) then
    -- `match x with` / `try ... with`: cases sit level with the match
    if last_word(p) == 'with' then
      local fw = first_word(p)
      if fw == 'match' or fw == 'match!' or fw == 'try' or fw == 'with' then return base end
    end
    -- `{ Field =` with the bracket still open: indent from the field, but
    -- `(fun x ->` bodies indent from the line
    if open_col and open_col < #praw then
      local item = item_col(praw, open_col)
      local rest = item and praw:sub(item) or ''
      if item and not rest:match('^fun%f[^%w_]') and not rest:match('^function%f[^%w_]') then
        return fn.strdisplaywidth(praw:sub(1, item - 1)) + sw
      end
    end
    return base + sw
  end

  if decl_words[first_word(p) or ''] and not p:find('=') then return base + sw end

  -- `[ a,` / `foo (a,` / `{ X = 1`: line up with the first item in the bracket
  if open_col then
    local item = item_col(praw, open_col)
    if item then return fn.strdisplaywidth(praw:sub(1, item - 1)) end
  end

  return base
end

return M
