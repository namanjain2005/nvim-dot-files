-- Java-specific defaults and JDTLS source actions.
vim.bo.expandtab = true
vim.bo.shiftwidth = 4
vim.bo.softtabstop = 4

vim.keymap.set("n", "<leader>jo", function()
  vim.lsp.buf.code_action({
    context = {
      only = { "source.organizeImports" },
      diagnostics = {},
    },
  })
end, { buffer = true, desc = "Java: organize imports" })
