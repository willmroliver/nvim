if vim.b.did_indent then return end
vim.b.did_indent = true

vim.bo.indentexpr = "v:lua.require'modules.format.fsharp_indent'.get()"
-- also re-indent when a line starts with a closer, `| Case`, `.Method`, else
-- or with. `=|>` and `=||` put an operator back after `=|` moved it like a case
vim.bo.indentkeys = '0),0],0},!^F,o,O,=|,=|>,=||,=.,=else,=elif,=with,=finally'
vim.b.undo_indent = 'setlocal indentexpr< indentkeys<'
