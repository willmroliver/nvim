local function new_bus(event)
  local M = {
    cbs = {}
  }

  M.add = function(cb)
    table.insert(M.cbs, cb)
  end

  vim.api.nvim_create_autocmd(event, {
    callback = function()
      for _, cb in ipairs(M.cbs) do
        cb()
      end
    end
  })

  return M
end

return new_bus
