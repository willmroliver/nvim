-- buffer cycling and deleting
--
-- :bnext / :bprevious go by buffer number, which is handed out when a buffer
-- is created, not when you open it. language servers create hidden buffers
-- for every file they report diagnostics on, so a file you open later can
-- keep an old number and land mid-cycle. <Tab> / <S-Tab> here cycle in the
-- order you opened buffers instead.
--
-- :bd closes every window showing the buffer, and with the tree open that
-- leaves you in the tree. :Bd (and :bd, via the abbreviation below) shows the
-- previous buffer in those windows first, so the layout stays.

local order = {} -- file buffers, in the order they were opened

local function is_file_buf(buf)
  return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted and vim.bo[buf].buftype == ''
end

vim.api.nvim_create_autocmd('BufEnter', {
  callback = function(args)
    if is_file_buf(args.buf) and not vim.tbl_contains(order, args.buf) then
      table.insert(order, args.buf)
    end
  end,
})

-- a deleted buffer that's opened again goes to the end
vim.api.nvim_create_autocmd('BufDelete', {
  callback = function(args)
    for i, b in ipairs(order) do
      if b == args.buf then
        table.remove(order, i)
        return
      end
    end
  end,
})

-- open buffers in order, then any never entered yet (extra files given on
-- the command line) by number
local function buffers()
  local list = vim.tbl_filter(is_file_buf, order)
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if is_file_buf(b) and not vim.tbl_contains(list, b) then table.insert(list, b) end
  end
  return list
end

local function index_of(list, buf)
  for i, b in ipairs(list) do
    if b == buf then return i end
  end
end

local function cycle(step)
  -- from the tree (or help, quickfix...), cycle the file window you came from
  if not is_file_buf(vim.api.nvim_get_current_buf()) then
    local prev = vim.fn.win_getid(vim.fn.winnr('#'))
    if prev ~= 0 and is_file_buf(vim.api.nvim_win_get_buf(prev)) then
      vim.api.nvim_set_current_win(prev)
    end
  end

  local list = buffers()
  local i = index_of(list, vim.api.nvim_get_current_buf())
  if not i then
    if #list > 0 then vim.cmd.buffer(list[step > 0 and 1 or #list]) end
    return
  end
  vim.cmd.buffer(list[(i - 1 + step) % #list + 1])
end

vim.keymap.set('n', '<Tab>', function() cycle(1) end, { desc = 'Next buffer (open order)' })
vim.keymap.set('n', '<S-Tab>', function() cycle(-1) end, { desc = 'Previous buffer (open order)' })

local function delete(buf, bang)
  if vim.bo[buf].modified and not bang then
    vim.notify(('E89: No write since last change for buffer %d (add ! to override)'):format(buf),
      vim.log.levels.ERROR)
    return
  end

  -- show the buffer before it in open order (or after, if it's first)
  local list = buffers()
  local i = index_of(list, buf)
  local instead = i and (list[i - 1] or list[i + 1])
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    if instead then
      vim.api.nvim_win_set_buf(win, instead)
    else
      vim.api.nvim_win_call(win, function() vim.cmd.enew() end)
    end
  end

  local ok, err = pcall(vim.cmd, ('bdelete%s %d'):format(bang and '!' or '', buf))
  if not ok then vim.notify(tostring(err):gsub('^Vim:', ''), vim.log.levels.ERROR) end
end

vim.api.nvim_create_user_command('Bd', function(opts)
  local buf = vim.api.nvim_get_current_buf()
  if opts.args ~= '' then
    buf = tonumber(opts.args) or vim.fn.bufnr(opts.args)
    if buf < 1 or not vim.api.nvim_buf_is_valid(buf) then
      vim.notify('E94: No matching buffer for ' .. opts.args, vim.log.levels.ERROR)
      return
    end
  end
  delete(buf, opts.bang)
end, { bang = true, nargs = '?', complete = 'buffer', desc = 'Delete buffer, keep its windows' })

-- typing :bd runs :Bd (:bdelete is still the built-in)
vim.cmd([[cnoreabbrev <expr> bd getcmdtype() ==# ':' && getcmdline() ==# 'bd' ? 'Bd' : 'bd']])
