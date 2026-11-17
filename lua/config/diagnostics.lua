local severity = vim.diagnostic.severity

vim.diagnostic.config({
  severity_sort = true,
  update_in_insert = false,
  underline = true,
  virtual_text = {
    spacing = 2,
    source = "if_many",
    prefix = "●",
  },
  signs = {
    text = {
      [severity.ERROR] = "E",
      [severity.WARN] = "W",
      [severity.INFO] = "I",
      [severity.HINT] = "H",
    },
  },
  float = {
    border = "rounded",
    source = true,
    header = "",
    prefix = "",
  },
  jump = {
    float = true,
    wrap = true,
  },
})
