-- Buffer-local Rust settings and cargo quick actions.
-- Requires the `cargo` compiler plugin (ships with Neovim).

vim.bo.expandtab = true
vim.bo.tabstop = 4
vim.bo.shiftwidth = 4
vim.bo.softtabstop = 4
vim.bo.textwidth = 100
vim.bo.suffixesadd = ".rs"

pcall(vim.cmd, "compiler cargo")

local function map(lhs, rhs, desc)
  vim.keymap.set("n", lhs, rhs, { buffer = true, silent = true, desc = desc })
end

map("<leader>rb", "<cmd>make build<cr>", "cargo build")
map("<leader>rt", "<cmd>make test<cr>", "cargo test")
map("<leader>rr", "<cmd>make run<cr>", "cargo run")
map("<leader>rc", "<cmd>make clippy<cr>", "cargo clippy")
map("<leader>rk", "<cmd>make check<cr>", "cargo check")

-- rust-analyzer owns formatting (rustfmt); only run when it is attached.
vim.api.nvim_create_autocmd("BufWritePre", {
  buffer = 0,
  callback = function(args)
    if vim.g.rust_format_on_save == false then
      return
    end
    local clients = vim.lsp.get_clients({ bufnr = args.buf, method = "textDocument/formatting" })
    if #clients > 0 then
      vim.lsp.buf.format({ bufnr = args.buf, async = false, timeout_ms = 3000 })
    end
  end,
})
