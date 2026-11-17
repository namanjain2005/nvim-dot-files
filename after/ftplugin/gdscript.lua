-- Buffer-local GDScript settings. Godot's style uses tabs.
local gd = require("config.gdscript")

vim.bo.expandtab = false
vim.bo.tabstop = 4
vim.bo.shiftwidth = 4
vim.bo.softtabstop = 4
vim.bo.textwidth = 100
vim.bo.suffixesadd = ".gd"

local function map(lhs, rhs, desc)
  vim.keymap.set("n", lhs, rhs, { buffer = true, silent = true, desc = desc })
end

map("<leader>gf", function()
  gd.format(0)
end, "gdformat buffer")
map("<leader>gl", function()
  gd.lint(0)
end, "gdlint buffer")
map("<leader>gc", function()
  gd.attach(0)
end, "connect Godot LSP")
map("<leader>gd", "<cmd>GodotLsp<cr>", "connect Godot LSP (command)")

if vim.g.gd_format_on_save ~= false then
  vim.api.nvim_create_autocmd("BufWritePre", {
    buffer = 0,
    callback = function()
      gd.format(0)
    end,
  })
end
