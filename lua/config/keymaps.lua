local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Keep the cursor centred on jumps.
map("n", "<C-d>", "<C-d>zz", opts)
map("n", "<C-u>", "<C-u>zz", opts)
map("n", "n", "nzzzv", opts)
map("n", "N", "Nzzzv", opts)

-- Move lines/selection.
map("n", "<A-j>", "<cmd>m .+1<cr>==", opts)
map("n", "<A-k>", "<cmd>m .-2<cr>==", opts)
map("v", "<A-j>", ":m '>+1<cr>gv=gv", opts)
map("v", "<A-k>", ":m '<-2<cr>gv=gv", opts)

-- Buffers.
map("n", "<S-l>", "<cmd>bnext<cr>", opts)
map("n", "<S-h>", "<cmd>bprevious<cr>", opts)
map("n", "<leader>bd", "<cmd>bdelete<cr>", opts)

-- Quickfix / location list.
map("n", "<leader>qo", "<cmd>copen<cr>", opts)
map("n", "<leader>qc", "<cmd>cclose<cr>", opts)

-- Terminal.
map("n", "<leader>tt", "<cmd>botright split | terminal<cr>", opts)
map("t", "<Esc><Esc>", "<C-\\><C-n>", opts)

-- Diagnostics.
map("n", "<leader>dd", vim.diagnostic.open_float, { desc = "Line diagnostics" })
map("n", "<leader>dq", vim.diagnostic.setqflist, { desc = "Diagnostics to quickfix" })
map("n", "<leader>dl", vim.diagnostic.setloclist, { desc = "Diagnostics to loclist" })
map("n", "<leader>dt", function()
  local on = vim.diagnostic.is_enabled()
  vim.diagnostic.enable(not on)
  vim.notify("diagnostics " .. (on and "disabled" or "enabled"))
end, { desc = "Toggle diagnostics" })

-- LSP (grn/gra/grr/K/[d/]d already exist in Neovim 0.11+).
map("n", "<leader>lf", function()
  vim.lsp.buf.format({ async = true })
end, { desc = "Format buffer" })
map("n", "<leader>li", "<cmd>checkhealth vim.lsp<cr>", { desc = "LSP health" })
map("n", "<leader>lr", "<cmd>LspRestart<cr>", { desc = "Restart LSP clients" })
map("n", "<leader>lh", vim.lsp.buf.hover, { desc = "Hover" })
map("n", "<leader>ls", vim.lsp.buf.signature_help, { desc = "Signature help" })
map("n", "<leader>ld", vim.lsp.buf.definition, { desc = "Definition" })
map("n", "<leader>lD", vim.lsp.buf.declaration, { desc = "Declaration" })
map("n", "<leader>lt", vim.lsp.buf.type_definition, { desc = "Type definition" })
map("n", "<leader>lR", vim.lsp.buf.references, { desc = "References" })
map("n", "<leader>lI", vim.lsp.buf.implementation, { desc = "Implementation" })
map("n", "<leader>lS", vim.lsp.buf.workspace_symbol, { desc = "Workspace symbols" })
map("n", "<leader>ln", vim.lsp.buf.rename, { desc = "Rename symbol" })
map("n", "<leader>la", vim.lsp.buf.code_action, { desc = "Code action" })
map("n", "<leader>lo", vim.lsp.buf.document_symbol, { desc = "Document symbols" })
