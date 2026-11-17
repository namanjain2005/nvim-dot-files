-- Debounced auto-completion: the popup appears once you pause typing.
--   vim.g.completion_autotrigger = false  -- disable
--   vim.g.completion_delay = 120          -- pause in ms
local M = {}

local timer = (vim.uv or vim.loop).new_timer()

function M.fire()
  if vim.fn.mode():sub(1, 1) ~= "i" then
    return
  end
  if vim.fn.pumvisible() == 1 then
    return
  end
  if #vim.lsp.get_clients({ bufnr = 0, method = "textDocument/completion" }) == 0 then
    return
  end
  vim.lsp.completion.get()
end

function M.schedule()
  if vim.g.completion_autotrigger == false then
    return
  end
  local delay = tonumber(vim.g.completion_delay) or 120
  timer:stop()
  timer:start(delay, 0, vim.schedule_wrap(M.fire))
end

function M.setup()
  vim.api.nvim_create_autocmd("InsertCharPre", {
    group = vim.api.nvim_create_augroup("config_completion", { clear = true }),
    callback = function()
      if vim.v.char:match("%S") then
        M.schedule()
      end
    end,
  })

  vim.api.nvim_create_autocmd("InsertLeave", {
    group = "config_completion",
    callback = function()
      timer:stop()
    end,
  })
end

return M
